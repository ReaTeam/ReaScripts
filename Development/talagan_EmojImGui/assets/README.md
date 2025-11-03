The purpose of this folder is to build emoji fonts that work with ReaImGui, and their indexes.

# Notes

Icons are identified by their utf8 character combination : "HEX1-HEX2-HEX3-...". Yeah, icons may be built with a sequence of characters that identifies them (ligatures). If not, they are simply identified by "HEX". This HEX sequence is called "hexcode" in the specs.

# COLRV0 issue

ReaImGui uses freetype, and the only color format I could find which is actually supported is glyf COLRV0.

- OpenMoji offers a font in the glyf COLRV0 format
- TweMoji doesn't, so I built a new one using this project : https://github.com/Emoji-COLRv0/Emoji-COLRv0

I followed the project's manual, took the SVGs from TweMoji 16.0 available in this "official" fork : https://github.com/jdecked/twemoji, and made the build. Both fonts are available in src/openmoji and src/twemoji

# Ligatures issue

The next problem is that these fonts use ligatures because they follow the emoji specification. But ReaImGui can't handle them currently. The idea is to remap those virtual glyphs (results of ligatures) from the fonts to real unicode points. I've used free spots in the PUA for this, and wrote a python script that uses fonttools for that purpose. As I'm not at ease with python and the framework, I had to use Claude.

The script generates two files :

- The patched font (in build/*-patched.ttf)
- The build/*-remap.json, containing the list of remappings for all ligatures

# TweMoji Hexcode mismatch issue

The TweMoji svg files have naming problems, they use hexcodes, but sometimes they do not match the specification. Some characters like ZWJ may be omitted in the hexcodes. I do some fallback pirouettes to find the right sequence and re-associate the right icon. It's the "find_real_place_for_icon" function in the index building script.

# Info databases

- OpenMoji uses it's own openmoji.json to describe its content
- TweMoji does not have that kind of file, but emojibase does, so this was the one used here

# Build flow

- generate_patched_font.py : generates patched fonts with real codepoints for ligature results (in the PUA). Generates a remap.json file to describe what's been remapped

- build_*moji_index : builds the index for the font. It describes the groups, subgroups, characters, and where they can be found in the font. This spec file is what will be used by the ReaImGui library to now how to pick icons in the fonts. OpenMoji and TweMoji have their own scripts, because they use different source.json files that describe them. However, the *-spec.json are unified under the same format, so that EmojImGui can process them equally.

- build_html_test_file : build test files in HTML to visually check that everything's ok

- build.sh contains the list of all commands that are used by the build flow (and can be launched to perform la totale)

# Running the python script

Create a local venv with :

- python3 -m venv myvenv
- python3 pip install fonttools
- source .myvenv/bin/active

