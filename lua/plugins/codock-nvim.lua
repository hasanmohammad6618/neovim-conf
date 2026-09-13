return {
    'gitsang/codock.nvim',
    opts = {
        width = 80,                -- Width of the vertical split
        codock_cmd = "crush",      -- Command to run in the terminal (pi, opencode, claude, codex, etc.)
        copy_to_clipboard = false, -- Copy to system clipboard
        header = true,             -- Show a one-line header with the slot number above each terminal
        actions = {}
    },
    cmd = { "Codock", "CodockFilePosPaste", "CodockFilePosYank", "CodockActions", "CodockWidth" },
    keys = {
        { "<leader>CY", ":'<,'>CodockFilePosYank<cr>", desc = "Copy file position", mode = { "n", "v" } },
        { "<leader>CP", ":'<,'>CodockFilePosPaste<cr>", desc = "Copy and paste file position", mode = { "n", "v" } },
        { "<leader>CA", ":'<,'>CodockActions<cr>", desc = "Run Codock actions", mode = { "n", "v" } }
    }
}
