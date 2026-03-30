# Factorio Admin Command Center (FACC)

A compact admin toolkit for Factorio 2.0 with a category-based GUI, live sliders/switches, and no console dependency for most actions.

- 🔗 Mod Portal: https://mods.factorio.com/mod/factorio-admin-command-center
- 🔗 GitHub: https://github.com/factoriocenter/factorio-admin-command-center

## Current Version

- 🏷️ Version: `4.3.0`
- 📝 Changelog: [changelog.txt](changelog.txt)

## Features (All Current)

### 🧪 Cheats:
- 🧙 `Cheat Mode`
- 🗺️ `Toggle editor mode`
- 💻 `Console`
- 🍲 `Unlock All Recipes`
- 🔬 `Unlock All Technologies`
- 🎯 `Set Infinite Researches to Level 100`
- ➕ `Add +100 to Infinite Researches`
- 💰 `Receive Coins (Tight spot or Rocket rush)`
- ⏱️ `Auto Instant Research`
- ⚡ `Adjust Game Speed`
- 🧪 `Laboratory Speed Bonus`
- 🧪 `Laboratory Productivity Bonus`

### 🛡️ Armor:
- 🤖 `Create Full Armor`

### 📐 Blueprints:
- 👻 `Enable ghosts on entity death`
- 🏗️ `Instant Blueprint Building`
- 🧹 `Instant Deconstruction`
- ⬆️ `Instant Upgrading`
- 🛤️ `Instant Rail Planner`
- 🧱 `Build All Ghosts`
- 🔧 `Repair and Rebuild`
- 🚧 `Remove Marked Structures`
- 💎 `Upgrade Inventory Blueprints to Legendary (Quality)`

### 🚶 Character:
- 👻 `Ghost Mode`
- 🛡️ `Invincible Player`
- 🩹 `Repair Mined Item`
- ✂️ `Delete Orphaned Characters`
- 🎒 `Convert Inventory to Legendary (Quality)`
- 🎛️ `Set Inventory Slots Bonus`
- 🗑️ `Character Trash Slot Bonus`
- 🏃 `Run Faster`
- ❤️ `Character Health Bonus`
- 🛠️ `Adjust Handcraft Speed`
- ⛏️ `Adjust Mining Speed`
- 📐 `Build Distance`
- 🤚 `Reach Distance`
- ⛏️ `Resource Reach Distance`
- 📦 `Item Drop Distance`
- 🤲 `Item Pickup Distance`
- 🧲 `Loot Pickup Distance`

### ⚔️ Combat:
- 🚫 `Disable Friendly Fire`
- 🔒 `Indestructible Builds`
- ☮️ `Peaceful Mode`
- 🔐 `Indestructible Builds (Permanent)`
- 🎯 `Fill Empty Turrets`
- 💥 `Ammo Damage Boost`
- 🔫 `Turret Damage Boost`
- 🔫 `Gun Speed Boost`
- 🧨 `Artillery Range Boost`

### 👾 Enemies:
- 🛑 `Disable Enemy Expansion`
- 💣 `Remove Enemy Nests`

### 🌍 Environment:
- ⏸️ `Freeze Daytime (Surface)`
- ☮️ `Peaceful Mode (Surface)`
- 🚫 `Don't Generate Enemies (Surface)`
- ☀️ `Perpetual Day`
- 🚫 `Disable Pollution`
- ♻️ `Auto Clean Pollution`
- 🌞 `Set Midday (Surface)`
- 🌚 `Set Midnight (Surface)`
- 🧽 `Clear Pollution`
- 🌫️ `Hide Map`
- 🗑️ `Remove Ground Items`
- 🕒 `Set Daytime (Surface)`
- 🌬️ `Set Surface Pressure (Space Age)`
- 🧲 `Set Surface Magnetic Field (Space Age)`
- 🌌 `Set Surface Gravity (Space Age)`
- ☀️ `Set Surface Solar Power Multiplier`
- 🔍 `Reveal Map`
- ⛰️ `Remove Cliffs`

### 🤖 Logistic Network:
- 📦 `Instant Personal Logistics`
- 🗑️ `Instant Trash`
- 🤖 `Add Robots`
- 🐇 `Increase worker robot speed`
- 📦 `Worker Robot Storage Bonus`
- 🔋 `Worker Robot Battery Bonus`
- ⏳ `Following Robot Lifetime Bonus`
- 🤖 `Maximum Following Robot Count`
- 🦾 `Inserter Stack Size Bonus`
- 📥 `Bulk Inserter Capacity Bonus`
- 📦 `Belt Stack Size Bonus`
- 📡 `Beacon Distribution Bonus`

