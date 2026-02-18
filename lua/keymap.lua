vim.keymap.set({ "n", "v" }, "<leader>qb", "<cmd>BufferClose<CR>")
vim.keymap.set({ "n", "v" }, "<leader>qw", "<cmd>q<CR>")
vim.keymap.set("n", "<A-Up>", ":m-2<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<A-Down>", ":m+<CR>", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "i" }, "<A-Left>", function()
	vim.cmd("bprevious")
end)
vim.keymap.set({ "n", "i", "v" }, "<C-/>", function()
	vim.cmd("normal gcc")
end)
vim.keymap.set({ "n", "i", "c", "v" }, "<C-q>", function()
	vim.cmd("qa!")
end)
vim.keymap.set("v", "<A-Down>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<A-Up>", ":m '<-2<CR>gv=gv")
vim.keymap.set({ "n", "i", "c", "v" }, "<C-s>", "<cmd>w!<CR>")
vim.keymap.set({ "n", "v", "i" }, "<A-Right>", function()
	vim.cmd("bnext")
end)
vim.keymap.set({ "n", "v", "i" }, "<C-f>", function()
	vim.cmd("NvimTreeToggle")
end)
vim.keymap.set({ "n", "i", "c", "v" }, "<C-e>", function()
	Snacks.picker.explorer({
		git_status = true,
		watch = true,
		git_untracked = true,
		ignored = true,
		hidden = true,
		diagnostics_open = true,
		git_status_open = true,
		show_empty = true,
	})
end, { remap = false })
