-- Green Phosphor — one hue. Same four stops as Alacritty green-phosphor.
--   bg #000000  dark #003318  dim #6FA783  fg #00FF66
-- Emphasis is bold / italic / reverse. No second hue.
-- Grok [ui] theme = "terminal" inherits the Alacritty 16-color map.

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end

vim.o.background = "dark"
vim.g.colors_name = "green-phosphor"
vim.opt.termguicolors = true

local bg, dark, dim, fg = "#000000", "#003318", "#6FA783", "#00FF66"

local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

local function paint(groups, opts)
  for _, group in ipairs(groups) do
    hi(group, opts)
  end
end

local ink = { fg = fg, bg = bg }
local recede = { fg = dim, bg = bg }
local recede_i = { fg = dim, bg = bg, italic = true }
local strong = { fg = fg, bg = bg, bold = true }
local invert = { fg = bg, bg = fg, bold = true }
local surface = { bg = dark }

-- UI
paint({ "Normal", "NormalFloat", "NormalNC", "MsgArea", "Terminal" }, ink)
paint({ "Cursor", "lCursor", "CursorIM", "TermCursor" }, { fg = bg, bg = fg })
paint({ "CursorLine", "CursorColumn", "ColorColumn" }, surface)
paint({ "Visual", "VisualNOS", "Search", "IncSearch", "CurSearch", "Substitute", "MatchParen" }, invert)

hi("LineNr", recede)
hi("CursorLineNr", strong)
hi("LineNrAbove", recede)
hi("LineNrBelow", recede)
hi("SignColumn", ink)
hi("FoldColumn", recede)
hi("Folded", recede_i)
hi("VertSplit", recede)
hi("WinSeparator", recede)

hi("StatusLine", { fg = fg, bg = dark })
hi("StatusLineNC", { fg = dim, bg = dark })
hi("StatusLineTerm", { fg = fg, bg = dark })
hi("StatusLineTermNC", { fg = dim, bg = dark })
hi("TabLine", recede)
hi("TabLineFill", recede)
hi("TabLineSel", { fg = fg, bg = dark, bold = true })
hi("WinBar", ink)
hi("WinBarNC", recede)

hi("Pmenu", ink)
hi("PmenuSel", invert)
hi("PmenuSbar", surface)
hi("PmenuThumb", { bg = fg })
hi("PmenuKind", recede)
hi("PmenuExtra", recede)
hi("FloatBorder", ink)
hi("FloatTitle", strong)

paint({ "Directory", "Title", "Question", "MoreMsg", "ModeMsg" }, strong)
paint({ "WarningMsg", "ErrorMsg", "Error" }, invert)
paint({ "NonText", "Whitespace", "EndOfBuffer" }, { fg = dark, bg = bg })
hi("SpecialKey", recede)
hi("Conceal", recede)
hi("SpellBad", { undercurl = true, sp = fg })
hi("SpellCap", { underline = true })
hi("SpellLocal", { underline = true })
hi("SpellRare", { underline = true })

-- Syntax: roles differ by weight, not hue
hi("Comment", recede_i)
hi("SpecialComment", recede_i)
paint({ "Constant", "String", "Character", "Number", "Boolean", "Float" }, ink)
hi("Identifier", ink)
hi("Function", strong)
paint({ "Statement", "Conditional", "Repeat", "Label", "Keyword", "Exception" }, strong)
hi("Operator", ink)
hi("PreProc", ink)
paint({ "Include", "Define", "PreCondit" }, strong)
hi("Macro", ink)
paint({ "Type", "StorageClass", "Structure", "Typedef" }, ink)
hi("Special", ink)
hi("SpecialChar", ink)
hi("Tag", strong)
hi("Delimiter", recede)
hi("Debug", ink)
hi("Underlined", { fg = fg, bg = bg, underline = true })
hi("Ignore", recede)
hi("Todo", invert)

-- Diagnostics: reverse for error, underline for the rest
hi("DiagnosticError", invert)
hi("DiagnosticWarn", strong)
hi("DiagnosticInfo", ink)
hi("DiagnosticHint", recede)
hi("DiagnosticOk", ink)
hi("DiagnosticUnderlineError", { undercurl = true, sp = fg })
hi("DiagnosticUnderlineWarn", { underline = true })
hi("DiagnosticUnderlineInfo", { underline = true })
hi("DiagnosticUnderlineHint", { underline = true, sp = dim })
hi("DiagnosticVirtualTextError", recede)
hi("DiagnosticVirtualTextWarn", recede)
hi("DiagnosticVirtualTextInfo", recede)
hi("DiagnosticVirtualTextHint", recede)
hi("DiagnosticUnnecessary", recede)
hi("DiagnosticDeprecated", { fg = dim, bg = bg, strikethrough = true })

