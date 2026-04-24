return {
	"stevearc/conform.nvim",
	opts = {},
	config = function()
		require("conform").setup({
			format_after_save = {
				lsp_format = "fallback",
				async = true,
			},
			formatters = {
				csskit = {
					command = "csskit",
					args = { "fmt", "$FILENAME" },
				},
			},
			formatters_by_ft = {
				css = { "csskit" },
				cpp = { "clang-format" },
				lua = { "stylua" },
				python = { "ruff_format" },
				-- Conform will run multiple formatters sequentially
				-- python = { "isort", "black" },
				-- You can customize some of the format options for the filetype (:help conform.format)
				rust = { "rustfmt" },
				-- Conform will run the first available formatter
				-- javascript = { "prettierd", "prettier", stop_after_first = true },
				typst = { "typstyle" },
			},
		})
	end,
}
