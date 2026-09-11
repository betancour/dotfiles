-- Green Phosphor — Neovim colorscheme
-- Overlay: config/nvim/colors/green-phosphor.lua
--
-- Color model (Itten + Hering opponent process, Oklch):
--   Light-dark   comments recede, keywords are the brightest phosphor
--   Warm-cool    literals (lime/amber) vs callables (cyan)
--   Saturation   types are icy/pale; strings and idents stay vivid
--   Complement   red is reserved for errors (true opposite of green)
--
-- Syntax hues are spaced ~40°+ in Oklch so roles stay distinct on black.
-- Statusline is a single-hue phosphor strip — no mode/git/diagnostic paint.
-- eza theme.yml uses these same hex values for folders, icons, and types.

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end

vim.o.background = "dark"
vim.g.colors_name = "green-phosphor"

local c = {
  black = "#000000",
  dark = "#003318",
  gray_green = "#005522",

  -- Phosphor scale (hue ~155°, luminance steps)
  dim = "#6FA783", -- comments / inactive (~7.5:1)
  green = "#00FF66", -- identifiers / primary (~15.5:1)
  bright = "#B5FFCE", -- keywords / near-white phosphor (~18:1)
  white = "#DEFAE6",

  -- Buffer alerts only (not used in the statusline)
  yellow = "#F9D544",
  red = "#FF3B3B",

  -- Syntax
  comment = "#6FA783", -- desaturated green
  keyword = "#B5FFCE", -- light-dark contrast vs ident
  func = "#1BE5EE", -- cool pole (cyan)
  type = "#B2E2E4", -- icy, low chroma
  str = "#C8F23C", -- warm lime
  const = "#F9D544", -- warm amber (yellow pole)
  punct = "#438C60", -- quieter than names
  param = "#5DEBBC", -- mint, between ident and func
  operator = "#94C5A4", -- mid luminance, low chroma
}

local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- ============================================================================
-- UI
-- ============================================================================

hi("Normal", { fg = c.green, bg = c.black })
hi("NormalFloat", { fg = c.green, bg = c.black })
hi("NormalNC", { fg = c.green, bg = c.black })

hi("Cursor", { fg = c.black, bg = c.green })
hi("lCursor", { fg = c.black, bg = c.green })
hi("CursorIM", { fg = c.black, bg = c.green })
hi("TermCursor", { fg = c.black, bg = c.green })

hi("CursorLine", { bg = c.dark })
hi("CursorColumn", { bg = c.dark })
hi("ColorColumn", { bg = c.dark })

hi("Visual", { fg = c.black, bg = c.green })
hi("VisualNOS", { fg = c.black, bg = c.green })

hi("LineNr", { fg = c.punct, bg = c.black })
hi("CursorLineNr", { fg = c.green, bg = c.black, bold = true })
hi("LineNrAbove", { fg = c.punct, bg = c.black })
hi("LineNrBelow", { fg = c.punct, bg = c.black })

hi("SignColumn", { fg = c.green, bg = c.black })
hi("FoldColumn", { fg = c.punct, bg = c.black })

hi("VertSplit", { fg = c.punct, bg = c.black })
hi("WinSeparator", { fg = c.punct, bg = c.black })

-- Statusline: one hue, luminance only. Plugin theme matches this.
hi("StatusLine", { fg = c.green, bg = c.dark })
hi("StatusLineNC", { fg = c.dim, bg = c.dark })
hi("StatusLineTerm", { fg = c.green, bg = c.dark })
hi("StatusLineTermNC", { fg = c.dim, bg = c.dark })

hi("TabLine", { fg = c.dim, bg = c.black })
hi("TabLineFill", { fg = c.dim, bg = c.black })
hi("TabLineSel", { fg = c.green, bg = c.dark, bold = true })

hi("WinBar", { fg = c.green, bg = c.black })
hi("WinBarNC", { fg = c.dim, bg = c.black })

hi("Pmenu", { fg = c.green, bg = c.black })
hi("PmenuSel", { fg = c.black, bg = c.green, bold = true })
hi("PmenuSbar", { bg = c.dark })
hi("PmenuThumb", { bg = c.green })
hi("PmenuKind", { fg = c.func })
hi("PmenuExtra", { fg = c.dim })

