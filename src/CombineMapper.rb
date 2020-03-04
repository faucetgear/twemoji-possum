require 'csv'
require 'colored'

$stdout.sync = true

UNICODE_PATH = File.join(Dir.pwd, "tmp", "full-emoji-list.csv")
MODIFIERS_PATH = File.join(Dir.pwd, "tmp", "full-emoji-modifiers.csv")
TWEMOJI_PATH = File.join(Dir.pwd, "tmp", "twemoji-list.csv")
CUSTOM_PATH = File.join(Dir.pwd, "tmp", "custom-list.csv")
NULL_PATH = File.join(Dir.pwd, "tmp", "NULL-LIST.csv")
COMBINE_PATH = File.join(Dir.pwd, "tmp", "twemoji-unicode-pairs.csv")

unicode_map = {}

CSV.foreach(UNICODE_PATH) do |row|
  unicode_map[row[0].to_sym] = row.drop(1)
end

modifiers_map = {}

CSV.foreach(MODIFIERS_PATH) do |row|
  modifiers_map[row[0].to_sym] = row.drop(1)
end

custom_map = {}

CSV.foreach(CUSTOM_PATH) do |row|
  custom_map[row[0].to_sym] = row.drop(1)
end

combine_map = {}

CSV.foreach(TWEMOJI_PATH) do |row|
  key = row[0].to_sym

  unicode_val = unicode_map[key] # always array
  modifiers_val = modifiers_map[key] # always array
  custom_val = custom_map[key] # always array

  combine_map[key] = []
  combine_map[key] += unicode_val if !unicode_val.to_a.empty?
  combine_map[key] += modifiers_val if !modifiers_val.to_a.empty?
  combine_map[key] += custom_val if !custom_val.to_a.empty? and (custom_val != unicode_val and custom_val != modifiers_val)
end

null_map = {}

combine_map.each do |key, val|
  null_map[key] = val if val.empty?
end

if !null_map.empty?
  puts "there are unresolved code points, investigate at tmp/NULL-LIST.csv".bold.red
end

CSV.open(NULL_PATH, "wb") do |csv|
  null_map.each do |key, val|
    csv << [key.to_s]
  end
end

CSV.open(COMBINE_PATH, "wb") do |csv|
  combine_map.each do |key, val|
    csv << [key.to_s, *val]
  end
end

puts "maps combined!"
