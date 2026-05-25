return {
  "sphamba/smear-cursor.nvim",
  event = "VeryLazy",
  opts = {
    cursor_color = "#c6a0f6",
  },
  keys = {
    {
      "<leader>us",
      function()
        require("smear_cursor").toggle()
      end,
      desc = "Toggle Smear Cursor",
    },
  },
}
