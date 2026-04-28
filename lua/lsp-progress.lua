-- LSP Progress Handler – robust version
-- -------------------------------------------------------------
-- Author: (fixed)
-- Date: 2026-03-21
-- -------------------------------------------------------------
-- Changelog from original:
--   - Fixed unsafe table mutation during iteration (cleanup, stale purge, LspDetach)
--   - Fixed is_message_redundant escaping/plain mismatch (now uses substring compare)
--   - Fixed end‑kind percentage override (now sets 100% after all updates)
--   - extract_work_progress now treats bare percentages as /100
--   - Guard against empty spinners table (fallback to default)
--   - schedule_cleanup gracefully falls back to vim.defer_fn if timer creation fails
--   - Preserved all original features and public API
-- -------------------------------------------------------------

local M = {}

-- -----------------------------------------------------------------
-- Default configuration (override via M.setup)
-- -----------------------------------------------------------------
local config = {
	spinners = { "◜ ", "◠ ", "◝ ", "◞ ", "◡ ", "◟ " },
	cleanup_delay_ms = 3100,
	notification_prefix = "lsp_progress_",
	notification_icon = " ",
	notification_timeout = 1800,
	debug = false,
	on_progress = nil, -- optional user callback (cache_entry, is_end)
}

-- -----------------------------------------------------------------
-- Helper utilities
-- -----------------------------------------------------------------
local function trim(s)
	return s:gsub("^%s+", ""):gsub("%s+$", "")
end

local function clamp(v, lo, hi)
	if v < lo then
		return lo
	end
	if v > hi then
		return hi
	end
	return v
end

local function debug(msg)
	if config.debug then
		vim.notify("[LSP Progress] " .. msg, vim.log.levels.DEBUG)
	end
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

	-- Ensure spinners table is never empty (prevents division by zero)
	if #config.spinners == 0 then
		config.spinners = { " " } -- fallback silent spinner
	end
end

-- -----------------------------------------------------------------
-- Internal state
-- -----------------------------------------------------------------
local progress_cache = {} -- token → entry
local stale_timer = nil -- periodic purge timer

-- -----------------------------------------------------------------
-- Notification helpers
-- -----------------------------------------------------------------
local function get_notification_id(token)
	return config.notification_prefix .. tostring(token)
end

local function show_notification(content, id, is_end)
	if type(_G.Snacks) == "table" and _G.Snacks.notifier then
		local opts = {
			icon = config.notification_icon,
			id = id,
			timeout = is_end and config.notification_timeout or 0,
			title = "LSP Progress",
		}
		pcall(function()
			_G.Snacks.notifier.notify(content, "info", opts)
		end)
	else
		local fallback = config.notification_icon .. " " .. content
		vim.notify(
			fallback,
			vim.log.levels.INFO,
			{ title = "LSP Progress", timeout = is_end and config.notification_timeout or 0 }
		)
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
	if not message then
		return nil, nil
	end

	local patterns = {
		"^%s*(%d+)%s*/%s*(%d+)%s*$", -- "10/100"
		"^%s*(%d+)%s+of%s+(%d+)%s*$", -- "10 of 100"
		"^Processing file%s+(%d+)%s+of%s+(%d+)", -- "Processing file 3 of 10"
		"%f[%d](%d+)%s+items?%s+processed", -- "5 items processed"
		"%f[%d](%d+)%s*/%s*(%d+)", -- "5/10"
		"^(%d+)%s*%%$", -- "45%"
		"^(%d+)%s*%%?%s*of%s*%d+", -- "45% of 100"
	}

	for _, pat in ipairs(patterns) do
		local done, total = message:match(pat)
		if done then
			done = tonumber(done)
			total = total and tonumber(total)
			-- If only a percentage was captured (pattern with "$"), treat as /100
			if not total and pat == "^(%d+)%s*%%$" then
				total = 100
			end
			return done, total
		end
	end
	return nil, nil
end

