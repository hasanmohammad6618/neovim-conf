return {
	"chomosuke/typst-preview.nvim",
	lazy = false, -- or ft = 'typst'
	version = "1.*",
	opts = {},
	config = function()
		require("typst-preview").setup({})
	end,
}
