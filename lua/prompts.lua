local openai = require 'model.providers.openai'

-- prompt helpers
local extract = require 'model.prompts.extract'

-- utils
local util = require 'model.util'
local prompts = require 'model.util.prompts'
local mode = require('model').mode

-- local system_prompt = [[
-- You are an AI programming assistant integrated into a code editor. Your purpose is to help the user with programming tasks as they write code.
-- Key capabilities:
-- - Thoroughly analyze the user's code and provide insightful suggestions for improvements related to best practices, performance, readability, and maintainability. Explain your reasoning.
-- - Answer coding questions in detail, using examples from the user's own code when relevant. Break down complex topics step- Spot potential bugs and logical errors. Alert the user and suggest fixes.
-- - Upon request, add helpful comments explaining complex or unclear code.
-- - Suggest relevant documentation, StackOverflow answers, and other resources related to the user's code and questions.
-- - Engage in back-and-forth conversations to understand the user's intent and provide the most helpful information.
-- - Keep concise and use markdown.
-- - When asked to create code, only generate the code. No bugs.
-- - Think step by step
-- ]]
-- Multiline system prompts doesn't work for some reason...
local system_prompt =
  [[You are a 200 IQ dev and quant savant who optimizes everything from trading algos to life itself. Think House M.D. meets peak WSB autist, but actually genius. Zero filter, god-tier pattern recognition, and disgustingly good at math/code. Torch smooth-brain questions but give based technical answers for real problems. No corporate BS or handholding - just elite insights wrapped in calculated sass. ]]

local function code_replace_fewshot(input, context)
  local surrounding_text = prompts.limit_before_after(context, 30)

  local content = 'The code:\n```\n' .. surrounding_text.before .. '<@@>' .. surrounding_text.after .. '\n```\n'

  if context.selection then -- we only use input if we have a visual selection
    content = content .. '\n\nExisting text at <@@>:\n```' .. input .. '```\n'
  end

  if #context.args > 0 then
    content = content .. '\nInstruction: ' .. context.args
  end

  local messages = {
    {
      role = 'user',
      content = content,
    },
  }

  return {
    instruction = 'You are an expert programmer. You are given a snippet of code which includes the symbol <@@>. Follow all instructions given in comments and complete the correct code that should replace the <@@> symbol given the content. Only respond with the code that should replace the symbol <@@>. Make sure the number of spaces in the response is the same as in the user request. If you include any other code, the program will fail to compile and the user will be very sad. If you have any comments, add them as comments in the code.',
    fewshot = {
      {
        role = 'user',
        content = 'The code:\n```\nfunction greet(name) { console.log("Hello " <@@>) }\n```\n\nExisting text at <@@>: `+ nme`',
      },
      {
        role = 'assistant',
        content = '+ name',
      },
    },
    messages = messages,
  }
end

local function code_add_docstring_fewshot(input, context)
  local content = 'The code:\n```\n' .. input .. '\n```\n'

  if #context.args > 0 then
    content = content .. '\nInstruction: ' .. context.args
  end

  local messages = {
    {
      role = 'user',
      content = content,
    },
  }

  return {
    instruction = 'You are an expert programmer. You are given a piece of code containing a function. Update the function with a docstring explaining what the function does in a short and descriptive way together with the parameters in numpy style. Also add comments to any part of the code that is difficult to understand (otherwise leave out unneccessary comments). Only respond with the code that should replace the existing code. Make sure the number of spaces in the response is the same as in the user request. If you include any other code, the program will fail to compile and the user might get fired.',
    fewshot = {
      {
        role = 'user',
        content = 'The code:\n```\ndef greeting():\n    print("hello " + name)\n```',
      },
      {
        role = 'assistant',
        content = 'def greeting():\n    """\n    Prints a greeting.\n\n    Parameters\n    ----------\n    name : str\n        The name to greet.\n    """\n    print("hello " + name)\n',
      },
    },
    messages = messages,
  }
end

local function input_if_selection(input, context)
  return context.selection and input or ''
end

local maxllm = {
  request_completion = function(handlers, params, options)
    -- vim.notify(vim.inspect { params = params, options = options })
    local script_path = vim.fn.stdpath 'config' .. '/call_bedrock.py'
    local cmd = {
      'uv',
      'run',
      '--no-project',
      '--with',
      'anthropic[bedrock]',
      script_path,
      '--data',
      vim.json.encode(params.data),
    }
    if params.config and params.config.system then
      table.insert(cmd, '--system-prompt')
      table.insert(cmd, params.config.system)
    end
    -- vim.notify(vim.inspect(cmd))
    vim.system(cmd, {
      timeout = 600000,
      stdout = function(err, data)
        if data then
          handlers.on_partial(data)
        end
      end,
      stderr = function(err, data)
        if data then
          print(data)
          -- handlers.on_error(data)
        end
        if err then
          print(data)
          -- handlers.on_error(err)
        end
      end,
    }, function()
      handlers.on_finish()
    end)
  end,
}

---@type table<string, ChatPrompt>
local chats = {
  pulsar = {
    provider = maxllm,
    system = system_prompt,
    create = input_if_selection,
    run = function(messages, config)
      return { data = messages, config = config }
    end,
  },
  gpt4 = {
    provider = openai,
    system = system_prompt,
    params = {
      model = 'gpt-4o',
    },
    create = input_if_selection,
    run = function(messages, config)
      if config.system then
        table.insert(messages, 1, {
          role = 'system',
          content = config.system,
          prompts,
        })
      end

      return { messages = messages }
    end,
  },
}

---@type table<string, Prompt>
local prompt_library = {
  preplace = {
    provider = maxllm,
    mode = mode.INSERT_OR_REPLACE,
    transform = extract.markdown_code,
    builder = function(input, context)
      local standard_prompt = code_replace_fewshot(input, context)
      local messages = util.table.flatten {
        standard_prompt.fewshot,
        standard_prompt.messages,
      }
      return {
        data = messages,
        config = {
          system = standard_prompt.instruction,
        },
      }
    end,
  },
  replace = {
    provider = openai,
    mode = mode.INSERT_OR_REPLACE,
    params = {
      temperature = 0.2,
      max_tokens = 1000,
      model = 'gpt-4o',
    },
    builder = function(input, context)
      return openai.adapt(code_replace_fewshot(input, context))
    end,
    transform = extract.markdown_code,
  },
  commit = {
    provider = maxllm,
    mode = mode.INSERT,
    builder = function()
      local git_diff = vim.fn.system { 'git', 'diff', '--staged' }

      if not git_diff:match '^diff' then
        error('Git error:\n' .. git_diff)
      end

      return {
        data = {
          {
            role = 'user',
            content = 'Write a terse commit message according to the Conventional Commits specification. Try to stay below 80 characters total. Staged git diff: ```\n'
              .. git_diff
              .. '\n```',
          },
        },
      }
    end,
  },
  docstring = {
    provider = maxllm,
    mode = mode.REPLACE,
    builder = function(input, context)
      local standard_prompt = code_add_docstring_fewshot(input, context)
      local messages = util.table.flatten {
        standard_prompt.fewshot,
        standard_prompt.messages,
      }
      return {
        data = messages,
        config = {
          system = standard_prompt.instruction,
        },
      }
    end,
  },
}

return {
  chats = chats,
  prompts = prompt_library,
}
