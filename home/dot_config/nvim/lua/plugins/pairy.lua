-- LazyVim plugin spec for pairy — local AI pair programmer

-- pairy lives in a local checkout, so this spec is skipped entirely on a
-- machine that does not have it rather than failing at startup.
local pairy_dir = vim.fn.expand("~/Desktop/Programming/2026_Q1_Projects/pairy")
if vim.fn.isdirectory(pairy_dir) == 0 then
  return {}
end

return {
  {
    dir    = pairy_dir,
    name   = "pairy",
    lazy   = false,
    config = function()
      require("pairy").setup({})

      -- Use wrapper functions so :PairyReload works without a Neovim restart.
      -- Direct references (pairy.send) would pin the old module after reload.
      local map = vim.keymap.set
      local p = function(fn) return function() require("pairy")[fn]() end end
      map("n", "<leader>ais", p("send"),         { desc = "Pairy: Send comment at cursor" })
      map("v", "<leader>ais", p("ask_selection"),{ desc = "Pairy: Ask about selection" })
      map("n", "<leader>air", p("retry"),        { desc = "Pairy: Retry comment at cursor" })
      map("n", "<leader>aic", p("clear"),        { desc = "Pairy: Clear all responses" })
      map("n", "<leader>aix", p("clear_line"),   { desc = "Pairy: Clear response at cursor" })
      map("n", "<leader>aia", p("send_all"),     { desc = "Pairy: Send all pair: comments" })
      map("n", "<leader>aiK", p("cancel"),       { desc = "Pairy: Cancel request" })
      map("n", "<leader>aiw", p("save_session"), { desc = "Pairy: Save session to markdown" })
      map("n", "<leader>aiy", p("yank"),         { desc = "Pairy: Yank response to clipboard" })
      map("n", "<leader>ait", p("toggle"),        { desc = "Pairy: Toggle responses" })
      map("n", "<leader>aii", p("inspect"),       { desc = "Pairy: Inspect word under cursor" })
      map("v", "<leader>aii", p("inspect_selection"), { desc = "Pairy: Inspect selection" })
    end,
  },
}
