# FACC Public Remote API (Runtime)

This document describes the public remote API exposed by Factorio Admin Command Center (FACC) for other mods.

- Mod id: `factorio-admin-command-center`
- Interface names:
  - `facc`
  - `factorio_admin_command_center` (alias)
- Runtime stage only (`control.lua`)
- Current interface version: `1`

## 1. Compatibility contract

The API uses explicit interface versioning:

- Call `get_interface_version()` before using advanced behavior.
- Version `1` is the initial stable public contract.
- New actions may be added without changing the interface version.
- Breaking method/signature changes should increment interface version.

Recommended guard:

```lua
local iface = remote.interfaces["facc"]
if not (iface and iface.run_action) then
  return -- FACC not available
end
local version = remote.call("facc", "get_interface_version")
if version < 1 then
  return
end
```

## 2. Discovery and health checks

### Interface discovery

```lua
local function find_facc_interface_name()
  if remote.interfaces["facc"] then return "facc" end
  if remote.interfaces["factorio_admin_command_center"] then
    return "factorio_admin_command_center"
  end
  return nil
end
```

### Health check

```lua
local name = find_facc_interface_name()
if name then
  local pong = remote.call(name, "ping")
  -- pong = { ok = true, pong = true, interface = "facc", version = 1 }
end
```

## 3. Method reference

All methods are exposed on both interface names.

### `get_interface_version() -> number`

Returns API interface version (`1` currently).

### `get_mod_version() -> string`

Returns installed FACC mod version from `script.active_mods`.

### `get_capabilities() -> table`

Returns runtime capability flags:

```lua
{
  quality = boolean,
  space_age = boolean,
  planets = {"nauvis", "vulcanus", "fulgora", "gleba", "aquilo", ...}
}
```

Notes:

- Base planet order starts with `nauvis`, `vulcanus`, `fulgora`, `gleba`, `aquilo`.
- Additional planets from other mods are appended.

### `ping() -> table`

Returns:

```lua
{ ok = true, pong = true, interface = "facc", version = 1 }
```

### `list_actions() -> table`

Returns current actions grouped by kind:

```lua
{
  run = {...},
  toggle = {...},
  value = {...},
  simple = {...}
}
```

### `has_action(action_name) -> boolean`

Returns whether action is currently exposed.

Use this for optional actions (for example Quality-only actions).

### `get_action_info(action_name) -> table|nil`

Returns metadata for one action:

```lua
{
  kind = "run"|"toggle"|"value"|"simple",
  requires_player = boolean,
  schema = table|nil
}
```

Returns `nil` when action does not exist.

### `run_action(action_name, player_index, args_table) -> table`

Generic execution entry point.

Common return shape:

```lua
{
  ok = boolean,
  error = "string-or-nil",
  action = "action-name"
}
```

For toggle actions, return includes `enabled`.

`args_table` is optional; non-table values are treated as `{}`.

### `set_toggle(action_name, player_index, enabled) -> table`

Convenience wrapper for toggle actions.

Equivalent to:

```lua
run_action(action_name, player_index, { enabled = enabled })
```

### `set_value(action_name, player_index, value, old_value) -> table`

Convenience wrapper for value actions.

Equivalent to:

```lua
run_action(action_name, player_index, { value = value, old_value = old_value })
```

### `run_batch(calls) -> table`

Executes multiple actions in order.

Input:

```lua
{
  { action = "facc_cheat_mode", player_index = 1, args = { enabled = true } },
  { action = "facc_remove_cliffs", player_index = 1, args = { radius = 64 } }
}
```

Output:

```lua
{
  ok = true,
  results = {
    { ok = true, action = "..." },
    { ok = false, error = "...", action = "..." }
  }
}
```

Notes:

- Not transactional. Failed calls do not roll back successful ones.
- Invalid item types return `{ ok = false, error = "invalid-call-item", index = i }`.

### `toggle_main_gui(player_index) -> table`

Toggles FACC main GUI for the player.

### `toggle_console_gui(player_index) -> table`

Toggles FACC console GUI for the player.

### `toggle_teleport_gui(player_index) -> table`

Toggles FACC Fast Teleport Manager GUI for the player.

### `refresh_stats_hud(player_index) -> table`

Forces an immediate refresh of the FACC Stats HUD for the player.

### `get_stats_hud_snapshot(player_index) -> table`

Returns the current Stats HUD snapshot:

