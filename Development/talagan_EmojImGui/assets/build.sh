#!/usr/bin/env sh

echo "\n\nGenerating patched fonts\n"
./generate_patched_font.py "src/openmoji/OpenMoji-color-glyf_colr_0.ttf" "build/OpenMoji-color-glyf_colr_0-patched.ttf" "build/OpenMoji-color-glyf_colr_0-remap.json"
./generate_patched_font.py "src/twemoji/TweMoji-color-glyf_colr_0.ttf" "build/TweMoji-color-glyf_colr_0-patched.ttf" "build/TweMoji-color-glyf_colr_0-remap.json"

echo "\n\nGenerating index files\n"
./build_openmoji_index.rb ./src/openmoji/openmoji.json                              ./build/OpenMoji-color-glyf_colr_0-remap.json   ./build/openmoji-spec.json
./build_twemoji_index.rb  ./src/emojibase/groups.json    ./src/emojibase/data.json  ./build/TweMoji-color-glyf_colr_0-remap.json    ./build/twemoji-spec.json

echo "\n\nGenerating html test files\n"
./build_html_test_file.rb "OpenMoji" "OpenMoji-color-glyf_colr_0-patched.ttf" "build/openmoji-spec.json" "build/openmoji.html"
./build_html_test_file.rb "TweMoji" "TweMoji-color-glyf_colr_0-patched.ttf" "build/twemoji-spec.json" "build/twemoji.html"

echo "\n\Generating lua index files\n"
./build_lua_indexes.lua

