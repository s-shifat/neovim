local M = {}

local FORMATS = {
  "png",
  "jpg",
  "jpeg",
  "gif",
  "bmp",
  "webp",
  "tiff",
  "heic",
  "avif",
  "pdf",
}

local config = {
  image = {
    enabled = true,
    formats = FORMATS,
    force = false,
    doc = {
      enabled = false,
      inline = false,
      float = false,
    },
    math = {
      enabled = false,
    },
    convert = {
      notify = true,
    },
  },
}

local DEBOUNCE_MS = 150
local MISSING_RETRIES = 6
local VIEWER_MARKER = "user_snacks_image_viewer"

local uv = vim.uv or vim.loop
local watchers = {}
local fingerprint_timers = {}
local pending_restores = {}
local stop_fingerprint_timer


function M.is_viewer(buf)
  return vim.api.nvim_buf_is_valid(buf)
    and vim.b[buf][VIEWER_MARKER] == true
end


function M.normalize_viewer(buf)
  if not M.is_viewer(buf) then
    return false
  end
  vim.bo[buf].autoread = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
  return true
end


function M.handle_external_change(buf)
  if not M.normalize_viewer(buf) then
    return false
  end
  -- The libuv watcher owns rendering. An empty choice tells Neovim that this
  -- buffer-local handler has reconciled the timestamp change without asking
  -- it to reload the binary source as text.
  vim.v.fcs_choice = ""
  return true
end


local function placement_registry()
  -- Snacks 2.31.0 keeps its placement registry private and exposes no passive
  -- getter. Read the registry captured by clean() so BufWinEnter never calls a
  -- constructor while terminal detection/attachment is still in progress.
  local placement = package.loaded["snacks.image.placement"]
  if type(placement) ~= "table" or type(placement.clean) ~= "function" then
    return nil
  end
  local clean = placement.clean
  local index = 1
  while true do
    local name, value = debug.getupvalue(clean, index)
    if not name then
      return nil
    end
    if name == "placements" and type(value) == "table" then
      return value
    end
    index = index + 1
  end
end


function M.existing_placements(buf)
  local registry = placement_registry()
  return registry and registry[buf] or nil
end


function M.restore_placement(buf)
  if not M.is_viewer(buf) or #vim.fn.win_findbuf(buf) == 0 then
    return 0
  end

  local restored = 0
  for _, placement in pairs(M.existing_placements(buf) or {}) do
    if placement.buf == buf and placement.hidden and not placement.closed then
      placement:show()
      restored = restored + 1
    end
  end
  return restored
end


function M.queue_placement_restore(buf)
  if pending_restores[buf] or not M.is_viewer(buf) then
    return false
  end
  pending_restores[buf] = true
  vim.schedule(function()
    pending_restores[buf] = nil
    M.restore_placement(buf)
  end)
  return true
end


function M.mark_viewer(buf, group)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  if M.is_viewer(buf) then
    return M.normalize_viewer(buf)
  end

  vim.b[buf][VIEWER_MARKER] = true
  vim.api.nvim_create_autocmd("FileChangedShell", {
    group = group,
    buffer = buf,
    callback = function(event)
      M.handle_external_change(event.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    buffer = buf,
    callback = function(event)
      M.queue_placement_restore(event.buf)
    end,
  })
  -- Snacks writes temporary progress/error lines after attach. Track actual
  -- buffer text changes so those internal writes can never acquire editing
  -- semantics or produce a save prompt.
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function()
      vim.schedule(function()
        M.normalize_viewer(buf)
      end)
    end,
  })
  return M.normalize_viewer(buf)
end


local function close_handle(handle)
  if handle and not handle:is_closing() then
    handle:close()
  end
end


function M.stop(buf)
  pending_restores[buf] = nil
  local watcher = watchers[buf]
  if not watcher then
    return
  end

  watchers[buf] = nil
  stop_fingerprint_timer(watcher.file)
  if watcher.timer then
    watcher.timer:stop()
    close_handle(watcher.timer)
  end
  if watcher.event then
    watcher.event:stop()
    close_handle(watcher.event)
  end
end


local function normalize(file)
  return vim.fs.normalize(vim.fn.fnamemodify(file, ":p"))
end


stop_fingerprint_timer = function(file)
  local normalized = file and normalize(file)
  local timer = fingerprint_timers[normalized]
  if timer then
    fingerprint_timers[normalized] = nil
    timer:stop()
    close_handle(timer)
  end
end


function M.fingerprint_path(file)
  local directory = vim.fn.stdpath("state") .. "/image-fingerprints"
  return directory .. "/" .. vim.fn.sha256(normalize(file)) .. ".json"
end


function M.fingerprint(file)
  local stat = uv.fs_stat(normalize(file))
  if not stat or stat.type ~= "file" then
    return nil
  end
  return {
    path = normalize(file),
    size = stat.size,
    mtime_sec = stat.mtime.sec,
    mtime_nsec = stat.mtime.nsec,
  }
end


function M.same_fingerprint(left, right)
  return type(left) == "table"
    and type(right) == "table"
    and left.path == right.path
    and left.size == right.size
    and left.mtime_sec == right.mtime_sec
    and left.mtime_nsec == right.mtime_nsec
end


function M.read_fingerprint(file)
  local read_ok, lines = pcall(vim.fn.readfile, M.fingerprint_path(file))
  if not read_ok or #lines ~= 1 then
    return nil
  end
  local ok, fingerprint = pcall(vim.json.decode, lines[1])
  return ok and type(fingerprint) == "table" and fingerprint or nil
end


