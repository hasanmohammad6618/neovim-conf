return {
    'gitsang/codock.nvim',
    opts = {
        width = 80,                -- Width of the vertical split
        codock_cmd = "pi",         -- Command to run in the terminal (pi, opencode, claude, codex, etc.)
        copy_to_clipboard = false, -- Copy to system clipboard
        header = true,             -- Show a one-line header with the slot number above each terminal
        actions = {}
    },
    cmd = { "Codock", "CodockFilePosPaste", "CodockFilePosYank", "CodockActions", "CodockWidth" },
    keys = {
        { "<leader>CCO", "<cmd>Codock opencode<cr>", desc = "Toggle Opencode", mode = { "n", "v" } },
        { "<leader>CCC", "<cmd>Codock claude<cr>", desc = "Toggle Claude", mode = { "n", "v" } },
        { "<leader>CCX", "<cmd>Codock codex<cr>", desc = "Toggle Codex", mode = { "n", "v" } },
        { "<leader>CCP", "<cmd>Codock pi<cr>", desc = "Toggle Pi Agent", mode = { "n", "v" } },
        {
            "<leader>CCD",
            "<cmd>Codock dsh --profile tui<cr>",
            desc = "Toggle Deepseek Harness TUI",
            mode = { "n", "v" }
        },
        { "<leader>CY", ":'<,'>CodockFilePosYank<cr>", desc = "Copy file position", mode = { "n", "v" } },
        { "<leader>CP", ":'<,'>CodockFilePosPaste<cr>", desc = "Copy and paste file position", mode = { "n", "v" } },
        { "<leader>CA", ":'<,'>CodockActions<cr>", desc = "Run Codock actions", mode = { "n", "v" } }
    }
}
