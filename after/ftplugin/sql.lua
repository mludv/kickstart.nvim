-- DBUI keymaps
vim.keymap.set('n', '<leader>w', '<Plug>(DBUI_SaveQuery)', { noremap = true, desc = 'Save current query', buffer = true })
vim.keymap.set('n', '<leader>e', '<Plug>(DBUI_EditBindParameters)', { noremap = true, desc = 'Edit bind parameters', buffer = true })
