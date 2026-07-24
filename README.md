# Quickshell Dynamic Island
Just a simple recreation of dynamic islands we found on our phones.

## Dependencies:
1. Quickshell.
2. MPRIS (auto installed on most new systems).
3. Matugen (optional, for color theme generation).

## What you will need to do:
1. Clone this repository either via `git clone https://github.com/ps2string/quickshell-simple-dynisland/` for via `Download .ZIP` from "Code" > "Local" > "Download .ZIP".
2. Extract the contents to any location you want to (preferably directly inside `~/.config/quickshell`.
3. (IF extracted other than `~/.config/quickshell` (i.e `~/Downloads`), move the folder into `~/.config/quickshell`.
4. To run it, just type in `qs -p ~/.config/quickshell/dynamic-island` inside your terminal.

### For color theming
- Your matugen `colors.json` should have this inside:
```json
{
  "colors": {
    "surface": "{{colors.surface.default.hex}}",
    "surface_container": "{{colors.surface_container.default.hex}}",
    "on_surface": "{{colors.on_surface.default.hex}}",
    "on_surface_variant": "{{colors.on_surface_variant.default.hex}}",
    "primary": "{{colors.primary.default.hex}}",
    "outline": "{{colors.outline.default.hex}}",
    "outline_variant": "{{colors.outline_variant.default.hex}}"
  }
}
```
- For `config.toml`
```toml
[templates.json]
input_path = "~/.config/matugen/templates/colors.json"
output_path = "~/.cache/matugen/colors.json"
```

### Preview:
<img width="397" height="119" alt="image" src="https://github.com/user-attachments/assets/5c1c4b54-bfe6-40fb-89bd-c22d7d1b4f4b" />
<img width="1366" height="768" alt="image" src="https://github.com/user-attachments/assets/2f8b2d18-3089-40f4-9fcd-6216ae783017" />

