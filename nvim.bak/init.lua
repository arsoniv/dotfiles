
vim.opt.rtp:prepend("~/.local/share/nvim/site/pack/lazy/start/lazy.nvim")

require("lazy").setup({
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
  { "nvim-treesitter/nvim-treesitter"},
  { "nvim-lualine/lualine.nvim" },
  { "tpope/vim-fugitive" },
  { "neovim/nvim-lspconfig" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "hrsh7th/cmp-cmdline" },
  { "neovim/nvim-lspconfig" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },
  { "nvim-telescope/telescope.nvim" },
  { "tpope/vim-fugitive" }
})

require("mason").setup()

require('telescope').setup()

require("mason-lspconfig").setup({
  automatic_installation = true,
})

local lspconfig = require("lspconfig")
local servers = require("mason-lspconfig").get_installed_servers()
for _, server in pairs(servers) do
  lspconfig[server].setup{}
end

local cmp = require("cmp")

vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    require("lsp.jdtls")
  end,
})


cmp.setup({
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  mapping = {
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping.select_next_item(),
    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
  },
  sources = {
    { name = "nvim_lsp" },
    { name = "buffer" },
    { name = "path" },
    { name = "luasnip" },
  },
})

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })


vim.opt.termguicolors = true
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })

vim.api.nvim_set_hl(0, "LineNr", { fg = "#7f849c", bg = "none" })           -- normal line numbers
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#89b4fa", bg = "none" })    -- current line number

vim.opt.number = true                 -- Show line numbers
vim.opt.relativenumber = true        -- Relative line numbers
vim.opt.mouse = "a"                  -- Enable mouse support
vim.opt.clipboard = "unnamedplus"   -- Use system clipboard
vim.opt.swapfile = false            -- Don't use swap files
vim.opt.backup = false              -- Don't use backup files
vim.opt.undofile = true             -- Persistent undo
vim.opt.encoding = "utf-8"          -- Always use UTF-8
vim.opt.fileencoding = "utf-8"      -- File encoding

vim.opt.termguicolors = true        -- Enable 24-bit RGB color
vim.opt.cmdheight = 1               -- Command line height
vim.opt.updatetime = 300            -- Faster completion
vim.opt.timeoutlen = 500            -- Shorter timeout for mappings
vim.opt.signcolumn = "yes"          -- Always show sign column

vim.opt.expandtab = true            -- Use spaces instead of tabs
vim.opt.shiftwidth = 2              -- Shift 2 spaces when tab
vim.opt.tabstop = 2                 -- 1 tab = 2 spaces
vim.opt.smartindent = true          -- Auto indent new lines

vim.opt.ignorecase = true           -- Ignore case
vim.opt.smartcase = true            -- Case-sensitive if mixed case
vim.opt.incsearch = true            -- Search as you type
vim.opt.hlsearch = true             -- Highlight search results

vim.opt.cursorline = false -- Highlight current line
vim.opt.scrolloff = 8               -- Minimum lines above/below cursor
vim.opt.sidescrolloff = 8           -- Minimum cols left/right of cursor
vim.opt.wrap = false                -- Disable line wrap
vim.opt.showmode = false            -- Don't show -- INSERT --

vim.opt.splitright = true           -- Vertical splits to the right
vim.opt.splitbelow = true           -- Horizontal splits below

vim.opt.completeopt = { "menu", "menuone", "noselect" }

vim.opt.path:append("**")           -- Search down into subfolders
vim.opt.wildmenu = true             -- Enhanced command-line completion

vim.opt.laststatus = 3              -- Global statusline (Neovim 0.7+)
vim.opt.showcmd = false             -- Don't show command in bottom bar

vim.opt.lazyredraw = true           -- Faster scrolling
vim.opt.ttimeoutlen = 0             -- No delay for key codes

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>")
