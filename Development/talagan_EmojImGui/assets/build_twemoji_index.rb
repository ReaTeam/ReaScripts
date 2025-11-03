#!/usr/bin/env ruby
# @noindex

require 'json'

# Vérifier les arguments
if ARGV.length != 4
  puts "Usage: ruby build_twemoji_base.rb <groups.json> <data.json> <remap_file.json> <output.json>"
  exit 1
end

groups_file = ARGV[0]
data_file = ARGV[1]
remap_file = ARGV[2]
output_file = ARGV[3]

# Charger les fichiers
puts "Loading #{groups_file}..."
groups_data = JSON.parse(File.read(groups_file))

puts "Loading #{remap_file}..."
remap_data = JSON.parse(File.read(remap_file))

puts "Loading #{data_file}..."
emojis = JSON.parse(File.read(data_file))

# Extraire les mappings
groups_map = groups_data["groups"]
subgroups_map = groups_data["subgroups"]
hierarchy = groups_data["hierarchy"]

# Initialiser la structure de sortie
output = { "groups" => [] }

# Créer un hash pour regrouper les emojis par groupe/sous-groupe
grouped = {}

emojis.each do |emoji|
  group_id = emoji["group"]
  subgroup_id = emoji["subgroup"]

  grouped[group_id] ||= {}
  grouped[group_id][subgroup_id] ||= []
  grouped[group_id][subgroup_id] << emoji
end

# Compteurs
variant_count = 0

def find_real_place_for_icon(hexcode, remap_data)
  is_multi  = !hexcode.index("-").nil?

  return hexcode.hex if !is_multi

  remap = remap_data[hexcode]
  if !remap
    # Try without FE0F
    hexcode = hexcode.gsub("-FE0F","")
    hexcode = hexcode.gsub("FE0F-","")
    remap = remap_data[hexcode]
  end

  if !remap
    puts "Warning !! Could not find #{hexcode} character in the remapping !!!"
    return hexcode.hex # This is a fallback, but this is wrong !!
  end

  remap.hex
end

# Construire la structure finale dans l'ordre des groupes
groups_map.keys.sort_by(&:to_i).each do |group_id|
  group_name = groups_map[group_id]
  subgroup_ids = hierarchy[group_id] || []

  subgroups_array = []

  subgroup_ids.each do |subgroup_id|
    subgroup_name = subgroups_map[subgroup_id.to_s]
    characters    = grouped[group_id.to_i] && grouped[group_id.to_i][subgroup_id] || []

    next if characters.empty?

    # Transformer les caractères
    chars_array = characters.map do |char|
      hexcode   = char["hexcode"]

      result = {
        "e" => char["emoji"],
        "x" => hexcode,
        "p" => find_real_place_for_icon(hexcode, remap_data),
        "l" => char["label"],
        "t" => char["tags"].join(" "),
      }

      # Ajouter les variantes si présentes
      if char["skins"] && !char["skins"].empty?
        variant_count += char["skins"].length

        result["v"] = char["skins"].map do |skin|
          hexcode = skin["hexcode"]
          tone    = skin["tone"]
          tone = tone.join(",") if tone.is_a? Array
          {
            "e" => skin["emoji"],
            "x" => hexcode,
            "p" => find_real_place_for_icon(hexcode, remap_data),
            "l" => skin["label"],
            "k" => tone
          }
        end
      end

      result
    end

    subgroups_array << {
      "n" => subgroup_name,
      "c" => chars_array
    }
  end

  next if subgroups_array.empty?

  output["groups"] << {
    "n" => group_name,
    "s" => subgroups_array
  }
end

# Écrire le fichier de sortie
puts "Writing to #{output_file}..."
File.write(output_file, JSON.generate(output))

puts "Done!"
puts "  - #{emojis.length} base emojis"
puts "  - #{variant_count} skin tone variants"
puts "  - #{output['groups'].length} groups"