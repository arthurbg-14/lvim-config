lvim.colorscheme = "cyberdream"

lvim.builtin.treesitter.ensure_installed = {
  "lua",
  "rust",
  "toml",
}

vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "rust_analyzer" })

local mason_path = vim.fn.glob(vim.fn.stdpath "data" .. "/mason/")

local codelldb_path = mason_path .. "bin/codelldb"
local liblldb_path = mason_path .. "packages/codelldb/extension/lldb/lib/liblldb"
local this_os = vim.loop.os_uname().sysname

-- The path in windows is different
if this_os:find "Windows" then
  codelldb_path = mason_path .. "packages\\codelldb\\extension\\adapter\\codelldb.exe"
  liblldb_path = mason_path .. "packages\\codelldb\\extension\\lldb\\bin\\liblldb.dll"
else
  -- The liblldb extension is .so for linux and .dylib for macOS
  liblldb_path = liblldb_path .. (this_os == "Linux" and ".so" or ".dylib")
end

pcall(function()
  require("rust-tools").setup {
    tools = {
      executor = require("rust-tools/executors").termopen, -- can be quickfix or termopen
      reload_workspace_from_cargo_toml = true,
      runnables = {
        use_telescope = true,
      },
      inlay_hints = {
        auto = true,
        only_current_line = false,
        show_parameter_hints = false,
        parameter_hints_prefix = "<-",
        other_hints_prefix = "=>",
        max_len_align = false,
        max_len_align_padding = 1,
        right_align = false,
        right_align_padding = 7,
        highlight = "Comment",
      },
      hover_actions = {
        border = "rounded",
      },
      on_initialized = function()
        vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter", "CursorHold", "InsertLeave" }, {
          pattern = { "*.rs" },
          callback = function()
            local _, _ = pcall(vim.lsp.codelens.refresh)
          end,
        })
      end,
    },
    dap = {
      -- adapter= codelldb_adapter,
      adapter = require("rust-tools.dap").get_codelldb_adapter(codelldb_path, liblldb_path),
    },
    server = {
      on_attach = function(client, bufnr)
        require("lvim.lsp").common_on_attach(client, bufnr)
        local rt = require "rust-tools"
        vim.keymap.set("n", "K", rt.hover_actions.hover_actions, { buffer = bufnr })
      end,

      capabilities = require("lvim.lsp").common_capabilities(),
      settings = {
        ["rust-analyzer"] = {
          lens = {
            enable = true,
          },
          checkOnSave = {
            enable = true,
            command = "clippy",
          },
        },
      },
    },
  }
end)

lvim.builtin.dap.on_config_done = function(dap)
  dap.adapters.codelldb = require("rust-tools.dap").get_codelldb_adapter(codelldb_path, liblldb_path)
  dap.configurations.rust = {
    {
      name = "Launch file",
      type = "codelldb",
      request = "launch",
      program = function()
        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
    },
  }
end

vim.api.nvim_set_keymap("n", "<m-d>", "<cmd>RustOpenExternalDocs<Cr>", { noremap = true, silent = true })

lvim.builtin.which_key.mappings["C"] = {
  name = "Rust",
  r = { "<cmd>RustRunnables<Cr>", "Runnables" },
  t = { "<cmd>lua _CARGO_TEST()<cr>", "Cargo Test" },
  m = { "<cmd>RustExpandMacro<Cr>", "Expand Macro" },
  c = { "<cmd>RustOpenCargo<Cr>", "Open Cargo" },
  p = { "<cmd>RustParentModule<Cr>", "Parent Module" },
  d = { "<cmd>RustDebuggables<Cr>", "Debuggables" },
  v = { "<cmd>RustViewCrateGraph<Cr>", "View Crate Graph" },
  R = {
    "<cmd>lua require('rust-tools/workspace_refresh')._reload_workspace_from_cargo_toml()<Cr>",
    "Reload Workspace",
  },
  o = { "<cmd>RustOpenExternalDocs<Cr>", "Open External Docs" },
  y = { "<cmd>lua require'crates'.open_repository()<cr>", "[crates] open repository" },
  P = { "<cmd>lua require'crates'.show_popup()<cr>", "[crates] show popup" },
  i = { "<cmd>lua require'crates'.show_crate_popup()<cr>", "[crates] show info" },
  f = { "<cmd>lua require'crates'.show_features_popup()<cr>", "[crates] show features" },
  D = { "<cmd>lua require'crates'.show_dependencies_popup()<cr>", "[crates] shaw dependencies" },
}

