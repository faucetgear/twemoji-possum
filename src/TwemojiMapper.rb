#######################################################
# TWEMOJI SCRAPER: the source is located at:
# https://twemoji.maxcdn.com/2/test/preview.html
#######################################################

require 'csv'
require 'nokogiri'
require 'open-uri'

URL = "https://twemoji.maxcdn.com/2/test/preview.html"
OUTPUT_PATH = File.join(Dir.pwd, "tmp", "twemoji-list.csv")

$stdout.sync = true

#######################################################
# FUNCTIONS: for process legibility
#######################################################

def pointOf emoji
  emoji.split("")
    .map { |s| s.ord.to_s(16)}
    .join("-")
    .gsub(/^(\w+)-fe0f$/, '\1')
end

#######################################################
# ANONYMOUS FXNS: for call-chaining legibility
#######################################################

emojis = lambda do |node|
  node.children.text
end

codePoints = lambda do |emoji|
  [ pointOf(emoji) ]
end

#######################################################
# CALLING THE SCRAPE/MAP PROCESS, WRITING THE LIST
#######################################################

puts "generating twemoji code point list"

puts "loading full twemoji list"
doc = Nokogiri::HTML(open(URL))

puts "twemoji list loaded, converting to list"
twemoji_entries = doc
  .css("li")
  .map(&emojis)
  .map(&codePoints)

puts "list generated, writing csv"
CSV.open(OUTPUT_PATH, "wb") do |csv|
  twemoji_entries.each do |entry|
    csv << entry
  end
end

puts "csv writing complete"
