return {
	{
		"romgrk/barbar.nvim",
		dependencies = {
			"lewis6991/gitsigns.nvim", -- OPTIONAL: for git status
			"nvim-tree/nvim-web-devicons", -- OPTIONAL: for file icons
		},
		init = function()
			vim.g.barbar_auto_setup = false
		end,
		opts = {
			-- lazy.nvim will automatically call setup for you. put your options here, anything missing will use the default:
			-- animation = true,
			insert_at_start = true,
		},
		version = "^1.0.0", -- optional: only update when a new 1.x version is released
		config = function()
			require("barbar").setup({
				maximum_padding = 1,
				icons = {
					separator = { left = "", right = "" },
					separator_at_end = false,
					inactive = {
						separator = { left = "" },
					},
				},
				sidebar_filetypes = {
					-- Use the default values: {event = 'BufWinLeave', text = '', align = 'left'}
					NvimTree = { event = "BufWinLeave", text = "File Explorer", align = "center" },
					-- Or, specify the text used for the offset:
					undotree = {
						text = "undotree",
						align = "center", -- *optionally* specify an alignment (either 'left', 'center', or 'right')
					},
					snacks_picker_list = { event = "BufWipeout", text = "File Explorer", align = "center" },
					-- Or, specify the event which the sidebar executes when leaving:
					["neo-tree"] = { event = "BufWipeout", text = "File Explorer", align = "center" },
					-- Or, specify all three
					Outline = { event = "BufWinLeave", text = "symbols-outline", align = "right" },
				},
			})
		end,
	},
}
