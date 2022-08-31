-- basic configuration
require('basic')
-- keybindings configuration
require('keybindings')
-- plugins configuration
require('plugins')
-- colorscheme configuration
require("colorscheme")
-- plugin configuration
require("plugin-config.nvim-tree")
require("plugin-config.bufferline")
require("plugin-config.lualine")
require("plugin-config.telescope")
require("plugin-config.dashboard")
require("plugin-config.project")
require("plugin-config.nvim-treesitter")
require'telescope'.load_extension('zoxide')

