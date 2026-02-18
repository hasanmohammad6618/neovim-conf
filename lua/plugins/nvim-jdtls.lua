return {
	"mfussenegger/nvim-jdtls",
	config = function()
		vim.lsp.config("jdtls", {
			handlers = {
				--- filter noisy notifications
				--- @param err lsp.ResponseError error
				--- @param result lsp.ProgressParams progress message
				--- @param ctx lsp.HandlerContext context
				["$/progress"] = function(err, result, ctx)
					local msg = result.value and result.value["message"]
					if msg and vim.startswith(msg, "Validate documents") then
						return
					end
					if msg and vim.startswith(msg, "Publish Diagnostics") then
						return
					end
					-- pass through to normal handler
					vim.lsp.handlers["$/progress"](err, result, ctx)
				end,
			},
			["jdtls"] = {
				settings = {
					initializationOptions = {
						settings = {
							java = {},
						},
					},
				},
			},
		})
	end,
}
