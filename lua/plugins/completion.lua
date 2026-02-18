return {
	"saghen/blink.cmp",
	-- optional: provides snippets for the snippet source
	-- use a release tag to download pre-built binaries
	version = "*",
	-- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
	-- build = 'cargo build --release',
	-- If you use nix, you can build from source using latest nightly rust with:
	-- build = 'nix run .#build-plugin',

	config = function()
		local opt = {
			signature = {
				enabled = true,
				trigger = {
					show_on_keyword = true,
					enabled = true,
					show_on_insert = true,
					show_on_trigger_character = true,
				},
				window = {
					max_width = 50,
					min_width = 50,
					max_height = 20,
					border = "double",
					treesitter_highlighting = true,
					show_documentation = true,
				},
			},
			keymap = {
				preset = "enter",
			},
			cmdline = {
				completion = {
					list = {
						selection = {
							auto_insert = true,
							preselect = true,
						},
					},
					menu = {
						auto_show = true,
					},
				},
				enabled = true,
				keymap = {
					preset = "default",
				},
			},
			completion = {
				trigger = {
					show_on_insert_on_trigger_character = false,
				},
				menu = {
					auto_show = true,
					enabled = true,
					min_width = 30,
					max_height = 18,
					winblend = 0,
					auto_show_delay_ms = 0,
					scrolloff = 0,
					border = "double",
					draw = {
						padding = 1,
						gap = 1,
						treesitter = { "lsp" },
					},
				},
				list = {
					max_items = 100,
					selection = {
						preselect = false,
						auto_insert = false,
					},
				},
				documentation = {
					auto_show = true,
					treesitter_highlighting = true,
					window = {
						min_width = 40,
						max_width = 40,
						max_height = 40,
						border = "double",
						scrollbar = true,
						winblend = 0,
					},
				},
			},
			-- 'default' for mappings similar to built-in completion
			-- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
			-- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
			-- See the full "keymap" documentation for information on defining your own keymap.

			appearance = {
				highlight_ns = vim.api.nvim_create_namespace("blink_cmp"),
				-- Sets the fallback highlight groups to nvim-cmp's highlight groups
				-- Useful for when your theme doesn't support blink.cmp
				-- Will be removed in a future release
				use_nvim_cmp_as_default = false,
				-- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
				-- Adjusts spacing to ensure icons are aligned
				nerd_font_variant = "normal",
				kind_icons = {
					Text = "󰦨",
					Method = "",
					Function = "",
					Constructor = "",
					Field = "",
					Variable = "",
					Property = "",

					Class = "",
					Interface = "",
					Struct = "",
					Module = "",

					Unit = "",
					Value = "󰦨",
					Enum = "",
					EnumMember = "",

					Keyword = "",
					Constant = "",

					Snippet = "",
					Color = "",
					File = "",
					Reference = "",
					Folder = "",
					Event = "",
					Operator = "",
					TypeParameter = "",
				},
			},

			-- Default list of enabled providers defined so that you can extend it
			-- elsewhere in your config, without redefining it, due to `opts_extend`
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
				providers = {
					lsp = {
						async = true,
					},
				},
			},
		}
		require("blink-cmp").setup(opt --[[@as blink.cmp.Config]])
	end,

	-- LSP servers and clients communicate which features they support through "capabilities".
	--  By default, Neovim supports a subset of the LSP specification.
	--  With blink.cmp, Neovim has *more* capabilities which are communicated to the LSP servers.
	--  Explanation from TJ: https://youtu.be/m8C0Cq9Uv9o?t=1275
	--
	-- This can vary by config, but in general for nvim-lspconfig:
}
