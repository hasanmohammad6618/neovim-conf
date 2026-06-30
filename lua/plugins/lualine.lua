return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        { "nvim-tree/nvim-web-devicons" }
    },
    config = function ()
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
                    "snacks_dashboard"
                },
                ignore_focus = {},
                always_divide_middle = true,
                always_show_tabline = true,
                globalstatus = true,
                update_in_insert = true,
                refresh = {
                    statusline = 50,
                    tabline = 100,
                    winbar = 100
                }
            },
            sections = {
                lualine_a = { { "mode", icon = "" } },
                lualine_b = { { "branch", icon = "" }, { "diff", icon = "" } },
                lualine_c = {
                    {
                        'lsp_status',
                        icon = '', -- f013
                        symbols = {
                            -- Standard unicode symbols to cycle through for LSP progress:
                            spinner = { '◜', '◝', '◝', '◞', '◟', '◟', '◟', '◜' },
                            -- Standard unicode symbol for when LSP is done:
                            done = '✓',
                            -- Delimiter inserted between LSP names:
                            separator = ' '
                        }
                    }
                },
                lualine_x = {
                    "diagnostics",
                    "filesize",
                    "encoding",
                    "filetype"
                },
                lualine_y = { "progress" },
                lualine_z = { { "location", icon = "" } }
            },
            inactive_sections = {
                lualine_a = { { "mode", icon = "" } },
                lualine_b = { { "branch", icon = "" }, { "diff", icon = "" } },
                lualine_x = {
                    "diagnostics",
                    "filesize",
                    "encoding",
                    "filetype"
                },
                lualine_y = { "progress" },
                lualine_z = { { "location", icon = "" } }
            },
            tabline = {},
            winbar = {},
            inactive_winbar = {},
            extensions = {}
        })
    end
}
