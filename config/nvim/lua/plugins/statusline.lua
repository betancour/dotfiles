-- Green Phosphor statusline. Same four stops as colors/green-phosphor.lua.

local fg = "#00FF66"
local bg = "#003318"
local dim = "#6FA783"

local mono = { fg = fg, bg = bg }
local section = {
  a = { fg = fg, bg = bg, gui = "bold" },
  b = mono,
  c = mono,
}
local inactive = {
  a = { fg = dim, bg = bg },
  b = { fg = dim, bg = bg },
  c = { fg = dim, bg = bg },
}

local theme = {
  normal = vim.deepcopy(section),
  insert = vim.deepcopy(section),
  visual = vim.deepcopy(section),
  replace = vim.deepcopy(section),
  command = vim.deepcopy(section),
  terminal = vim.deepcopy(section),
  inactive = inactive,
}

local function paint(sections)
  if not sections then
    return
  end
  for _, sec in pairs(sections) do
    if type(sec) == "table" then
      for i, comp in ipairs(sec) do
        if type(comp) == "table" then
          if comp.color ~= nil then
            comp.color = vim.deepcopy(mono)
          end
          local name = comp[1]
          if name == "diagnostics" or name == "diff" or name == "filetype" then
            comp.colored = false
          end
          -- pretty_path: drop MatchParen / Bold so modified files stay phosphor
          if type(name) == "function" and not comp.color and not comp.cond then
            sec[i] = {
              LazyVim.lualine.pretty_path({
                modified_hl = "",
                filename_hl = "",
                directory_hl = "",
              }),
            }
          end
        end
      end
    end
  end
end

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.theme = theme
      opts.options.component_separators = { left = "", right = "" }
      opts.options.section_separators = { left = "", right = "" }
      paint(opts.sections)
      paint(opts.inactive_sections)
      return opts
    end,
  },
}
