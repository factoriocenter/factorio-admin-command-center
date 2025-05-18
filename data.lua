-- data.lua
-- Registers control inputs, toolbar shortcuts, the Legendary Upgrader tool,
-- and—only if enabled—a dedicated “Cheat Tools” crafting tab with its recipes.

--------------------------------------------------------------------------------
-- 0) Read startup setting to show/hide the Cheat Tools tab
--------------------------------------------------------------------------------
local show_cheat_tab = settings.startup["facc-show-cheat-tab"].value

--------------------------------------------------------------------------------
-- 1) If enabled, define new item-group and subgroup for Cheat Tools
--------------------------------------------------------------------------------
if show_cheat_tab then
  data:extend({
    {
      type           = "item-group",
      name           = "facc-cheat-tools",
      order          = "z[facc-cheat-tools]",
      icon           = "__core__/graphics/icons/category/unsorted.png",
      icon_size      = 128,
      localised_name = {"item-group-name.facc-cheat-tools"}
    },
    {
      type  = "item-subgroup",
      name  = "facc-cheat-recipes",
      group = "facc-cheat-tools",
      order = "a"
    }
  })
end

--------------------------------------------------------------------------------
-- 2) Custom input: Toggle Admin GUI (Ctrl + .)
--------------------------------------------------------------------------------
data:extend({
  {
    type                  = "custom-input",
    name                  = "facc_toggle_gui",
    key_sequence          = "CONTROL + PERIOD",
    consuming             = "game-only",
    localised_name        = {"controls.facc_toggle_gui"},
    localised_description = {"controls.facc_toggle_gui_description"}
  }
})

--------------------------------------------------------------------------------
-- 3) Toolbar shortcut: Toggle Admin GUI
--------------------------------------------------------------------------------
data:extend({
  {
    type                     = "shortcut",
    name                     = "facc_toggle_gui_shortcut",
    localised_name           = {"controls.facc_toggle_gui"},
    localised_description    = {"controls.facc_toggle_gui_description"},
    action                   = "lua",
    associated_control_input = "facc_toggle_gui",
    icon                     = "__factorio-admin-command-center__/graphics/icons/shortcut-toolbar/mip/facc-x56.png",
    icon_size                = 56,
    small_icon               = "__factorio-admin-command-center__/graphics/icons/shortcut-toolbar/mip/facc-x24.png",
    small_icon_size          = 24
  }
})

--------------------------------------------------------------------------------
-- 4) Legendary Upgrader tool & its shortcut
--------------------------------------------------------------------------------
do
  local sounds = require("__base__.prototypes.item_sounds")
  data:extend({
    {
      type                         = "selection-tool",
      name                         = "facc_legendary_upgrader",
      localised_name               = {"facc.legendary-upgrader-name"},
      localised_description        = {"facc.legendary-upgrader-desc"},
      icons                        = {{ icon = "__factorio-admin-command-center__/graphics/icons/legendary-upgrade-planner.png" }},
      flags                        = {"only-in-cursor", "not-stackable", "spawnable"},
      subgroup                     = "tool",
      order                        = "c[admin]-d[legendary-upgrader]",
      inventory_move_sound         = sounds.planner_inventory_move,
      pick_sound                   = sounds.planner_inventory_pickup,
      drop_sound                   = sounds.planner_inventory_move,
      stack_size                   = 1,
      draw_label_for_cursor_render = true,
      skip_fog_of_war              = true,

      select = {
        border_color    = {0, 200, 0},
        mode            = {"upgrade"},
        cursor_box_type = "not-allowed",
        started_sound   = { filename = "__core__/sound/upgrade-select-start.ogg" },
        ended_sound     = { filename = "__core__/sound/upgrade-select-end.ogg" }
      },
      alt_select = {
        border_color    = {0, 0, 0, 0},
        mode            = {"nothing"},
        cursor_box_type = "not-allowed"
      },
      reverse_select = {
        border_color    = {0, 200, 0},
        mode            = {"upgrade"},
        cursor_box_type = "not-allowed"
      },
      reverse_alt_select = {
        border_color    = {0, 0, 0, 0},
        mode            = {"nothing"},
        cursor_box_type = "not-allowed"
      }
    },
    {
      type                     = "shortcut",
      name                     = "facc_give_legendary_upgrader",
      localised_name           = {"facc.legendary-upgrader-shortcut"},
      localised_description    = {"facc.legendary-upgrader-shortcut-desc"},
      action                   = "lua",
      technology_to_unlock     = "construction-robotics",
      item_to_spawn            = "facc_legendary_upgrader",
      style                    = "green",
      icon                     = "__factorio-admin-command-center__/graphics/icons/shortcut-toolbar/mip/legendary-upgrade-planner-x56.png",
      icon_size                = 56,
      small_icon               = "__factorio-admin-command-center__/graphics/icons/shortcut-toolbar/mip/legendary-upgrade-planner-x24.png",
      small_icon_size          = 24
    }
  })
