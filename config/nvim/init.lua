-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

if vim.g.neovide then
  -- Put anything you want to happen only in Neovide here
  vim.print(vim.g.neovide_version)

  vim.g.neovide_macos_simple_fullscreen = false
  
  -- Use Liberation Mono as fallback on all platforms
  vim.o.guifont = "Liberation Mono:h12"
end
