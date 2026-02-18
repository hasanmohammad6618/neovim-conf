return {
	"nvim-tree/nvim-web-devicons",
	opts = {},
	lazy = false, -- Load immediately on startup
	priority = 2000, -- High priority
	config = function()
		require("nvim-web-devicons").setup({
			-- your personal icons can go here (to override)
			-- you can specify color or cterm_color instead of specifying both of them
			-- DevIcon will be appended to `name`
			override = {
				zsh = {
					icon = "",
					color = "#428850",
					cterm_color = "65",
					name = "Zsh",
				},
			},
			-- globally encable different highlight colors per icon (default to true)
			-- if set to false all icons will have the default icon's color
			color_icons = true,
			-- globally enable default icons (default to false)
			-- will get overriden by `get_icons` option
			default = true,
			-- globally enable "strict" selection of icons - icon will be looked up in
			-- different tables, first by filename, and if not found by extension; this
			-- prevents cases when file doesn't have any extension but still gets some icon
			-- because its name happened to match some extension (default to false)
			strict = true,
			-- set the light or dark variant manually, instead of relying on `background`
			-- (default to nil)
			variant = "dark",
			-- same as `override` but specifically for overrides by filename
			-- takes effect when `strict` is true
			override_by_filename = {
				[".python-version"] = {
					icon = "",
					name = "PythonVersion",
				},
				[".gitignore"] = {
					icon = "  ",
					name = "Gitignore",
				},
				[".bash_profile"] = {
					icon = "",
					name = "bash_profile",
					color = "#f9e2af",
				},
				[".bashrc"] = {
					icon = "",
					name = "bashrc",
					color = "#f9e2af",
				},
				[".bash_history"] = {
					icon = "",
					name = "bash_history",
				},
				[".bash_logout"] = {
					icon = "",
					name = "bash_logout",
				},
				[".profile"] = {
					icon = "",
					name = "profile",
				},
				["lua-language-server"] = {
					icon = "",
					name = "lua-language-server",
				},
				["cookie"] = {
					icon = "",
					name = "Cookie",
				},
				["database"] = {
					icon = "",
					name = "database",
				},
				["database-shm"] = {
					icon = " ",
					name = "database-shm",
				},
				["database-wal"] = {
					icon = "",
					name = "database-wal",
				},
				["NvimTree_1"] = {
					icon = "",
					name = "NvimTree",
				},
				["config"] = {
					icon = "",
					name = "Config",
				},
				[".clang-format"] = {
					icon = "",
					name = "clang-format",
				},
				["bash"] = {
					icon = "",
					name = "Bash",
				},
				["exclude"] = {
					icon = "",
					name = "Exclude",
				},
			},
			-- same as `override` but specifically for overrides by extension
			-- takes effect when `strict` is true
			override_by_extension = {
				["sample"] = {
					icon = "",
					name = "Github_Sample",
				},
				["css"] = {
					icon = "",
					color = "#7aa2f7",
					name = "CSS",
				},
				["log"] = {
					icon = "",
					name = "Log",
				},
				["toml"] = {
					icon = "",
					name = "Toml",
				},
				["lock"] = {
					icon = "",
					color = "#f7f9fa",
					name = "Lock",
				},
				["json5"] = {
					icon = "",
					color = "#ffd726",
					name = "JSON",
				},
				["json"] = {
					icon = "",
					color = "#ffd726",
					name = "JSON",
				},
				["js"] = {
					icon = "",
					cterm_color = 185,
					color = "#ffd726",
					name = "JavaScript",
				},
				["conf"] = {
					icon = "",
					name = "conf",
				},
				["ini"] = {
					icon = "",
					name = "ini",
				},
				["tag"] = {
					icon = "",
					name = "Tag",
				},
				["cargo-lock"] = {
					icon = "",
					color = "#f7f9fa",
					name = "cargo-lock",
				},
				["timestamp"] = {
					icon = "",
					name = "Timestamp",
				},
				["bin"] = {
					icon = "",
					color = "#fab387",
					name = "Binary",
				},
				["o"] = {
					icon = "",
					color = "#fab387",
					name = "Binary",
				},
				["txt"] = {
					icon = "",
					name = "Text",
					color = "#f9e2af",
				},
				["sqlite"] = {
					icon = "",
					name = "SQLite",
				},
				["db"] = {
					icon = "",
					name = "Database",
				},
				["mdb"] = {
					icon = "",
					name = "Database",
				},
				["kcache"] = {
					icon = "",
					name = "kcache",
				},
				["cache-9"] = {
					icon = "",
					name = "cache-9",
				},
				["metadata"] = {
					icon = "",
					name = "metadata",
				},
				["png"] = {
					color = "#b4befe",
					icon = "",
					name = "PNG",
				},
				["profile"] = {
					icon = "",
					name = "Profile",
				},
				["appimage"] = {
					icon = "",
					color = "#b4befe",
					name = "Appimage",
				},
				["sqlite-shm"] = {
					icon = "",
					name = "SQLite-SHM",
				},
				["sqlite-wal"] = {
					icon = "",
					name = "SQLite-WAL",
				},
				["sqlite-journal"] = {
					icon = "",
					name = "SQLite-Journal",
				},
				["delta"] = {
					icon = "󰇂",
					name = "Delta",
				},
				["jsonlz4"] = {
					icon = "󰈹",
					name = "JSONLZ4",
				},
			},
			-- same as `override` but specifically for operating system
			-- takes effect when `strict` is true
			override_by_operating_system = {
				["apple"] = {
					icon = "",
					color = "#A2AAAD",
					cterm_color = "248",
					name = "Apple",
				},
			},
		})
	end,
}
