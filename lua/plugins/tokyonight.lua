return {
	"folke/tokyonight.nvim",
	lazy = false,
	priority = 1000,
	opts = {},
	config = function()
		require("tokyonight").setup({
			style = "night",
			light_style = "day",
			cache = true,
			day_brightness = 0.3,
			styles = {
				comments = { italic = false },
				keywords = { italic = false },
				functions = {},
				variables = {},
			},
			plugins = {
				all = true,
				auto = true,
			},
			transparent = false,
			dim_inactive = false,
			lualine_bold = false,
			terminal_colors = true,
			on_colors = function(colors)
				colors.error = colors.red
				colors.warning = colors.yellow
				colors.info = colors.blue
				colors.hint = colors.green1
				colors.green = "#A7E399"
			end,
			on_highlights = function(highlights, colors)
				highlights.NvimTreeWinSeparator = {
					bg = colors.bg,
					fg = colors.bg,
				}
				highlights.NvimTreeModifiedIcon = {
					fg = colors.warning,
					link = 0,
					global_link = 0,
				}

				highlights.DiagnosticUnderlineError.undercurl = nil
				highlights.DiagnosticUnderlineError.underdashed = true

				highlights.DiagnosticUnderlineWarn.undercurl = nil
				highlights.DiagnosticUnderlineWarn.underdashed = true

				highlights.DiagnosticUnderlineInfo.undercurl = nil
				highlights.DiagnosticUnderlineInfo.underdashed = true

				highlights.DiagnosticUnderlineHint.undercurl = nil
				highlights.DiagnosticUnderlineHint.underdashed = true

				highlights["@lsp.type.unresolvedReference"].undercurl = nil
				highlights["@lsp.type.unresolvedReference"].underdashed = true

				highlights.BlinkCmpKindFile = {
					bg = "NONE",
					link = 0,
					global_link = 0,
				}

				highlights.LazyButtonActive = {
					bg = "#1A3A4E",
				}

				highlights.NvimTreeIndentMarker = {
					fg = colors.comment,
				}

				highlights["SnacksWinSeparator"] = {
					fg = colors.bg,
				}

				highlights["LspReferenceText"] = {
					bg = colors.bg_highlight,
				}

				highlights["@lsp.type.selfTypeKeyword"] = {
					fg = "#FF8996",
					link = nil,
				}

				highlights.PreProc = {
					fg = "#56c2d6",
				}

				highlights["@keyword.import"] = {
					fg = "#bb9af7",
				}

				highlights["@lsp.type.variable"] = {
					fg = colors.fg,
				}

				highlights["@type.builtin"] = {
					fg = "#56c2d6",
				}

				highlights.Special = {
					fg = "#6cd0c8",
				}

				highlights.BlinkCmpLabelDescription = {
					fg = colors.comment,
				}

				highlights["@lsp.type.method"] = {
					fg = "#90B8F8",
				}

				highlights["@lsp.typemod.class.defaultLibrary"] = {
					fg = "#FFE194",
				}

				highlights["@lsp.typemod.variable.mutable.rust"] = {
					underline = true,
					fg = "#CCDCFB",
				}

				highlights["@lsp.type.function"] = {
					fg = colors.blue,
				}

				highlights["@lsp.type.property.rust"] = {
					fg = "#8AD2C0",
				}

				highlights["@lsp.type.enum"] = {
					fg = "#f7768e",
				}

				highlights["@lsp.type.struct"] = {
					fg = "#FFE194",
				}

				highlights["@lsp.type.struct.rust"] = {
					link = "@lsp.type.struct",
				}

				highlights["@lsp.type.interface"] = {
					fg = "#FCCCC7",
				}

				highlights["@lsp.type.derive.rust"] = {
					fg = colors.teal,
				}

				highlights["@lsp.typemod.macro.defaultLibrary.rust"] = {
					fg = colors.blue,
				}

				highlights["@markup.link.label.markdown_inline"] = {
					fg = "#70b1da",
				}

				highlights["@lsp.type.formatSpecifier"] = {
					fg = colors.green1,
				}

				highlights["@lsp.type.lifetime.rust"] = {
					fg = colors.fg,
				}

				highlights["@lsp.typemod.function.defaultLibrary.lua"] = {
					link = nil,
				}

				highlights["@lsp.typemod.function.defaultLibrary.rust"] = {
					link = nil,
				}

				highlights["@lsp.typemod.method.defaultLibrary.rust"] = {
					link = nil,
				}

				highlights["@lsp.typemod.enum.defaultLibrary.rust"] = {
					link = nil,
				}

				highlights["@lsp.typemod.enumMember.defaultLibrary.rust"] = {
					link = nil,
				}

				highlights["@lsp.typemod.struct.defaultLibrary.rust"] = {}

				highlights["@constant.builtin"] = {
					link = "@constant",
				}

				highlights.LazyReasonPlugin = {
					fg = colors.blue,
				}
			end,
		})
		vim.cmd([[colorscheme tokyonight]])
	end,
}
