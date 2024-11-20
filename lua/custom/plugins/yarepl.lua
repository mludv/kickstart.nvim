local repl_ft = { 'python', 'mchat', 'markdown' }

---@type LazySpec
return {
  {
    'milanglacier/yarepl.nvim',
    keys = {
      { '<leader>rs', '<Plug>(REPLStart-ipython)', mode = 'n', ft = repl_ft, noremap = false, desc = 'Start an REPL' },
      { '<leader>rf', '<Plug>(REPLFocus)', mode = 'n', ft = repl_ft, desc = 'Focus on REPL', noremap = false },
      { '<leader>rv', '<CMD>Telescope REPLShow<CR>', mode = 'n', ft = repl_ft, desc = 'View REPLs', noremap = false },
      { '<leader>rh', '<Plug>(REPLHide)', mode = 'n', ft = repl_ft, desc = 'Hide REPL', noremap = false },
      { '<leader>re', '<Plug>(REPLExec)', mode = 'n', ft = repl_ft, desc = 'Execute command in REPL', expr = true, noremap = false },
      { '<leader>rq', '<Plug>(REPLClose)', mode = 'n', ft = repl_ft, desc = 'Quit REPL', noremap = false },
      { '<leader>rc', '<CMD>REPLCleanup<CR>', mode = 'n', ft = repl_ft, desc = 'Clear REPLs', noremap = false },
      { '<leader>rS', '<CMD>REPLSwap<CR>', mode = 'n', ft = repl_ft, desc = 'Swap REPLs', noremap = false },
      { '<leader>ra', '<CMD>REPLAttachBufferToREPL<CR>', mode = 'n', ft = repl_ft, desc = 'Attach current buffer to a REPL', noremap = false },
      { '<leader>rd', '<CMD>REPLDetachBufferToREPL<CR>', mode = 'n', ft = repl_ft, desc = 'Detach current buffer to any REPL', noremap = false },

      { '<leader>rr', '<Plug>(REPLSendLine)', mode = 'n', ft = repl_ft, desc = 'Send line to REPL', noremap = false },
      { '<leader>ro', '<Plug>(REPLSendOperator)', mode = 'n', ft = repl_ft, desc = 'Send current line to REPL', noremap = false },
      { '<leader>r', '<Plug>(REPLSendVisual)', mode = 'v', ft = repl_ft, desc = 'Send visual region to REPL', noremap = false },
    },
    config = function()
      require('yarepl').setup {}
    end,
  },
}
