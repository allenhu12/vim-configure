-- vim.g.mapleader = ","
-- vim.g.maplocalleader = ","
local map = vim.api.nvim_set_keymap
-- 复用 opt 参数
local opt = {noremap = true, silent = true }
map("n", "<Space>", "", opt)
vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- vim.g.mapleader = ","
-- vim.g.maplocalleader = ","

-- visual模式下缩进代码
map("v", "<", "<gv", opt)
map("v", ">", ">gv", opt)
-- 上下移动选中文本111111
map("v", "J", ":move '>+1<CR>gv-gv", opt)
map("v", "K", ":move '<-2<CR>gv-gv", opt)
-- 上下滚动浏览
--map("n", "<C-j>", "4j", opt)
--map("n", "<C-k>", "4k", opt)
-- ctrl u / ctrl + d  只移动9行，默认移动半屏
map("n", "<C-u>", "9k", opt)
map("n", "<C-d>", "9j", opt)
-- 在visual 模式里粘贴不要复制
map("v", "p", '"_dP', opt)

-- 退出
-- map("n", "q", ":q<CR>", opt)
-- map("n", "qq", ":q!<CR>", opt)
 --map("n", "Q", ":qa!<CR>", opt)
-- insert 模式下，跳到行首行尾
map("i", "<C-h>", "<ESC>I", opt)
map("i", "<C-l>", "<ESC>A", opt)

-- command mode
map("c", "<C-j>", "<C-n>", {noremap = true})
map("c", "<C-,>", "<C-w>", {noremap = true})
map("c", "<C-k>", "<C-p>", {noremap = true})
map("c", "<C-h>", "<Left>", {noremap = true})
map("c", "<C-l", "<Right>", {noremap = true})

-- normal mode, better window management
map("n", "<C-h>", "<C-w>h", opt)
map("n", "<C-j>", "<C-w>j", opt)
map("n", "<C-k>", "<C-w>k", opt)
map("n", "<C-l>", "<C-w>l", opt)
-- ":" to ";" to enter command mode quickly, noted, no "slient = ture"
map("n", ";", ":", {noremap = true} )
-- Move text up and down
map("n", "<S-j>", "<Esc>:m .+1<CR>==gi", opt)
map("n", "<S-k>", "<Esc>:m .-2<CR>==gi", opt)
map("n", "<m-k>", "<Esc>:m .-2<CR>==gi", opt)
map("n", "<leader>n", ":noh<cr>", opt)
-- nnoremap <A-j> :m .+1<CR>==
-- nnoremap <A-k> :m .-2<CR>==
-- inoremap <A-j> <Esc>:m .+1<CR>==gi
-- inoremap <A-k> <Esc>:m .-2<CR>==gi
-- vnoremap <A-j> :m '>+1<CR>gv=gv
-- vnoremap <A-k> :m '<-2<CR>gv=gv
-- map("v", "<m-j>", "m '>+1<CR>gv=gv", opt)
-- map("v", "<m-k>", "m '<-2<CR>gv=gv", opt)


-- stay indent
map("v", "<", "<gv", opt)
map("v", ">", ">gv", opt)


-- 插件快捷键
local pluginKeys = {}
-- zoxide to switch directory
map("n", "ff", ":Telescope zoxide list<CR>", opt)
-- nvim-tree
-- alt + m 键打开关闭tree
map("n", "<m-m>", ":NvimTreeToggle<CR>", opt)
-- 列表快捷键
pluginKeys.nvimTreeList = {
  -- 打开文件或文件夹
  { key = {"<CR>", "o", "<2-LeftMouse>"}, action = "edit" },
  -- 分屏打开文件
  { key = "v", action = "vsplit" },
  { key = "h", action = "split" },
  -- 显示隐藏文件
  { key = "i", action = "toggle_ignored" }, -- Ignore (node_modules)
  { key = ".", action = "toggle_dotfiles" }, -- Hide (dotfiles)
  -- 文件操作
  { key = "<F5>", action = "refresh" },
  { key = "a", action = "create" },
  { key = "d", action = "remove" },
  { key = "r", action = "rename" },
  { key = "x", action = "cut" },
  { key = "c", action = "copy" },
  { key = "p", action = "paste" },
  { key = "s", action = "system_open" },
}

-- bufferline
-- 左右Tab切换
-- map("n", "<C-h>", ":BufferLineCyclePrev<CR>", opt)
-- map("n", "<C-l>", ":BufferLineCycleNext<CR>", opt)
map("n", "<C-g>", ":BufferLinePick<CR>", opt)
map("n", "x;1", ":BufferLineGoToBuffer 1<CR>", opt)
map("n", "x;2", ":BufferLineGoToBuffer 2<CR>", opt)
map("n", "x;3", ":BufferLineGoToBuffer 3<CR>", opt)
map("n", "x;4", ":BufferLineGoToBuffer 4<CR>", opt)
map("n", "x;5", ":BufferLineGoToBuffer 5<CR>", opt)
map("n", "x;6", ":BufferLineGoToBuffer 6<CR>", opt)
map("n", "x;7", ":BufferLineGoToBuffer 7<CR>", opt)
map("n", "x;8", ":BufferLineGoToBuffer 8<CR>", opt)
map("n", "x;9", ":BufferLineGoToBuffer 9<CR>", opt)

-- 关闭
--"moll/vim-bbye"
-- map("n", "<C-w>", ":Bdelete!<CR>", opt)
map("n", "<leader>bl", ":BufferLineCloseRight<CR>", opt)
map("n", "<leader>bh", ":BufferLineCloseLeft<CR>", opt)
map("n", "<leader>bc", ":BufferLinePickClose<CR>", opt)
map("n", "<Tab>", ":BufferLineCycleNext<CR>", opt)

-- Telescope
-- 查找文件
map("n", "<C-p>", ":Telescope find_files<CR>", opt)
-- buffers
map("n", "<C-\\>", ":Telescope buffers<CR>", opt)
-- 全局搜索
map("n", "f/", ":Telescope live_grep<CR>", opt)
-- easymotion
map("n", "<C-f>", "<Plug>(easymotion-overwin-f)", opt)
-- trouble
-- Lua

 -- map("n","<leader>xx", ":TroubleToggle<cr>",opt)
 -- 
 -- vim.api.nvim_set_keymap("n", "<leader>xw", "<cmd>Trouble workspace_diagnostics<cr>",
 --   {silent = true, noremap = true}
 -- )
 -- vim.api.nvim_set_keymap("n", "<leader>xd", "<cmd>Trouble document_diagnostics<cr>",
 --   {silent = true, noremap = true}
 -- )
 -- vim.api.nvim_set_keymap("n", "<leader>xl", "<cmd>Trouble loclist<cr>",
 --   {silent = true, noremap = true}
 -- )
 -- vim.api.nvim_set_keymap("n", "<leader>xq", "<cmd>Trouble quickfix<cr>",
 --   {silent = true, noremap = true}
 -- )
 -- vim.api.nvim_set_keymap("n", "gR", "<cmd>Trouble lsp_references<cr>",
 --   {silent = true, noremap = true}
 -- )
-- map("n", "<m-j>", "<cmd>lua require("trouble").next({skip_groups = true, jump = true})<cr>", opt)
-- trouble end
map("n", "qq", ":call ToggleQuickFix()<cr>", opt)
map("n", "<leader>l", ":call ToggleLocationList()<CR>", opt)
map("n", "<leader>q", ":call ToggleQuickFix()<CR>", opt)
return pluginKeys
