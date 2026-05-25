return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-neotest/neotest-python",
  },
  keys = {
    { "<leader>tt", function() require("neotest").run.run() end, desc = "Run Nearest Test" },
    { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run File Tests" },
    { "<leader>to", function() require("neotest").output_panel.toggle() end, desc = "Toggle Output Panel" },
    { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle Summary" },
  },
  opts = function()
    return {
      adapters = {
        require("neotest-python"),
      },
    }
  end,
}
