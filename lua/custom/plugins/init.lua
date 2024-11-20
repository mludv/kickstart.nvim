-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
---@type LazySpec
return {
  {
    'alexghergh/nvim-tmux-navigation',
    event = 'VeryLazy',
    opts = {
      disable_when_zoomed = false,
      keybindings = {
        left = '<C-h>',
        down = '<C-j>',
        up = '<C-k>',
        right = '<C-l>',
        -- last_active = "<C-\\>",
        -- next = "<C-Space>",
      },
    },
    config = function(_, opts)
      local ntn = require 'nvim-tmux-navigation'
      ntn.setup(opts)

      vim.keymap.set('t', '<C-h>', ntn.NvimTmuxNavigateLeft, { remap = true })
      vim.keymap.set('t', '<C-j>', ntn.NvimTmuxNavigateDown, { remap = true })
      vim.keymap.set('t', '<C-k>', ntn.NvimTmuxNavigateUp, { remap = true })
      vim.keymap.set('t', '<C-l>', ntn.NvimTmuxNavigateRight, { remap = true })
    end,
  },
  {
    'stevearc/oil.nvim',
    keys = {
      { '-', '<CMD>Oil<CR>', mode = 'n', desc = 'Open parent directory' },
    },
    config = function()
      require('oil').setup {
        keymaps = {
          ['g?'] = 'actions.show_help',
          ['<CR>'] = 'actions.select',
          ['<C-s>'] = { 'actions.select', opts = { vertical = true }, desc = 'Open the entry in a vertical split' },
          ['<C-d>'] = { 'actions.select', opts = { horizontal = true }, desc = 'Open the entry in a horizontal split' },
          ['<C-h>'] = false,
          ['<C-t>'] = { 'actions.select', opts = { tab = true }, desc = 'Open the entry in new tab' },
          ['<C-p>'] = 'actions.preview',
          ['<C-c>'] = 'actions.close',
          ['<C-u>'] = 'actions.refresh',
          ['<C-l>'] = false,
          ['-'] = 'actions.parent',
          ['_'] = 'actions.open_cwd',
          ['`'] = 'actions.cd',
          ['~'] = { 'actions.cd', opts = { scope = 'tab' }, desc = ':tcd to the current oil directory', mode = 'n' },
          ['gs'] = 'actions.change_sort',
          ['gx'] = 'actions.open_external',
          ['g.'] = 'actions.toggle_hidden',
          ['g\\'] = 'actions.toggle_trash',
        },
      }
      -- vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
    end,
    -- Optional dependencies
    dependencies = { 'nvim-tree/nvim-web-devicons' },
  },
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    opts = {},
    keys = {
      { '<leader>tt', ':ToggleTerm dir=gitdir', mode = 'n', desc = '[T]oggle terminal' },
    },
  },
  -- {
  --   'kdheepak/lazygit.nvim',
  --   cmd = {
  --     'LazyGit',
  --     'LazyGitConfig',
  --     'LazyGitCurrentFile',
  --     'LazyGitFilter',
  --     'LazyGitFilterCurrentFile',
  --   },
  --   -- optional for floating window border decoration
  --   dependencies = {
  --     'nvim-lua/plenary.nvim',
  --   },
  --   -- setting the keybinding for LazyGit with 'keys' is recommended in
  --   -- order to load the plugin when the command is run for the first time
  --   keys = {
  --     { '<leader>hl', '<cmd>LazyGit<cr>', desc = '[L]azyGit' },
  --   },
  -- },
  -- {
  --   'luckasRanarison/tailwind-tools.nvim',
  --   dependencies = { 'nvim-treesitter/nvim-treesitter' },
  --   event = 'VeryLazy',
  --   opts = {}, -- your configuration
  -- },
}
