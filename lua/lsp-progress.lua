-- LSP Progress Handler – robust version
-- -------------------------------------------------------------
-- Author: (fixed)
-- Date: 2026-03-21
-- -------------------------------------------------------------
-- Changelog:
--   - Fixed token collision between different LSP clients
--   - Fixed unsafe table mutation during iteration
--   - Improved message parsing and redundancy checks
--   - Added standard hyphen normalization
--   - Improved notification content formatting
-- -------------------------------------------------------------

local M = {}

-- -----------------------------------------------------------------
-- Default configuration
-- -----------------------------------------------------------------
local config = {
	spinners = { "◜ ", "◠ ", "◝ ", "◞ ", "◡ ", "◟ " },
	cleanup_delay_ms = 3100,
	notification_prefix = "lsp_progress_",
	notification_icon = " ",
	notification_timeout = 1800,
	debug = false,
	on_progress = nil,
}

-- -----------------------------------------------------------------
-- Helper utilities
-- -----------------------------------------------------------------
local function trim(s)
	return s:gsub("^%s+", ""):gsub("%s+$", "")
end

local function clamp(v, lo, hi)
	return math.max(lo, math.min(v, hi))
end

local function debug(msg)
	if config.debug then
		vim.notify("[LSP Progress] " .. msg, vim.log.levels.DEBUG)
	end
end

local function get_cache_key(client_id, token)
	return tostring(client_id) .. ":" .. tostring(token)
end

local function get_notification_id(client_id, token)
	return config.notification_prefix .. tostring(client_id) .. "_" .. tostring(token)
end

-- -----------------------------------------------------------------
-- Public configuration API
-- -----------------------------------------------------------------
function M.setup(opts)
	vim.validate({ opts = { opts, "table", true } })
	if not opts then
		return
	end

	vim.validate({
		spinners = { opts.spinners, "table", true },
		cleanup_delay_ms = { opts.cleanup_delay_ms, "number", true },
		notification_prefix = { opts.notification_prefix, "string", true },
		notification_icon = { opts.notification_icon, "string", true },
		notification_timeout = { opts.notification_timeout, "number", true },
		debug = { opts.debug, "boolean", true },
		on_progress = { opts.on_progress, "function", true },
	})

	for k, v in pairs(opts) do
		config[k] = v
	end

	if #config.spinners == 0 then
		config.spinners = { " " }
	end
end

-- -----------------------------------------------------------------
-- Internal state
-- -----------------------------------------------------------------
local progress_cache = {}
local stale_timer = nil

-- -----------------------------------------------------------------
-- Notification helpers
-- -----------------------------------------------------------------
local function show_notification(content, id, is_end)
	local title = "LSP Progress"
	local timeout = is_end and config.notification_timeout or 0

	if type(_G.Snacks) == "table" and _G.Snacks.notifier then
		local opts = { icon = config.notification_icon, id = id, timeout = timeout, title = title }
		pcall(function()
			_G.Snacks.notifier.notify(content, "info", opts)
		end)
	else
		local fallback = config.notification_icon .. " " .. content
		vim.notify(fallback, vim.log.levels.INFO, {
			title = title,
			id = id, -- Some notifiers like nvim-notify use id for replacement
			timeout = timeout,
			replace = id, -- Support for some other notification plugins
		})
	end
end

local function cleanup_notification(id)
	if type(_G.Snacks) == "table" and _G.Snacks.notifier and type(_G.Snacks.notifier.hide) == "function" then
		pcall(function()
			_G.Snacks.notifier.hide(id)
		end)
	end
end

-- -----------------------------------------------------------------
-- Message parsing
-- -----------------------------------------------------------------
local function extract_work_progress(message)
	if not message or message == "" then
		return nil, nil
	end

	local patterns = {
		"^%s*(%d+)%s*/%s*(%d+)%s*$", -- "10/100"
		"^%s*(%d+)%s+of%s+(%d+)%s*$", -- "10 of 100"
		"^Processing file%s+(%d+)%s+of%s+(%d+)", -- "Processing file 3 of 10"
		"%f[%d](%d+)%s+items?%s+processed", -- "5 items processed"
		"%f[%d](%d+)%s*/%s*(%d+)", -- "5/10"
		"^(%d+)%s*%%", -- "45%" or "45% complete"
		"^(%d+)%s*%%?%s*of%s*(%d+)", -- "45% of 100"
	}

	for _, pat in ipairs(patterns) do
		local d_str, t_str = message:match(pat)
		if d_str then
			local done = tonumber(d_str)
			local total = tonumber(t_str or "")
			if not total and pat:find("%%") then
				total = 100
			end
			return done, total
		end
	end
	return nil, nil
