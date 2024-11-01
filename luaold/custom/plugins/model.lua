local function save_mchat()
  -- Get the base directory using stdpath
  local base_dir = vim.fn.stdpath 'data' .. '/model'

  -- Ensure the directory exists
  vim.fn.mkdir(base_dir, 'p')

  -- Prompt the user for a filename
  local filename = vim.fn.input 'Enter filename: '

  if filename ~= '' then
    -- Construct the full path
    local full_path = base_dir .. '/' .. filename

    -- Save the current buffer to the file
    local success, err = pcall(function()
      vim.cmd('write ' .. vim.fn.fnameescape(full_path))
    end)

    if success then
      print('File saved to: ' .. full_path)
    else
      print('Error saving file: ' .. err)
    end
  else
    print 'Save cancelled'
  end
end

---@type LazySpec
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
    keys = {
      { '<leader>ln', ':Mchat pulsar<cr>', mode = 'n', desc = '[N]ew chat window' },
      { '<leader>lr', ':M preplace<cr>', mode = 'v', desc = '[R]eplace the selected text' },
      {
        '<leader>lp',
        function()
          vim.ui.input({ prompt = 'Prompt: ' }, function(input)
            vim.cmd('M preplace ' .. input)
          end)
        end,
        mode = 'v',
        desc = '[P]rompt and replace',
      },
      { '<leader>lw', save_mchat, mode = 'n', ft = 'mchat', desc = '[W]rite chat file' },
      { '<leader>ld', ':Mdelete<cr>', mode = 'n', ft = 'mchat', desc = '[D]elete LLM response' },
      { '<leader>ls', ':Mselect<cr>', mode = 'n', ft = 'mchat', desc = '[S]elect LLM response' },
      { '<leader>ll', ':Mchat<cr>', mode = 'n', ft = 'mchat', desc = 'Generate [L]LM response' },
    },
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
