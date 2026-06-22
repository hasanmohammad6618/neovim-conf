-- LSP Progress Handler – Refactored & Fixed
local M = {}

local config = {
    spinners = { "◜ ", "◠ ", "◝ ", "◞ ", "◡ ", "◟ " },
    cleanup_delay_ms = 3100,
    notification_prefix = "lsp_progress_",
    notification_icon = "",
    notification_timeout = 1800,
    debug = false,
    on_progress = nil
}

function M.setup(opts)
    if not opts then return end
    for k, v in pairs(opts) do
        if config[k] ~= nil then config[k] = v end
    end
    if #config.spinners == 0 then
        config.spinners = { " " }
    end
end

local function clamp(v, lo, hi)
    return math.max(lo, math.min(v, hi))
end
local function debug(msg)
    if config.debug then vim.notify("[LSP Progress] " .. msg, vim.log.levels.DEBUG) end
end
local function get_key(id, token)
    return id .. ":" .. token
end
local function get_nid(id, token)
    return config.notification_prefix .. id .. "_" .. token
end

local function show_notif(content, id, is_end)
    local opts = { id = id, title = "LSP Progress", timeout = is_end and config.notification_timeout or 0 }
    if _G.Snacks and _G.Snacks.notifier then
        pcall(
            _G.Snacks.notifier.notify, content, "info",
            vim.tbl_extend("keep", opts, { icon = config.notification_icon })
        )
    else
        vim.notify(config.notification_icon .. " " .. content, vim.log.levels.INFO, opts)
    end
end

local function hide_notif(id)
    if _G.Snacks and _G.Snacks.notifier and _G.Snacks.notifier.hide then
        pcall(_G.Snacks.notifier.hide, id)
    end
end

local function parse_progress(msg)
    if not msg or msg == "" then return nil, nil end
    local patterns = {
        "^%s*(%d+)%s*/%s*(%d+)%s*$", "^%s*(%d+)%s+of%s+(%d+)%s*$", "^Processing file%s+(%d+)%s+of%s+(%d+)",
        "%f[%d](%d+)%s+items?%s+processed", "%f[%d](%d+)%s*/%s*(%d+)", "^(%d+)%s*%%", "^(%d+)%s*%%?%s*of%s+(%d+)"
    }
    for _, p in ipairs(patterns) do
        local d, t = msg:match(p)
        if d then
            local done = tonumber(d)
            local total = tonumber(t) or (p:find("%%") and 100 or nil)
            return done, total
        end
    end
    return nil, nil
end

