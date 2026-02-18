return {
	"rachartier/tiny-devicons-auto-colors.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("tiny-devicons-auto-colors").setup({
			autoreload = true,
		})
	end,
}
