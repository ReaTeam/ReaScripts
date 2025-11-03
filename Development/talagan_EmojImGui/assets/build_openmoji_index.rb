#!/usr/bin/env ruby
# @noindex


Dir.chdir(File.dirname(__FILE__))

require "json"

if ARGV.count != 3
  puts "Usage: ruby build_openmoji_base.rb <openmoji.json> <remap_file.json> <output.json>"
  exit 1
end

source_json = ARGV[0]
remap_file  = ARGV[1]
dest_json   = ARGV[2]

database    = JSON.parse(File.read(source_json))
remap_data  = JSON.parse(File.read(remap_file))

blacklist = ["20E3"]

lookup = {}
list   = []

database.map do |ic|
  tags    = (ic["tags"].split(",") + ic["openmoji_tags"].split(",") ).map { |t| t.strip }.sort.uniq.compact
  hexcode = ic["hexcode"]

  if blacklist.include? hexcode
    next
  end

  if hexcode.index("-") && !remap_data[hexcode]
    puts "Warning !! Multichar icon without a remapping found #{hexcode} !"
  end

  pua_cp  = remap_data[hexcode] ? remap_data[hexcode].hex : hexcode.hex
  is_skin = (ic["skintone"] != "")

  c = {
    x: hexcode,
    p: pua_cp,
    a: ic["annotation"].capitalize,
    e: ic["emoji"]
  }

  if !is_skin
    # Put tags only on parent char
    c[:t] = tags.join(" ")
    c[:g] = ic["group"]
    c[:s] = ic["subgroups"]
  else
    c[:k] = ic["skintone"]
  end

  lookup[c[:x]] = c

  if is_skin
    parent = lookup[ic["skintone_base_hexcode"]]
    parent[:v] ||= []
    parent[:v] << c
  else
    list << c
  end
end

skc = 0
slk = {}
list.each do |c|
  g = c[:g]; slk[g] ||= {}
  s = c[:s]; slk[g][s] ||= []
  cc = { e: c[:e], x: c[:x], p: c[:p], l: c[:a], t: c[:t] }
  if c[:v]
    cc[:v] = c[:v].map{ |sc| { x: sc[:x], p: sc[:p], l: sc[:a], e: sc[:e], k: sc[:k]} }
    skc += c[:v].length
  end
  slk[g][s] << cc
end

groups = []
slk.each do |gn, g|
  subgroups = []
  g.each do |sn, s|
    subgroups << { n: sn.capitalize, c: s }
  end

  groups << { n: gn.capitalize, s: subgroups }
end

#groups.sort_by! { |g| g[:n] }

ret = { groups: groups }
File.open(dest_json, "wb") { |f| f << JSON.generate(ret) }

puts "✅ #{dest_json} generated with #{list.size + skc} emojis (including PUA). #{skc} emojis are skintone variants."
