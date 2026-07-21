-- Gestor portable de perfiles Anime4K para uosc.
-- Mantiene una única definición de cada cadena de shaders, estado visible,
-- selección automática por resolución y protección ante fotogramas perdidos.

local mp = require('mp')
local utils = require('mp.utils')

local profiles = {
    A = table.concat({
        '~~/shaders/Anime4K_Clamp_Highlights.glsl',
        '~~/shaders/Anime4K_Restore_CNN_VL.glsl',
        '~~/shaders/Anime4K_Upscale_CNN_x2_VL.glsl',
        '~~/shaders/Anime4K_AutoDownscalePre_x2.glsl',
        '~~/shaders/Anime4K_AutoDownscalePre_x4.glsl',
        '~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl',
    }, ';'),
    B = table.concat({
        '~~/shaders/Anime4K_Clamp_Highlights.glsl',
        '~~/shaders/Anime4K_Restore_CNN_Soft_VL.glsl',
        '~~/shaders/Anime4K_Upscale_CNN_x2_VL.glsl',
        '~~/shaders/Anime4K_AutoDownscalePre_x2.glsl',
        '~~/shaders/Anime4K_AutoDownscalePre_x4.glsl',
        '~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl',
    }, ';'),
    AA = table.concat({
        '~~/shaders/Anime4K_Clamp_Highlights.glsl',
        '~~/shaders/Anime4K_Restore_CNN_VL.glsl',
        '~~/shaders/Anime4K_Upscale_CNN_x2_VL.glsl',
        '~~/shaders/Anime4K_Restore_CNN_M.glsl',
        '~~/shaders/Anime4K_AutoDownscalePre_x2.glsl',
        '~~/shaders/Anime4K_AutoDownscalePre_x4.glsl',
        '~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl',
    }, ';'),
    LITE = table.concat({
        '~~/shaders/Anime4K_Clamp_Highlights.glsl',
        '~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl',
    }, ';'),
}

local labels = {A = 'Modo A', B = 'Modo B', AA = 'Modo AA', LITE = 'Ligero', OFF = 'Desactivado'}
local state_path = mp.command_native({'expand-path', '~~/state/anime4k.json'})
local state = {mode = 'OFF', manual_mode = 'A', automatic = false, safeguard = true}
local last_dropped = 0
local cycle_order = {'OFF', 'A', 'B', 'AA', 'LITE'}

local function load_state()
    local file = io.open(state_path, 'r')
    if not file then return end
    local saved = utils.parse_json(file:read('*a'))
    file:close()
    if type(saved) ~= 'table' then return end
    state.manual_mode = profiles[saved.manual_mode] and saved.manual_mode or state.manual_mode
    state.automatic = saved.automatic == true
    state.safeguard = saved.safeguard ~= false
end

local function save_state()
    local file = io.open(state_path, 'w')
    if not file then return end
    file:write(utils.format_json({manual_mode = state.manual_mode, automatic = state.automatic, safeguard = state.safeguard}))
    file:close()
end

local function send_button()
    local badge = state.automatic and ('AUTO·' .. state.mode) or (state.mode ~= 'OFF' and state.mode or nil)
    local data = {
        icon = 'auto_awesome',
        active = state.mode ~= 'OFF',
        badge = badge,
        command = 'script-message-to anime4k_manager cycle',
        tooltip = 'NEURAL UPSCALE // ' .. (state.automatic and 'AUTO / ' or '') .. labels[state.mode] .. ' // CLIC: CAMBIAR',
		foreground = 'd8c935',
		background = 'f4f4f4',
    }
    mp.commandv('script-message-to', 'uosc', 'set-button', 'anime4k', utils.format_json(data))
end

local function set_profile(mode, quiet)
    mode = string.upper(mode or 'OFF')
    if mode == 'OFF' then
        mp.commandv('change-list', 'glsl-shaders', 'clr', '')
    elseif profiles[mode] then
        mp.commandv('change-list', 'glsl-shaders', 'set', profiles[mode])
    else
        return
    end
    state.mode = mode
    if not quiet then mp.osd_message('Anime4K · ' .. labels[mode], 2) end
    send_button()