```lua
{
  ok = true,
  snapshot = {
    enabled = boolean,
    settings = {
      enabled = boolean,
      single_line = boolean,
      adjust_for_fps_ups = boolean,
      adjust_for_clock = boolean,
      show_coordinates = boolean,
      show_distance = boolean,
      show_daytime = boolean,
      show_playtime = boolean,
      show_playtime_days = boolean,
      show_evolution = boolean,
      show_pollution = boolean,
      show_research_eta = boolean,
      show_movement_speed = boolean,
      show_player_max_speed = boolean,
      show_vehicle_max_speed = boolean,
      show_jetpack_fuel = boolean,
      show_handcraft_timer = boolean,
      offset_preset_one_info = boolean,
      offset_preset_two_infos = boolean,
      offset_preset_three_infos = boolean,
      distance_origin_x = number,
      distance_origin_y = number
    },
    line_count = number,
    lines = { LocalisedString, ... },
    position = { x = number, y = number, surface = string }
  }
}
```

Current HUD line order (when enabled): `Coordinates/Distance`, `Day/Time`, `Playtime`, `Evolution`, `Pollution`, `Research ETA`, `Movement Speed`, `Handcraft Timer`.

Addon-equivalent sensors from the ASD package are included:
- StatsGui-CoordinatesDistance
- StatsGui-HandcraftTimer
- StatsGui-MovementSpeed (including optional Jetpack fuel line when Jetpack mod is active)

### `get_stats_hud_capabilities() -> table`

Returns HUD capability metadata for external mods:

```lua
{
  ok = true,
  order = { "coordinates_distance", "daytime", "playtime", "evolution", "pollution", "research_eta", "movement_speed", "handcraft_timer" },
  sensors = {
    coordinates_distance = true,
    daytime = true,
    playtime = true,
    evolution = true,
    pollution = true,
    research_eta = true,
    movement_speed = true,
    movement_speed_player_max = true,
    movement_speed_vehicle_max = true,
    movement_speed_jetpack_fuel = boolean,
    handcraft_timer = true
  },
  source_mods = { "StatsGui", "StatsGui-CoordinatesDistance", "StatsGui-HandcraftTimer", "StatsGui-MovementSpeed" }
}
```

### `list_saved_teleports(player_index) -> table`

Returns the player's saved custom teleport points:

```lua
{
  ok = true,
  points = {
    {
      id = number,
      name = string,
      position = { x = number, y = number },
      surface_index = number,
      surface_name = string,
      caption = "Name (X,Y)"
    }
  }
}
```

### `save_current_teleport(player_index, name) -> table`

Saves current player location as a custom point.

### `rename_saved_teleport(player_index, point_id, new_name) -> table`

Renames one saved custom point by id.

### `delete_saved_teleport(player_index, point_id) -> table`

Deletes one saved custom point by id.

### `teleport_to_saved(player_index, point_id) -> table`

Teleports player to one saved custom point by id.

### `list_tag_teleports(player_index) -> table`

Lists visible map tags available as teleport destinations.

### `teleport_to_tag(player_index, tag_number) -> table`

Teleports player to one map tag by tag number.

### `hide_tag_teleport(player_index, tag_number) -> table`

Hides one map tag from Fast Teleport picker by tag number.

### `unhide_tag_teleports(player_index) -> table`

Restores all hidden map tags in Fast Teleport picker.

## 4. Action execution rules

### 4.1 Player validation

Most actions require a valid `player_index`.

Validation errors:

- `invalid-player-index`
- `player-not-found`

### 4.2 Actions that do not require player

These actions may be called with `player_index = nil`:

- `facc_auto_clean_pollution`
- `facc_auto_instant_research`
- `facc_instant_blueprint_building`
- `facc_instant_deconstruction`
- `facc_instant_upgrading`
- `facc_instant_rail_planner`
- `facc_auto_clean_pollution_interval`
- `facc_auto_instant_research_interval`

### 4.3 Boolean conversion for toggle actions

Toggle `enabled` values are converted as follows:

- `boolean`: unchanged
- `number`: `0` is false, any other is true
- `string`: true for `"1"`, `"true"`, `"on"`, `"yes"` (case-insensitive)
- anything else: false

### 4.4 Numeric conversion and defaults

Numeric values are parsed with `tonumber`; if parsing fails, the action fallback/default is used.

### 4.5 Result semantics

`ok = true` means the action call did not raise a Lua runtime error.

Important:

- Some underlying actions may print a message and return early for game-state reasons (permission checks, unsupported property, missing DLC, etc.).
- In those cases `ok` may still be `true`.
- Use your own pre-checks (`get_capabilities`, `has_action`, player/force checks) when you need strict deterministic behavior.

## 5. Capability-dependent behavior

### Quality mod

When `script.active_mods["quality"]` is active, these extra run actions are exposed:

- `facc_convert_inventory`
- `facc_upgrade_blueprints`
- `facc_convert_to_legendary`

If Quality is not active, these actions are absent from `list_actions()` and `has_action()` returns false.

### Space Age and surface actions

Space-related actions may still exist but can be no-op with in-game feedback depending on runtime state.

