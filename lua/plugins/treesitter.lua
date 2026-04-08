return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		local parsers = {
			"lua",
			"rust",
			"c",
			"cpp",
			"html",
			"css",
			"javascript",
			"typescript",
			"tsx",
			"jsx",
			"json",
			"jsdoc",
			"json5",
			"python",
			"markdown",
			"markdown_inline",
			"toml",
			"java",
			"typst",
			"yaml",
		}

		local ins_parser = require("nvim-treesitter.config").get_installed("parsers")

		local parsers_to_ins = {}

		for _, p in ipairs(parsers) do
			if not ins_parser[p] then
				table.insert(parsers_to_ins, p)
			end
		end
		local ms = require("mason-registry")
		ms.refresh(function()
			if ms.is_installed("tree-sitter-cli") then
				require("nvim-treesitter").install(parsers_to_ins)
			end
		end)

		vim.api.nvim_create_autocmd("FileType", {
			pattern = parsers,
			callback = function(arg)
				vim.treesitter.start(arg.buf)
			end,
		})
	end,
}
