-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
vim.g.lazyvim_python_ruff = "ruff"

vim.opt.winbar = "%=%m %f"
vim.opt.wrap = true

vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = true,
})