Use `get_capabilities().space_age` before calling Space Age specific behavior in strict integrations.

## 6. Complete action reference

### 6.1 Run actions

| Action | Player required | Args | Notes |
|---|---|---|---|
| `facc_toggle_editor` | yes | none | Toggle editor mode command path. |
| `facc_delete_ownerless` | yes | none | Deletes ownerless characters. |
| `facc_build_all_ghosts` | yes | none | Builds all reachable ghosts. |
| `facc_remove_cliffs` | yes | `radius:number` default `50` | Area action. |
| `facc_remove_nests` | yes | `radius:number` default `50` | Area action. |
| `facc_reveal_map` | yes | `radius:number` default `150` | Charts nearby area. |
| `facc_hide_map` | yes | none | Re-hides charted area logic path. |
| `facc_remove_decon` | yes | none | Removes deconstruction marks. |
| `facc_remove_pollution` | yes | none | Clears pollution in player area/surface logic. |
| `facc_repair_rebuild` | yes | none | Repair/rebuild helper action. |
| `facc_recharge_energy` | yes | none | Recharges electric entities (sync or background based on settings). |
| `facc_ammo_turrets` | yes | none | Refills turrets. |
| `facc_increase_resources` | yes | none | Resource increase action. |
| `facc_unlock_recipes` | yes | none | Unlocks all recipes for force. |
| `facc_unlock_technologies` | yes | none | Unlocks all technologies for force. |
| `facc_insert_coins` | yes | none | Inserts map-specific coin rewards. |
| `facc_remove_ground_items` | yes | none | Removes dropped item entities. |
| `facc_generate_planet_surfaces` | yes | none | Generates available planet surfaces. |
| `facc_create_full_armor` | yes | none | Gives full armor/equipment set. |
| `facc_add_robots` | yes | none | Adds logistic/construction bots. |
| `facc_fill_platform_thrusters` | yes | none | Space platform thruster refuel helper. |
| `facc_regenerate_resources` | yes | none | Regenerates resource patches. |
| `facc_high_infinite_research_levels` | yes | none | Sets infinite research to level 100. |
| `facc_add_infinite_research_levels` | yes | none | Adds +100 to current infinite research levels. |
| `facc_ghost_on_death` | yes | none | Enables ghost-on-death behavior (research-aware). |
| `facc_indestructible_builds_permanent` | yes | none | Permanent indestructible entities mode. |
| `facc_non_minable_permanent` | yes | none | Permanent non-minable entities mode. |
| `facc_convert_inventory` | yes | none | Quality-only action. |
| `facc_upgrade_blueprints` | yes | none | Quality-only action. |
| `facc_convert_to_legendary` | yes | `radius:number` default `75` | Quality-only area conversion. |

### 6.2 Toggle actions

| Action | Player required | Args | Notes |
|---|---|---|---|
| `facc_cheat_mode` | yes | `enabled` | Force cheat mode toggle. |
| `facc_always_day` | yes | `enabled` | Surface daytime freeze logic. |
| `facc_disable_pollution` | yes | `enabled` | Pollution settings toggle. |
| `facc_disable_friendly_fire` | yes | `enabled` | Force friendly-fire toggle. |
| `facc_indestructible_builds` | yes | `enabled` | Live indestructible build toggle. |
| `facc_peaceful_mode` | yes | `enabled` | Force peaceful mode. |
| `facc_enemy_expansion` | yes | `enabled` | Enemy expansion toggle. |
| `facc_toggle_minable` | yes | `enabled` | Minable entities toggle. |
| `facc_toggle_trains` | yes | `enabled` | Train manual/automatic behavior toggle. |
| `facc_ghost_mode` | yes | `enabled` | Character ghost mode toggle. |
| `facc_invincible_player` | yes | `enabled` | Character invincibility toggle. |
| `facc_repair_mined_item` | yes | `enabled` | Repair mined item behavior toggle. |
| `facc_instant_request` | yes | `enabled` | Instant request logistic behavior toggle. |
| `facc_instant_trash` | yes | `enabled` | Instant trash logistic behavior toggle. |
| `facc_surface_freeze_daytime` | yes | `enabled` | Per-surface freeze daytime. |
| `facc_surface_peaceful_mode` | yes | `enabled` | Per-surface peaceful mode. |
| `facc_surface_no_enemies_mode` | yes | `enabled` | Per-surface no enemies mode. |
| `facc_auto_clean_pollution` | no | `enabled` | Also executes immediate clean pass for all players. |
| `facc_auto_instant_research` | no | `enabled` | Also executes immediate instant-research pass for all players. |
| `facc_instant_blueprint_building` | no | `enabled` | State switch used by event pipeline. |
| `facc_instant_deconstruction` | no | `enabled` | State switch used by event pipeline. |
| `facc_instant_upgrading` | no | `enabled` | State switch used by event pipeline. |
| `facc_instant_rail_planner` | no | `enabled` | State switch used by event pipeline. |