-- Diff / git: add = ink, delete = reverse, change = surface
hi("DiffAdd", { fg = fg, bg = dark })
hi("DiffChange", surface)
hi("DiffDelete", invert)
hi("DiffText", invert)
hi("Added", ink)
hi("Changed", ink)
hi("Removed", recede)
hi("GitSignsAdd", ink)
hi("GitSignsChange", recede)
hi("GitSignsDelete", recede)

hi("LspReferenceText", surface)
hi("LspReferenceRead", surface)
hi("LspReferenceWrite", { bg = dark, bold = true })
hi("LspInlayHint", recede_i)
hi("LspSignatureActiveParameter", strong)
hi("LspCodeLens", recede_i)

-- Treesitter + LSP tokens: collapse onto the syntax groups
local links = {
  ["@comment"] = "Comment",
  ["@comment.documentation"] = "Comment",
  ["@comment.error"] = "Error",
  ["@comment.warning"] = "WarningMsg",
  ["@comment.todo"] = "Todo",
  ["@comment.note"] = "Comment",
  ["@string"] = "String",
  ["@string.documentation"] = "String",
  ["@string.escape"] = "SpecialChar",
  ["@string.regexp"] = "String",
  ["@string.special"] = "Special",
  ["@character"] = "Character",
  ["@boolean"] = "Boolean",
  ["@number"] = "Number",
  ["@number.float"] = "Float",
  ["@variable"] = "Identifier",
  ["@variable.builtin"] = "Identifier",
  ["@variable.parameter"] = "Identifier",
  ["@variable.member"] = "Identifier",
  ["@constant"] = "Constant",
  ["@constant.builtin"] = "Constant",
  ["@constant.macro"] = "Macro",
  ["@module"] = "Type",
  ["@label"] = "Label",
  ["@function"] = "Function",
  ["@function.builtin"] = "Function",
  ["@function.call"] = "Function",
  ["@function.macro"] = "Macro",
  ["@function.method"] = "Function",
  ["@function.method.call"] = "Function",
  ["@constructor"] = "Type",
  ["@type"] = "Type",
  ["@type.builtin"] = "Type",
  ["@type.definition"] = "Type",
  ["@attribute"] = "PreProc",
  ["@property"] = "Identifier",
  ["@keyword"] = "Keyword",
  ["@keyword.coroutine"] = "Keyword",
  ["@keyword.function"] = "Keyword",
  ["@keyword.operator"] = "Keyword",
  ["@keyword.import"] = "Include",
  ["@keyword.type"] = "Type",
  ["@keyword.modifier"] = "Keyword",
  ["@keyword.repeat"] = "Repeat",
  ["@keyword.return"] = "Keyword",
  ["@keyword.debug"] = "Debug",
  ["@keyword.exception"] = "Exception",
  ["@keyword.conditional"] = "Conditional",
  ["@keyword.conditional.ternary"] = "Operator",
  ["@keyword.directive"] = "PreProc",
  ["@keyword.directive.define"] = "Define",
  ["@operator"] = "Operator",
  ["@punctuation.delimiter"] = "Delimiter",
  ["@punctuation.bracket"] = "Delimiter",
  ["@punctuation.special"] = "Delimiter",
  ["@markup.strong"] = "Title",
  ["@markup.italic"] = "Comment",
  ["@markup.heading"] = "Title",
  ["@markup.heading.1"] = "Title",
  ["@markup.heading.2"] = "Title",
  ["@markup.heading.3"] = "Title",
  ["@markup.quote"] = "Comment",
  ["@markup.math"] = "Constant",
  ["@markup.link"] = "Underlined",
  ["@markup.link.label"] = "Underlined",
  ["@markup.link.url"] = "Underlined",
  ["@markup.raw"] = "String",
  ["@markup.raw.block"] = "String",
  ["@markup.list"] = "Keyword",
  ["@markup.list.checked"] = "Identifier",
  ["@markup.list.unchecked"] = "Comment",
  ["@tag"] = "Tag",
  ["@tag.builtin"] = "Tag",
  ["@tag.attribute"] = "Identifier",
  ["@tag.delimiter"] = "Delimiter",
  ["@diff.plus"] = "Added",
  ["@diff.minus"] = "Removed",
  ["@diff.delta"] = "Changed",
  ["@lsp.type.class"] = "@type",
  ["@lsp.type.comment"] = "@comment",
  ["@lsp.type.decorator"] = "@attribute",
  ["@lsp.type.enum"] = "@type",
  ["@lsp.type.enumMember"] = "@constant",
  ["@lsp.type.event"] = "@function",
  ["@lsp.type.function"] = "@function",
  ["@lsp.type.interface"] = "@type",
  ["@lsp.type.keyword"] = "@keyword",
  ["@lsp.type.macro"] = "@function.macro",
  ["@lsp.type.method"] = "@function.method",
  ["@lsp.type.modifier"] = "@keyword.modifier",
  ["@lsp.type.namespace"] = "@module",
  ["@lsp.type.number"] = "@number",
  ["@lsp.type.operator"] = "@operator",
  ["@lsp.type.parameter"] = "@variable.parameter",
  ["@lsp.type.property"] = "@property",
  ["@lsp.type.regexp"] = "@string.regexp",
  ["@lsp.type.string"] = "@string",
  ["@lsp.type.struct"] = "@type",
  ["@lsp.type.type"] = "@type",
  ["@lsp.type.typeParameter"] = "@type.definition",
  ["@lsp.type.variable"] = "@variable",
  ["@lsp.typemod.function.defaultLibrary"] = "@function.builtin",
  ["@lsp.typemod.variable.defaultLibrary"] = "@variable.builtin",
  ["@lsp.typemod.variable.readonly"] = "@constant",
}
for from, to in pairs(links) do
  hi(from, { link = to })
