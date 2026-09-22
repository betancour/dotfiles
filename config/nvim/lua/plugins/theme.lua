return {
	{
		"folke/tokyonight.nvim",
		name = "tokyonight",
		priority = 1000,
		opts = {
			style = "night",
			background = {
				dark = "night",
				light = "day",
			},
			transparent_background = false,
			term_colors = true,
			integrations = {
				cmp = true,
				gitsigns = true,
				neotree = true,
				notify = true,
				treesitter = true,
				which_key = true,
			},
		},
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "tokyonight-night",
		},
	},
}
