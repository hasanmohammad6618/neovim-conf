-- =================================================================
-- Enhanced LSP Progress Handler (Fixed Brackets + Duplication)
-- =================================================================

---@class LspProgressCacheEntry
---@field spinner_idx integer
---@field title string
---@field message string
---@field percentage number
---@field work_done integer
---@field total_work integer|nil
---@field report_count integer
---@field start_time number
---@field client_id integer
---@field server_name string

---@class LspProgressHandlerModule: table
local M = {}

---@type string[]
local SPINNERS = { "◜ ", "◠ ", "◝ ", "◞ ", "◡ ", "◟ " }
local SPINNER_COUNT = #SPINNERS
local NOTIFICATION_PREFIX = "lsp_progress_"
local CLEANUP_DELAY_MS = 3100

---@type table<string|integer, LspProgressCacheEntry>
local progress_cache = {}

---Generate notification ID from token
---@param token string|integer
---@return string
local function get_notification_id(token)
	return NOTIFICATION_PREFIX .. tostring(token)
end

---Show notification using Snacks notifier
---@module "snacks"
---@param content string
---@param id string
---@param is_end boolean
local function show_notification(content, id, is_end)
	if not (Snacks and Snacks.notifier) then
		return
	end
	Snacks.notifier.notify(content, "info", {
		icon = " ",
		id = id,
		timeout = is_end and 1800 or 0,
		title = "LSP Progress",
	})
end

---Clean up notification by ID
---@param id string
local function cleanup_notification(id)
	if Snacks and Snacks.notifier and type(Snacks.notifier.hide) == "function" then
		Snacks.notifier.hide(id)
	end
end

---Extract work progress from message string
---@param message string|nil
---@return integer|nil done
---@return integer|nil total
local function extract_work_progress(message)
	if not message then
		return nil, nil
	end

	-- Patterns in order of specificity
	local patterns = {
		{ "^%s*(%d+)%s*/%s*(%d+)%s*$" }, -- "10/100"
		{ "^%s*(%d+)%s+of%s+(%d+)%s*$" }, -- "10 of 100"
		{ "^Processing file%s+(%d+)%s+of%s+(%d+)" }, -- "Processing file 10 of 100"
		{ "%f[%d](%d+)%s+items?%s+processed" }, -- "10 items processed"
		{ "%f[%d](%d+)%s*/%s*(%d+)" }, -- More lenient pattern
	}

	for _, pattern in ipairs(patterns) do
		local done, total = message:match(pattern[1])
		if done then
			return tonumber(done), total and tonumber(total)
		end
	end
	return nil, nil
end