end
hi("@markup.strikethrough", { fg = dim, bg = bg, strikethrough = true })
hi("@string.special.url", { fg = fg, bg = bg, underline = true })

-- Completion / pickers / trees: names stay ink so they never inherit NonText
paint({ "CmpItemAbbr", "CmpItemKind", "BlinkCmpLabel", "BlinkCmpKind" }, ink)
paint({ "CmpItemAbbrMatch", "CmpItemAbbrMatchFuzzy", "BlinkCmpLabelMatch" }, strong)
paint({ "CmpItemMenu", "CmpItemKindText", "BlinkCmpSource" }, recede)
hi("BlinkCmpDoc", ink)
hi("BlinkCmpDocBorder", ink)
hi("BlinkCmpMenuSelection", invert)

hi("TelescopeNormal", ink)
hi("TelescopeBorder", ink)
hi("TelescopePromptNormal", ink)
hi("TelescopePromptBorder", ink)
hi("TelescopePromptTitle", { fg = fg, bg = dark, bold = true })
hi("TelescopeResultsTitle", { fg = fg, bg = dark, bold = true })
hi("TelescopePreviewTitle", { fg = fg, bg = dark, bold = true })
hi("TelescopeSelection", invert)
hi("TelescopeMatching", strong)

hi("IblIndent", { fg = dark, bg = bg })
hi("IblScope", recede)
hi("SnacksIndent", { fg = dark, bg = bg })
hi("SnacksIndentScope", recede)

paint({ "SnacksPickerFile", "SnacksPickerDirectory", "MiniFilesFile", "MiniFilesDirectory" }, ink)
hi("SnacksPickerDirectory", strong)
hi("MiniFilesDirectory", strong)
paint({ "SnacksPickerDir", "SnacksPickerPathHidden", "SnacksPickerPathIgnored" }, recede)
hi("SnacksPickerTree", recede)
hi("SnacksPickerLink", { fg = fg, bg = bg, italic = true })
paint({
  "SnacksPickerGitStatus",
  "SnacksPickerGitStatusAdded",
  "SnacksPickerGitStatusModified",
  "SnacksPickerGitStatusDeleted",
  "SnacksPickerGitStatusRenamed",
  "SnacksPickerGitStatusCopied",
  "SnacksPickerGitStatusUntracked",
  "SnacksPickerGitStatusStaged",
}, ink)
paint({ "SnacksPickerGitStatusIgnored" }, recede)
hi("SnacksPickerGitStatusUnmerged", invert)

hi("NeoTreeNormal", ink)
hi("NeoTreeNormalNC", ink)
hi("NeoTreeFileName", ink)
hi("NeoTreeFileNameOpened", strong)
hi("NeoTreeDirectoryName", strong)
hi("NeoTreeDirectoryIcon", ink)
hi("NeoTreeRootName", strong)
hi("NeoTreeDimText", recede)
hi("NeoTreeDotfile", recede)
hi("NeoTreeGitUntracked", ink)
hi("NeoTreeGitIgnored", recede)