### ⛏️ Mining:
- ⛏️ `Entity Minability`
- 🚫 `Non-minable Builds (Permanent, Current Surface)`
- ⛏️ `Mining Drill Productivity Bonus`

### 🪐 Planets:
- ♻️ `Regenerate Resources`
- 📈 `Increase Resources`
- 🗺️ `Generate Planets Surfaces and Chart Area (Space Age)`
- 🌍 `Teleport to Planets (Space Age progression)`
- 🧭 `Fast Teleport Manager`

### ⚡ Power:
- 🔋 `Recharge Energy`

### 🚂 Trains:
- 🚆 `Automatic Trains`
- 🛑 `Train Braking Force Bonus`

### 🛰️ Transportation:
- 🛡️ `Create Full Tank`
- 🕷️ `Create Full Spidertron`
- ⛽ `Refuel Platform Thrusters (Space Age)`
- 📏 `Platform Distance (Space Age)`

## Extra Tools

- 🔘 Toolbar shortcut: open/close Admin GUI.
- 🧰 Toolbar shortcut: equip `Legendary Upgrader (Quality)`.
- 🧭 Hotkey for Fast Teleport Manager (`Ctrl + Shift + T` by default).
- 📊 Stats HUD (coordinates, time/day, playtime, evolution, pollution, research ETA, movement/vehicle speed, fuel, handcraft timer).
- 🌐 Public Remote API for mod integrations: [`docs/REMOTE_API.md`](docs/REMOTE_API.md)
- 💻 Lua console window with `Ctrl + Enter` execution.
- 📦 Optional `Cheat Tools` crafting tab (startup setting) with recipes for: `infinity-chest`, `infinity-pipe`, `heat-interface`, `electric-energy-interface`, `loader`/`fast-loader`/`express-loader`/`turbo-loader` (when available), `linked-chest`, `lane-splitter`, `infinity-cargo-wagon`, `burner-generator`.

## Startup Settings
- 📋 `Show Cheat Tools tab`
- 🏆 `Enable achievement overrides`
- 🧩 `Show internal names`
- ♾️ `Infinite Resources`
- 🪨 `Infinite Resources Multiplier (Solid)`
- 💧 `Infinite Resources Multiplier (Fluid)`
- ⛏️ `Instant mining drills`
- 🏭 `Instant crafting machines`
- ⚡ `Remove electricity requirement from machines`
- ⛽ `Remove fuel requirement from machines and vehicles`
- 🧪 `Ignore recipe ingredient inputs`
- 🔄 `Enable auto resource regeneration`
- 🧵 `Enable background optimization for heavy actions`
- 📊 `Stats HUD toggles and layout presets`

## Controls

- ⌨️ `Ctrl + .` -> Toggle Admin GUI
- ⌨️ `Ctrl + Enter` -> Execute Lua console command
- ⌨️ `Ctrl + Shift + T` -> Toggle Fast Teleport Manager
- ⚙️ All shortcuts are rebindable in `Settings -> Controls -> Mods`

## Compatibility

- 🎮 Factorio: `2.0` (base `>= 2.0.76`)
- 📚 Required library: `flib >= 0.16.5`
- 🔌 Optional integrations: `quality >= 2.0.76`, `space-age >= 2.0.76`, `elevated-rails >= 2.0.76`
- 🌍 Optional locale pack: `factorio-admin-command-center-locales >= 1.3.8`
- 👥 In multiplayer, admin tools are available to admins only.

## Languages

- 🇺🇸 English
- 🇧🇷 Portuguese (Brazil)
- 🌐 Additional languages are available via the optional companion locales mod.

## Installation

1. ✅ Install from Mod Portal (recommended): https://mods.factorio.com/mod/factorio-admin-command-center
2. 📦 Or download from Releases and place the `.zip` in your Factorio `mods` folder.

## License

[MIT](LICENSE) © <!-- change year start --> 2026<!-- change year end --> Factorio Center

## Contributors

<!-- readme: contributors,bot/- -start -->
<table>
	<tbody>
		<tr>
            <td align="center">
                <a href="https://github.com/louanfontenele">
                    <img src="https://avatars.githubusercontent.com/u/2886066?v=4" width="100;" alt="louanfontenele"/>
                    <br />
                    <sub><b>Louan Fontenele</b></sub>
                </a>
            </td>
            <td align="center">
                <a href="https://github.com/lsalazarm99">
                    <img src="https://avatars.githubusercontent.com/u/42286051?v=4" width="100;" alt="lsalazarm99"/>
                    <br />
                    <sub><b>Leonardo Salazar</b></sub>
                </a>
            </td>
		</tr>
	<tbody>
</table>
<!-- readme: contributors,bot/- -end -->