end

--------------------------------------------------------------------------------
-- 5) Custom input: Execute Lua console (Ctrl + Enter)
--------------------------------------------------------------------------------
data:extend({
  {
    type                  = "custom-input",
    name                  = "facc_console_exec_input",
    key_sequence          = "CONTROL + ENTER",
    consuming             = "game-only",
    localised_name        = {"controls.facc_console_exec_input"},
    localised_description = {"controls.facc_console_exec_input_description"}
  }
})

--------------------------------------------------------------------------------
-- 6) Only if the Cheat tab is ON, register all of its recipes
--------------------------------------------------------------------------------
if show_cheat_tab then

  -- Helper to assign subgroup & visibility
  local function default_properties(tbl)
    tbl.enabled                     = true
    tbl.hidden                      = false
    tbl.subgroup                    = "facc-cheat-recipes"
    tbl.hidden_from_player_crafting = false
    tbl.hide_from_player_crafting   = false
  end

  --------------------------------------------------------------------------------
  -- 6.1) Infinity Chest
  --------------------------------------------------------------------------------
  local inf_chest_ingredients = {
    {type="item", name="steel-chest",        amount=100},
    {type="item", name="electronic-circuit", amount=100},
    {type="item", name="advanced-circuit",   amount=100},
    {type="item", name="processing-unit",    amount=100},
  }
  if data.raw.recipe["infinity-chest"] then
    local r = data.raw.recipe["infinity-chest"]
    r.ingredients = inf_chest_ingredients
    default_properties(r)
    default_properties(data.raw.item["infinity-chest"])
  else
    local r = {
      type            = "recipe",
      name            = "infinity-chest",
      energy_required = 0.5,
      ingredients     = inf_chest_ingredients,
      results         = {{type="item", name="infinity-chest", amount=1}}
    }
    default_properties(r)
    default_properties(data.raw.item["infinity-chest"])
    data:extend({ r })
  end

  --------------------------------------------------------------------------------
  -- 6.2) Infinity Pipe
  --------------------------------------------------------------------------------
  local inf_pipe_ingredients = {
    {type="item", name="pipe",               amount=100},
    {type="item", name="electronic-circuit", amount=100},
    {type="item", name="advanced-circuit",   amount=100},
    {type="item", name="processing-unit",    amount=100},
  }
  if data.raw.recipe["infinity-pipe"] then
    local r = data.raw.recipe["infinity-pipe"]
    r.ingredients = inf_pipe_ingredients
    default_properties(r)
    default_properties(data.raw.item["infinity-pipe"])
  else
    local r = {
      type            = "recipe",
      name            = "infinity-pipe",
      energy_required = 0.5,
      ingredients     = inf_pipe_ingredients,
      results         = {{type="item", name="infinity-pipe", amount=1}}
    }
    default_properties(r)
    default_properties(data.raw.item["infinity-pipe"])
    data:extend({ r })
  end

  --------------------------------------------------------------------------------
  -- 6.3) Heat Interface
  --------------------------------------------------------------------------------
  local heat_ingredients = {
    {type="item", name="copper-plate", amount=100},
    {type="item", name="steel-plate",  amount=100},
    {type="item", name="pipe",         amount=100},
  }
  if data.raw.recipe["heat-interface"] then
    local r = data.raw.recipe["heat-interface"]
    r.category    = nil
    r.ingredients = heat_ingredients
    default_properties(r)
    default_properties(data.raw.item["heat-interface"])
  else
    local r = {
      type            = "recipe",
      name            = "heat-interface",
      energy_required = 0.5,
      ingredients     = heat_ingredients,
      results         = {{type="item", name="heat-interface", amount=1}}
    }
    default_properties(r)
    default_properties(data.raw.item["heat-interface"])
    data:extend({ r })
  end

  --------------------------------------------------------------------------------
  -- 6.4) Electric Energy Interface
  --------------------------------------------------------------------------------
  local eei_ingredients = {
    {type="item", name="accumulator",        amount=100},
    {type="item", name="electronic-circuit", amount=100},
    {type="item", name="advanced-circuit",   amount=100},
    {type="item", name="processing-unit",    amount=100},
  }
  if data.raw.recipe["electric-energy-interface"] then
    local r = data.raw.recipe["electric-energy-interface"]
    r.ingredients = eei_ingredients
    default_properties(r)
    default_properties(data.raw.item["electric-energy-interface"])
  else
    local r = {
      type            = "recipe",
      name            = "electric-energy-interface",
      energy_required = 0.5,
      ingredients     = eei_ingredients,
      results         = {{type="item", name="electric-energy-interface", amount=1}}
    }
    default_properties(r)
    default_properties(data.raw.item["electric-energy-interface"])
    data:extend({ r })
  end

  --------------------------------------------------------------------------------
  -- 6.5) Loader series (loader, fast-loader, express-loader, turbo-loader)
  --------------------------------------------------------------------------------
  do
    local base = {
      loader = {
        ingredients = {
          {type="item", name="iron-plate",      amount=100},
          {type="item", name="iron-gear-wheel", amount=100},
        }
      },
      ["fast-loader"] = {
        ingredients = {
          {type="item", name="iron-gear-wheel", amount=100},
          {type="item", name="loader",          amount=1},
        }
      },
      ["express-loader"] = {
        category    = "crafting-with-fluid",
        ingredients = {
          {type="item",  name="iron-gear-wheel", amount=100},
          {type="item",  name="fast-loader",     amount=1},
          {type="fluid", name="lubricant",       amount=100},
        }
      }
    }
    for name, def in pairs(base) do
      local r = {
        type            = "recipe",
        name            = name,
        category        = def.category,
        energy_required = 0.5,
        ingredients     = def.ingredients,
        results         = {{type="item", name=name, amount=1}}
      }
      default_properties(r)
      data:extend({ r })
    end
    -- turbo-loader only if tungsten-plate exists
    if data.raw.item["tungsten-plate"] then
      local r = {
        type            = "recipe",
        name            = "turbo-loader",
        category        = "crafting-with-fluid",
        energy_required = 0.5,
        ingredients     = {
          {type="item",  name="tungsten-plate", amount=100},
          {type="item",  name="express-loader", amount=1},
          {type="fluid", name="lubricant",      amount=100},
        },
        results         = {{type="item", name="turbo-loader", amount=1}}
      }
      default_properties(r)
      data:extend({ r })
    end
  end

  --------------------------------------------------------------------------------
  -- 6.6) Linked Chest
  --------------------------------------------------------------------------------
  do
    local r = {
      type            = "recipe",
      name            = "linked-chest",
      energy_required = 0.5,
      ingredients     = {
        {type="item", name="active-provider-chest",  amount=100},
        {type="item", name="passive-provider-chest", amount=100},
        {type="item", name="buffer-chest",           amount=100},
        {type="item", name="requester-chest",        amount=100},
      },
      results         = {{type="item", name="linked-chest", amount=1}}
    }
    default_properties(r)
    data:extend({ r })
  end

  --------------------------------------------------------------------------------
  -- 6.7) Lane Splitter (two versions: with turbo-splitter or without)
  --------------------------------------------------------------------------------
  if data.raw.item["turbo-splitter"] then
    local r = {
      type            = "recipe",
      name            = "lane-splitter",
      energy_required = 0.5,
      ingredients     = {
        {type="item", name="splitter",         amount=100},
        {type="item", name="fast-splitter",    amount=1},
        {type="item", name="express-splitter", amount=1},
        {type="item", name="turbo-splitter",   amount=1},
      },
      results         = {{type="item", name="lane-splitter", amount=1}}
    }
    default_properties(r)
    data:extend({ r })
  else
    local r = {
      type            = "recipe",
      name            = "lane-splitter",
      energy_required = 0.5,
      ingredients     = {
        {type="item", name="splitter",         amount=100},
        {type="item", name="fast-splitter",    amount=100},
        {type="item", name="express-splitter", amount=1},
      },
      results         = {{type="item", name="lane-splitter", amount=1}}
    }
    default_properties(r)
    data:extend({ r })
  end

  --------------------------------------------------------------------------------
  -- 6.8) Infinity Cargo Wagon
  --------------------------------------------------------------------------------
  do
    local r = {
      type            = "recipe",
      name            = "infinity-cargo-wagon",
      energy_required = 0.5,
      ingredients     = {
        {type="item", name="cargo-wagon",     amount=25},
        {type="item", name="iron-plate",      amount=100},
        {type="item", name="steel-plate",     amount=100},
        {type="item", name="iron-gear-wheel", amount=100},
      },
      results         = {{type="item", name="infinity-cargo-wagon", amount=1}}
    }
    default_properties(r)
    data:extend({ r })
  end

  --------------------------------------------------------------------------------
  -- 6.9) Burner Generator
  --------------------------------------------------------------------------------
  do
    local r = {
      type            = "recipe",
      name            = "burner-generator",
      energy_required = 0.5,
      ingredients     = {
        {type="item", name="steam-engine",    amount=25},
        {type="item", name="iron-plate",      amount=100},
        {type="item", name="iron-gear-wheel", amount=100},
        {type="item", name="pipe",            amount=100},
      },
      results         = {{type="item", name="burner-generator", amount=1}}
    }
    default_properties(r)
    data:extend({ r })
  end

end
