vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'nvim_treesitter#foldexpr()'

vim.bo.expandtab = true -- Use spaces instead of tabs
vim.bo.shiftwidth = 2 -- Number of spaces to use for each step of (auto)indent
vim.bo.tabstop = 2 -- Number of spaces that a <Tab> in the file counts for

-- Keymaps for mchat files
-- vim.keymap.set('n', '<leader>ld', ':Mdelete<cr>', { desc = '[D]elete LLM response' })
-- vim.keymap.set('n', '<leader>ls', ':Mselect<cr>', { desc = '[S]elect LLM response' })
-- vim.keymap.set('n', '<leader>ll', ':Mchat<cr>', { desc = 'Generate [L]LM response' })
