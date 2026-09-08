-- RubyMine-like keymaps
-- cmd shift p = Go to file -> <leader>p or <leader>ff
-- cmd b = Go to definition -> gd

local map = vim.keymap.set

local function safe_picker(picker)
  local ok, snacks = pcall(require, "snacks")
  if not ok or not snacks.picker or not snacks.picker[picker] then
    vim.notify("Snacks picker unavailable: " .. picker, vim.log.levels.WARN)
    return
  end
  snacks.picker[picker]()
end

local function goto_line_prompt()
  local line = vim.fn.input("Go to line: ")
  if line == nil or line == "" then
    return
  end
  if line:match("^%d+$") then
    vim.cmd("normal! " .. line .. "G")
  else
    vim.notify("Please enter a valid line number", vim.log.levels.WARN)
  end
end

local function goto_definition_direct()
  local params = vim.lsp.util.make_position_params(0, "utf-8")
  vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result)
    if err then
      vim.notify("Definition lookup failed: " .. (err.message or "unknown error"), vim.log.levels.ERROR)
      return
    end
    if not result or vim.tbl_isempty(result) then
      vim.notify("No definition found", vim.log.levels.INFO)
      return
    end

    local target = result
    if type(result) == "table" and result[1] then
      target = result[1]
    end
    if target.targetUri then
      target = { uri = target.targetUri, range = target.targetSelectionRange or target.targetRange }
    end

    vim.lsp.util.show_document(target, "utf-8", { focus = true })
    vim.cmd("normal! zz")
  end)
end

local function goto_alternate_file()
  if vim.fn.exists(":A") == 2 then
    vim.cmd("A")
    return
  end

  local current_file = vim.fn.expand("%")
  local alternate_file = current_file:gsub("_spec%.rb$", ".rb"):gsub("spec/", "app/"):gsub("test/", "app/")

  if current_file ~= alternate_file and vim.fn.filereadable(alternate_file) == 1 then
    vim.cmd("edit " .. alternate_file)
    return
  end

  alternate_file = current_file:gsub("%.rb$", "_spec.rb"):gsub("app/", "spec/"):gsub("lib/", "spec/lib/")
  if vim.fn.filereadable(alternate_file) == 1 then
    vim.cmd("edit " .. alternate_file)
  else
    vim.notify("No alternate file found", vim.log.levels.INFO)
  end
end

local function split_right()
  vim.cmd("rightbelow vsplit")
end

local function cycle_next_context()
  if vim.fn.winnr("$") > 1 then
    vim.cmd("wincmd w")
  else
    vim.cmd("bnext")
  end
end

local function cycle_prev_context()
  if vim.fn.winnr("$") > 1 then
    vim.cmd("wincmd W")
  else
    vim.cmd("bprevious")
  end
end

-- File navigation (like cmd+shift+p in RubyMine)
map("n", "<leader>p", function()
  Snacks.picker.files()
end, { desc = "Find Files (RubyMine cmd+shift+p)" })

-- Requested shortcuts
map("n", "<C-b>", goto_definition_direct, { desc = "Go to Definition (Ctrl+b)" })
map("n", "<C-S-p>", function()
  safe_picker("files")
end, { desc = "Global File Search (Ctrl+Shift+p)" })
-- Find in Project. NOT <C-f>: that is vim's page-forward, and RubyMine's real
-- Linux binding for "Find in Path" is Ctrl+Shift+F anyway.
map("n", "<C-S-f>", function()
  safe_picker("grep")
end, { desc = "Find in Project (Ctrl+Shift+f)" })
-- Go to Line. NOT <C-l>: LazyVim uses <C-h/j/k/l> for window navigation and
-- vim uses <C-l> to redraw. <C-g> is RubyMine's own "Go to Line".
map("n", "<C-g>", goto_line_prompt, { desc = "Go to Line (Ctrl+g)" })
map("n", "<C-S-t>", goto_alternate_file, { desc = "Go to Related Test/File (Ctrl+Shift+t)" })
map("n", "<C-S-Bslash>", split_right, { desc = "Split Right (Ctrl+Shift+|)" })
map("n", "<C-Bar>", split_right, { desc = "Split Right (Ctrl+|)" })
map("n", "<C-S-\\>", split_right, { desc = "Split Right (Ctrl+Shift+\\)" })
map("n", "<C-\\>", split_right, { desc = "Split Right (Ctrl+\\ fallback)" })
map("n", "<C-Tab>", cycle_next_context, { desc = "Next Window/Buffer (Ctrl+Tab)" })
map("n", "<C-S-Tab>", cycle_prev_context, { desc = "Previous Window/Buffer (Ctrl+Shift+Tab)" })
map("n", "<C-PageDown>", "<cmd>bnext<cr>", { desc = "Next Buffer (Ctrl+PageDown)" })
map("n", "<C-PageUp>", "<cmd>bprevious<cr>", { desc = "Previous Buffer (Ctrl+PageUp)" })
-- Close buffer. NOT <C-w>: that is vim's window prefix, and shadowing it breaks
-- <C-w>s / <C-w>v / <C-w>hjkl. <C-F4> is RubyMine's own "Close tab" on Linux.
map("n", "<C-F4>", "<cmd>bdelete<cr>", { desc = "Close Buffer (Ctrl+F4)" })

-- Deliberately NOT redefining LSP navigation here.
--
-- LazyVim already sets these as buffer-local maps on LspAttach, and its
-- versions check server capability first, so they degrade cleanly instead of
-- erroring on a buffer whose server lacks the method. Global duplicates also
-- shadowed nothing useful -- buffer-local always wins -- so they only fired in
-- buffers with no LSP, where they were guaranteed to fail.
--
--   gd  Goto Definition        gr  References
--   gD  Goto Declaration       gI  Goto Implementation
--   gy  Goto Type Definition   gO  Document Outline
--   K   Hover                  <leader>cr  Rename
--   <leader>ca  Code Action    <leader>ss  Document Symbols
--
-- Removed from here: gb, gB, gR, gI, <leader>rn, <leader>ca.

-- Quick switch between related files (spec <-> implementation)
map("n", "<leader>rs", goto_alternate_file, { desc = "Toggle spec/implementation" })

-- Run current spec file
map("n", "<leader>rsf", function()
  local current_file = vim.fn.expand("%")
  if current_file:match("_spec%.rb$") then
    require("neotest").run.run(vim.fn.expand("%"))
  else
    vim.notify("Not a spec file", vim.log.levels.WARN)
  end
end, { desc = "Run spec file" })
