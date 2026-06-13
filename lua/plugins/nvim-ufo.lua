return {
	"kevinhwang91/nvim-ufo",
	dependencies = "kevinhwang91/promise-async",
	config = function()
		vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
		vim.o.foldlevelstart = 99
		vim.o.foldenable = true
		require("ufo").setup({
			preview = {},
			close_fold_kinds_for_ft = {},
			enable_get_fold_virt_text = true,
			provider_selector = function(bufnr, filetype, _)
				if filetype == "snacks_dashboard" then
					require("ufo").detach(bufnr)
				else
					if filetype == "NvimTree" then
						vim.wo.statuscolumn = ""
					end
				end
			end,
		})
	end,
}
