cat > ~/.cache/wal/colors.json <<EOF
{
    "wallpaper": "",
    "alpha": "100",
    "colors": {
        "color0": "{{colors.surface.default.hex}}",
        "color1": "{{colors.on_surface.default.hex}}",
        "color2": "{{colors.surface_container.default.hex}}",
        "color3": "{{colors.on_surface.default.hex}}",
        "color4": "{{colors.primary.default.hex}}",
        "color5": "{{colors.secondary.default.hex}}",
        "color6": "{{colors.surface_container_highest.default.hex}}",
        "color7": "",
        "color8": "",
        "color9": "",
        "color10": "",
        "color11": "",
        "color12": "",
        "color13": "",
        "color14": "",
        "color15": ""
    }
}
EOF
pywalfox <* if {{ is_dark_mode }} *>dark<* else *>light<* endif *>
pywalfox update