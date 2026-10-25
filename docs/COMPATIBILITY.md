# Factorio 2.1 and 2.0 compatibility

FACC targets Factorio 2.1.23 and newer 2.1 releases, with a Factorio 2.0.76+ fallback built from the same source tree. This migration preserves existing features; it does not introduce new gameplay tools.

## Packages

| Engine | Main mod | Locale pack | FLib |
| --- | --- | --- | --- |
| 2.1 | `factorio-admin-command-center_4.4.0.zip` | `factorio-admin-command-center-locales_1.4.0.zip` | 0.17.2+ |
| 2.0 | `factorio-admin-command-center_4.3.3.zip` | `factorio-admin-command-center-locales_1.3.9.zip` | 0.16.5+ for Factorio 2.0 |

Factorio's Mod Structure documentation explicitly restricts `factorio_version` to one major/minor version. A `2.0` package is rejected by 2.1 before its Lua code can run. Each engine therefore gets a distinct package version and metadata, while all Lua, graphics and translations come from the same source files. Distinct mod versions also allow both artifacts to be published independently on the Mod Portal.

The repository's `info.json` is the primary 2.1 manifest. `compatibility/2.0.json` overrides only the fallback version and dependencies during packaging. The builder does not modify the working copy's manifest.

Creating a GitHub release, or running the **Zip and Upload Mod** workflow manually, builds and attaches both engine-specific ZIPs. The workflow contains its own package generation step and does not depend on local development scripts. ZIP contents exclude development files, Git metadata and generated artifacts. Publishing to the Mod Portal remains a separate action.

Install the appropriate ZIP and matching dependencies in the game's mod directory. When using a development checkout directly, its default manifest requires Factorio 2.1. Use the generated fallback ZIP in a separate Factorio 2.0 mod directory.

## API changes covered

| Area | Factorio 2.1 | Factorio 2.0 fallback |
| --- | --- | --- |
| Recipe categories | `RecipePrototype.categories` array | `RecipePrototype.category` string |
| Thruster filters and capacity | `LuaEntity.get_fluid_box_prototype`, `get_fluid_filter`, `get_fluid_capacity` | `LuaFluidBox.get_prototype`, `get_filter`, `get_locked_fluid`, `get_capacity` |
| Setting fluid contents | `LuaEntity.set_fluid` returns a numeric amount | `LuaEntity.set_fluid` returns `Fluid?` |
| HUD propellant totals | `LuaEntity.get_fluid_count` | Same supported method |
| Legendary Upgrader selection | Explicit `upgrade` and `any-entity` flags | Existing `upgrade` flag |
| Console Ctrl+Enter input | `CONTROL + RETURN` | `CONTROL + ENTER` |
| Saved, tag and planet teleports | Exit remote view before moving the physical player | Same exit method is supported |
| FLib table iteration | `any_of` through a local adapter | `for_each` through the same adapter |
| Math floor/min/max | Lua `math` functions | Same Lua functions |
| Blueprint item/equipment requests | Writable `insert_plan`, with exact inventory positions and equipment ghosts | Same supported plan API |
| Tracked logistics entities | Prototype `get-by-unit-number` flag and requester-point discovery | Same indexing requirement |
| Surface properties | Bound `get_property` / `set_property` calls | Same bound calls |

The fluid adapter accepts prototype filters as `LuaFluidPrototype` objects (documented in both APIs), rather than assuming they are strings. Failed fluid writes and failed remote-view exits do not count as successful operations. Existing platform/rocket restrictions on exiting remote view remain in effect.

The FLib adapter preserves callback order and early-exit behavior, forwards all other table utilities, and does not mutate FLib's module. The runtime version is taken from `script.active_mods.base`, and the data stage uses `mods.base`; the FACC package version is not used for API selection.

## Sources

- Local API snapshots used for the migration: **2.0.77** and **2.1.23**, both runtime and prototype JSON files under `Factorio API Docs`.
- Local `auxiliary/mod-structure.html` for the engine-version restriction and dependency semantics.
- Installed Factorio 2.1.23 `data/changelog.txt` for behavior changes, including remote-view teleports and selection modes.
- Installed FLib 0.17.2 ZIP: `table.lua`, `math.lua`, and `changelog.txt` for its 0.17 API changes.
- Official FLib 0.16.5 source from its [upstream release tag](https://codeberg.org/raiguard/flib/src/tag/v0.16.5), commit `ebfc56b1fdf079ec4df4c8cfc438af5a2de9a88e`, used with the real Factorio 2.0.77 headless executable. The test dependency ZIP was assembled from that source; it is not a checksum-verified Mod Portal ZIP.
