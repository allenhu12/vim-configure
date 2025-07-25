local packer = require("packer")
packer.startup(
    function(use)
        -- Packer 可以管理自己本身
        use 'wbthomason/packer.nvim'
        -- 你的插件列表...
        -- colorscheme
        use("folke/tokyonight.nvim")
        use ( "EdenEast/nightfox.nvim" )
        use {"savq/melange"}
        -- others
        -- use({ "kyazdani42/nvim-tree.lua", requires = "kyazdani42/nvim-web-devicons", tag = 'nightly' })
        -- use({ "akinsho/bufferline.nvim", tag = "v2.*",requires = { "kyazdani42/nvim-web-devicons", "moll/vim-bbye" }})
        use {
            'kyazdani42/nvim-tree.lua',
            requires = {
                'kyazdani42/nvim-web-devicons', -- optional, for file icons
            },
            config = function() require'nvim-tree'.setup {} end
        }

        use {'akinsho/bufferline.nvim', tag = "*", requires = 'nvim-tree/nvim-web-devicons'}
        use({ "nvim-lualine/lualine.nvim",  requires = { "kyazdani42/nvim-web-devicons" } })
        use("arkav/lualine-lsp-progress")
        use { 'nvim-telescope/telescope.nvim', requires = { "nvim-lua/plenary.nvim" } }
        -- telescope extensions
        use "LinArcX/telescope-env.nvim"
        use("glepnir/dashboard-nvim")
        -- project
        use("ahmedkhalf/project.nvim")
        -- treesitter （新增）
        use({ "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" })
        use({"ojroques/vim-oscyank"})
        -- easymotion
        use({"easymotion/vim-easymotion"})
        --
        use({'dyng/ctrlsf.vim'})
        --
        -- use({'amiorin/ctrlp-z'})
        -- 
        use 'neoclide/coc.nvim'
        --
        use({'jvgrootveld/telescope-zoxide'})
        --
        use({'junegunn/vim-peekaboo'})
        --
        use({'rking/ag.vim'})
        -- 
        -- Lua
        use {
            "folke/trouble.nvim",
            requires = "kyazdani42/nvim-web-devicons",
            config = function()
                require("trouble").setup {
                    -- your configuration comes here
                    -- or leave it empty to use the default settings
                    -- refer to the configuration section below
                }

            end
        }
        -- for quick fix window 
        use {'romainl/vim-qf'}
        use {'kevinhwang91/nvim-bqf', ft = 'qf'}
        -- use a built_in function to toggle quickfix window
        -- use {'milkypostman/vim-togglelist'}
        -- optional
        use {'junegunn/fzf', run = function()
            vim.fn['fzf#install']()
        end
        }
        use {"junegunn/fzf.vim"}
        -- for tags
        use {'tpope/vim-fugitive'}
        use {'preservim/tagbar'}
        -- for keymap query
        use {"folke/which-key.nvim"}
        -- for tags preview
        use {"skywind3000/vim-preview"}
        -- for bookmarks
        use {"AndrewRadev/simple_bookmarks.vim"}
        -- for highlight marks
        -- for surround
        use {'tpope/vim-surround'}
        -- for quickly file browser
        use { "nvim-telescope/telescope-file-browser.nvim" }
    end)

-- 每次保存 plugins.lua 自动安装插件
pcall(
  vim.cmd,
  [[
    augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
    augroup end
  ]]
)
