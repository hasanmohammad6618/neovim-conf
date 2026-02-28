return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		{ "nvim-tree/nvim-web-devicons" },
	},
	config = function()
		local function lsp_status()
			local clients = vim.lsp.get_clients({ bufnr = 0 })
			if #clients == 0 then
				return ""
			end
			local names = {}
			for _, client in ipairs(clients) do
				table.insert(names, client.name)
			end
			return "LSP: " .. table.concat(names, ", ")
		end

		require("lualine").setup({
			options = {
				icons_enabled = true,
				theme = "auto",
				component_separators = "",
				section_separators = { left = "", right = "" },
				-- disabled_filetypes = {
				--   statusline = {},
				--   winbar = {},
				-- },
				disabled_filetypes = {
					"snacks_dashboard",
				},
				ignore_focus = {},
				always_divide_middle = true,
				always_show_tabline = true,
				globalstatus = true,
				update_in_insert = true,
				refresh = {
					statusline = 50,
					tabline = 100,
					winbar = 100,
				},
			},
			sections = {
				lualine_a = { { "mode", icon = "" } },
				lualine_b = { { "branch", icon = "" }, { "diff", icon = "" } },
				lualine_c = {
					{
						lsp_status,
						icon = "", -- f013
					},
				},
				lualine_x = {
					"diagnostics",
					"filesize",
					"encoding",
					"filetype",
				},
				lualine_y = { "progress" },
				lualine_z = { { "location", icon = "" } },
			},
			inactive_sections = {
				lualine_a = { { "mode", icon = "" } },
				lualine_b = { { "branch", icon = "" }, { "diff", icon = "" } },
				lualine_c = { lsp_status },
				lualine_x = {
					"diagnostics",
					"filesize",
					"encoding",
					"filetype",
				},
				lualine_y = { "progress" },
				lualine_z = { { "location", icon = "" } },
			},
			tabline = {},
			winbar = {},
			inactive_winbar = {},
			extensions = {},
		})
	end,
}
