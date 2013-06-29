#!/usr/bin/env ruby

require 'sinatra'
require 'sinatra/streaming'
require 'sinatra/reloader' if development?

require 'open-uri'
require 'zlib'

WORDLIST_FILE = './wordlist.gz'

# Index route
get '/' do
  erb :index
end

# Actual Work
post '/sleuth/:in_words' do
  in_words = params[:in_words].gsub(/\s/, '').downcase!
  min_word_length = [params[:min].to_i, 3].max

  # First test - regex test to determine if candidate word only uses letters we have
  matcher = /^[#{in_words}]{#{min_word_length},}$/

  stream do |out|

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

          out.write("#{candidate}\n") if res
        end
      end
    end
  end
end