hi("FloatBorder", { fg = c.green, bg = c.black })
hi("FloatTitle", { fg = c.green, bg = c.black, bold = true })

hi("Search", { fg = c.black, bg = c.green, bold = true })
hi("IncSearch", { fg = c.black, bg = c.bright, bold = true })
hi("CurSearch", { fg = c.black, bg = c.bright, bold = true })
hi("Substitute", { fg = c.black, bg = c.green, bold = true })

hi("MatchParen", { fg = c.black, bg = c.green, bold = true })

hi("Folded", { fg = c.dim, bg = c.black })

hi("Directory", { fg = c.keyword, bold = true })
hi("Title", { fg = c.bright, bold = true })

hi("Question", { fg = c.green, bold = true })
hi("MoreMsg", { fg = c.green })
hi("ModeMsg", { fg = c.green, bold = true })
hi("WarningMsg", { fg = c.yellow, bold = true })
hi("ErrorMsg", { fg = c.red, bold = true })

hi("NonText", { fg = c.dark })
hi("Whitespace", { fg = c.dark })
hi("SpecialKey", { fg = c.punct })
hi("EndOfBuffer", { fg = c.dark })
hi("Conceal", { fg = c.punct })

hi("SpellBad", { undercurl = true, sp = c.red })
hi("SpellCap", { undercurl = true, sp = c.yellow })
hi("SpellLocal", { undercurl = true, sp = c.func })
hi("SpellRare", { undercurl = true, sp = c.const })

-- ============================================================================
-- Syntax
-- ============================================================================

hi("Comment", { fg = c.comment, italic = true })

hi("Constant", { fg = c.const })
hi("String", { fg = c.str })
hi("Character", { fg = c.str })
hi("Number", { fg = c.const })
hi("Boolean", { fg = c.const, bold = true })
hi("Float", { fg = c.const })

hi("Identifier", { fg = c.green })
hi("Function", { fg = c.func, bold = true })

hi("Statement", { fg = c.keyword, bold = true })
hi("Conditional", { fg = c.keyword, bold = true })
hi("Repeat", { fg = c.keyword, bold = true })
hi("Label", { fg = c.keyword })
hi("Operator", { fg = c.operator })
hi("Keyword", { fg = c.keyword, bold = true })
hi("Exception", { fg = c.keyword, bold = true })

hi("PreProc", { fg = c.func })
hi("Include", { fg = c.keyword, bold = true })
hi("Define", { fg = c.keyword, bold = true })
hi("Macro", { fg = c.func })
hi("PreCondit", { fg = c.keyword, bold = true })

hi("Type", { fg = c.type })
hi("StorageClass", { fg = c.keyword, bold = true })
hi("Structure", { fg = c.type })
hi("Typedef", { fg = c.type })

hi("Special", { fg = c.const })
hi("SpecialChar", { fg = c.const })
hi("Tag", { fg = c.func, bold = true })
hi("Delimiter", { fg = c.punct })
hi("SpecialComment", { fg = c.dim, italic = true })
hi("Debug", { fg = c.yellow })

hi("Underlined", { fg = c.func, underline = true })
hi("Ignore", { fg = c.dim })
hi("Error", { fg = c.red, bold = true })
hi("Todo", { fg = c.black, bg = c.const, bold = true })

-- ============================================================================
-- Diagnostics (buffer — statusline stays phosphor-only)
-- ============================================================================

hi("DiagnosticError", { fg = c.red })
hi("DiagnosticWarn", { fg = c.yellow })
hi("DiagnosticInfo", { fg = c.func })
hi("DiagnosticHint", { fg = c.dim })
hi("DiagnosticOk", { fg = c.green })

hi("DiagnosticUnderlineError", { undercurl = true, sp = c.red })
hi("DiagnosticUnderlineWarn", { undercurl = true, sp = c.yellow })
hi("DiagnosticUnderlineInfo", { undercurl = true, sp = c.func })
hi("DiagnosticUnderlineHint", { undercurl = true, sp = c.dim })

hi("DiagnosticVirtualTextError", { fg = c.red })
hi("DiagnosticVirtualTextWarn", { fg = c.yellow })
hi("DiagnosticVirtualTextInfo", { fg = c.func })
hi("DiagnosticVirtualTextHint", { fg = c.dim })