end

local function set_manual(mode)
    mode = string.upper(mode or 'OFF')
    state.automatic = false
    if profiles[mode] then state.manual_mode = mode end
    set_profile(mode)
    save_state()
end

local function apply_automatic()
    if not state.automatic then return end
    local height = mp.get_property_number('video-params/h', 0)
    if height <= 0 then return end
    if height <= 720 then set_profile('B', true)
    elseif height <= 1080 then set_profile('A', true)
    else set_profile('OFF', true) end
    mp.osd_message(('Anime4K automático · %dp → %s'):format(height, labels[state.mode]), 2)
end

local function toggle_auto()
    state.automatic = not state.automatic
    if state.automatic then apply_automatic() else set_profile(state.manual_mode) end
    save_state()
    send_button()
end

local function cycle_profile()
    local current = state.mode
    state.automatic = false
    local next_mode = 'OFF'
    for index, mode in ipairs(cycle_order) do
        if mode == current then
            next_mode = cycle_order[(index % #cycle_order) + 1]
            break
        end
    end
    if profiles[next_mode] then state.manual_mode = next_mode end
    set_profile(next_mode)
    save_state()
end

local function toggle_safeguard()
    state.safeguard = not state.safeguard
    save_state()
    mp.osd_message('Protección de rendimiento · ' .. (state.safeguard and 'Activada' or 'Desactivada'), 2)
end

local function open_menu()
    local function item(title, hint, value, active)
        return {title = title, hint = hint, value = value, active = active}
    end
    local menu = {
        type = 'anime4k-profiles', title = 'NEURAL UPSCALE // ANIME4K',
        items = {
            item('Automático', '720p: B · 1080p: A · 1440p/4K: original', 'script-message-to anime4k_manager toggle-auto', state.automatic),
            {separator = true},
            item('Modo A', '1080p · restauración y escalado x2', 'script-message-to anime4k_manager set A', not state.automatic and state.mode == 'A'),
            item('Modo B', '720p · restauración suave y escalado x2', 'script-message-to anime4k_manager set B', not state.automatic and state.mode == 'B'),
            item('Modo AA', 'Doble restauración · máxima calidad', 'script-message-to anime4k_manager set AA', not state.automatic and state.mode == 'AA'),
            item('Modo ligero', 'GPU integrada o equipos portátiles', 'script-message-to anime4k_manager set LITE', not state.automatic and state.mode == 'LITE'),
            item('Desactivar', 'Imagen original', 'script-message-to anime4k_manager set OFF', not state.automatic and state.mode == 'OFF'),
            {separator = true},
            item('Protección de rendimiento', state.safeguard and 'Activada · reduce a Ligero si detecta caídas' or 'Desactivada', 'script-message-to anime4k_manager toggle-safeguard', state.safeguard),
        },
    }
    mp.commandv('script-message-to', 'uosc', 'open-menu', utils.format_json(menu))
end

local function performance_check()
    if not state.safeguard or state.mode == 'OFF' or state.mode == 'LITE' then
        last_dropped = mp.get_property_number('vo-drop-frame-count', 0)
        return
    end
    local dropped = mp.get_property_number('vo-drop-frame-count', 0)
    local delta = math.max(0, dropped - last_dropped)
    last_dropped = dropped
    if delta >= 12 then
        state.automatic = false
        state.manual_mode = 'LITE'
        set_profile('LITE', true)
        save_state()
        mp.osd_message(('Anime4K · %d cuadros perdidos\nCambiado al perfil Ligero'):format(delta), 4)
    end
end

load_state()
mp.add_key_binding(nil, 'menu', open_menu)
mp.register_script_message('set', set_manual)
mp.register_script_message('cycle', cycle_profile)
mp.register_script_message('toggle-auto', toggle_auto)
mp.register_script_message('toggle-safeguard', toggle_safeguard)
mp.register_event('file-loaded', function()
    last_dropped = mp.get_property_number('vo-drop-frame-count', 0)
    if state.automatic then apply_automatic() else set_profile(state.manual_mode, true) end
end)
mp.add_periodic_timer(5, performance_check)
mp.add_timeout(0.3, send_button)
