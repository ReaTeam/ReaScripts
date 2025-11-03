# @noindex

#!/usr/bin/env ruby

require "json"

font_name = ARGV[0]
font_path = ARGV[1]
json_spec = ARGV[2]
out_path  = ARGV[3]

spec = JSON.parse(File.read(json_spec))

File.open(out_path, "wb") { |f|
  f.puts "<!DOCTYPE html>"
  f.puts "<html>"
  f.puts "<head>"
  f.puts "<script src='skin.js'></script>"
  f.puts "<style>"
  f.puts "@font-face { font-family: '#{font_name}'; src: url('#{font_path}'); }"
  f.puts "@font-face { font-family: 'NotDef'; src: url('AND-Regular.ttf'); }"
  f.puts ".test      { font-family: '#{font_name}', 'NotDef'; font-size: 30px; text-align:center; display:inline-block; width:50px; border: solid 1px black }"
  f.puts "</style>"
  f.puts "</head>"
  f.puts "<body>"
  f.puts "<div class='skin-selector-wrapper'>Skin <select id='skin-selector'><option value='-1'>All</option><option value='0'>Default</option><option value='1'>Light</option><option value='2'>Medium Light</option><option value='3'>Medium</option><option value='4'>Medium Dark</option><option value='5'>Dark</option></select></div>"
  f.puts "<div>"
  spec['groups'].each { |g|
    g['s'].each { |sub_group|
      f.puts "<div style='margin-bottom:10px'>"
      f.puts "<div>#{g['n']} &gt; #{sub_group['n']}</div>"
      sub_group['c'].each { |c|
        variants = (c['v'] or [])
        f.puts "<div class='test' data-skin='#{(variants.count>0)?(0):('')}'  title='#{c['l']}'>&##{c['p']};</div>"
        variants.each_with_index { |sc, i|
          f.puts "<div class='test' data-skin='#{sc['k']}' title='#{sc['l']} / Skins : #{sc['k']}'>&##{sc['p']};</div>"
        }
      }
      f.puts "</div>"
    }
  }
  f.puts "</div>"
  f.puts "</body>"
}