hi("DiagnosticUnnecessary", { fg = c.dim })
hi("DiagnosticDeprecated", { fg = c.dim, strikethrough = true })

-- ============================================================================
-- Diff
-- ============================================================================

hi("DiffAdd", { fg = c.green, bg = c.dark })
hi("DiffChange", { fg = c.const, bg = c.dark })
hi("DiffDelete", { fg = c.red, bg = c.black })
hi("DiffText", { fg = c.black, bg = c.green, bold = true })

hi("Added", { fg = c.green })
hi("Changed", { fg = c.const })
hi("Removed", { fg = c.red })

-- ============================================================================
-- Git signs
-- ============================================================================

hi("GitSignsAdd", { fg = c.green, bg = c.black })
hi("GitSignsChange", { fg = c.const, bg = c.black })
hi("GitSignsDelete", { fg = c.red, bg = c.black })

-- ============================================================================
-- LSP
-- ============================================================================

hi("LspReferenceText", { bg = c.dark })
hi("LspReferenceRead", { bg = c.dark })
hi("LspReferenceWrite", { bg = c.gray_green })
hi("LspInlayHint", { fg = c.dim, italic = true })
hi("LspSignatureActiveParameter", { fg = c.const, bold = true })
hi("LspCodeLens", { fg = c.dim, italic = true })

-- ============================================================================
-- Telescope
-- ============================================================================

hi("TelescopeNormal", { fg = c.green, bg = c.black })
hi("TelescopeBorder", { fg = c.green, bg = c.black })
hi("TelescopePromptNormal", { fg = c.green, bg = c.black })
hi("TelescopePromptBorder", { fg = c.green, bg = c.black })
hi("TelescopePromptTitle", { fg = c.green, bg = c.dark, bold = true })
hi("TelescopeResultsTitle", { fg = c.green, bg = c.dark, bold = true })
hi("TelescopePreviewTitle", { fg = c.green, bg = c.dark, bold = true })
hi("TelescopeSelection", { fg = c.black, bg = c.green, bold = true })
hi("TelescopeMatching", { fg = c.str, bold = true })

-- ============================================================================
-- Treesitter
-- ============================================================================

hi("@comment", { link = "Comment" })
hi("@comment.documentation", { fg = c.dim, italic = true })
hi("@comment.error", { fg = c.red, italic = true, bold = true })
hi("@comment.warning", { fg = c.yellow, italic = true, bold = true })
hi("@comment.todo", { fg = c.black, bg = c.const, bold = true })
hi("@comment.note", { fg = c.func, italic = true, bold = true })

hi("@string", { link = "String" })
hi("@string.documentation", { fg = c.str, italic = true })
hi("@string.escape", { fg = c.const, bold = true })
hi("@string.regexp", { fg = c.const })
hi("@string.special", { fg = c.const })
hi("@string.special.url", { fg = c.func, underline = true })
hi("@character", { link = "Character" })
hi("@character.special", { fg = c.const })
hi("@boolean", { link = "Boolean" })
hi("@number", { link = "Number" })
hi("@number.float", { link = "Float" })

hi("@variable", { fg = c.green })
hi("@variable.builtin", { fg = c.func, italic = true })
hi("@variable.parameter", { fg = c.param })
hi("@variable.parameter.builtin", { fg = c.param, italic = true })
hi("@variable.member", { fg = c.green })
hi("@constant", { link = "Constant" })
hi("@constant.builtin", { fg = c.const, bold = true })
hi("@constant.macro", { fg = c.func })
hi("@module", { fg = c.type })
hi("@module.builtin", { fg = c.type, italic = true })
hi("@label", { link = "Label" })

hi("@function", { link = "Function" })
hi("@function.builtin", { fg = c.func, bold = true, italic = true })
hi("@function.call", { fg = c.func })
hi("@function.macro", { fg = c.func, italic = true })
hi("@function.method", { fg = c.func, bold = true })
hi("@function.method.call", { fg = c.func })
hi("@constructor", { fg = c.type, bold = true })

