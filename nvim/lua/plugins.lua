local packer = require("packer")
packer.startup(
  function(use)
   -- Packer 可以管理自己本身
   use 'wbthomason/packer.nvim'
   -- 你的插件列表...
   -- colorscheme
   use("folke/tokyonight.nvim")
   -- others
   use({ "kyazdani42/nvim-tree.lua", requires = "kyazdani42/nvim-web-devicons" })
   use({ "akinsho/bufferline.nvim", requires = { "kyazdani42/nvim-web-devicons", "moll/vim-bbye" }})
   use({ "nvim-lualine/lualine.nvim", requires = { "kyazdani42/nvim-web-devicons" } })
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
   use({'amiorin/ctrlp-z'})
   -- 
   use 'neoclide/coc.nvim'
   --
   use({'jvgrootveld/telescope-zoxide'})
   --
   use({'junegunn/vim-peekaboo'})
   --
   use({'rking/ag.vim'})
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
