require 'open-uri'
require 'json'

class GamesController < ApplicationController

  def new
    @letters = (0...10).map { ('A'..'Z').to_a[rand(26)] }
  end

  def score
    @word = params[:word]
    @result = run_game(@word, JSON.parse(params[:letters]), params[:start].to_i, Time.now.to_i)
    session['score'] += @result[:score]
  end

  def home
    session['score'] = 0
  end

# ----- GAME RESULTS -----

def hash_winner(attempt, start_time, end_time)
  result = Hash.new(0)
  # - calcul du temps de reponse
  # - calcul du score
  # - message = "Well done!"
  result[:time] = "Your time: #{end_time - start_time}s"
  result[:score] = attempt.size - (end_time - start_time) / 20
  result[:message] = "Congratulation! #{attempt.upcase} is a valid English word!"
  return result
end

  def english_word?(attempt)
    url = "https://wagon-dictionary.herokuapp.com/#{attempt}"
    word_serialized = open(url).read
    word = JSON.parse(word_serialized)
    return word['found']
  end

  def hash_occ_letters(attempt, grid)
  # nb occurrences de chaque lettre de l'attempt
  counter_attempt = Hash.new(0)
  attempt.upcase.split('').each { |letter| counter_attempt[letter] += 1 }
  # nb occurrences de chaque lettre de la grid
  counter_grid = Hash.new(0)
  grid.each { |letter| counter_grid[letter] += 1 }
  return [counter_attempt, counter_grid]
end

def overused_letters?(counter_attempt, counter_grid)
  # tableau pour stocker true ou false selon selon si occ attempt > occ grid
  array = Array.new(0)
  counter_attempt.each do |letter, occ|
    if occ > counter_grid[letter]
      # => au moins une lettre de la grille est utilisee plus d'1 fois:
      array << false
    else
      # => toutes les lettres de la grille sont utilisees au max 1 fois
      array << true
    end
  end
  return true if array.include?(false)
end

def run_game(attempt, grid, start_time, end_time)
  # TODO: runs the game and return detailed hash of result
  # verifie si le mot existe
  # => JSON API
  return result = {score: 0, message: "Sorry but #{attempt.upcase} does not seem to be a valid English word..."} unless english_word?(attempt)
  # verifie si chaque lettre de attempt est inclus dans la grille
  return result = {score: 0, message: "Sorry but #{attempt.upcase} can't be built out of #{grid.join(",")}"} unless attempt.upcase.split('').all? { |letter| grid.include?(letter) }

  # verifie si chaque lettre de la grille est utilisee une seule fois
  # nb occurrences de chaque lettre de l'attempt
  counters = hash_occ_letters(attempt, grid)
  if overused_letters?(counters[0], counters[1])
    # => au moins une lettre de la grille est utilisee plusieurs fois
    result = {score: 0, message: "Sorry but #{attempt.upcase} can't be built out of #{grid.join(",")}"}
  else
    # => toutes les conditions sont verifiee
    result = hash_winner(attempt, start_time, end_time)
  end
  return result
end

end
