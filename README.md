# 🛠️ Factorio Admin Command Center (FACC)

**A full-featured GUI-based admin toolkit for Factorio 2.0+.**  
Take control of every aspect of your world with a sleek tabbed interface—no console typing required. Ideal for both **single-player** and **multiplayer admins**.

> 🎮 Requires **Factorio 2.0+** | 👨‍💻 Created by [louanbastos](https://github.com/loadsec)  
> 📦 Available on [Factorio Mod Portal](https://mods.factorio.com/mod/factorio-admin-command-center)

---

## 🚀 Key Features

🔘 **Quick Access** – Toggle Admin Command Center via **Ctrl + .** or by clicking the **toolbar shortcut**  
⚙️ **Automation Toggles** – Auto Clean Pollution, Auto Instant Research, Cheat Mode, Always-Day, Disable Pollution, Disable Friendly Fire, Peaceful Mode, Disable Enemy Expansion, Indestructible Builds  
🖥️ **Lua Console** – GUI textbox with multiline input, history, error feedback; execute with **Ctrl + Enter**  
🌐 **Languages** – English 🇺🇸 & Portuguese 🇧🇷  
👥 **Multiplayer** – Only admins see the GUI and tools; all features available in single-player

---

## 🧩 Full Feature List

### ⚙️ Automation Toggles

- ♻️ **Auto Clean Pollution** – Automatically clear pollution every _X_ seconds (slider configurable)
- 🚀 **Auto Instant Research** – Automatically complete research every _X_ seconds (slider configurable)
- 🔓 **Cheat Mode** – Build and spawn items freely
- ☀️ **Always-Day** – Keep the world in perpetual daylight
- 🍃 **Disable Pollution** – Clear current pollution and stop new pollution
- 🔫 **Disable Friendly Fire** – Prevent allies from damaging each other
- 🕊️ **Peaceful Mode** – Biters won’t attack unless provoked
- 🛑 **Disable Enemy Expansion** – Freeze biter nest growth
- 🏰 **Indestructible Builds** – Make all existing structures unbreakable (toggle back anytime)

### 💎 Legendary Tools

- 🦾 **Legendary Armor Builder** – One button to generate a full mech armor with top-tier legendary equipment
- 💠 **Convert Inventory to Legendary** – Instantly upgrade all carried items, weapons, armor, and equipment to legendary quality
- 🏗️ **Convert Constructions to Legendary** – Destroy & rebuild nearby structures as legendary-quality ghosts (slider radius)
- 🔄 **Legendary Upgrader Tool** – Drag-select any area to upgrade all entities and ghosts to legendary quality

### 🛠️ Core Functionality

- 🛠️ **Toggle Editor Mode** – Enter or exit the map editor with one click
- 🧍 **Delete Ownerless Characters** – Remove stray player entities on the map
- 🩹 **Repair & Rebuild** – Heal damaged entities and revive ghosts
- ⚡ **Recharge Energy** – Fully refill electric buffers on all machines
- 🎯 **Ammo to Turrets** – Auto-insert uranium magazines into empty gun turrets
- 🗑️ **Remove Pollution** – Instantly clear all pollution on the current surface

### 🏗️ Blueprint & Ghost Tools

- 🏗️ **Build All Ghosts** – Revive every ghost entity and tile ghost (including landfill)
- ❌ **Remove Marked Structures** – Delete all deconstruction-marked entities
- 📘 **Upgrade Inventory Blueprints** – Scan your inventory and blueprint books; upgrade every blueprint to legendary quality

### 📦 Resource & Power Tools

- 💰 **Max Resources** – Set all resource patches to maximum (2³² − 1)

### 🌍 Map Tools

- 👁️ **Reveal Map** – Chart an adjustable-radius area around you
- 🌑 **Hide Map** – Unchart all explored chunks
- 🪨 **Remove Cliffs** – Destroy cliffs within an adjustable radius
- 🐜 **Remove Enemy Nests** – Wipe out biter spawners & worms within an adjustable radius

### 🔓 Unlocks

- 🔓 **Unlock All Recipes** – Enable every recipe for your force
- 🧪 **Unlock All Technologies** – Instantly research all techs
- 🏆 **Unlock Achievements** – Grant every base & Space Age achievement

---

## 🕹️ Controls

| Action                        | Keybind / UI                 |
| ----------------------------- | ---------------------------- |
| Toggle Admin GUI              | `Ctrl + .`                   |
| Toolbar Shortcut              | (Click the FACC icon)        |
| Execute Lua Console Command   | `Ctrl + Enter`               |
| Open/Close Lua Console Window | (Exec button in console GUI) |

> You can rebind shortcuts in **Settings → Controls → Mods**

---

## 📦 Installation

### ✅ From Mod Portal (Recommended)

Install directly via the official portal:  
🔗 [Factorio Admin Command Center](https://mods.factorio.com/mod/factorio-admin-command-center)

### 🔻 From GitHub Releases

1. Go to the [Releases page](https://github.com/loadsec/factorio-admin-command-center/releases)
2. Download the latest `.zip`
3. Move the `.zip` to your Factorio `mods` folder – no extraction needed!

> Tip: Rename to `factorio-admin-command-center_<version>.zip` if desired

### 🛠️ Manual Installation

1. Clone or download this repo
2. Rename the extracted folder to `factorio-admin-command-center`
3. Move to your mods directory:
   - Windows: `%APPDATA%\Factorio\mods`
   - Linux: `~/.factorio/mods`
4. Launch Factorio and enable the mod in the Mods menu

---

## 👥 Multiplayer Support

- ✅ **Single-player:** All features available
- ✅ **Multiplayer:** GUI and tools visible only to admins

---

## 🌐 Localization

- 🇺🇸 English (default)
- 🇧🇷 Português (Brasil)

---

## ⚠️ Re-enabling Achievements

Factorio disables achievements on any modded save. To still earn achievements when using this mod, you can use one of these external tools:

- **Windows:** [FactorioAchievementEnabler](https://github.com/oorzkws/FactorioAchievementEnabler)
- **Linux:** [FAE_Linux](https://github.com/UnlegitSenpaii/FAE_Linux)

_No known achievement enabler exists for macOS or Nintendo Switch._

---

## 🤝 Contributing

Pull requests welcome:

1. Fork the repo
2. Create a branch: `git checkout -b feature/my-feature`
3. Commit: `git commit -m "feat: your feature"`
4. Push & open a PR

---

## 📄 License

Licensed under the [MIT License](LICENSE)

---

> _“With great power comes great administrative responsibility.”_
