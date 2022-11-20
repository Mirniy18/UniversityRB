# frozen_string_literal: true

require 'stringio'

NUMBERS_COUNT = 3

operator_s, operator = loop do
  print 'Enter operation (+-*/):'

  s = gets.chomp

  r = {
    '+' => :+,
    '-' => :-,
    '*' => :*,
    '/' => :/
  }[s]

  break s, r unless r.nil?
end

numbers = (1..NUMBERS_COUNT).each.lazy.map do |i|
  loop do
    print "Enter number #{i}:"
    begin
      break Integer(gets.chomp)
    rescue ArgumentError
      next
    end
  end
end

operator_s = " #{operator_s} "
expr_s_io = StringIO.new

begin
  result = numbers.map do |x|
    expr_s_io << operator_s if expr_s_io.length.positive?
    expr_s_io << x
    x
  end.inject(operator)

  puts "Result: #{expr_s_io.string} = #{result}"
rescue ZeroDivisionError
  puts 'Division by 0'
end