local function write_fingerprint(file, fingerprint)
  local path = M.fingerprint_path(file)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local temporary = path .. "." .. vim.fn.getpid() .. ".tmp"
  local wrote = vim.fn.writefile({ vim.json.encode(fingerprint) }, temporary) == 0
  local renamed = wrote and uv.fs_rename(temporary, path) or nil
  if not renamed then
    pcall(uv.fs_unlink, temporary)
    return false
  end
  return true
end


function M.invalidate_snacks_cache(file)
  -- This Snacks version has no public reload API. Its converter considers an
  -- existing per-source output complete, so rebuild the same conversion plan
  -- and remove only that source's derived files before reattaching the view.
  local convert = require("snacks.image.convert").convert({ src = file })
  for _, step in ipairs(convert.steps) do
    if step.file ~= convert.src then
      for _, derived in ipairs({ step.file, step.file .. ".info" }) do
        if uv.fs_stat(derived) then
          local removed = uv.fs_unlink(derived)
          if not removed then
            return false
          end
        end
      end
    end
  end

  -- Image.clear() is the smallest upstream-provided cache reset available.
  -- Existing placements retain their image objects; the target buffer below
  -- receives a fresh object and terminal image id when it is reattached.
  require("snacks.image.image").clear()
  return true
end


function M.prepare_source(file, force)
  local current = M.fingerprint(file)
  if not current then
    return false
  end
  if not force and M.same_fingerprint(current, M.read_fingerprint(file)) then
    return true, false
  end
  if not M.invalidate_snacks_cache(file) then
    return false
  end
  return true, true
end


function M.record_fingerprint_when_ready(file)
  file = normalize(file)
  local current = M.fingerprint(file)
  if not current then
    return
  end

  stop_fingerprint_timer(file)
  local timer = uv.new_timer()
  if not timer then
    return
  end
  fingerprint_timers[file] = timer
  local attempts = 0
  timer:start(50, 100, vim.schedule_wrap(function()
    attempts = attempts + 1
    local latest = M.fingerprint(file)
    local convert = require("snacks.image.convert").convert({ src = file })
    local stat = uv.fs_stat(convert.file)
    if M.same_fingerprint(current, latest) and stat and stat.size > 0 then
      write_fingerprint(file, current)
      fingerprint_timers[file] = nil
      timer:stop()
      close_handle(timer)
    elseif attempts >= 100 or not latest then
      fingerprint_timers[file] = nil
      timer:stop()
      close_handle(timer)
    end
  end))
end


local function refresh(buf, file)
  if not M.is_viewer(buf) or vim.bo[buf].filetype ~= "image" then
    M.stop(buf)
    return true
  end
  if vim.fn.filereadable(file) ~= 1 then
    return false
  end

  local ok, err = pcall(function()
    assert(M.prepare_source(file, true), "could not prepare changed image source")
    require("snacks.image.placement").clean(buf)
    require("snacks.image.buf").attach(buf, { src = file })
    M.normalize_viewer(buf)
    vim.schedule(function()
      M.normalize_viewer(buf)
    end)
    M.record_fingerprint_when_ready(file)
  end)
  if not ok then
    vim.notify_once(
      "Image live refresh failed: " .. tostring(err),
      vim.log.levels.WARN
    )
  end
  return true
end


local function queue_refresh(buf, retries)
  local watcher = watchers[buf]
  if not watcher then
    return
  end

  watcher.timer:stop()
  watcher.timer:start(DEBOUNCE_MS, 0, vim.schedule_wrap(function()
    local current = watchers[buf]
    if not current then
      return
    end
    if not refresh(buf, current.file) and retries > 0 then
      queue_refresh(buf, retries - 1)
    end
  end))
end


function M.watch(buf)
  if watchers[buf] or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local file = vim.api.nvim_buf_get_name(buf)
  local directory = vim.fs.dirname(file)
  local filename = vim.fs.basename(file)
  if file == "" or not directory then
    return
  end

  local event = uv.new_fs_event()
  local timer = uv.new_timer()
  if not event or not timer then
    close_handle(event)
    close_handle(timer)
    return
  end

  watchers[buf] = {
    event = event,
    timer = timer,
    file = file,
  }
  local ok, err = event:start(directory, {}, vim.schedule_wrap(function(event_err, changed)
    if event_err then
      M.stop(buf)
      vim.notify_once(
        "Image live refresh watcher failed: " .. tostring(event_err),
        vim.log.levels.WARN
      )
      return
    end
    if changed == nil or changed == filename then
      queue_refresh(buf, MISSING_RETRIES)
    end
  end))
  if not ok then
    M.stop(buf)
    vim.notify_once(
      "Could not watch image for live refresh: " .. tostring(err),
      vim.log.levels.WARN
    )
  end
end


function M.setup()
  local group = vim.api.nvim_create_augroup("user.image_live_refresh", { clear = true })
  -- Register before Snacks so stale persistent artifacts are removed before
  -- its direct-view BufReadCmd creates an image from them.
  vim.api.nvim_create_autocmd("BufReadCmd", {
    group = group,
    pattern = "*." .. table.concat(FORMATS, ",*."),
    callback = function(event)
      M.mark_viewer(event.buf, group)
      local ok, prepared, changed = pcall(M.prepare_source, event.file, false)
      if not ok or not prepared then
        vim.notify_once(
          "Image cache freshness check failed: " .. tostring(prepared),
          vim.log.levels.WARN
        )
      elseif changed then
        M.record_fingerprint_when_ready(event.file)
      end
    end,
  })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "image",
    callback = function(event)
      M.mark_viewer(event.buf, group)
      vim.schedule(function()
        M.normalize_viewer(event.buf)
      end)
      M.watch(event.buf)
    end,
  })
  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = group,
    callback = function(event)
      M.stop(event.buf)
    end,
  })
end


function M.active_watchers()
  return vim.tbl_count(watchers)
end


function M.snacks_config()
  return vim.deepcopy(config)
end


return M
