-- VS Code Dark Modern inspired colorscheme
-- ~/.config/nvim/lua/colors/dark-modern.lua

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end

vim.o.background = "dark"
vim.g.colors_name = "dark-modern"

local c = {
  bg = "#1F1F1F",
  bg_alt = "#181818",
  bg_float = "#252526",
  bg_visual = "#264F78",
  bg_cursor = "#2A2D2E",
  bg_status = "#181818",

  fg = "#CCCCCC",
  fg_dim = "#808080",
  fg_muted = "#6A6A6A",

  red = "#F44747",
  orange = "#CE9178",
  yellow = "#DCDCAA",
  green = "#6A9955",
  cyan = "#4EC9B0",
  blue = "#569CD6",
  purple = "#C586C0",
  light_blue = "#9CDCFE",

  border = "#3E3E42",
  line = "#2A2D2E",

  error = "#F44747",
  warning = "#CCA700",
  info = "#3794FF",
  hint = "#4EC9B0",
}

local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Editor
hi("Normal", { fg = c.fg, bg = c.bg })
hi("NormalFloat", { fg = c.fg, bg = c.bg_float })
hi("NormalNC", { fg = c.fg, bg = c.bg })
hi("Cursor", { fg = c.bg, bg = c.fg })
hi("CursorLine", { bg = c.bg_cursor })
hi("CursorColumn", { bg = c.bg_cursor })
hi("ColorColumn", { bg = c.bg_cursor })

hi("LineNr", { fg = c.fg_muted })
hi("CursorLineNr", { fg = c.fg, bold = true })
hi("SignColumn", { fg = c.fg_muted, bg = c.bg })

hi("Visual", { bg = c.bg_visual })
hi("Search", { fg = c.bg, bg = c.yellow })
hi("IncSearch", { fg = c.bg, bg = c.orange })
hi("CurSearch", { fg = c.bg, bg = c.yellow })

hi("MatchParen", {
  fg = c.yellow,
  bg = c.bg_cursor,
  bold = true,
})

-- UI
hi("StatusLine", {
  fg = c.fg,
  bg = c.bg_status,
})

hi("StatusLineNC", {
  fg = c.fg_dim,
  bg = c.bg_alt,
})

hi("WinSeparator", {
  fg = c.border,
  bg = c.bg,
})

hi("VertSplit", {
  fg = c.border,
  bg = c.bg,
})

hi("FloatBorder", {
  fg = c.border,
  bg = c.bg_float,
})

hi("Pmenu", {
  fg = c.fg,
  bg = c.bg_float,
})

hi("PmenuSel", {
  fg = c.fg,
  bg = c.bg_visual,
})

hi("PmenuSbar", {
  bg = c.bg_cursor,
})

hi("PmenuThumb", {
  bg = c.fg_dim,
})

hi("Folded", {
  fg = c.fg_dim,
  bg = c.bg_float,
})

hi("FoldColumn", {
  fg = c.fg_muted,
  bg = c.bg,
})

-- Messages
hi("ErrorMsg", { fg = c.error })
hi("WarningMsg", { fg = c.warning })
hi("MoreMsg", { fg = c.green })
hi("Question", { fg = c.blue })

-- Comments
hi("Comment", {
  fg = "#6A9955",
  italic = true,
})

-- Syntax
hi("Constant", { fg = c.blue })
hi("String", { fg = c.orange })
hi("Character", { fg = c.orange })
hi("Number", { fg = c.light_blue })
hi("Boolean", { fg = c.blue })
hi("Float", { fg = c.light_blue })

hi("Identifier", { fg = c.light_blue })
hi("Function", { fg = c.yellow })

hi("Statement", { fg = c.purple })
hi("Conditional", { fg = c.purple })
hi("Repeat", { fg = c.purple })
hi("Label", { fg = c.purple })
hi("Operator", { fg = c.fg })
hi("Keyword", { fg = c.purple })
hi("Exception", { fg = c.purple })

hi("PreProc", { fg = c.purple })
hi("Include", { fg = c.purple })
hi("Define", { fg = c.purple })
hi("Macro", { fg = c.purple })
hi("PreCondit", { fg = c.purple })

hi("Type", { fg = c.cyan })
hi("StorageClass", { fg = c.blue })
hi("Structure", { fg = c.cyan })
hi("Typedef", { fg = c.cyan })

hi("Special", { fg = c.light_blue })
hi("SpecialChar", { fg = c.orange })
hi("Tag", { fg = c.blue })
hi("Delimiter", { fg = c.fg })
hi("Debug", { fg = c.red })

hi("Underlined", {
  fg = c.blue,
  underline = true,
})

hi("Title", {
  fg = c.blue,
  bold = true,
})

hi("Todo", {
  fg = c.bg,
  bg = c.yellow,
  bold = true,
})

-- Diagnostics
hi("DiagnosticError", {
  fg = c.error,
})

