return {
  {
    "tpope/vim-rails",
    dependencies = { "tpope/vim-bundler" },
    ft = { "ruby", "eruby" },
    keys = {
      { "<leader>ra", "<cmd>A<cr>", desc = "Rails Alternate (app/spec)" },
      { "<leader>rr", "<cmd>R<cr>", desc = "Rails Related File" },
    },
  },
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "olimorris/neotest-rspec",
    },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      opts.adapters["neotest-rspec"] = {
        rspec_cmd = function()
          if vim.fn.executable("bin/rspec") == 1 then
            return vim.tbl_flatten({ "bin/rspec" })
          end
          return vim.tbl_flatten({ "bundle", "exec", "rspec" })
        end,
      }
    end,
    keys = {
      { "<leader>tr", function() require("neotest").run.run() end, desc = "Run nearest spec" },
      { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run spec file" },
      { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run last spec" },
      { "<leader>ta", function() require("neotest").run.run({ suite = true }) end, desc = "Run all specs" },
      { "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug nearest spec" },
      { "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show spec output" },
      { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle spec summary" },
    },
  },
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "suketa/nvim-dap-ruby",
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
      "theHamsta/nvim-dap-virtual-text",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup()
      require("nvim-dap-virtual-text").setup()

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end

      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end

      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      require("dap-ruby").setup()
    end,
    keys = {
      {
        "<leader>dR",
        function()
          require("dap").run({
            type = "ruby",
            request = "attach",
            name = "run rails",
            command = "bundle",
            args = { "exec", "rails", "s" },
            options = { source_filetype = "ruby" },
            waiting = 1000,
            random_port = true,
            error_on_failure = true,
            localfs = true,
          })
        end,
        desc = "Debug Rails Server (bin/rails s)",
      },
      {
        "<leader>dV",
        function()
          require("dap").run({
            type = "ruby",
            request = "attach",
            name = "bin/dev",
            command = "bin/dev",
            options = { source_filetype = "ruby" },
            waiting = 1000,
            random_port = true,
            error_on_failure = true,
            localfs = true,
          })
        end,
        desc = "Debug bin/dev",
      },
      {
        "<leader>da",
        function()
          require("dap").run({
            type = "ruby",
            request = "attach",
            name = "attach existing (port 38698)",
            options = { source_filetype = "ruby" },
            waiting = 0,
            port = 38698,
            localfs = true,
          })
        end,
        desc = "Attach Debugger (port 38698)",
      },
      {
        "<leader>df",
        function()
          require("dap").run({
            type = "ruby",
            request = "attach",
            name = "debug current file",
            command = "rdbg",
            current_file = true,
            options = { source_filetype = "ruby" },
            waiting = 1000,
            random_port = true,
            error_on_failure = true,
            localfs = true,
          })
        end,
        desc = "Debug Current File",
      },
      { "<F5>", function() require("dap").continue() end, desc = "Debug Continue/Start" },
      { "<F9>", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<F10>", function() require("dap").step_over() end, desc = "Step over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Step into" },
      { "<S-F11>", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "Conditional breakpoint" },
      { "<leader>dl", function() require("dap").run_to_cursor() end, desc = "Run to cursor" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
      { "<leader>dn", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>do", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>du", function() require("dapui").toggle({}) end, desc = "Toggle debug UI" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle debug REPL" },
    },
  },
}
