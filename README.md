# Bloom & Branch

A cozy gardening game inspired by Stardew Valley. Tend your garden through the seasons, manage soil moisture, and grow flowers suited to your chosen biome.

Built with [Godot 4.3](https://godotengine.org/).

## Requirements

- [Godot 4.3](https://godotengine.org/download) (standard version, not .NET)

## Running Locally

### macOS

```bash
brew install --cask godot
```

Or download the `.dmg` directly from [godotengine.org/download](https://godotengine.org/download) and move `Godot.app` to `/Applications`.

### Windows / Linux

Download the installer or binary from [godotengine.org/download](https://godotengine.org/download) and install it.

---

### Open the project

1. Launch Godot
2. Click **Import**
3. Navigate to the `bloomville` folder and select `project.godot`
4. Click **Import & Edit**
5. Press **F5** (or the ▶ Play button) to run the game

## Controls

| Input | Action |
|---|---|
| Left click | Water the selected soil tile |
| F5 | Save game |
| F9 | Load game |

## Gameplay

On first launch you'll be prompted to choose a **biome** and **starting season**. Each biome has a different soil moisture decay rate:

| Biome | Decay per hour |
|---|---|
| Forest | 0.05 |
| Mountain | 0.03 |
| Beach | 0.08 |
| Desert | 0.10 |

Tiles shift in color from dry (tan) to moist (brown) to wet (dark brown) based on their moisture level. Click a tile to water it. Check back after a few in-game hours to see it dry out.

Your save file is stored at `user://bloomville.save` (inside Godot's user data directory).
