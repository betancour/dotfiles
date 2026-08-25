-- ThePrimeagen Harpoon 2. Keymap contract: docs/HARPOON.md
-- Do not steal <C-hjkl>, <C-s>, or tmux <M-1>..<M-9>. Ctrl-Shift dies in the tty.
return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    settings = {
      save_on_toggle = true,
      sync_on_ui_close = true,
    },
  },
  config = function(_, opts)
    local harpoon = require("harpoon")
    harpoon:setup(opts)
    harpoon:extend(require("harpoon.extensions").builtins.navigate_with_number())
    harpoon:extend({
      UI_CREATE = function(cx)
        vim.keymap.set("n", "<C-v>", function()
          harpoon.ui:select_menu_item({ vsplit = true })
        end, { buffer = cx.bufnr, desc = "Harpoon vsplit" })
        vim.keymap.set("n", "<C-x>", function()
          harpoon.ui:select_menu_item({ split = true })
        end, { buffer = cx.bufnr, desc = "Harpoon split" })
        vim.keymap.set("n", "<C-t>", function()
          harpoon.ui:select_menu_item({ tabedit = true })
        end, { buffer = cx.bufnr, desc = "Harpoon tab" })
      end,
    })
  end,
  keys = function()
    local keys = {
      {
        "<leader>a",
        function()
          require("harpoon"):list():add()
        end,
        desc = "Harpoon add file",
      },
      {
        "<leader>h",
        function()
          local harpoon = require("harpoon")
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Harpoon quick menu",
      },
      {
        "[a",
        function()
          require("harpoon"):list():prev({ ui_nav_wrap = true })
        end,
        desc = "Harpoon prev",
      },
      {
        "]a",
        function()
          require("harpoon"):list():next({ ui_nav_wrap = true })
        end,
        desc = "Harpoon next",
      },
    }
    for i = 1, 4 do
      table.insert(keys, {
        "<leader>" .. i,
        function()
          require("harpoon"):list():select(i)
        end,
        desc = "Harpoon file " .. i,
      })
    end
    return keys
  end,
}
