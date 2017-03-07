#!/usr/bin/env ruby

require 'sinatra'
require 'sinatra/streaming'

if development?
  require 'sinatra/reloader'
  puts 'Running in development mode'
end

require 'open-uri'
require 'zlib'

require './lib/numbers_game.rb'

WORDLIST_FILE = './wordlist.gz'

# www.gnuterrypratchett.com
after do
  response.headers['X-Clacks-Overhead'] = "GNU Terry Pratchett"
end

# Index route
get '/' do
  erb :index
end

get '/numbers' do
  erb :numbers
end

# Numbers round
get '/sleuth/:numbers/:target' do
  start = Time.now

  in_nums = params[:numbers].split(',').collect do |x|
    x.to_i
  end
  target = params[:target].to_i
  operators = [ '+', '-', '*', '/']

  result = NumbersGame.new(in_nums, target, operators).run
  formula = result.text unless result.nil?

  return erb :numbers, :locals => { :formula => formula, :time => (Time.now - start) }
end

# Letters round
get '/sleuth/:in_words' do
  start = Time.now
  in_words = params[:in_words].gsub(/\s/, '').downcase
  min_word_length = [params[:min].to_i, 3].max

  # First test - regex test to determine if candidate word only uses letters we have
  matcher = /^[#{in_words}]{#{min_word_length},}$/

  result = []

  Zlib::GzipReader.open(WORDLIST_FILE) do |f|
    f.each_line do |candidate|
      candidate.downcase!
      candidate.chomp!

      if matcher =~ candidate then
        # Second test - use in_words and array to remove each char in turn
        # if this occurs without failing to remove a char we have a match
        # and we output it
        letters = in_words.chars
        res = candidate.chars.all? do |c_char|
          # returns nil if nothing removed

          l_idx = letters.index(c_char)
          letters.slice! l_idx if l_idx
        end

        result << candidate if res
      end
    end
  end

  result.sort! do |a,b|
    r = b.size - a.size
    if r == 0 then
      r = a <=> b
    end
    r
  end

  return erb :words, :locals => { :input => in_words, :result => result, :time => Time.now - start }
end
