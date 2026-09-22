-- ~/.config/nvim/lua/plugins/editorconfig.lua
return {
  {
    -- dummy spec so this file is loaded by lazy
    -- editorconfig is builtin; we only set options
    dir = vim.fn.stdpath("config"),
    name = "editorconfig-enable",
    lazy = false,
    init = function()
      vim.g.editorconfig = true
    end,
  },
}
