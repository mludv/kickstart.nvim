local openai = require 'model.providers.openai'

-- prompt helpers
local extract = require 'model.prompts.extract'
local consult = require 'model.prompts.consult'

-- utils
local util = require 'model.util'
local async = require 'model.util.async'
local prompts = require 'model.util.prompts'
local mode = require('model').mode

local system_prompt = [[
You are an AI programming assistant integrated into a code editor. Your purpose is to help the user with programming tasks as they write code.
Key capabilities:
- Thoroughly analyze the user's code and provide insightful suggestions for improvements related to best practices, performance, readability, and maintainability. Explain your reasoning.
- Answer coding questions in detail, using examples from the user's own code when relevant. Break down complex topics step- Spot potential bugs and logical errors. Alert the user and suggest fixes.
- Upon request, add helpful comments explaining complex or unclear code.
- Suggest relevant documentation, StackOverflow answers, and other resources related to the user's code and questions.
- Engage in back-and-forth conversations to understand the user's intent and provide the most helpful information.
- Keep concise and use markdown.
- When asked to create code, only generate the code. No bugs.
- Think step by step
]]

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
    instruction = 'You are an expert programmer. You are given a snippet of code which includes the symbol <@@>. Complete the correct code that should replace the <@@> symbol given the content. Only respond with the code that should replace the symbol <@@>. If you include any other code, the program will fail to compile and the user will be very sad.',
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

local function input_if_selection(input, context)
  return context.selection and input or ''
end

local Job = require 'plenary.job'

local test_provider = {
  request_completion = function(handlers, params, options)
    Job:new({
      command = '/Users/max/Projects/test.sh',
      on_stdout = function(err, data)
        if err then
          print 'error'
          print(err)
        else
          handlers.on_partial(data)
        end
      end,
      on_exit = function(j, return_val)
        handlers.on_finish()
      end,
    }):start()
    -- vim.notify(vim.inspect { params = params, options = options })
  end,
}

---@type table<string, ChatPrompt>
local chats = {
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
        })
      end

      return { messages = messages }
    end,
  },
}

---@type table<string, Prompt>
local prompt_library = {
  test_prompt = {
    provider = test_provider,
    builder = function(input, context)
      return {
        input = input,
        context = context,
      }
    end,
  },
  replace = {
    provider = openai,
    mode = mode.INSERT_OR_REPLACE,
    params = {
      temperature = 0.2,
      max_tokens = 1000,
      model = 'gpt-4',
    },
    builder = function(input, context)
      return openai.adapt(code_replace_fewshot(input, context))
    end,
    transform = extract.markdown_code,
  },
  commit = {
    provider = openai,
    mode = mode.INSERT,
    builder = function()
      local git_diff = vim.fn.system { 'git', 'diff', '--staged' }

      if not git_diff:match '^diff' then
        error('Git error:\n' .. git_diff)
      end

      return {
        messages = {
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
}

return {
  chats = chats,
  prompts = prompt_library,
}
