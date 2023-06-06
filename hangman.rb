require 'set'
require 'json'

filename = 'google-10000-english-no-swears.txt'

def get_random_word
  random_word = @words.sample
  random_word.length.between?(5, 12) ? random_word : get_random_word
end

@words = File.readlines(filename).map(&:chomp)
word = get_random_word

class Game
  attr_reader :hidden, :lives, :already_guessed

  def initialize(word)
    @word = word
    @hidden = "_" * @word.length
    @lives = 8
    @already_guessed = Set.new
  end

  def make_guess(char)
    @already_guessed.add(char)
    if @word.include?(char)
      @word.each_char.with_index do |ch, index|
        @hidden[index] = ch if ch == char
      end
      true
    else
      @lives -= 1
      false
    end
  end

  def won?
    @word == @hidden
  end

  def ended?
    won? || lives == 0
  end

  def to_json
    {
      'word' => @word,
      'hidden' => @hidden,
      'lives' => @lives,
      'already_guessed' => @already_guessed.to_a
    }.to_json
  end

  def self.from_json(json)
    game_data = JSON.parse(json)
    word = game_data['word']
    Game.new(word).tap do |game|
      game.instance_variable_set(:@hidden, game_data['hidden'])
      game.instance_variable_set(:@lives, game_data['lives'])
      game.instance_variable_set(:@already_guessed, Set.new(game_data['already_guessed']))
    end
  end
end

SAVES_PATH = "saves/"

def generate_file_name
  words = []
  3.times do
    words << get_random_word.capitalize
  end
  words.join("").concat(".json")
end

def save_game(game)
  filename = generate_file_name
  serialized_game = JSON.dump(game.to_json)
  File.open(SAVES_PATH + filename, 'w') do |file|
    file.write(serialized_game)
  end
  puts "Game saved as: #{filename}"
end

def prompt_file_name
  puts "Please enter the file name of the saved game"
  filename = gets.chomp
  until File.exist?(SAVES_PATH + filename)
    puts "File you have entered does not exist, try again"
    filename = gets.chomp
  end
  filename
end

def load_game
  filename = prompt_file_name
  serialized_game = File.read(SAVES_PATH + filename)
  game_data = JSON.parse(serialized_game)
  Game.from_json(game_data)
end


puts "Welcome to Hangman!"
puts "(1) New game"
puts "(2) Load game"
mode = gets.chomp
until mode == '1' || mode == '2'
  print "Please, enter 1 or 2: "
  mode = gets.chomp
end

if mode == '1'
  game = Game.new(word)
else
  game = load_game
  puts "\n\nWelcome back"
end

puts "The word has #{word.length} letters."
puts "You have #{game.lives} lives."
puts "Type 'save' at any point of the game to save"
puts "Hidden word: #{game.hidden}"

until game.ended?
  print"Please enter a character: "
  guess = gets.chomp.downcase

  if guess == 'save'
    save_game(game)
    exit
  end

  until guess.length == 1 && guess =~ /[[:alpha:]]/ && !game.already_guessed.include?(guess)
    print "Invalid guess. Please enter a single alphabetic character that you haven't guessed before: "
    guess = gets.chomp.downcase
  end

  if game.make_guess(guess)
    puts "Correct guess!"
  else
    puts "Wrong guess. You have #{game.lives} lives left."
  end

  puts game.hidden
end

if game.won?
  puts "Congratulations! You guessed the word correctly: #{game.hidden}"
else
  puts "You lost! The word was #{word}. Better luck next time!"
end

