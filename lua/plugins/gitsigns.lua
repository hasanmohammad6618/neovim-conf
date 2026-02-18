return {
	"lewis6991/gitsigns.nvim",
	config = function()
		require("gitsigns").setup({
			attach_to_untracked = true,
			current_line_blame = true,
			numhl = true,
			current_line_blame_opts = {
				virt_text = true,
				virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
				delay = 100,
				ignore_whitespace = false,
				virt_text_priority = 100,
				use_focus = true,
			},
			signs = {
				add = { text = "⎥" },
				change = { text = "⎥" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
				untracked = { text = "⎥" },
			},
		})
	end,
}