### 6.3 Value actions

| Action | Player required | Args | Notes |
|---|---|---|---|
| `facc_set_game_speed` | yes | `value:number` | Sets game speed. |
| `facc_set_mining_speed` | yes | `value:number` | Mining speed bonus value. |
| `facc_run_faster` | yes | `value:number` | Running speed bonus value. |
| `facc_set_platform_distance` | yes | `value:number` | Clamped to `[0..1]` in module. |
| `facc_set_crafting_speed` | yes | `value:number`, `old_value?:number` | Delta style slider action. |
| `facc_increase_robot_speed` | yes | `value:number`, `old_value?:number` | Delta style slider action. |
| `facc_ammo_damage_boost` | yes | `value:number`, `old_value?:number` | Delta style slider action. |
| `facc_turret_damage_boost` | yes | `value:number`, `old_value?:number` | Delta style slider action. |
| `facc_build_distance` | yes | `value:number`, `old_value?:number` | Adds/removes build distance bonus delta. |
| `facc_reach_distance` | yes | `value:number`, `old_value?:number` | Adds/removes reach distance bonus delta. |
| `facc_resource_reach_distance` | yes | `value:number`, `old_value?:number` | Adds/removes resource reach bonus delta. |
| `facc_item_drop_distance` | yes | `value:number`, `old_value?:number` | Adds/removes drop distance bonus delta. |
| `facc_item_pickup_distance` | yes | `value:number`, `old_value?:number` | Adds/removes pickup distance bonus delta. |
| `facc_loot_pickup_distance` | yes | `value:number`, `old_value?:number` | Adds/removes loot pickup distance bonus delta. |
| `facc_surface_daytime` | yes | `value:number` | Accepts `[0..1]` or `[0..100]`; normalized and clamped. |
| `facc_surface_pressure` | yes | `value:number` | Surface property setter path. |
| `facc_surface_magnetic_field` | yes | `value:number` | Surface property setter path. |
| `facc_surface_gravity` | yes | `value:number` | Surface property setter path. |
| `facc_auto_clean_pollution_interval` | no | `value:number` | Clamped to `1..300` seconds. |
| `facc_auto_instant_research_interval` | no | `value:number` | Clamped to `1..300` seconds. |

### 6.4 Simple actions

| Action | Player required | Args | Notes |
|---|---|---|---|
| `facc_surface_daytime_midday` | yes | none | Shortcut for `daytime = 0.5`. |
| `facc_surface_daytime_midnight` | yes | none | Shortcut for `daytime = 0`. |
| `facc_teleport_to_planet` | yes | `planet_name:string` or `value:string` | Teleport helper (supports modded planets when available). |
| `facc_console_exec` | yes | `code:string` | Executes Lua console snippet through FACC console module. |
| `facc_console` | yes | none | Toggles FACC console GUI. |
| `facc_toggle_main_gui` | yes | none | Toggles FACC main window. |
| `facc_refresh_main_gui` | yes | none | Refreshes currently open main GUI. |
| `facc_refresh_stats_hud` | yes | none | Forces a Stats HUD refresh for the player. |
| `facc_tp_open` | yes | none | Toggles Fast Teleport Manager GUI. |

## 7. Error catalog

Known explicit errors from API wrapper:

- `missing-action`
- `unknown-action`
- `invalid-player-index`
- `player-not-found`
- `missing-planet-name`
- `missing-code`
- `invalid-calls-table`
- `invalid-call-item`
- `not-allowed`
- `saved-point-not-found`
- `name-empty`
- `tag-not-found`
- `surface-missing`
- `teleport-failed`

Additional errors can be raw Lua error strings from wrapped calls (`pcall` capture).

## 8. Recommended integration pattern

Use this order:

1. Detect interface (`facc` then alias).
2. Check `get_interface_version()`.
3. Cache `get_capabilities()`.
4. Gate optional actions with `has_action()`.
5. Use `get_action_info()` for schema and player requirement.
6. Execute with `run_action`/`set_toggle`/`set_value`.
7. Handle `{ ok=false, error=... }` and log details.

## 9. Practical examples

See:

- `docs/examples/remote_client_example.lua`

## 10. API changelog

### Interface v1

- Public interfaces `facc` and `factorio_admin_command_center`.
- Generic action executor (`run_action`) with grouped action model.
- Convenience wrappers (`set_toggle`, `set_value`, `run_batch`).
- GUI helpers (`toggle_main_gui`, `toggle_console_gui`).
- Runtime capability and action introspection methods.
