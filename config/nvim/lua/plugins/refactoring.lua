-- ThePrimeagen refactoring.nvim — Primeagen-style refactor + debug print maps
return {
	"ThePrimeagen/refactoring.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"lewis6991/async.nvim",
	},
	opts = {},
	keys = {
		{
			"<leader>re",
			function()
				return require("refactoring").extract_func()
			end,
			mode = { "n", "x" },
			expr = true,
			desc = "Extract Function",
		},
		{
			"<leader>ree",
			function()
				return require("refactoring").extract_func() .. "_"
			end,
			mode = "n",
			expr = true,
			desc = "Extract Function (line)",
		},
		{
			"<leader>rE",
			function()
				return require("refactoring").extract_func_to_file()
			end,
			mode = { "n", "x" },
			expr = true,
			desc = "Extract Function To File",
		},
		{
			"<leader>rv",
			function()
				return require("refactoring").extract_var()
			end,
			mode = { "n", "x" },
			expr = true,
			desc = "Extract Variable",
		},
		{
			"<leader>rvv",
			function()
				return require("refactoring").extract_var() .. "_"
			end,
			mode = "n",
			expr = true,
			desc = "Extract Variable (line)",
		},
		{
			"<leader>ri",
			function()
				return require("refactoring").inline_var()
			end,
			mode = { "n", "x" },
			expr = true,
			desc = "Inline Variable",
		},
		{
			"<leader>rI",
			function()
				return require("refactoring").inline_func()
			end,
			mode = { "n", "x" },
			expr = true,
			desc = "Inline Function",
		},
		{
			"<leader>rs",
			function()
				require("refactoring").select_refactor()
			end,
			mode = { "n", "x" },
			desc = "Select Refactor",
		},
		-- Debug prints
		{
			"<leader>pv",
			function()
				return require("refactoring.debug").print_var({ output_location = "below" }) .. "iw"
			end,
			mode = "n",
			expr = true,
			desc = "Debug print var below",
		},
		{
			"<leader>pv",
			function()
				return require("refactoring.debug").print_var({ output_location = "below" })
			end,
			mode = "x",
			expr = true,
			desc = "Debug print var below",
		},
		{
			"<leader>pV",
			function()
				return require("refactoring.debug").print_var({ output_location = "above" }) .. "iw"
			end,
			mode = "n",
			expr = true,
			desc = "Debug print var above",
		},
		{
			"<leader>pV",
			function()
				return require("refactoring.debug").print_var({ output_location = "above" })
			end,
			mode = "x",
			expr = true,
			desc = "Debug print var above",
		},
		{
			"<leader>pe",
			function()
				return require("refactoring.debug").print_exp({ output_location = "below" })
			end,
			mode = { "n", "x" },
			expr = true,
			desc = "Debug print exp below",
		},
		{
			"<leader>pE",
			function()
				return require("refactoring.debug").print_exp({ output_location = "above" })
			end,
			mode = { "n", "x" },
			expr = true,
			desc = "Debug print exp above",
		},
		{
			"<leader>pp",
			function()
				return require("refactoring.debug").print_loc({ output_location = "below" })
			end,
			mode = "n",
			expr = true,
			desc = "Debug print location below",
		},
		{
			"<leader>pP",
			function()
				return require("refactoring.debug").print_loc({ output_location = "above" })
			end,
			mode = "n",
			expr = true,
			desc = "Debug print location above",
		},
		{
			"<leader>pc",
			function()
				return require("refactoring.debug").cleanup({ restore_view = true })
			end,
			mode = { "n", "x" },
			expr = true,
			desc = "Debug print cleanup",
		},
	},
}
