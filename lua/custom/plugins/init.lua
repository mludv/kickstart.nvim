-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
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
  },
  {
    'stevearc/oil.nvim',
    config = function()
      require('oil').setup()
      vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
    end,
    -- Optional dependencies
    dependencies = { 'nvim-tree/nvim-web-devicons' },
  },
  {
    'kdheepak/lazygit.nvim',
    cmd = {
      'LazyGit',
      'LazyGitConfig',
      'LazyGitCurrentFile',
      'LazyGitFilter',
      'LazyGitFilterCurrentFile',
    },
    -- optional for floating window border decoration
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    -- setting the keybinding for LazyGit with 'keys' is recommended in
    -- order to load the plugin when the command is run for the first time
    keys = {
      { '<leader>hl', '<cmd>LazyGit<cr>', desc = '[L]azyGit' },
    },
  },
  -- {
  --   'luckasRanarison/tailwind-tools.nvim',
  --   dependencies = { 'nvim-treesitter/nvim-treesitter' },
  --   event = 'VeryLazy',
  --   opts = {}, -- your configuration
  -- },
  {
    -- 'melbaldove/llm.nvim',
    dir = vim.fn.stdpath 'config' .. '/lua/llm',
    event = 'VeryLazy',
    dependencies = { 'nvim-neotest/nvim-nio' },
    config = function()
      vim.keymap.set('n', '<leader>m', require('llm').create_llm_md, { desc = 'Open LL[M] Scratchpad' })

      local maxllm_continue = function()
        require('llm').invoke_llm_and_stream_into_editor { replace = false }
      end
      local maxllm_replace = function()
        require('llm').invoke_llm_and_stream_into_editor { replace = true }
      end
      vim.keymap.set('n', '<leader>,', maxllm_continue, { desc = '[,] Continue document with LLM output' })
      vim.keymap.set('v', '<leader>,', maxllm_continue, { desc = '[,] Continue document with LLM output' })
      vim.keymap.set('v', '<leader>.', maxllm_replace, { desc = '[.] Replace selection with LLM output' })
    end,
  },
}
