return {
  {
    'gsuuon/model.nvim',

    -- To get treesitter highlighting of chat buffers with markdown injections,
    -- use :TSInstall mchat after model.nvim has been loaded (if you're using
    -- Lazy run :Lazy load model.nvim first).
    --
    -- The grammar repo is at gsuuon/tree-sitter-mchat.

    -- Don't need these if lazy = false
    cmd = { 'M', 'Model', 'Mchat' },
    init = function()
      vim.filetype.add {
        extension = {
          mchat = 'mchat',
        },
      }
    end,
    ft = 'mchat',

    config = function()
      require('model').setup {
        -- prompts = require('prompts').prompts,
        -- chats = require('prompts').chats,
        prompts = require('model.util').module.autoload('prompts').prompts,
        chats = require('model.util').module.autoload('prompts').chats,
        -- chats = {
        --   chatgpt = {},
        -- },
      }

      -- require('model.providers.llamacpp').setup({
      --   binary = '~/path/to/server/binary',
      --   models = '~/path/to/models/directory'
      -- })
    end,
  },
}
