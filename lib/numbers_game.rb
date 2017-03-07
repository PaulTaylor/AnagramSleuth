require 'set'

MAX_WORKING_VALUE = 999999

class FoundSolution < StandardError
  attr_reader :answer

  def initialize(answer)
    @answer = answer
  end
end

class Expression
  attr_reader :text, :used_numbers, :remaining_numbers

  def initialize(text, used_numbers, remaining_numbers)
    @text = text.to_s
	@used_numbers = used_numbers
	@remaining_numbers = remaining_numbers
  end

  def result
    # gsub ensures we use float arithmetic not int (with bad roundings)
	@result = eval(@text.gsub(/([0-9]+)/, '\1.0')) if @result.nil?
	@result
  end

  def extend_with(op, right)
    left = self

	if ['+', '*'].include? op then
	  # we adjust left/right so that the side that sorts lowest
	  # by formula is on the left.  This ensures consistency and
	  # means we don't add both (1 + 2) and (2 + 1) to the expression
	  # list (as it's pointless).
	  left, right = [left, right].sort_by { |e| e.text }
	end

    remaining_numbers = Array.new(left.remaining_numbers)
	used_numbers = Array.new(left.used_numbers)

	# Need to make sure that the numbers used on the right are
	# remaining on the left.  This is complicated by the possibility
	# of duplicates in one or both.

	# if right.used_numbers is larger than left.remaining_numbers - match is impossible
	return if right.used_numbers.size > left.remaining_numbers.size

	# Check each used_number to see if its in the remaining_numbers in turn:
	right.used_numbers.each do |n|
	  del_idx = remaining_numbers.index(n)

	  unless del_idx
		# the rhs formula uses a number that is not available - abort
	    return
	  end

	  del_num = remaining_numbers.delete_at(del_idx)
	  used_numbers << del_num
	end

	# Now we can be sure we've only used numbers that were available, and that
	# remaining_numbers and used_numbers are appropriately set
	e = Expression.new("(#{left.text} #{op} #{right.text})", used_numbers, remaining_numbers)
	begin
	  if e.result() == e.result().to_i and e.result() > 1 and e.result() < MAX_WORKING_VALUE then
	    return e
      else
	    nil
	  end
	rescue
	end
  end

  def to_s
    @text
  end

  def eql?(other)
    @text.eql? other.text
  end

  def hash
	@text.hash
  end
end

class NumbersGame

  def initialize(numbers, target, ops = ['+', '-', '/', '*'])
    @numbers = numbers
    @target = target
    @ops = ops
  end

  def run

    # List of expressions we've generated so far
    @expressions = Set.new

    # Individual numbers are expressions in their own right
    @numbers.each_with_index do |n, idx|
      remaining = @numbers.take(idx) + @numbers[(idx + 1)..@numbers.size()]
      @expressions.add(Expression.new(n, [n], remaining))
    end

    # expressions can be extended by using one of the operations
    def extend_expression(left, lidx)
      extended = Set.new
      @ops.each do |op|
        @expressions.each_with_index do |right, ridx|
    	  next if ridx == lidx
    	  new_exp = left.extend_with(op, right)
    	  if new_exp and (new_exp.result == @target)
    	    raise FoundSolution.new(new_exp)
    	  end
    	  extended.add(new_exp) unless new_exp.nil?
    	end
      end
      return extended
    end

    answer = nil
    (1..3).each do |iteration|
      begin
        new_expressions = Set.new

      	# Attempt to extend each expression (that is able to be extended)
      	@expressions.each_with_index do |exp, idx|
          new_expressions.merge(extend_expression(exp, idx))
        end

        @expressions.merge(new_expressions)
      rescue FoundSolution => f
        answer = f.answer
      end
    end

    return answer
  end
end
