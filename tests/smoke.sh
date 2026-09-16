#!/usr/bin/env bash

set -euo pipefail

nvim_bin="${NVIM_SMOKE_NVIM:-nvim}"
expected_runtime="${NVIM_SMOKE_EXPECT_RUNTIME:-}"

fail() {
  echo "neovim-smoke: FAIL: $*" >&2
  exit 1
}

if [[ "$nvim_bin" == */* ]]; then
  [[ -x "$nvim_bin" ]] ||
    fail "Neovim executable does not exist: $nvim_bin"
else
  command -v "$nvim_bin" >/dev/null 2>&1 ||
    fail "Neovim executable is not available: $nvim_bin"
fi

tmp_dir="$(mktemp -d)"

cleanup() {
  rm -rf "$tmp_dir"
}

trap cleanup EXIT

export HOME="$tmp_dir/home"
export XDG_CONFIG_HOME="$tmp_dir/xdg-config"
export XDG_DATA_HOME="$tmp_dir/xdg-data"
export XDG_STATE_HOME="$tmp_dir/xdg-state"
export XDG_CACHE_HOME="$tmp_dir/xdg-cache"

# Test the editor's declared default theme, not a caller-provided temporary override.
unset NVIM_COLORSCHEME

mkdir -p \
  "$HOME" \
  "$XDG_CONFIG_HOME" \
  "$XDG_DATA_HOME" \
  "$XDG_STATE_HOME" \
  "$XDG_CACHE_HOME"

probe="$tmp_dir/probe.lua"
sentinel="$tmp_dir/smoke-ok"

export NVIM_SMOKE_SENTINEL="$sentinel"

cat > "$probe" <<'LUA'
local function fail(message)
  vim.api.nvim_err_writeln("neovim-smoke: FAIL: " .. message)
  vim.cmd("cquit 1")
end

if vim.g.neovim_config_loaded ~= true then
  fail("packaged Neovim configuration did not finish loading")
end

-- Verify that the Nix-packaged theme plugin and declared default colorscheme loaded.
local catppuccin_ok, catppuccin_err = pcall(require, "catppuccin")

if not catppuccin_ok then
  fail(
    "Catppuccin plugin is unavailable: "
      .. tostring(catppuccin_err)
  )
end

local theme_default = vim.g.neovim_theme_default
local theme_requested = vim.g.neovim_theme_requested
local theme_loaded = vim.g.neovim_theme_loaded

if type(theme_default) ~= "string" or theme_default == "" then
  fail("default colorscheme was not declared")
end

if theme_requested ~= theme_default then
  fail(
    ("startup requested colorscheme '%s', expected default '%s'")
      :format(
        tostring(theme_requested),
        tostring(theme_default)
      )
  )
end

if theme_loaded ~= theme_requested then
  fail(
    ("requested colorscheme '%s' but loaded '%s'")
      :format(
        tostring(theme_requested),
        tostring(theme_loaded)
      )
  )
end

if vim.g.colors_name ~= theme_loaded then
  fail(
    ("Neovim reports active colorscheme '%s', expected '%s'")
      :format(
        tostring(vim.g.colors_name),
        tostring(theme_loaded)
      )
  )
end

-- Verify that the shared icon provider was initialized during normal UI startup.
local devicons_ok, devicons = pcall(require, "nvim-web-devicons")

if not devicons_ok then
  fail("nvim-web-devicons plugin is unavailable")
end

if devicons.has_loaded() ~= true then
  fail("nvim-web-devicons was not initialized during UI startup")
end

-- Verify that the packaged statusline initialized and replaced native mode text.
if package.loaded.lualine == nil then
  fail("Lualine was not initialized during UI startup")
end

if vim.o.showmode then
  fail("native showmode remained enabled after Lualine initialized")
end

if vim.o.laststatus ~= 3 then
  fail("Lualine did not configure one global statusline")
end

-- Verify that the packaged Git-sign layer is available and initialized.
local gitsigns_ok, gitsigns_err = pcall(require, "gitsigns")

if not gitsigns_ok then
  fail("Gitsigns plugin is unavailable: " .. tostring(gitsigns_err))
end

if package.loaded.gitsigns == nil then
  fail("Gitsigns was not initialized during UI startup")
end

if vim.fn.executable("git") ~= 1 then
  fail("Git is unavailable to the packaged editor")
end

-- Verify the Stage 8A search stack is packaged and initialized through the
-- normal navigation entry point.
for _, dependency in ipairs({
  "plenary",
  "telescope",
  "telescope._extensions.fzf",
  "telescope._extensions.ui-select",
  "telescope._extensions.live_grep_args",
}) do
  local dependency_ok, dependency_err = pcall(require, dependency)

  if not dependency_ok then
    fail(("Telescope dependency '%s' is unavailable: %s"):format(
      dependency,
      tostring(dependency_err)
    ))
  end
end


if vim.g.neovim_telescope_loaded ~= true then
  fail("Telescope navigation setup did not finish")
end


for _, executable in ipairs({ "rg", "fd", "magick", "gs" }) do
  if vim.fn.executable(executable) ~= 1 then
    fail(("required executable '%s' is unavailable"):format(executable))
  end
end

-- Verify that Snacks owns notifications and provides the Stage 8B Explorer
-- without enabling unrelated automatic modules.
local snacks_ok, snacks = pcall(require, "snacks")

if not snacks_ok then
  fail("Snacks plugin is unavailable")
end

if snacks.did_setup ~= true then
  fail("Snacks was not initialized during UI startup")
end

if snacks.config.notifier.enabled ~= true then
  fail("Snacks notifier is not enabled")
end

if snacks.config.explorer.enabled ~= true then
  fail("Snacks Explorer is not enabled")
end

if snacks.config.explorer.replace_netrw ~= true then
  fail("Snacks Explorer does not own directory opening")
end

if snacks.config.picker.enabled ~= true then
  fail("Snacks Picker infrastructure is not enabled for Explorer")
end

if snacks.config.image.enabled ~= true then
  fail("Snacks image viewing is not enabled")
end

local image_formats = {
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

if not vim.deep_equal(snacks.config.image.formats, image_formats) then
  fail("Snacks image formats differ from the supported direct-file scope")
end

if snacks.config.image.force ~= false then
  fail("Snacks image terminal detection is being forced")
end

if snacks.config.image.doc.enabled ~= false
  or snacks.config.image.doc.inline ~= false
  or snacks.config.image.doc.float ~= false
  or snacks.config.image.math.enabled ~= false
then
  fail("Snacks document or math image rendering is unexpectedly enabled")
end

if snacks.config.image.convert.notify ~= true then
  fail("Snacks image conversion failures will not notify the user")
end

local image_view = require("user.ui.image")
if type(image_view.setup) ~= "function"
  or type(image_view.watch) ~= "function"
  or type(image_view.stop) ~= "function"
  or type(image_view.prepare_source) ~= "function"
  or type(image_view.invalidate_snacks_cache) ~= "function"
  or type(image_view.record_fingerprint_when_ready) ~= "function"
  or type(image_view.is_viewer) ~= "function"
  or type(image_view.mark_viewer) ~= "function"
  or type(image_view.normalize_viewer) ~= "function"
  or type(image_view.handle_external_change) ~= "function"
  or type(image_view.existing_placements) ~= "function"
  or type(image_view.restore_placement) ~= "function"
  or type(image_view.queue_placement_restore) ~= "function"
  or image_view.active_watchers() ~= 0
then
  fail("Snacks direct image live-refresh lifecycle is unavailable")
end

local image_refresh_autocmds = vim.api.nvim_get_autocmds({
  group = "user.image_live_refresh",
})
if #image_refresh_autocmds < 3 then
  fail("Snacks direct image live-refresh autocmds are unavailable")
end

local fingerprint_source = vim.fn.tempname() .. ".png"
vim.fn.writefile({ "first" }, fingerprint_source)
local first_fingerprint = image_view.fingerprint(fingerprint_source)
if not first_fingerprint
  or not image_view.same_fingerprint(first_fingerprint, first_fingerprint)
  or image_view.same_fingerprint(first_fingerprint, nil)
then
  fail("Snacks image source fingerprint comparison is unavailable")
end
vim.fn.writefile({ "different-size" }, fingerprint_source)
local changed_fingerprint = image_view.fingerprint(fingerprint_source)
if image_view.same_fingerprint(first_fingerprint, changed_fingerprint) then
  fail("Snacks image source fingerprint did not detect a changed file")
end
if image_view.read_fingerprint(fingerprint_source) ~= nil then
  fail("Missing Snacks image fingerprint state was not handled safely")
end
local malformed_path = image_view.fingerprint_path(fingerprint_source)
vim.fn.mkdir(vim.fs.dirname(malformed_path), "p")
vim.fn.writefile({ "not json" }, malformed_path)
if image_view.read_fingerprint(fingerprint_source) ~= nil then
  fail("Malformed Snacks image fingerprint state was not handled safely")
end
vim.fn.delete(malformed_path)
vim.fn.delete(fingerprint_source)

local watched_image = vim.fn.tempname() .. ".png"
vim.fn.writefile({ "not-rendered-by-this-structural-test" }, watched_image)
local watched_buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(watched_buf, watched_image)
vim.api.nvim_set_current_buf(watched_buf)
vim.bo[watched_buf].filetype = "image"
if not image_view.is_viewer(watched_buf)
  or vim.bo[watched_buf].autoread
  or vim.bo[watched_buf].modifiable
  or vim.bo[watched_buf].modified
then
  fail("Snacks direct image buffer does not have view-only semantics")
end
vim.bo[watched_buf].modified = true
image_view.normalize_viewer(watched_buf)
if vim.bo[watched_buf].modified then
  fail("Snacks direct image buffer retained programmatic modifications")
end
local viewer_change_handlers = vim.api.nvim_get_autocmds({
  event = "FileChangedShell",
  buffer = watched_buf,
})
if #viewer_change_handlers ~= 1 then
  fail("Snacks direct image buffer lacks a scoped external-change handler")
end
local viewer_enter_handlers = vim.api.nvim_get_autocmds({
  event = "BufWinEnter",
  buffer = watched_buf,
})
if #viewer_enter_handlers < 1 then
  fail("Snacks direct image buffer lacks placement restoration")
end
local image_module = require("snacks.image.image")
local terminal_module = require("snacks.image.terminal")
local original_image_new = image_module.new
local original_terminal_detect = terminal_module.detect
local image_new_count = 0
local terminal_detect_count = 0
image_module.new = function(...)
  image_new_count = image_new_count + 1
  return original_image_new(...)
end
terminal_module.detect = function(...)
  terminal_detect_count = terminal_detect_count + 1
  return original_terminal_detect(...)
end
if image_view.existing_placements(watched_buf) ~= nil
  or image_view.restore_placement(watched_buf) ~= 0
  or image_new_count ~= 0
  or terminal_detect_count ~= 0
then
  fail("Initial Snacks image placement restore was not a passive no-op")
end

local placement_module = require("snacks.image.placement")
local placement_registry
for index = 1, 20 do
  local name, value = debug.getupvalue(placement_module.clean, index)
  if name == "placements" then
    placement_registry = value
    break
  end
end
if type(placement_registry) ~= "table" then
  fail("Pinned Snacks placement registry is unavailable")
end
local show_count = 0
local fake_placement = {
  buf = watched_buf,
  hidden = true,
  show = function(self)
    self.hidden = false
    show_count = show_count + 1
  end,
}
placement_registry[watched_buf] = { fake_placement }
if image_view.restore_placement(watched_buf) ~= 1 or show_count ~= 1 then
  fail("Snacks direct image placement was not restored")
end
if image_view.restore_placement(watched_buf) ~= 0 or show_count ~= 1 then
  fail("Visible Snacks image placement was restored more than once")
end
fake_placement.hidden = true
if not image_view.queue_placement_restore(watched_buf)
  or image_view.queue_placement_restore(watched_buf)
then
  fail("Snacks image placement restoration was not deduplicated")
end
vim.wait(100, function()
  return show_count == 2
end)
placement_registry[watched_buf] = nil
image_module.new = original_image_new
terminal_module.detect = original_terminal_detect
if show_count ~= 2 then
  fail("Queued Snacks image placement restoration did not run")
end
if image_new_count ~= 0 or terminal_detect_count ~= 0 then
  fail("Snacks image placement lookup initialized image or terminal state")
end
if image_view.active_watchers() ~= 1 then
  fail("Snacks direct image view did not create one filesystem watcher")
end
vim.api.nvim_buf_delete(watched_buf, { force = true })
vim.wait(100, function()
  return image_view.active_watchers() == 0
end)
if image_view.active_watchers() ~= 0 then
  fail("Snacks direct image watcher survived buffer cleanup")
end
vim.fn.delete(watched_image)

local ordinary_buf = vim.api.nvim_create_buf(true, false)
if image_view.is_viewer(ordinary_buf)
  or image_view.normalize_viewer(ordinary_buf)
  or image_view.handle_external_change(ordinary_buf)
  or image_view.restore_placement(ordinary_buf) ~= 0
  or image_view.queue_placement_restore(ordinary_buf)
then
  fail("Ordinary buffers were opted into Snacks image viewer semantics")
end
local ordinary_change_handlers = vim.api.nvim_get_autocmds({
  event = "FileChangedShell",
  buffer = ordinary_buf,
})
if #ordinary_change_handlers ~= 0 then
  fail("Ordinary buffers received the image external-change handler")
end
vim.api.nvim_buf_delete(ordinary_buf, { force = true })

local explorer_config = snacks.config.picker.sources.explorer

if explorer_config.focus ~= "list" then
  fail("Snacks Explorer does not initially focus its interactive list")
end

for _, option in ipairs({ "hidden", "ignored", "follow_file", "git_status", "diagnostics" }) do
  if explorer_config[option] ~= true then
    fail("Snacks Explorer option is not enabled: " .. option)
  end
end

if explorer_config.auto_close ~= false or explorer_config.jump.close ~= false then
  fail("Snacks Explorer is not configured to remain open while editing")
end

local explorer_keys = explorer_config.win.list.keys
if explorer_keys.V ~= "edit_vsplit" or explorer_keys.B ~= "edit_split" then
  fail("Snacks Explorer split mappings are unavailable")
end

if not vim.deep_equal(explorer_keys["<S-CR>"], { { "pick_win", "jump" } }) then
  fail("Snacks Explorer window-picker mapping is unavailable")
end

for _, key in ipairs({ "V", "B", "<S-CR>" }) do
  if vim.fn.maparg(key, "n") ~= "" then
    fail("Snacks Explorer mapping leaked globally: " .. key)
  end
end

if vim.fn.maparg("<leader>e", "n") == "" then
  fail("Snacks Explorer mapping is unavailable: <leader>e")
end

if vim.fn.maparg("<leader>er", "n") ~= "" then
  fail("Snacks Explorer exposes an unexpected <leader>er child mapping")
end

-- Oil is present on runtimepath, but its Lua module and configuration remain
-- deferred until the explicit Stage 8C launcher is first used.
if #vim.api.nvim_get_runtime_file("lua/oil/init.lua", false) == 0 then
  fail("Oil is unavailable from the Nix plugin inventory")
end

local oil_navigation = require("user.navigation.oil")

for name in pairs(package.loaded) do
  if name == "oil" or vim.startswith(name, "oil.") then
    fail("Oil module loaded during ordinary startup: " .. name)
  end
end

if oil_navigation.is_initialized() or oil_navigation.initialization_count() ~= 0 then
  fail("Oil initialized during ordinary startup")
end

local oil_mapping = vim.fn.maparg("<leader>f", "n", false, true)
if type(oil_mapping) ~= "table"
  or oil_mapping.desc ~= "Toggle Oil filesystem editor"
  or type(oil_mapping.callback) ~= "function"
then
  fail("Oil launcher is unavailable: <leader>f")
end

for _, mapping in ipairs({ "<leader>sp", "<leader>sf" }) do
  if vim.fn.maparg(mapping, "n") == "" then
    fail("Telescope mapping is unavailable: " .. mapping)
  end
end

local original_cwd = vim.fn.getcwd()
local oil_test_root = vim.fn.tempname()
local oil_test_nested = oil_test_root .. "/nested"
vim.fn.mkdir(oil_test_nested, "p")
vim.fn.system({ "git", "-C", oil_test_root, "init", "--quiet" })
vim.cmd.lcd(vim.fn.fnameescape(oil_test_nested))

local special_buf = vim.api.nvim_create_buf(false, true)
vim.bo[special_buf].buftype = "nofile"
if oil_navigation.starting_directory(special_buf) ~= oil_test_root then
  fail("Oil special-buffer fallback did not resolve the project root")
end
vim.api.nvim_buf_delete(special_buf, { force = true })

local non_project = vim.fn.tempname()
vim.fn.mkdir(non_project, "p")
vim.cmd.lcd(vim.fn.fnameescape(non_project))
special_buf = vim.api.nvim_create_buf(false, true)
vim.bo[special_buf].buftype = "nofile"
if oil_navigation.starting_directory(special_buf) ~= non_project then
  fail("Oil special-buffer fallback did not resolve cwd outside a project")
end
vim.api.nvim_buf_delete(special_buf, { force = true })

local file_dir = oil_test_root .. "/files"
local file_path = file_dir .. "/example.lua"
vim.fn.mkdir(file_dir, "p")
vim.fn.writefile({ "return true" }, file_path)
local file_buf = vim.fn.bufadd(file_path)
vim.fn.bufload(file_buf)
if oil_navigation.starting_directory(file_buf) ~= file_dir then
  fail("Oil did not resolve a normal file buffer to its parent directory")
end
vim.api.nvim_buf_delete(file_buf, { force = true })
vim.cmd.lcd(vim.fn.fnameescape(original_cwd))
vim.fn.delete(oil_test_root, "rf")
vim.fn.delete(non_project, "rf")

local oil = oil_navigation.ensure_oil()
if not oil or not oil_navigation.is_initialized() then
  fail("Oil did not initialize on first use")
end
local oil_config = require("oil.config")
if oil_config.default_file_explorer ~= false then
  fail("Oil unexpectedly owns directory opening")
end
if oil_config.float.max_width ~= 0.80 or oil_config.float.max_height ~= 0.75 then
  fail("Oil floating window does not use the intended proportional size")
end
oil_navigation.ensure_oil()
if oil_navigation.initialization_count() ~= 1 then
  fail("Oil setup is not idempotent")
end

vim.notify("notification smoke test", vim.log.levels.INFO)

if vim.notify ~= snacks.notifier.notify then
  fail("vim.notify was not routed through Snacks notifier")
end

for _, module in ipairs({
  "bigfile",
  "dashboard",
  "indent",
  "input",
  "quickfile",
  "scope",
  "scroll",
  "statuscolumn",
  "words",
}) do
  if snacks.config[module].enabled ~= false then
    fail("unexpected Snacks module enabled: " .. module)
  end
end

-- Exercise core TextYankPost behavior so broken autocmd callbacks fail the smoke test.
local yank_ok, yank_err = pcall(function()
  vim.api.nvim_buf_set_lines(
    0,
    0,
    -1,
    false,
    {
      "smoke yank line one",
      "smoke yank line two",
    }
  )

  vim.cmd("normal! gg")
  vim.cmd("normal! yy") -- Trigger TextYankPost for a real yank.
  vim.cmd("normal! dd") -- Trigger TextYankPost for a real delete.
  vim.bo.modified = false
end)

if not yank_ok then
  fail("TextYankPost callback failed: " .. tostring(yank_err))
end

local expected_runtime = vim.env.NVIM_SMOKE_EXPECT_RUNTIME

if expected_runtime and expected_runtime ~= "" then
  local found = false

  for _, path in ipairs(vim.opt.runtimepath:get()) do
    if path == expected_runtime then
      found = true
      break
    end
  end

  if not found then
    fail(
      "expected configuration runtime is missing: "
        .. expected_runtime
    )
  end
end

local sentinel_path = vim.env.NVIM_SMOKE_SENTINEL

if not sentinel_path or sentinel_path == "" then
  fail("NVIM_SMOKE_SENTINEL is not set")
end

local result = vim.fn.writefile({ "ok" }, sentinel_path)

if result ~= 0 then
  fail("could not write smoke-test sentinel")
end

vim.cmd("qall")
LUA

output=""

if ! output="$(
  "$nvim_bin" \
    --headless \
    -c "luafile $probe" \
    2>&1
)"; then
  printf '%s\n' "$output" >&2
  fail "Neovim exited unsuccessfully"
fi

[[ -f "$sentinel" ]] ||
  fail "Neovim exited without completing the smoke probe"

echo "neovim-smoke: PASS"
