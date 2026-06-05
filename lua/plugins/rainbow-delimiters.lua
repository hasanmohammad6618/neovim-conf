return {
	"HiPhish/rainbow-delimiters.nvim",
	config = function()
		require("rainbow-delimiters.setup").setup({
			strategy = {
				[""] = "rainbow-delimiters.strategy.global",
				commonlisp = "rainbow-delimiters.strategy.local",
			},
			query = {
				[""] = "rainbow-delimiters",
				latex = "rainbow-blocks",
			},
			highlight = {
				"RainbowDelimiterViolet",
				"RainbowDelimiterRed",
				"RainbowDelimiterYellow",
				"RainbowDelimiterBlue",
				"RainbowDelimiterOrange",
				"RainbowDelimiterGreen",
				"RainbowDelimiterCyan",
			},
			blacklist = {},
		})
	end,
}
