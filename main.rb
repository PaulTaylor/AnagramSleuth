#!/usr/bin/env ruby

require 'sinatra'
require 'sinatra/streaming'

if development?
  require 'sinatra/reloader'
  puts 'Running in development mode'
end

require 'open-uri'
require 'zlib'

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
post '/sleuth/:numbers/:target' do
  in_nums = params[:numbers].split(',').collect do |x|
    x.to_i
  end
  target = params[:target].to_i

  operators = [ '+', '-', '*', '/']

  # Generate possible formulae
  last_round = in_nums.collect { |x| x.to_s }
  (2..in_nums.size).each do |idx|
    this_round = []
    last_round.each do |stem|
      # Add each possible combination of op and number to the end of the last round
      # Is this a new number that isn't currently in the formula?
      this_iter_nums = in_nums.clone
      form_nums = stem.split(/[\(\)+*\/-]/)
      form_nums.each do |s_fn|
        fn = s_fn.to_i
        next if fn == 0
        idx = this_iter_nums.index(fn)
        this_iter_nums.delete_at(idx) if idx
      end

      # this_iter_nums now contains the remaining numbers
      this_iter_nums.each do |new_num|
        operators.each do |op|
          formula = "(#{stem}#{op}#{new_num})"
          eval_f = formula.gsub(/([0-9]+)/, '\1.0')
          # No point doing more if we've hit the target
          # gsub forces arithmetic into float mode so we can detect non-integer arithmetic
          res = eval(eval_f)
          if res % 1 != 0 or res < 1 then
            # Decimal values cannot continue - only integers
            next
          elsif res == target.to_f then
            return formula
          else
            this_round << formula
          end
        end
      end
      # add to to_check
      last_round = this_round
    end
  end

  "No answer."
end

# Letters round
post '/sleuth/:in_words' do
  in_words = params[:in_words].gsub(/\s/, '').downcase
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
