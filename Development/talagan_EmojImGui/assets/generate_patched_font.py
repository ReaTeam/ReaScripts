#!/usr/bin/env python3
# @noindex

from fontTools import ttLib
import json
import shutil
import os
import sys

def extract_ligatures_to_new_font(input_font_path, output_font_path, mapping_json_path='ligature_mapping.json'):
    """
    Extracts ligatures from a font and maps them to direct Unicode codepoints.
    Creates a new font without GSUB table and a JSON mapping file.

    Args:
        input_font_path: Path to the source OpenMoji font
        output_font_path: Path for the output font without ligatures
        mapping_json_path: Path for the JSON mapping file
    """

    # Load the source font
    font = ttLib.TTFont(input_font_path)

    # Dictionary to store ligature mappings: (glyph_sequence) -> result_glyph
    ligature_mappings = {}

    # Explore GSUB (Glyph Substitution) table to find ligatures
    if 'GSUB' in font:
        gsub = font['GSUB']

        # Iterate through features (mainly 'liga', 'dlig', 'clig', 'ccmp', 'rlig')
        if hasattr(gsub, 'table') and hasattr(gsub.table, 'FeatureList'):
            for feature_record in gsub.table.FeatureList.FeatureRecord:
                feature_tag = feature_record.FeatureTag

                # Focus on ligature-related features
                if feature_tag in ['liga', 'dlig', 'clig', 'ccmp', 'rlig']:
                    feature = feature_record.Feature

                    # Iterate through lookups in this feature
                    for lookup_index in feature.LookupListIndex:
                        lookup = gsub.table.LookupList.Lookup[lookup_index]

                        # Type 4 = Ligature substitution
                        if lookup.LookupType == 4:
                            for subtable in lookup.SubTable:
                                for first_glyph, ligatures in subtable.ligatures.items():
                                    for ligature in ligatures:
                                        # Sequence of glyphs forming the ligature
                                        component_glyphs = [first_glyph] + ligature.Component
                                        # Resulting glyph
                                        result_glyph = ligature.LigGlyph

                                        ligature_mappings[tuple(component_glyphs)] = result_glyph

    print(f"Found {len(ligature_mappings)} ligatures")

    # Build reverse mapping: glyph_name -> existing codepoint
    glyph_to_unicode = font.getBestCmap() or {}
    reverse_cmap = {v: k for k, v in glyph_to_unicode.items()}

    # Get the cmap table for modifications
    cmap = font['cmap']

    # Find a Unicode cmap table (format 4 or 12)
    unicode_cmap = None
    for table in cmap.tables:
        if table.isUnicode():
            unicode_cmap = table
            break

    if unicode_cmap is None:
        raise Exception("No Unicode cmap table found in font")

    # Build a set of already used codepoints in the PUA
    existing_pua_codepoints = set()
    for codepoint in unicode_cmap.cmap.keys():
        if 0xE000 <= codepoint <= 0xF8FF:
            existing_pua_codepoints.add(codepoint)

    print(f"Found {len(existing_pua_codepoints)} existing codepoints in Private Use Area")

    # Get list of all glyphs in font for validation
    glyph_set = set(font.getGlyphOrder())

    # Private Use Area range (U+E000-U+F8FF)
    pua_start = 0xE000
    pua_end = 0xF8FF
    current_pua = pua_start

    # Dictionary for new mappings: codepoint -> glyph_name
    new_mappings = {}

    # Dictionary for JSON output: "HEX1-HEX2-HEX3" -> "HEXRES"
    json_mappings = {}

    for component_glyphs, result_glyph in ligature_mappings.items():
        # Verify that the result glyph exists in the font
        if result_glyph not in glyph_set:
            print(f"Warning: Glyph {result_glyph} not found in font, skipping")
            continue

        # Check if the result glyph already has a codepoint
        if result_glyph in reverse_cmap:
            codepoint = reverse_cmap[result_glyph]
            print(f"Glyph {result_glyph} already has codepoint U+{codepoint:04X}")
        else:
            # Find next available PUA codepoint
            while current_pua in existing_pua_codepoints and current_pua <= pua_end:
                current_pua += 1

            if current_pua > pua_end:
                raise Exception("Private Use Area is full, cannot map more ligatures")

            codepoint = current_pua
            existing_pua_codepoints.add(codepoint)
            current_pua += 1

            # Add to new mappings
            new_mappings[codepoint] = result_glyph

        # Build the JSON mapping key: convert glyph names to their codepoints
        component_codepoints = []
        for glyph_name in component_glyphs:
            # Find the codepoint for this glyph
            if glyph_name in reverse_cmap:
                component_codepoints.append(f"{reverse_cmap[glyph_name]:04X}")
            else:
                # If glyph has no codepoint, use its name
                component_codepoints.append(glyph_name)

        ligature_key = "-".join(component_codepoints)
        result_hex = f"{codepoint:04X}"
        json_mappings[ligature_key] = result_hex

        # Display mapping for info
        component_names = ' + '.join(component_glyphs)
        # print(f"U+{codepoint:04X}: {ligature_key} ({component_names}) -> {result_glyph}")

    # Update ALL Unicode cmap tables with new mappings
    tables_updated = 0
    for table in cmap.tables:
        if table.isUnicode():
            for codepoint, glyph_name in new_mappings.items():
                table.cmap[codepoint] = glyph_name
            tables_updated += 1
            print(f"Updated cmap table format {table.format} (platform {table.platformID}, encoding {table.platEncID})")

    print(f"\nAdded {len(new_mappings)} new cmap entries to {tables_updated} tables")

    # Remove GSUB table to prevent automatic substitution
    if 'GSUB' in font:
        del font['GSUB']
        print("Removed GSUB table from font")

    # Also remove GPOS if it exists (positioning substitutions)
    if 'GPOS' in font:
        del font['GPOS']
        print("Removed GPOS table from font")

    # Save the modified font
    font.save(output_font_path)
    print(f"\nNew font saved: {output_font_path}")

    # Verify that the modifications were saved correctly
    test_font = ttLib.TTFont(output_font_path)
    test_cmap = test_font.getBestCmap()
    print(f"\nVerification: Font has {len(test_cmap)} total codepoints")
    pua_count = sum(1 for cp in test_cmap.keys() if 0xE000 <= cp <= 0xF8FF)
    print(f"PUA codepoints in saved font: {pua_count}")
    test_font.close()

    # Save JSON mapping
    with open(mapping_json_path, 'w', encoding='utf-8') as f:
        json.dump(json_mappings, f, indent=2, ensure_ascii=False)

    print(f"JSON mapping saved: {mapping_json_path}")
    print(f"Total mappings: {len(json_mappings)}")

    if new_mappings:
        print(f"PUA codepoints used: U+{pua_start:04X} - U+{current_pua-1:04X}")

    # Close the font
    font.close()

    return json_mappings


if __name__ == "__main__":
    # Usage example
    input_font      = sys.argv[1]
    output_font     = sys.argv[2]
    mapping_json    = sys.argv[3]

    try:
        mappings = extract_ligatures_to_new_font(input_font, output_font, mapping_json)

        print("\n✓ Processing completed successfully!")

    except FileNotFoundError:
        print(f"Error: File {input_font} not found")
    except Exception as e:
        print(f"Error during processing: {e}")
        import traceback
        traceback.print_exc()