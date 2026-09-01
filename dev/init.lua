if vim.env.NVIM_APPNAME ~= "nvim-next" then
  error(
    "nvim-next: refusing to start without NVIM_APPNAME=nvim-next; "
      .. "experimental mutable state must remain isolated from stable Neovim"
  )
end

local root = vim.env.NEOVIM_DEV_ROOT

if not root or root == "" then
  error("nvim-next: NEOVIM_DEV_ROOT is not set")
end

local config_dir = root .. "/config"

if vim.fn.isdirectory(config_dir) == 0 then
  error("nvim-next: config directory not found: " .. config_dir)
end

vim.opt.runtimepath:prepend(config_dir)

vim.g.neovim_profile = "next"

dofile(config_dir .. "/init.lua")
