-- OBS frontend hotkeys -> obs-browser's documented javascript_event proc.
-- This needs no socket server and does not require Browser Source Interact.

obs = obslua

local source_name = "ETS Steering Widget"
local debug_enabled = false
local left_hotkey_id = nil
local right_hotkey_id = nil
local left_pressed = false
local right_pressed = false

-- OBS hotkey names are global, not scoped to this Lua file. Keep these stable
-- for persistence and specific enough not to collide with another script.
local LEFT_HOTKEY_NAME = "com.ets-steering-widget.keyboard.left.v1"
local RIGHT_HOTKEY_NAME = "com.ets-steering-widget.keyboard.right.v1"

local function hotkey_is_registered(id)
  return id ~= nil and (obs.OBS_INVALID_HOTKEY_ID == nil or id ~= obs.OBS_INVALID_HOTKEY_ID)
end

local function send_steer(direction, pressed, log_callback)
  if log_callback and debug_enabled then
    obs.script_log(
      obs.LOG_INFO,
      string.format("Keyboard bridge: hotkey callback direction=%d, pressed=%s, source=%s", direction, tostring(pressed), source_name)
    )
  end

  local source = obs.obs_get_source_by_name(source_name)
  if source == nil then
    if log_callback then
      obs.script_log(obs.LOG_WARNING, "Keyboard bridge: Browser Source not found: " .. source_name)
    end
    return false
  end

  local calldata = obs.calldata_create()
  obs.calldata_set_string(calldata, "eventName", "etsSteeringKeyboard")
  obs.calldata_set_string(
    calldata,
    "jsonString",
    string.format('{"direction":%d,"pressed":%s}', direction, pressed and "true" or "false")
  )
  local sent = obs.proc_handler_call(obs.obs_source_get_proc_handler(source), "javascript_event", calldata)
  obs.calldata_destroy(calldata)
  obs.obs_source_release(source)

  if not sent and log_callback then
    obs.script_log(obs.LOG_WARNING, "Keyboard bridge: Browser Source does not provide javascript_event: " .. source_name)
  end
  return sent
end

local function on_left_hotkey(pressed)
  left_pressed = pressed
  send_steer(-1, pressed, true)
end

local function on_right_hotkey(pressed)
  right_pressed = pressed
  send_steer(1, pressed, true)
end

local function sync_keyboard_state()
  -- CEF may not have created the page when a hotkey fires; replaying state also
  -- recovers a release that occurred while the Browser Source was unavailable.
  send_steer(-1, left_pressed, false)
  send_steer(1, right_pressed, false)
end

function script_description()
  return "Sends OBS global left/right hotkeys to an ETS Steering Browser Source without using Interact."
end

function script_properties()
  local props = obs.obs_properties_create()
  local source_list = obs.obs_properties_add_list(
    props,
    "source_name",
    "Browser Source",
    obs.OBS_COMBO_TYPE_LIST,
    obs.OBS_COMBO_FORMAT_STRING
  )
  local sources = obs.obs_enum_sources()
  if sources ~= nil then
    for _, source in ipairs(sources) do
      if obs.obs_source_get_id(source) == "browser_source" then
        local name = obs.obs_source_get_name(source)
        obs.obs_property_list_add_string(source_list, name, name)
      end
    end
    obs.source_list_release(sources)
  end
  obs.obs_properties_add_bool(props, "debug", "Debug: логировать нажатия клавиш")
  return props
end

function script_defaults(settings)
  obs.obs_data_set_default_string(settings, "source_name", source_name)
  obs.obs_data_set_default_bool(settings, "debug", false)
end

function script_update(settings)
  source_name = obs.obs_data_get_string(settings, "source_name")
  debug_enabled = obs.obs_data_get_bool(settings, "debug")
  if debug_enabled then
    obs.script_log(obs.LOG_INFO, "Keyboard bridge: debug enabled; source=" .. source_name)
  end
end

function script_load(settings)
  -- OBS persists script property values separately; initialize local state now
  -- instead of relying on a later script_update callback.
  script_update(settings)

  if type(obs.obs_hotkey_register_frontend) ~= "function" then
    obs.script_log(obs.LOG_ERROR, "Keyboard bridge: this OBS Lua API does not expose obs_hotkey_register_frontend; assigned OBS hotkeys are unavailable")
    return
  end

  -- This must run in script_load. Registering later can miss OBS's initial
  -- hotkey configuration load and leaves the Settings > Hotkeys entry stale.
  left_hotkey_id = obs.obs_hotkey_register_frontend(LEFT_HOTKEY_NAME, "ETS Steering: hold left", on_left_hotkey)
  right_hotkey_id = obs.obs_hotkey_register_frontend(RIGHT_HOTKEY_NAME, "ETS Steering: hold right", on_right_hotkey)

  if not hotkey_is_registered(left_hotkey_id) or not hotkey_is_registered(right_hotkey_id) then
    obs.script_log(obs.LOG_ERROR, "Keyboard bridge: failed to register one or both frontend hotkeys")
  elseif debug_enabled then
    obs.script_log(obs.LOG_INFO, "Keyboard bridge: frontend hotkeys registered; assign them in Settings > Hotkeys")
  end

  local left_hotkey = obs.obs_data_get_array(settings, "left_hotkey")
  local right_hotkey = obs.obs_data_get_array(settings, "right_hotkey")
  if hotkey_is_registered(left_hotkey_id) then
    obs.obs_hotkey_load(left_hotkey_id, left_hotkey)
  end
  if hotkey_is_registered(right_hotkey_id) then
    obs.obs_hotkey_load(right_hotkey_id, right_hotkey)
  end
  if debug_enabled and obs.obs_data_array_count(left_hotkey) == 0 and obs.obs_data_array_count(right_hotkey) == 0 then
    obs.script_log(obs.LOG_WARNING, "Keyboard bridge: no saved hotkey bindings; assign ETS Steering: hold left/right in Settings > Hotkeys, then click Apply")
  end
  obs.obs_data_array_release(left_hotkey)
  obs.obs_data_array_release(right_hotkey)

  if hotkey_is_registered(left_hotkey_id) or hotkey_is_registered(right_hotkey_id) then
    obs.timer_add(sync_keyboard_state, 250)
  end
end

function script_unload()
  obs.timer_remove(sync_keyboard_state)
  -- Lua callbacks must be unregistered explicitly. Otherwise a reload can
  -- leave the old global hotkey name registered without this script's callback.
  if type(obs.obs_hotkey_unregister) == "function" then
    if hotkey_is_registered(left_hotkey_id) then
      obs.obs_hotkey_unregister(left_hotkey_id)
    end
    if hotkey_is_registered(right_hotkey_id) then
      obs.obs_hotkey_unregister(right_hotkey_id)
    end
  end
end

function script_save(settings)
  if hotkey_is_registered(left_hotkey_id) then
    local left_hotkey = obs.obs_hotkey_save(left_hotkey_id)
    obs.obs_data_set_array(settings, "left_hotkey", left_hotkey)
    obs.obs_data_array_release(left_hotkey)
  end
  if hotkey_is_registered(right_hotkey_id) then
    local right_hotkey = obs.obs_hotkey_save(right_hotkey_id)
    obs.obs_data_set_array(settings, "right_hotkey", right_hotkey)
    obs.obs_data_array_release(right_hotkey)
  end
end