end

-- -----------------------------------------------------------------
-- Redundancy check
-- -----------------------------------------------------------------
local function is_message_redundant(title, message)
	if not title or not message or title == "" or message == "" then
		return false
	end
	local norm_title = trim(title):lower()
	local norm_message = trim(message):lower()

	if norm_message == norm_title then
		return true
	end

	-- Check if message is just title + punctuation/suffix
	if norm_message:sub(1, #norm_title) == norm_title then
		local rest = norm_message:sub(#norm_title + 1)
		if rest == "" or rest:match("^[%s%.%…!%-]+$") then
			return true
		end
	end

	return false
end

-- -----------------------------------------------------------------
-- Server name resolution
-- -----------------------------------------------------------------
local function get_reliable_server_name(client)
	local candidates = {
		client.name,
		client.server_info and client.server_info.name,
		client.config and client.config.name,
		"LSP-" .. tostring(client.id),
	}
	for _, c in ipairs(candidates) do
		if c and c ~= "" then
			return c
		end
	end
	return "LSP"
end

-- -----------------------------------------------------------------
-- Cache entry handling
-- -----------------------------------------------------------------
local function handle_begin_progress(client, progress, token)
	local server_name = get_reliable_server_name(client)
	local key = get_cache_key(client.id, token)

	local old = progress_cache[key]
	if old and old.timer then
		pcall(function()
			if not old.timer:is_closing() then
				old.timer:stop()
				old.timer:close()
			end
		end)
	end

	progress_cache[key] = {
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
		timer = nil,
		token = token,
	}
	return progress_cache[key]
end

local function update_cache_entry(entry, progress, kind)
	if kind == "report" then
		entry.spinner_idx = (entry.spinner_idx % #config.spinners) + 1
		entry.report_count = entry.report_count + 1
	end

	if progress.message then
		entry.message = progress.message
	end

	local done, total = extract_work_progress(progress.message)
	if done then
		entry.work_done = done
		if total then
			entry.total_work = total
		end
		if entry.total_work and entry.total_work > 0 then
			entry.percentage = clamp((done / entry.total_work) * 100, 0, 100)
		end
	end

	if progress.percentage then
		entry.percentage = clamp(progress.percentage, 0, 100)
	end

	-- Fallback heuristic
	if kind == "report" and not progress.percentage and not done then
		local report_progress = clamp(entry.report_count * 2, 0, 40)
		local elapsed_ms = (vim.uv.hrtime() - entry.start_time) / 1e6
		local time_progress = clamp(elapsed_ms / 1000, 0, 40)
		entry.percentage = clamp(report_progress + time_progress, 0, 95)
	end

	if kind == "end" then
		entry.spinner_idx = 1
		entry.percentage = 100
		if entry.total_work and entry.total_work > 0 then
			entry.work_done = entry.total_work
		end
	end

	entry.percentage = clamp(entry.percentage, 0, 100)
end

local function build_notification_content(entry, is_end)
	local title = entry.title or ""
	local message = entry.message or ""
	local server_name = entry.server_name or "LSP"

	local components = {}
	local spinner = is_end and "✓ " or config.spinners[entry.spinner_idx] or " "
	table.insert(components, spinner)
	table.insert(components, "[" .. server_name .. "]")

	if title ~= "" then
		table.insert(components, title)
	end

	if message ~= "" and not is_message_redundant(title, message) then
		table.insert(components, message)
	end

	if entry.total_work and entry.total_work > 0 then
		-- Only add work stats if not already in message
		local d, t = extract_work_progress(message)
		if not (d == entry.work_done and t == entry.total_work) then
			table.insert(components, string.format("[%d/%d]", entry.work_done, entry.total_work))
		end
	end

	table.insert(components, string.format("(%.0f%%)", entry.percentage))
	return table.concat(components, " ")
end

-- -----------------------------------------------------------------
-- Cleanup utilities
-- -----------------------------------------------------------------
local function schedule_cleanup(key, notification_id)
	local entry = progress_cache[key]
	if not entry then
		return
	end

	if entry.timer then
		pcall(function()
			if not entry.timer:is_closing() then
				entry.timer:stop()
				entry.timer:close()
			end
		end)
	end

	local timer = vim.uv.new_timer()
	if timer then
		entry.timer = timer
		timer:start(
			config.cleanup_delay_ms,
			0,
			vim.schedule_wrap(function()
				if not timer:is_closing() then
					cleanup_notification(notification_id)
					progress_cache[key] = nil
					pcall(function()
						timer:close()
					end)
				end
			end)
		)
	else
		vim.defer_fn(
			vim.schedule_wrap(function()
				cleanup_notification(notification_id)
				progress_cache[key] = nil
			end),
			config.cleanup_delay_ms
		)
	end
end

local function start_stale_purge()
	if stale_timer and not stale_timer:is_closing() then
		return
	end

	stale_timer = vim.uv.new_timer()
	if not stale_timer then
		return
	end

	stale_timer:start(
		60000,
		60000,
		vim.schedule_wrap(function()
			local now = vim.uv.hrtime()
			local keys_to_remove = {}
			for key, entry in pairs(progress_cache) do
				if entry.start_time then
					local age_sec = (now - entry.start_time) / 1e9
					if age_sec > 300 then
						keys_to_remove[key] = true
					end
				end
			end
			for key, _ in pairs(keys_to_remove) do
				local entry = progress_cache[key]
				if entry then
					local nid = get_notification_id(entry.client_id, entry.token)
					cleanup_notification(nid)
					if entry.timer and not entry.timer:is_closing() then
						pcall(function()
							entry.timer:stop()
							entry.timer:close()
						end)
					end
					progress_cache[key] = nil
					debug("Purged stale progress entry for " .. key)
				end
			end
		end)
	)
end

local function stop_stale_purge()
	if stale_timer and not stale_timer:is_closing() then
		pcall(function()
			stale_timer:stop()
			stale_timer:close()
		end)
		stale_timer = nil
	end
end

function M.cleanup()
	local keys = vim.tbl_keys(progress_cache)
	for _, key in ipairs(keys) do
		local entry = progress_cache[key]
		if entry then
			if entry.timer and not entry.timer:is_closing() then
				pcall(function()
					entry.timer:stop()
					entry.timer:close()
				end)
			end
			cleanup_notification(get_notification_id(entry.client_id, entry.token))
			progress_cache[key] = nil
		end
	end
	stop_stale_purge()
end

-- -----------------------------------------------------------------
-- LSP progress handler
-- -----------------------------------------------------------------
vim.lsp.handlers["$/progress"] = function(err, result, ctx)
	if err then
		debug("LSP progress error: " .. tostring(err))
		return
	end

	local ok, handler_err = pcall(function()
		local client = vim.lsp.get_client_by_id(ctx.client_id)
		if not client then
			return
		end

		local progress = result.value
		local token = result.token
		local kind = progress and progress.kind
		if not kind then
			return
		end

		local key = get_cache_key(ctx.client_id, token)
		local nid = get_notification_id(ctx.client_id, token)
		local entry = progress_cache[key]

		if kind == "begin" then
			entry = handle_begin_progress(client, progress, token)
		end

		if not entry then
			return
		end

		update_cache_entry(entry, progress, kind)

		local content = build_notification_content(entry, kind == "end")
		show_notification(content, nid, kind == "end")

		if type(config.on_progress) == "function" then
			pcall(function()
				config.on_progress(entry, kind == "end")
			end)
		end

		if kind == "end" then
			schedule_cleanup(key, nid)
		end
	end)

	if not ok then
		vim.notify("LSP progress handler error: " .. tostring(handler_err), vim.log.levels.ERROR)
	end
end

-- -----------------------------------------------------------------
-- Autocommands
-- -----------------------------------------------------------------
local augroup = vim.api.nvim_create_augroup("LspProgressHandler", { clear = true })

vim.api.nvim_create_autocmd("VimLeavePre", {
	group = augroup,
	callback = function()
		M.cleanup()
	end,
})

vim.api.nvim_create_autocmd("LspDetach", {
	group = augroup,
	callback = function(args)
		local client_id = args.data.client_id
		local keys_to_remove = {}
		for key, entry in pairs(progress_cache) do
			if entry.client_id == client_id then
				keys_to_remove[key] = true
			end
		end
		for key, _ in pairs(keys_to_remove) do
			local entry = progress_cache[key]
			if entry then
				if entry.timer and not entry.timer:is_closing() then
					pcall(function()
						entry.timer:stop()
						entry.timer:close()
					end)
				end
				cleanup_notification(get_notification_id(entry.client_id, entry.token))
				progress_cache[key] = nil
			end
		end
	end,
})

start_stale_purge()

return M
