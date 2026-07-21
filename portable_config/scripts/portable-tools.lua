-- Centro de herramientas que conserva toda la información dentro de portable_config.

local mp = require('mp')
local utils = require('mp.utils')

local session_path = mp.command_native({'expand-path', '~~/state/last-session.json'})
local cache_path = mp.command_native({'expand-path', '~~/cache'})
local previous_session = nil

local function read_json(path)
    local file = io.open(path, 'r')
    if not file then return nil end
    local data = utils.parse_json(file:read('*a'))
    file:close()
    return data
end

local function write_json(path, data)
    local file = io.open(path, 'w')
    if file then file:write(utils.format_json(data)); file:close() end
end

local function walk(path, remove)
    local total, count = 0, 0
    for _, name in ipairs(utils.readdir(path, 'all') or {}) do
        local child = utils.join_path(path, name)
        local info = utils.file_info(child)
        if info and info.is_dir then
            local s, c = walk(child, remove); total, count = total + s, count + c
        elseif info then
            total, count = total + (info.size or 0), count + 1
            if remove then os.remove(child) end
        end
    end
    return total, count
end

local function cache_label()
    local bytes, count = walk(cache_path, false)
    return ('%.1f MB · %d archivos'):format(bytes / 1048576, count)
end

local function diagnostics()
    local params = mp.get_property_native('video-params') or {}
    local decoder = mp.get_property('hwdec-current', 'No')
    local fps = mp.get_property_number('container-fps', 0)
    local display = mp.get_property_number('display-fps', 0)
    local dropped = mp.get_property_number('vo-drop-frame-count', 0)
    local shaders = mp.get_property_native('glsl-shaders') or {}
    local menu = {
        type = 'portable-diagnostics', title = 'SYSTEM DIAGNOSTICS // 4KMPV', items = {
            {title = ('Vídeo: %dx%d · %.3f FPS'):format(params.w or 0, params.h or 0, fps)},
            {title = ('Pantalla: %.2f Hz'):format(display)},
            {title = 'Decodificación: ' .. decoder},
            {title = ('Shaders activos: %d'):format(#shaders)},
            {title = ('Cuadros perdidos: %d'):format(dropped)},
            {title = 'Caché: ' .. cache_label()},
            {title = 'Configuración: portable_config'},
        }
    }
    mp.commandv('script-message-to', 'uosc', 'open-menu', utils.format_json(menu))
end

local function clear_cache()
    local _, count = walk(cache_path, true)
    mp.osd_message(('Caché portable limpiada · %d archivos'):format(count), 3)
end

local function restore_session()
    if type(previous_session) ~= 'table' or #previous_session == 0 then
        mp.osd_message('No hay una sesión anterior para restaurar', 2); return
    end
    for index, path in ipairs(previous_session) do
        mp.commandv('loadfile', path, index == 1 and 'replace' or 'append-play')
    end
    mp.osd_message(('Sesión restaurada · %d elementos'):format(#previous_session), 3)
end

local function open_tools()
    local session_hint = type(previous_session) == 'table' and (#previous_session .. ' elementos') or 'No disponible'
    local menu = {type = 'portable-tools', title = 'SYSTEM CORE // PORTABLE', items = {
        {title = 'Diagnóstico', hint = 'GPU, FPS, shaders y fotogramas perdidos', value = 'script-message-to portable_tools diagnostics'},
        {title = 'Restaurar sesión anterior', hint = session_hint, value = 'script-message-to portable_tools restore-session'},
        {title = 'Limpiar caché de shaders', hint = cache_label(), value = 'script-message-to portable_tools clear-cache'},
        {title = 'Abrir configuración', hint = 'portable_config', value = 'script-binding uosc/open-config-directory'},
    }}
    mp.commandv('script-message-to', 'uosc', 'open-menu', utils.format_json(menu))
end

local function save_session()
    local paths = {}
    for _, item in ipairs(mp.get_property_native('playlist') or {}) do
        if item.filename and item.filename ~= '' then paths[#paths + 1] = item.filename end
    end
    if #paths > 0 then write_json(session_path, paths) end
end

previous_session = read_json(session_path)
mp.add_key_binding(nil, 'menu', open_tools)
mp.register_script_message('diagnostics', diagnostics)
mp.register_script_message('clear-cache', clear_cache)
mp.register_script_message('restore-session', restore_session)
mp.register_event('shutdown', save_session)
mp.add_timeout(0.35, function()
    mp.commandv('script-message-to', 'uosc', 'set-button', 'portable-tools', utils.format_json({
        icon = 'tune', command = 'script-binding portable-tools/menu', tooltip = 'SYSTEM CORE // PORTABLE',
        foreground = '555555', background = 'f4f4f4'
    }))
end)