-- -----------------------------------------------------------------
-- Redundancy check (prefix match, case‑insensitive)
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
	-- Check if message starts with title (no pattern escaping needed)
	if string.sub(norm_message, 1, #norm_title) == norm_title then
		return true
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

	-- Cancel any pre‑existing timer for the same token
	local old = progress_cache[token]
	if old and old.timer then
		pcall(function()
			if not old.timer:is_closing() then
				old.timer:stop()
				old.timer:close()
			end
		end)
	end

	progress_cache[token] = {
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
	}
	return progress_cache[token]
end

local function update_cache_entry(entry, progress, kind)
	-- Always advance spinner on reports
	if kind == "report" then
		entry.spinner_idx = (entry.spinner_idx % #config.spinners) + 1
		entry.report_count = entry.report_count + 1
	end

	if progress.message then
		entry.message = progress.message
	end

	-- Extract numeric progress from the message
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

	-- Direct percentage/value fields
	if progress.percentage then
		entry.percentage = clamp(progress.percentage, 0, 100)
	end
	if type(progress.value) == "number" then
		entry.percentage = clamp(progress.value, 0, 100)
	end

	-- Fallback heuristic when nothing concrete is reported
	if kind == "report" and not progress.percentage and not done and not (type(progress.value) == "number") then
		local report_progress = clamp(entry.report_count * 5, 0, 50)
		local elapsed_ms = (vim.uv.hrtime() - entry.start_time) / 1e6
		local time_progress = clamp(elapsed_ms / 600, 0, 50)
		entry.percentage = clamp(report_progress + time_progress, 0, 99)
	end

	-- Force 100% on completion (overrides any half‑baked progress)
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

	if entry.total_work and entry.total_work > 0 then
		table.insert(components, string.format("%d/%d", entry.work_done, entry.total_work))
	elseif message ~= "" and not is_message_redundant(title, message) then
		table.insert(components, message)
	end

	table.insert(components, string.format("(%.0f%%)", entry.percentage))
	return table.concat(components, " ")
end

-- -----------------------------------------------------------------
-- Cleanup utilities
-- -----------------------------------------------------------------
local function schedule_cleanup(token, notification_id)
	local entry = progress_cache[token]
	if not entry then
		return
	end

	-- Cancel any existing timer for this entry
	if entry.timer then
		pcall(function()
			if not entry.timer:is_closing() then
				entry.timer:stop()
				entry.timer:close()
			end
		end)
	end

	-- Prefer uv timer for cancellability; fallback to vim.defer_fn
	local timer = vim.uv.new_timer()
	if timer then
		entry.timer = timer
		timer:start(
			config.cleanup_delay_ms,
			0,
			vim.schedule_wrap(function()
				if not timer:is_closing() then
					cleanup_notification(notification_id)
					progress_cache[token] = nil
					pcall(function()
						timer:close()
					end)
				end
			end)
		)
	else
		-- Fallback without cancellation support
		entry.timer = nil
		vim.defer_fn(
			vim.schedule_wrap(function()
				cleanup_notification(notification_id)
				progress_cache[token] = nil
			end),
			config.cleanup_delay_ms
		)
	end
end

-- Periodic purge of entries that never received an "end"
local function start_stale_purge()
	if stale_timer and not stale_timer:is_closing() then
		return
	end

	stale_timer = vim.uv.new_timer()
	if not stale_timer then
		return
	end

	stale_timer:start(
		60000, -- first run after 60s
		60000, -- repeat every 60s
		vim.schedule_wrap(function()
			local now = vim.uv.hrtime()
			local to_remove = {} -- collect tokens to remove safely
			for token, entry in pairs(progress_cache) do
				if entry.start_time then
					local age_sec = (now - entry.start_time) / 1e9
					if age_sec > 300 then -- 5 minutes stale
						to_remove[token] = true
					end
				end
			end
			for token, _ in pairs(to_remove) do
				local entry = progress_cache[token]
				if entry then
					local nid = get_notification_id(token)
					cleanup_notification(nid)
					if entry.timer and not entry.timer:is_closing() then
						pcall(function()
							entry.timer:stop()
							entry.timer:close()
						end)
					end
					progress_cache[token] = nil
					debug("Purged stale progress entry for token " .. tostring(token))
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

-- -----------------------------------------------------------------
-- Public API
-- -----------------------------------------------------------------
function M.cleanup()
	local tokens = vim.tbl_keys(progress_cache) -- snapshot keys
	for _, token in ipairs(tokens) do
		local entry = progress_cache[token]
		if entry then
			if entry.timer and not entry.timer:is_closing() then
				pcall(function()
					entry.timer:stop()
					entry.timer:close()
				end)
			end
			cleanup_notification(get_notification_id(token))
			progress_cache[token] = nil
		end
	end
	stop_stale_purge()
end

-- -----------------------------------------------------------------
-- LSP progress handler
-- -----------------------------------------------------------------
vim.lsp.handlers["$/progress"] = function(_, result, ctx)
	local ok, err = pcall(function()
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

		local entry = progress_cache[token]
		local nid = get_notification_id(token)

		if kind == "begin" then
			entry = handle_begin_progress(client, progress, token)
			if not entry then
				return
			end
		end

		if not entry then
			return
		end

		update_cache_entry(entry, progress, kind)

		local content = build_notification_content(entry, kind == "end")
		show_notification(content, nid, kind == "end")

		-- Optional user callback
		if type(config.on_progress) == "function" then
			pcall(function()
				config.on_progress(entry, kind == "end")
			end)
		end

		if kind == "end" then
			schedule_cleanup(token, nid)
		end
	end)

	if not ok then
		vim.notify("LSP progress handler error: " .. tostring(err), vim.log.levels.ERROR)
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
		local tokens_to_remove = {}
		for token, entry in pairs(progress_cache) do
			if entry.client_id == client_id then
				tokens_to_remove[token] = true
			end
		end
		for token, _ in pairs(tokens_to_remove) do
			local entry = progress_cache[token]
			if entry then
				if entry.timer and not entry.timer:is_closing() then
					pcall(function()
						entry.timer:stop()
						entry.timer:close()
					end)
				end
				cleanup_notification(get_notification_id(token))
				progress_cache[token] = nil
			end
		end
	end,
})

-- Start the stale‑entry purge timer when the module loads
start_stale_purge()

return M
