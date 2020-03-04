#######################################################
# UNICODE SCRAPER: return code point : name
# pairs from the authoritative emoji list at
# http://unicode.org/emoji/charts/full-emoji-list.html
#######################################################

require 'csv'
require 'nokogiri'
require 'open-uri'

URL_EMOJI_LIST = "https://unicode.org/emoji/charts/full-emoji-list.html"
URL_EMOJI_MODIFIERS = "https://unicode.org/emoji/charts/full-emoji-modifiers.html"
OUTPUT_EMOJI_LIST_PATH = File.join(Dir.pwd, "tmp", "full-emoji-list.csv")
OUTPUT_EMOJI_MODIFIERS_PATH = File.join(Dir.pwd, "tmp", "full-emoji-modifiers.csv")

# this will be called from a rake task primarily, so the stdout
# buffer needs to make it through to the caller's context
$stdout.sync = true

#######################################################
# FUNCTIONS: for process legibility
#######################################################

def codeOf node
  node.css("td.code a")[0]
    .attributes["name"]
    .value
    .gsub("_", "-")
end

def nameOf node
  name = node.css("td.name")[0]
    .children
    .text
    .downcase
    .strip
    .gsub(/⊛\s/, "")
    .gsub(/&/, "and")
    .gsub(/\s+/, "-")
    .gsub(/,/, "")
    .gsub(/:/, "")
    .gsub("!", "exc")
    .gsub("'", "")
    .gsub(/“|”/, "")
    .gsub("’", "")
    .gsub(/å|ã/, "a")
    .gsub(/é/, "e")
    .gsub(/í/, "i")
    .gsub(/ô/, "o")
    .gsub(/-\(blood-type\)$/, "")
    .gsub(/\.\-/, "-")
    .gsub(/\-\-/, "")
    .gsub(/-\(\w+\)/, "")
    .gsub(/\./, "")

  { node: node, name: name }
end

def swapBackwardsFlagName name
  if name.match("flag")
    n_array = name.split("-")
    n_array
      .insert(-1, n_array.delete_at(n_array.index("flag"))) # moves flag to the end
      .join("-")
  else
    name
  end
end

def flagNameOf node
  name = node.css("td.name")[1]
    .children
    .css("a")
    .children
    .map { |child| child.text.downcase.strip }
    .join("-")
    .gsub(/\s+/, "-")
    .gsub(/,/, "")
    .gsub("!", "exc")
    .gsub("'", "")
    .gsub("’", "")
    .gsub(/å|ã/, "a")
    .gsub(/é/, "e")
    .gsub(/í/, "i")
    .gsub(/ô/, "o")

  swapBackwardsFlagName name
end

def substForFlag obj
  str = obj[:name]
  # upon writing, all flag names were designated as "regional indicator"
  name = str.include?("regional-indicator-symbol") ? flagNameOf(obj[:node]) : str

  { node: obj[:node], name: name }
end

def substituteEquivalent obj
  str = obj[:name]
  # some of the clunkier names have an ≊ moniker for a simpler name
  name = str.include?("≊") ? str.split("≊")[1].strip.sub(/^-/, '') : str

  { node: obj[:node], name: name }
end

#######################################################
# ANONYMOUS FXNS: for call-chaining legibility
#######################################################

# this removes the "th" rows from the scrape because they don't
# have any important info
withoutHeaders = lambda { |node| node.child.name != "th" }

# this creates the mapping pairs by chaining the methods in the
# FUNCTIONS subheading
codeToName = lambda do |node|
  code_point = codeOf node
  human_name = (substForFlag substituteEquivalent nameOf node)[:name]

  [ code_point, human_name ]
end

#######################################################
# CALLING THE SCRAPE/MAP PROCESS, WRITING THE LIST
#######################################################

puts "generating unicode hex code point to human readable names list"

puts "loading full emoji list"
emoji_list_doc = Nokogiri::HTML(open(URL_EMOJI_LIST))

puts "emoji list loaded, converting to map"
emoji_list_entries = emoji_list_doc
  .css("tr")
  .select(&withoutHeaders)
  .map(&codeToName)

puts "emoji list map generated, writing csv"
CSV.open(OUTPUT_EMOJI_LIST_PATH, "wb") do |csv|
  emoji_list_entries.each do |entry|
    csv << entry
  end
end

puts "loading full emoji modifiers"
emoji_modifiers_doc = Nokogiri::HTML(open(URL_EMOJI_MODIFIERS))

puts "emoji modifiers loaded, converting to map"
emoji_modifiers_entries = emoji_modifiers_doc
  .css("tr")
  .select(&withoutHeaders)
  .map(&codeToName)

puts "emoji modifiers map generated, writing csv"
CSV.open(OUTPUT_EMOJI_MODIFIERS_PATH, "wb") do |csv|
  emoji_modifiers_entries.each do |entry|
    csv << entry
  end
end

puts "csv writing complete"