lvim.plugins = {
  "declancm/cinnamon.nvim",
  "mfussenegger/nvim-dap-python",
  "simrat39/rust-tools.nvim",
  {
      "scottmckendry/cyberdream.nvim",
      lazy = false,
      priority = 1000,
  },
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000, -- Ensure it loads first
  },
  {
    "saecki/crates.nvim",
    version = "v0.3.0",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("crates").setup {
        null_ls = {
          enabled = true,
          name = "crates.nvim",
        },
        popup = {
          border = "rounded",
        },
      }
    end,
  },
  {
    "j-hui/fidget.nvim",
    config = function()
      require("fidget").setup()
    end,
  },
  { "nvim-treesitter/nvim-treesitter-angular" },
  { "lunarvim/colorschemes" },
  { "Mofiqul/dracula.nvim" },
  { "joeveiga/ng.nvim" },
  { "liangxianzhe/floating-input.nvim" },
  { "rcarriga/nvim-notify" },
  { "windwp/nvim-ts-autotag" },
  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = true,
  },
  { "APZelos/blamer.nvim" },
}
require("lvim.lsp.manager").setup("angularls")
require('nvim-ts-autotag').setup({
  filetypes = { "html" , "xml" },
})

-- ANGULAR CLI
local notify = require 'notify'

vim.ui.input = function(opts, on_confirm)
	require("floating-input").input(opts, on_confirm, { border = 'double' })
end

function Angular_cli(cmd)
  local handle, err = io.popen("ng " .. cmd)

  if handle == nil then
    return notify("Error: " .. err, vim.log.levels.ERROR)
  end

  local result = handle:read("*a")
  handle:close()
  notify(result, vim.log.levels.INFO)
end

vim.opt.relativenumber = true

lvim.builtin.which_key.mappings["a"] = {
  name = "Angular",
  t = { "<cmd>lua require('ng').goto_template_for_component({ noremap = true, silent = true, reuse_window = true })<cr>", "Go to Template for Component" },
  c = { "<cmd>lua require('ng').goto_component_with_template_file({ noremap = true, silent = true, reuse_window = true })<cr>", "Go to Component with Template File" },
  T = { "<cmd>lua require('ng').get_template_tcb({ noremap = true, silent = true, reuse_window = true })<cr>", "Get Template TCB" },
  C = { "<cmd>lua vim.ui.input({prompt='NG:'}, Angular_cli)<cr>", "Angular CLI" },
}
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float)
lvim.builtin.which_key.mappings["l"]["h"] = { "<cmd>ClangdSwitchSourceHeader<cr>", "Switch Header/Source" }

-- DEBUGGER

local dap = require('dap')

dap.adapters.cppdbg = {
  id = 'cppdbg',
  type = 'executable',
  command = vim.env.HOME .. '/cpptools/extension/debugAdapters/bin/OpenDebugAD7',
}

dap.configurations.cpp = {
  {
    name = "Launch file",
    type = "cppdbg",
    request = "launch",
    miDebuggerPath = '/usr/bin/gdb',
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopAtEntry = true,
  },
  {
    name = 'Attach to gdbserver :1234',
    type = 'cppdbg',
    request = 'launch',
    MIMode = 'gdb',
    miDebuggerServerAddress = 'localhost:1234',
    miDebuggerPath = '/usr/bin/gdb',
    cwd = '${workspaceFolder}',
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
  },
}

require('dap-python').setup('/usr/bin/python')
dap.configurations.python = {
  {
      type = 'python',
      request = 'launch',
      name = 'My custom launch configuration',
      program = '${file}',
  }
}

require("cinnamon").setup {
    -- Enable all provided keymaps
    keymaps = {
        basic = true,
        extra = true,
    },
    -- Only scroll the window
    options = { mode = "window" },
}

require'lspconfig'.clangd.setup{}
