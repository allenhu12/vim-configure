local status, telescope = pcall(require, "telescope")
if not status then
  vim.notify("没有找到 telescope")
  return
end

local actions = require("telescope.actions")
local trouble = require("trouble.providers.telescope")


telescope.setup({
  defaults = {
        -- 打开弹窗后进入的初始模式，默认为 insert，也可以是 normal
        initial_mode = "insert",
        -- 窗口内快捷键
        --mappings = require("keybindings").telescopeList,
        file_ignore_patterns = {"tags", "build/"},
        mappings = {
            i = { ["<c-t>"] = trouble.open_with_trouble },
            n = { ["<c-t>"] = trouble.open_with_trouble },
        },
  },
  pickers = {
    -- 内置 pickers 配置
    find_files = {
      -- 查找文件换皮肤，支持的参数有： dropdown, cursor, ivy
      theme = "ivy", 
    },

    live_grep = {
      -- 查找文件换皮肤，支持的参数有： dropdown, cursor, ivy
            theme = "ivy", 
            file_ignore_patterns = {"tags"},
    }
  },
  extensions = {
     -- 扩展插件配置
  },
})

-- telescope extensions
pcall(telescope.load_extension, "env")