hi("DiagnosticWarn", {
  fg = c.warning,
})

hi("DiagnosticInfo", {
  fg = c.info,
})

hi("DiagnosticHint", {
  fg = c.hint,
})

hi("DiagnosticUnderlineError", {
  undercurl = true,
  sp = c.error,
})

hi("DiagnosticUnderlineWarn", {
  undercurl = true,
  sp = c.warning,
})

hi("DiagnosticUnderlineInfo", {
  undercurl = true,
  sp = c.info,
})

hi("DiagnosticUnderlineHint", {
  undercurl = true,
  sp = c.hint,
})

-- Git
hi("DiffAdd", { fg = c.green, bg = "#263826" })
hi("DiffChange", { fg = c.yellow, bg = "#3A3620" })
hi("DiffDelete", { fg = c.red, bg = "#3A2525" })
hi("DiffText", { fg = c.fg, bg = "#4A4425" })

hi("GitSignsAdd", { fg = c.green })
hi("GitSignsChange", { fg = c.yellow })
hi("GitSignsDelete", { fg = c.red })

-- Treesitter
hi("@comment", { link = "Comment" })

hi("@string", { fg = c.orange })
hi("@string.escape", { fg = c.blue })
hi("@string.special", { fg = c.blue })

hi("@number", { fg = c.light_blue })
hi("@boolean", { fg = c.blue })
hi("@constant", { fg = c.blue })
hi("@constant.builtin", { fg = c.blue })

hi("@variable", { fg = c.light_blue })
hi("@variable.builtin", { fg = c.blue })
hi("@parameter", { fg = c.light_blue })

hi("@function", { fg = c.yellow })
hi("@function.call", { fg = c.yellow })
hi("@function.builtin", { fg = c.yellow })
hi("@method", { fg = c.yellow })
hi("@method.call", { fg = c.yellow })

hi("@keyword", { fg = c.purple })
hi("@keyword.function", { fg = c.purple })
hi("@keyword.return", { fg = c.purple })
hi("@conditional", { fg = c.purple })
hi("@repeat", { fg = c.purple })

hi("@type", { fg = c.cyan })
hi("@type.builtin", { fg = c.cyan })
hi("@constructor", { fg = c.cyan })

hi("@property", { fg = c.light_blue })
hi("@field", { fg = c.light_blue })

hi("@operator", { fg = c.fg })
hi("@punctuation", { fg = c.fg })
hi("@tag", { fg = c.blue })
hi("@tag.attribute", { fg = c.light_blue })

-- LSP semantic tokens
hi("@lsp.type.class", { fg = c.cyan })
hi("@lsp.type.interface", { fg = c.cyan })
hi("@lsp.type.enum", { fg = c.cyan })
hi("@lsp.type.struct", { fg = c.cyan })
hi("@lsp.type.type", { fg = c.cyan })

hi("@lsp.type.function", { fg = c.yellow })
hi("@lsp.type.method", { fg = c.yellow })

hi("@lsp.type.variable", { fg = c.light_blue })
hi("@lsp.type.parameter", { fg = c.light_blue })
hi("@lsp.type.property", { fg = c.light_blue })

hi("@lsp.type.keyword", { fg = c.purple })
hi("@lsp.type.namespace", { fg = c.cyan })

-- Telescope
hi("TelescopeNormal", {
  fg = c.fg,
  bg = c.bg_float,
})

hi("TelescopeBorder", {
  fg = c.border,
  bg = c.bg_float,
})

hi("TelescopePromptNormal", {
  fg = c.fg,
  bg = c.bg_cursor,
})

hi("TelescopePromptBorder", {
  fg = c.border,
  bg = c.bg_cursor,
})

hi("TelescopeSelection", {
  fg = c.fg,
  bg = c.bg_visual,
})

hi("TelescopeMatching", {
  fg = c.yellow,
  bold = true,
})

-- Neo-tree / file explorers
hi("NeoTreeNormal", {
  fg = c.fg,
  bg = c.bg,
})

hi("NeoTreeNormalNC", {
  fg = c.fg_dim,
  bg = c.bg,
})

hi("NeoTreeDirectoryName", {
  fg = c.blue,
})

hi("NeoTreeDirectoryIcon", {
  fg = c.blue,
})

hi("NeoTreeGitAdded", {
  fg = c.green,
})

hi("NeoTreeGitModified", {
  fg = c.yellow,
})

hi("NeoTreeGitDeleted", {
  fg = c.red,
})

-- Spell checking
hi("SpellBad", {
  undercurl = true,
  sp = c.red,
})

hi("SpellCap", {
  undercurl = true,
  sp = c.blue,
})

hi("SpellRare", {
  undercurl = true,
  sp = c.purple,
})

hi("SpellLocal", {
  undercurl = true,
  sp = c.cyan,
})
