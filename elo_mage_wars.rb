require 'csv'
require 'pry' # binding.pry;


STANDARD_SCORE = 1800

class Game
  attr_reader :char1, :char2, :result
  def initialize(char1, char2, result)
    @char1 = char1
    @char2 = char2
    @result = result
  end
end

class Character
  attr_reader :player, :mage, :spellbook
  def initialize(player, mage, spellbook)
    @player = player
    @mage = mage
    @spellbook = spellbook
  end
  def to_s
    "Character(#{player}, #{mage}, #{spellbook})"
  end
end

class History
  attr_accessor :mapping
  def initialize
    @mapping = {}
  end

  def fetch_elo_score(char)
    unless mapping.has_key?(char.player)
      mapping[char.player] = {}
    end

    unless mapping[char.player].has_key?(char.mage)
       mapping[char.player][char.mage] = {}
    end

    unless mapping[char.player][char.mage].has_key?(char.spellbook)
      mapping[char.player][char.mage][char.spellbook] = STANDARD_SCORE
    end

    return mapping[char.player][char.mage][char.spellbook]
  end

  def update_elo_score(char, new_score)
    mapping[char.player][char.mage][char.spellbook] = new_score
  end

  def ranked_characters
    dot_it(mapping).sort do |e1, e2| 
      e2[1] <=> e1[1] 
    end.map{|e| [e[0].split(".").join(" "), e[1]] }
  end
end


def dot_it(object, prefix = nil)
  if object.is_a? Hash
    object.map do |key, value|
      if prefix
        dot_it value, "#{prefix}.#{key}"
      else
        dot_it value, "#{key}"
      end
    end.reduce(&:merge)
  else
    {prefix => object}
  end
end

def elo_score(char1_old, char2_old, result, k: 100)
  diff = [(char2_old - char1_old).abs, 400].min
  tenth = 10**(diff / 400)
  chance_1 = 1.0 / (1 + tenth)
  chance_2 = 1.0 - chance_1
  r2 = result == 1 ? 0 : 1

  elo_new_1 = char1_old + (k * (result - chance_1))
  elo_new_2 = char2_old + (k * (r2 - chance_2))

  [elo_new_1, elo_new_2]
end

def print_score(char, old_score, new_score)
  puts "#{char} - #{old_score} - #{new_score}"
end

def parse_games(path_to_games: "games.csv")
  games = []
  CSV.foreach(path_to_games, headers: true, col_sep: ";") do |row|
    c1 = Character.new(row["player1"],row["mage1"],row["spellbook1"])
    c2 = Character.new(row["player2"],row["mage2"],row["spellbook2"])
    games << Game.new(c1, c2, row["result"].to_i)
  end
  games
end

games = parse_games
history = History.new
games.each_with_index do |g, index|
  old_score_1 = history.fetch_elo_score(g.char1)
  old_score_2 = history.fetch_elo_score(g.char2)
  new_score_1, new_score_2 = elo_score(old_score_1, old_score_2, g.result)
  history.update_elo_score(g.char1, new_score_1)
  history.update_elo_score(g.char2, new_score_2)
  print_score(g.char1, old_score_1, new_score_1)
  print_score(g.char2, old_score_2, new_score_2)
  puts "-"*50
end

puts "Ranking:"
history.ranked_characters.each_with_index do |r, index|
  puts "  #{index + 1}. #{r.join(" - ")}"
end


