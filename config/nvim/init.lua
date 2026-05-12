-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

if vim.g.neovide then
  -- Put anything you want to happen only in Neovide here
  vim.print(vim.g.neovide_version)

  vim.g.neovide_macos_simple_fullscreen = false
  
  vim.o.guifont = "MesloLGS NF:h12"
end
