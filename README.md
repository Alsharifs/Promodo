# Advanced Pomodoro Timer for KOReader

A standalone full-screen Pomodoro timer plugin for KOReader.

## Features

- 25-minute focus session
- 5-minute rest session
- Start / Pause / Reset / Exit controls
- Automatic Focus ↔ Rest switching
- Absolute-time countdown to reduce timer drift
- Full-screen interface
- KOReader main-menu integration
- Plugin metadata for proper installation and discovery

## Project structure

```text
advanced_promodo.koplugin/
├── _meta.lua
├── main.lua
├── promodo_app.lua
└── README.md
```

## Installation

1. Download or copy the complete `advanced_promodo.koplugin` folder.
2. Copy the folder to:

```text
koreader/plugins/
```

3. Restart KOReader.
4. Open the KOReader main menu.
5. Find **Advanced Pomodoro Timer**.
6. Select **Open Timer**.

## Important

The folder name must remain exactly:

```text
advanced_promodo.koplugin
```

The plugin metadata file `_meta.lua` is required for reliable plugin-manager/app-store handling.

## Development

The plugin entry point is:

```text
main.lua
```

The timer UI and timer logic are implemented in:

```text
promodo_app.lua
```