---Check if message is redundant with title
---@param title string
---@param message string
---@return boolean
local function is_message_redundant(title, message)
	if title == "" or message == "" then
		return false
	end

	-- Normalize strings: trim, lower case, remove trailing punctuation
	local function normalize(str)
		return str:gsub("[%.…%s]+$", ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
	end

	local norm_title = normalize(title)
	local norm_message = normalize(message)

	-- Direct equality
	if norm_message == norm_title then
		return true
	end

	-- Message starts with title
	if norm_message:find("^" .. vim.pesc(norm_title), 1, true) then
		return true
	end

	return false
end

---Get reliable server name with fallbacks
---@param client table
---@return string
local function get_reliable_server_name(client)
	-- Priority order for server name
	local candidates = {
		client.name,
		client.server_info and client.server_info.name,
		client.config and client.config.name,
		"LSP-" .. tostring(client.id),
	}

	for _, candidate in ipairs(candidates) do
		if candidate and candidate ~= "" then
			return candidate
		end
	end

	return "LSP"
end

---Update cache entry with progress data
---@param cache_entry LspProgressCacheEntry
---@param progress table
---@param kind "begin"|"report"|"end"
local function update_cache_entry(cache_entry, progress, kind)
	if kind == "report" then
		cache_entry.spinner_idx = (cache_entry.spinner_idx % SPINNER_COUNT) + 1
		cache_entry.report_count = cache_entry.report_count + 1
	elseif kind == "end" then
		cache_entry.spinner_idx = 1
		cache_entry.percentage = 100
		if cache_entry.total_work and cache_entry.total_work > 0 then
			cache_entry.work_done = cache_entry.total_work
		end
	end

	-- Update message if provided
	if progress.message then
		cache_entry.message = progress.message
	end

	-- Extract work progress from message
	local done, total = extract_work_progress(progress.message)
	if done then
		cache_entry.work_done = done
		if total then
			cache_entry.total_work = total
		end
		if cache_entry.total_work and cache_entry.total_work > 0 then
			cache_entry.percentage = math.min((done / cache_entry.total_work) * 100, 100)
		end
	end

	-- Apply percentage if directly provided
	if progress.percentage then
		cache_entry.percentage = progress.percentage
	end

	-- Calculate estimated percentage if not provided
	if kind == "report" and not progress.percentage and not done then
		local report_progress = math.min(cache_entry.report_count * 5, 50)
		local elapsed_ms = (vim.uv.hrtime() - cache_entry.start_time) / 1e6
		local time_progress = math.min(elapsed_ms / 600, 50)
		cache_entry.percentage = math.min(report_progress + time_progress, 99)
	end
end

---Build notification content from cache entry
---@param cache_entry LspProgressCacheEntry
---@param is_end boolean
---@return string
local function build_notification_content(cache_entry, is_end)
	local components = {}
	local spinner = is_end and "✓ " or SPINNERS[cache_entry.spinner_idx]

	table.insert(components, spinner)
	table.insert(components, "[" .. (cache_entry.server_name ~= "" and cache_entry.server_name or "LSP") .. "]")

	if cache_entry.title ~= "" then
		table.insert(components, cache_entry.title)
	end

	if cache_entry.total_work and cache_entry.total_work > 0 then
		table.insert(components, string.format("%d/%d", cache_entry.work_done, cache_entry.total_work))
	elseif cache_entry.message ~= "" and not is_message_redundant(cache_entry.title, cache_entry.message) then
		table.insert(components, cache_entry.message)
	end

	table.insert(components, string.format("(%.0f%%)", math.min(cache_entry.percentage or 0, 100)))
	return table.concat(components, " ")
end

---Schedule cleanup for completed progress
---@param token string|integer
---@param notification_id string
local function schedule_cleanup(token, notification_id)
	local timer = vim.uv.new_timer()
	if not timer then
		return
	end

	timer:start(
		CLEANUP_DELAY_MS,
		0,
		vim.schedule_wrap(function()
			if not timer:is_closing() then
				cleanup_notification(notification_id)
				progress_cache[token] = nil
				timer:close()
			end
		end)
	)
end

---Handle begin progress event
---@param client table
---@param progress table
---@param token string|integer
---@return LspProgressCacheEntry|nil
local function handle_begin_progress(client, progress, token)
	local server_name = get_reliable_server_name(client)

	local cache_entry = {
		spinner_idx = 1,
		title = progress.title or "",
		message = progress.message or "",
		percentage = 0,
		work_done = 0,
		total_work = nil,
		report_count = 0,
		start_time = vim.uv.hrtime(),
		client_id = client.id,
		server_name = server_name,
	}

	progress_cache[token] = cache_entry
	return cache_entry
end

---Validate progress parameters
---@param result any
---@param ctx table
---@return boolean, table|nil, table|nil, string|integer|nil
local function validate_progress_params(result, ctx)
	local client = vim.lsp.get_client_by_id(ctx.client_id)
	if not client then
		return false
	end

	local progress = result.value
	local token = result.token
	local kind = progress and progress.kind

	if not kind then
		return false
	end

	return true, client, progress, token, kind
end

---Main LSP progress handler
---@param _ any
---@param result {token: string|integer, value: {kind: "begin"|"report"|"end", title?: string, message?: string, percentage?: number}}
---@param ctx {client_id: integer}
vim.lsp.handlers["$/progress"] = function(_, result, ctx)
	local valid, client, progress, token, kind = validate_progress_params(result, ctx)
	if not valid then
		return
	end

	local cache_entry = progress_cache[token]
	local notification_id = get_notification_id(token)

	-- Handle begin event
	if kind == "begin" then
		cache_entry = handle_begin_progress(client, progress, token)
		if not cache_entry then
			return
		end
	end

	-- Must have cache entry for report/end events
	if not cache_entry then
		return
	end

	-- Update cache entry based on progress kind
	update_cache_entry(cache_entry, progress, kind)

	-- Show notification
	local content = build_notification_content(cache_entry, kind == "end")
	show_notification(content, notification_id, kind == "end")

	-- Schedule cleanup for completed progress
	if kind == "end" then
		schedule_cleanup(token, notification_id)
	end
end

---Function to cleanup all progress
function M.cleanup()
	for token in pairs(progress_cache) do
		local id = get_notification_id(token)
		cleanup_notification(id)
		progress_cache[token] = nil
	end
end

-- Cleanup on exit
vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = M.cleanup,
})

-- Add autocmd to cleanup on LSP detach
vim.api.nvim_create_autocmd("LspDetach", {
	callback = function(args)
		local client_id = args.data.client_id
		for token, entry in pairs(progress_cache) do
			if entry.client_id == client_id then
				local id = get_notification_id(token)
				cleanup_notification(id)
				progress_cache[token] = nil
			end
		end
	end,
})

return M
