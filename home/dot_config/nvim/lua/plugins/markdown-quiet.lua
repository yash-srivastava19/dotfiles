-- Markdown lint noise control. Two separate problems, two separate fixes.
--
-- 1. markdownlint-cli2 does not search upward from cwd for its config, so any
--    repo without one gets every default rule -- including MD013 (80-char
--    lines), which is meaningless for prose. Passing --config explicitly is
--    the only reliable way to apply one ruleset everywhere.
--
-- 2. The warnings that remain still do not belong inline. nvim-lint publishes
--    under its own diagnostic namespace, so virtual_text can be stripped for
--    markdownlint alone -- LSP diagnostics keep rendering inline as before.
--    The message moves to the echo area at the bottom instead.

-- The filename matters. markdownlint-cli2 rejects anything that is not one of
-- its supported names (or a prefix of one) and exits 2 with NO diagnostics --
-- which looks like a working filter but is really a broken linter.
local md_config = vim.fn.expand("~/.config/markdownlint/.markdownlint-cli2.yaml")

return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters = opts.linters or {}
      opts.linters["markdownlint-cli2"] = {
        args = { "--config", md_config, "-" },
      }

      -- Deferred because require("lint") needs the plugin on the rtp, which
      -- happens after this opts function runs.
      vim.schedule(function()
        local ok, lint = pcall(require, "lint")
        if not ok then
          return
        end
        local ns = lint.get_namespace("markdownlint-cli2")
        vim.diagnostic.config({
          virtual_text = false,
          underline = false,
          signs = true, -- keep a gutter mark so you know a line has a warning
        }, ns)
      end)

      return opts
    end,
  },

  -- Echo the diagnostic under the cursor at the bottom, replacing the inline
  -- text we just turned off.
  {
    "LazyVim/LazyVim",
    opts = function()
      local grp = vim.api.nvim_create_augroup("YashDiagEcho", { clear = true })

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorHold" }, {
        group = grp,
        pattern = { "*.md", "*.markdown" },
        callback = function()
          -- Never stomp on a real message the user is reading.
          if vim.fn.mode() ~= "n" then
            return
          end
          local line = vim.api.nvim_win_get_cursor(0)[1] - 1
          local diags = vim.diagnostic.get(0, { lnum = line })
          if #diags == 0 then
            vim.api.nvim_echo({ { "" } }, false, {})
            return
          end
          local d = diags[1]
          local msg = d.message:gsub("%s+", " ")
          vim.api.nvim_echo({ { msg, "DiagnosticWarn" } }, false, {})
        end,
      })
    end,
  },
}