hi("@type", { link = "Type" })
hi("@type.builtin", { fg = c.type, italic = true })
hi("@type.definition", { fg = c.type, bold = true })
hi("@attribute", { fg = c.const })
hi("@attribute.builtin", { fg = c.const, italic = true })
hi("@property", { fg = c.green })

hi("@keyword", { link = "Keyword" })
hi("@keyword.coroutine", { link = "Keyword" })
hi("@keyword.function", { link = "Keyword" })
hi("@keyword.operator", { fg = c.keyword, bold = true })
hi("@keyword.import", { link = "Include" })
hi("@keyword.type", { fg = c.type, bold = true })
hi("@keyword.modifier", { link = "Keyword" })
hi("@keyword.repeat", { link = "Repeat" })
hi("@keyword.return", { link = "Keyword" })
hi("@keyword.debug", { fg = c.yellow, bold = true })
hi("@keyword.exception", { link = "Exception" })
hi("@keyword.conditional", { link = "Conditional" })
hi("@keyword.conditional.ternary", { fg = c.operator })
hi("@keyword.directive", { link = "PreProc" })
hi("@keyword.directive.define", { link = "Define" })
hi("@operator", { link = "Operator" })

hi("@punctuation.delimiter", { fg = c.punct })
hi("@punctuation.bracket", { fg = c.punct })
hi("@punctuation.special", { fg = c.operator })

hi("@markup.strong", { fg = c.white, bold = true })
hi("@markup.italic", { fg = c.green, italic = true })
hi("@markup.strikethrough", { fg = c.dim, strikethrough = true })
hi("@markup.underline", { underline = true })
hi("@markup.heading", { fg = c.bright, bold = true })
hi("@markup.heading.1", { fg = c.bright, bold = true })
hi("@markup.heading.2", { fg = c.func, bold = true })
hi("@markup.heading.3", { fg = c.keyword, bold = true })
hi("@markup.quote", { fg = c.comment, italic = true })
hi("@markup.math", { fg = c.const })
hi("@markup.link", { fg = c.func, underline = true })
hi("@markup.link.label", { fg = c.func })
hi("@markup.link.url", { fg = c.dim, underline = true })
hi("@markup.raw", { fg = c.str })
hi("@markup.raw.block", { fg = c.str })
hi("@markup.list", { fg = c.keyword })
hi("@markup.list.checked", { fg = c.green })
hi("@markup.list.unchecked", { fg = c.dim })

hi("@tag", { fg = c.func, bold = true })
hi("@tag.builtin", { fg = c.func, bold = true })
hi("@tag.attribute", { fg = c.type })
hi("@tag.delimiter", { fg = c.punct })

hi("@diff.plus", { fg = c.green })
hi("@diff.minus", { fg = c.red })
hi("@diff.delta", { fg = c.const })

-- ============================================================================
-- LSP semantic tokens
-- ============================================================================

hi("@lsp.type.class", { link = "@type" })
hi("@lsp.type.comment", { link = "@comment" })
hi("@lsp.type.decorator", { link = "@attribute" })
hi("@lsp.type.enum", { link = "@type" })
hi("@lsp.type.enumMember", { link = "@constant" })
hi("@lsp.type.event", { link = "@function" })
hi("@lsp.type.function", { link = "@function" })
hi("@lsp.type.interface", { link = "@type" })
hi("@lsp.type.keyword", { link = "@keyword" })
hi("@lsp.type.macro", { link = "@function.macro" })
hi("@lsp.type.method", { link = "@function.method" })
hi("@lsp.type.modifier", { link = "@keyword.modifier" })
hi("@lsp.type.namespace", { link = "@module" })
hi("@lsp.type.number", { link = "@number" })
hi("@lsp.type.operator", { link = "@operator" })
hi("@lsp.type.parameter", { link = "@variable.parameter" })
hi("@lsp.type.property", { link = "@property" })
hi("@lsp.type.regexp", { link = "@string.regexp" })
hi("@lsp.type.string", { link = "@string" })
hi("@lsp.type.struct", { link = "@type" })
hi("@lsp.type.type", { link = "@type" })
hi("@lsp.type.typeParameter", { link = "@type.definition" })
hi("@lsp.type.variable", { link = "@variable" })
hi("@lsp.typemod.function.defaultLibrary", { link = "@function.builtin" })
hi("@lsp.typemod.variable.defaultLibrary", { link = "@variable.builtin" })
hi("@lsp.typemod.variable.readonly", { link = "@constant" })