local function is_redundant(title, msg)
    if not title or not msg or title == "" or msg == "" then return false end
    local t = title:lower():gsub("^%s+", ""):gsub("%s+$", "")
    local m = msg:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if t == m then return true end
    if m:sub(1, #t) == t then
        local rest = m:sub(#t + 1)
        return rest == "" or rest:match("^[%s%.!%-…]+$") ~= nil
    end
    return false
end

local function get_server_name(client)
    return client.name or (client.server_info and client.server_info.name)
        or (client.config and client.config.name) or ("LSP-" .. client.id)
end

local cache = {}
local stale_timer = nil

local function update_entry(client, token, progress, kind)
    local key = get_key(client.id, token)
    local entry = cache[key]

    if kind == "begin" then
        if entry and entry.timer then pcall(function() entry.timer:stop(); entry.timer:close() end) end
        entry = {
            spinner_idx = 1,
            title = progress.title or "",
            message = progress.message or "",
            percentage = 0,
            work_done = 0,
            total_work = nil,
            report_count = 0,
            start_time = vim.uv.hrtime(),
            client_id = client.id,
            server_name = get_server_name(client),
            timer = nil,
            token = token
        }
        cache[key] = entry
    end

    if not entry then return nil end

    if kind == "report" then
        entry.spinner_idx = (entry.spinner_idx % #config.spinners) + 1
        entry.report_count = entry.report_count + 1
    end
    if progress.message then entry.message = progress.message end

    local done, total = parse_progress(progress.message)
    if done then
        entry.work_done = done
        if total then entry.total_work = total end
        if entry.total_work and entry.total_work > 0 then
            entry.percentage = clamp((done / entry.total_work) * 100, 0, 100)
        end
    end
    if progress.percentage then entry.percentage = clamp(progress.percentage, 0, 100) end

    if kind == "report" and not progress.percentage and not done then
        local rp = clamp(entry.report_count * 2, 0, 40)
        local elapsed_sec = (vim.uv.hrtime() - entry.start_time) / 1e9
        entry.percentage = clamp(rp + clamp(elapsed_sec, 0, 40), 0, 95)
    end

    if kind == "end" then
        entry.spinner_idx = 1
        entry.percentage = 100
        if entry.total_work and entry.total_work > 0 then
            entry.work_done = entry.total_work

            -- FIX: Update the message text to reflect the final progress (e.g., 19/21 -> 21/21)
            if entry.message and entry.message ~= "" then
                local final_slash = string.format("%d/%d", entry.total_work, entry.total_work)
                local final_of = string.format("%d of %d", entry.total_work, entry.total_work)
                entry.message = entry.message:gsub("%d+%s*/%s*%d+", final_slash, 1)
                entry.message = entry.message:gsub("%d+%s+of%s+%d+", final_of, 1)
            end
        end
    end

    entry.percentage = clamp(entry.percentage, 0, 100)
    return entry
end

local function build_content(entry, is_end)
    local comps = { is_end and "✓ " or config.spinners[entry.spinner_idx] or " ", "[" .. entry.server_name .. "]" }
    if entry.title ~= "" then table.insert(comps, entry.title) end
    if entry.message ~= "" and not is_redundant(entry.title, entry.message) then
        table.insert(comps, entry.message)
    end
    if entry.total_work and entry.total_work > 0 then
        local d, t = parse_progress(entry.message)
        if not (d == entry.work_done and t == entry.total_work) then
            table.insert(comps, string.format("[%d/%d]", entry.work_done, entry.total_work))
        end
    end
    table.insert(comps, string.format("(%.0f%%)", entry.percentage))
    return table.concat(comps, " ")
end

local function schedule_cleanup(key, nid)
    local entry = cache[key]
    if not entry then return end
    if entry.timer then pcall(function() entry.timer:stop(); entry.timer:close() end) end

    local timer = vim.uv.new_timer()
    if timer then
        entry.timer = timer
        timer:start(
            config.cleanup_delay_ms, 0,
            vim.schedule_wrap(function ()
                if not timer:is_closing() then
                    hide_notif(nid)
                    cache[key] = nil
                    pcall(function ()
                        timer:close()
                    end)
                end
            end)
        )
    else
        vim.defer_fn(vim.schedule_wrap(function ()
                hide_notif(nid)
                cache[key] = nil
            end), config.cleanup_delay_ms)
    end
end

local function purge_stale()
    if stale_timer and not stale_timer:is_closing() then return end
    stale_timer = vim.uv.new_timer()
    if not stale_timer then return end

    stale_timer:start(
        60000, 60000,
        vim.schedule_wrap(function ()
            local now = vim.uv.hrtime()
            for key, entry in pairs(cache) do
                if entry.start_time and (now - entry.start_time) / 1e9 > 300 then
                    local nid = get_nid(entry.client_id, entry.token)
                    hide_notif(nid)
                    if entry.timer and not entry.timer:is_closing() then
                        pcall(function ()
                            entry.timer:stop()
                            entry.timer:close()
                        end)
                    end
                    cache[key] = nil
                    debug("Purged stale: " .. key)
                end
            end
        end)
    )
end

function M.cleanup()
    for _, entry in pairs(cache) do
        if entry.timer and not entry.timer:is_closing() then
            pcall(function ()
                entry.timer:stop()
                entry.timer:close()
            end)
        end
        hide_notif(get_nid(entry.client_id, entry.token))
    end
    cache = {}
    if stale_timer and not stale_timer:is_closing() then
        pcall(function ()
            stale_timer:stop()
            stale_timer:close()
        end)
        stale_timer = nil
    end
end

vim.lsp.handlers["$/progress"] = function (err, result, ctx)
    if err then
        debug("Error: " .. tostring(err))
        return
    end
    local ok, herr = pcall(function ()
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        if not client then return end

        local progress = result.value
        local token = result.token
        local kind = progress and progress.kind
        if not kind then return end

        local entry = update_entry(client, token, progress, kind)
        if not entry then return end

        local nid = get_nid(ctx.client_id, token)
        local is_end = kind == "end"
        show_notif(build_content(entry, is_end), nid, is_end)

        if type(config.on_progress) == "function" then
            pcall(config.on_progress, entry, is_end)
        end

        if is_end then schedule_cleanup(get_key(ctx.client_id, token), nid) end
    end)
    if not ok then vim.notify("LSP handler error: " .. tostring(herr), vim.log.levels.ERROR) end
end

local augroup = vim.api.nvim_create_augroup("LspProgressHandler", { clear = true })
vim.api.nvim_create_autocmd("VimLeavePre", { group = augroup, callback = M.cleanup })
vim.api.nvim_create_autocmd("LspDetach", {
    group = augroup,
    callback = function (args)
        local cid = args.data.client_id
        for key, entry in pairs(cache) do
            if entry.client_id == cid then
                if entry.timer and not entry.timer:is_closing() then
                    pcall(function ()
                        entry.timer:stop()
                        entry.timer:close()
                    end)
                end
                hide_notif(get_nid(entry.client_id, entry.token))
                cache[key] = nil
            end
        end
    end
})

purge_stale()
return M
