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

-- Yanks the python function under the cursor
local function yank_python_function()
  -- Get the current buffer and cursor position
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  -- Get the root tree and current node
  local parser = vim.treesitter.get_parser(bufnr, 'python')
  local root = parser:parse()[1]:root()
  local node = root:named_descendant_for_range(row, col, row, col)

  -- Find the closest function definition node
  while node and node:type() ~= 'function_definition' do
    node = node:parent()
  end

  if node then
    -- Get the range of the function definition
    local start_row, start_col, end_row, end_col = node:range()

    -- Set the visual selection
    vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
    vim.cmd 'normal! v'
    vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })

    -- Yank the selection
    vim.cmd 'normal! y'
  else
    print 'No function found at cursor position'
  end
end

local function paste_python_function()
  -- Get the contents of the unnamed register
  local yanked_text = vim.fn.getreg '"'

  -- Prepare the formatted text
  local formatted_text = '```python\n' .. yanked_text .. '\n```'

  -- Insert the formatted text at the cursor position
  vim.api.nvim_put(vim.split(formatted_text, '\n'), 'l', true, true)
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
        '<leader>lo',
        function()
          vim.ui.input({ prompt = 'Prompt: ' }, function(input)
            vim.cmd('M preplace ' .. input)
          end)
        end,
        mode = 'v',
        desc = '[O]rder and replace',
      },
      { '<leader>lw', save_mchat, mode = 'n', ft = 'mchat', desc = '[W]rite chat file' },
      { '<leader>ld', ':Mdelete<cr>', mode = 'n', ft = 'mchat', desc = '[D]elete LLM response' },
      { '<leader>ls', ':Mselect<cr>', mode = 'n', ft = 'mchat', desc = '[S]elect LLM response' },
      { '<leader>ll', ':Mchat<cr>', mode = 'n', ft = 'mchat', desc = 'Generate [L]LM response' },
      { '<leader>ly', yank_python_function, mode = 'n', ft = 'python', desc = '[Y]ank python function' },
      { '<leader>lp', paste_python_function, mode = 'n', desc = '[P]aste python function' },
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