-- ============================================================================
-- Completion
-- ============================================================================

hi("CmpItemAbbr", { fg = c.green })
hi("CmpItemAbbrMatch", { fg = c.str, bold = true })
hi("CmpItemAbbrMatchFuzzy", { fg = c.str })
hi("CmpItemMenu", { fg = c.dim })
hi("CmpItemKind", { fg = c.func })
hi("CmpItemKindFunction", { fg = c.func })
hi("CmpItemKindMethod", { fg = c.func })
hi("CmpItemKindVariable", { fg = c.green })
hi("CmpItemKindKeyword", { fg = c.keyword })
hi("CmpItemKindSnippet", { fg = c.const })
hi("CmpItemKindClass", { fg = c.type })
hi("CmpItemKindModule", { fg = c.type })
hi("CmpItemKindText", { fg = c.dim })

hi("BlinkCmpLabel", { fg = c.green })
hi("BlinkCmpLabelMatch", { fg = c.str, bold = true })
hi("BlinkCmpKind", { fg = c.func })
hi("BlinkCmpSource", { fg = c.dim })
hi("BlinkCmpDoc", { fg = c.green, bg = c.black })
hi("BlinkCmpDocBorder", { fg = c.green, bg = c.black })
hi("BlinkCmpMenuSelection", { fg = c.black, bg = c.green, bold = true })

-- ============================================================================
-- Indent guides
-- ============================================================================

hi("IblIndent", { fg = c.dark })
hi("IblScope", { fg = c.punct })
hi("SnacksIndent", { fg = c.dark })
hi("SnacksIndentScope", { fg = c.punct })

-- ============================================================================
-- File tree (Snacks explorer — names must not inherit NonText)
-- ============================================================================
-- Snacks defaults PathHidden / PathIgnored / GitStatusUntracked / Dir to
-- NonText. That group is the CRT-black gutter color, so filenames vanish.

hi("SnacksPickerFile", { fg = c.green })
hi("SnacksPickerDirectory", { fg = c.keyword, bold = true })
hi("SnacksPickerDir", { fg = c.dim })
hi("SnacksPickerPathHidden", { fg = c.dim })
hi("SnacksPickerPathIgnored", { fg = c.dim })
hi("SnacksPickerTree", { fg = c.punct })
hi("SnacksPickerLink", { fg = c.func, italic = true })

hi("SnacksPickerGitStatus", { fg = c.const })
hi("SnacksPickerGitStatusAdded", { fg = c.green })
hi("SnacksPickerGitStatusModified", { fg = c.const })
hi("SnacksPickerGitStatusDeleted", { fg = c.red })
hi("SnacksPickerGitStatusRenamed", { fg = c.func })
hi("SnacksPickerGitStatusCopied", { fg = c.func })
hi("SnacksPickerGitStatusUntracked", { fg = c.green })
hi("SnacksPickerGitStatusIgnored", { fg = c.dim })
hi("SnacksPickerGitStatusUnmerged", { fg = c.red })
hi("SnacksPickerGitStatusStaged", { fg = c.bright })

hi("NeoTreeNormal", { fg = c.green, bg = c.black })
hi("NeoTreeNormalNC", { fg = c.green, bg = c.black })
hi("NeoTreeFileName", { fg = c.green })
hi("NeoTreeFileNameOpened", { fg = c.bright, bold = true })
hi("NeoTreeDirectoryName", { fg = c.keyword, bold = true })
hi("NeoTreeDirectoryIcon", { fg = c.keyword })
hi("NeoTreeRootName", { fg = c.bright, bold = true })
hi("NeoTreeDimText", { fg = c.dim })
hi("NeoTreeDotfile", { fg = c.dim })
hi("NeoTreeGitUntracked", { fg = c.green })
hi("NeoTreeGitIgnored", { fg = c.dim })

hi("MiniFilesFile", { fg = c.green })
hi("MiniFilesDirectory", { fg = c.keyword, bold = true })

vim.opt.termguicolors = true
