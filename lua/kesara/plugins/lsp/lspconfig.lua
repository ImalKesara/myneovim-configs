return {
   {
      "neovim/nvim-lspconfig",
      event = { "BufReadPre", "BufNewFile" },
      dependencies = {
         -- Replace hrsh7th/cmp plugins with coq_nvim
         { "ms-jpq/coq_nvim", branch = "coq" },
         { "ms-jpq/coq.artifacts", branch = "artifacts" }, -- Optional: for snippets
         { "antosha417/nvim-lsp-file-operations", config = true },
         { "folke/neodev.nvim", opts = {} },
      },
      config = function()
         -- Import lspconfig plugin
         local lspconfig = require("lspconfig")

         -- Import mason_lspconfig plugin
         local mason_lspconfig = require("mason-lspconfig")

         -- Configure coq_nvim (replacing cmp-nvim-lsp)
         vim.g.coq_settings = {
            auto_start = "shut-up", -- Start silently
            keymap = { recommended = true }, -- Use default keymaps (e.g., <Tab> to cycle)
            clients = {
               lsp = { enabled = true }, -- Enable LSP completions
            },
         }

         local keymap = vim.keymap -- for conciseness

         -- Your existing LspAttach autocommand
         vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspConfig", {}),
            callback = function(ev)
               local opts = { buffer = ev.buf, silent = true }

               opts.desc = "Show LSP references"
               keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)

               opts.desc = "Go to declaration"
               keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

               opts.desc = "Show LSP definitions"
               keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

               opts.desc = "Show LSP implementations"
               keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

               opts.desc = "Show LSP type definitions"
               keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)

               opts.desc = "See available code actions"
               keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

               opts.desc = "Smart rename"
               keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

               opts.desc = "Show buffer diagnostics"
               keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)

               opts.desc = "Show line diagnostics"
               keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

               opts.desc = "Go to previous diagnostic"
               keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)

               opts.desc = "Go to next diagnostic"
               keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

               opts.desc = "Show documentation for what is under cursor"
               keymap.set("n", "K", vim.lsp.buf.hover, opts)

               opts.desc = "Restart LSP"
               keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
            end,
         })

         -- Change Diagnostic symbols in the sign column (gutter)
         local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
         for type, icon in pairs(signs) do
            local hl = "DiagnosticSign" .. type
            vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
         end

         -- LSP server configurations
         mason_lspconfig.setup_handlers({
            -- Default handler for installed servers
            function(server_name)
               lspconfig[server_name].setup({})
            end,
            ["tsserver"] = function()
               -- Configure tsserver explicitly for TypeScript/JavaScript/SvelteKit
               lspconfig.tsserver.setup({
                  filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact", "svelte" },
                  root_dir = lspconfig.util.root_pattern("tsconfig.json", "jsconfig.json", "package.json", ".git"),
               })
            end,
            ["svelte"] = function()
               lspconfig["svelte"].setup({
                  on_attach = function(client, bufnr)
                     vim.api.nvim_create_autocmd("BufWritePost", {
                        pattern = { "*.js", "*.ts" },
                        callback = function(ctx)
                           client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
                        end,
                     })
                  end,
               })
            end,
            ["graphql"] = function()
               lspconfig["graphql"].setup({
                  filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
               })
            end,
            ["emmet_ls"] = function()
               lspconfig["emmet_ls"].setup({
                  filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
               })
            end,
            ["lua_ls"] = function()
               lspconfig["lua_ls"].setup({
                  settings = {
                     Lua = {
                        diagnostics = { globals = { "vim" } },
                        completion = { callSnippet = "Replace" },
                     },
                  },
               })
            end,
         })
      end,
   },
}
