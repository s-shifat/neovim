local M = {}

local languages = {
  sh = "bash",
  lua = "lua",
  nix = "nix",
  python = "python",
  tex = "latex",
  markdown = "markdown",
  json = "json",
  yaml = "yaml",
  toml = "toml",
  csv = "csv",
}

local warned = {}

local function start_highlighting(args)
  local language = languages[vim.bo[args.buf].filetype]
  if not language or vim.treesitter.highlighter.active[args.buf] then return end

  local ok, err = pcall(vim.treesitter.start, args.buf, language)

  if not ok and not warned[language] then
    warned[language] = true
    vim.notify(
      ("Treesitter: could not start %s highlighting: %s"):format(language, err),
      vim.log.levels.WARN
    )
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("user.treesitter", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = vim.tbl_keys(languages),
    callback = start_highlighting,
  })

  -- Native session restore can reopen buffers before filetype detection runs.
  vim.api.nvim_create_autocmd("SessionLoadPost", {
    group = group,
    callback = function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].buftype == "" and vim.bo[buf].filetype == "" then
          local filetype = vim.filetype.match({ buf = buf })
          if languages[filetype] then
            vim.bo[buf].filetype = filetype
          end
        end
      end
    end,
  })
end

return M
