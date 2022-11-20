# frozen_string_literal: true

require 'benchmark'

PARENTHESES_ALL = '([{)]}'
PARENTHESES_ALL_A = PARENTHESES_ALL.chars.map(&:ord)

def check(s)
  stack = []

  s.chars.each do |c|
    next unless PARENTHESES_ALL.include? c

    i = PARENTHESES_ALL_A.find_index c.ord

    if i < 3
      stack << i
    else
      return false unless (i - 3) == stack.pop
    end
  end

  stack.empty?
end

def tests(f)
  raise unless method(f).call '()[]{}'
  raise unless method(f).call '([{}])'
  raise unless method(f).call '(_)[__]{___}'
  raise unless method(f).call '(_[__{___}__]_)'

  raise if method(f).call '(]'
  raise if method(f).call '([)]'
  raise if method(f).call '([{}])(]'
  raise if method(f).call '('
  raise if method(f).call ')'

  puts 'Passed'
end

def benches
  times = 100_000

  s = '(_[__{___}__]_)(_[__{___}__]_)(_[__{___}__]_)(_[__{___}__]_)(_[__{___}__]_)'

  puts "check1: #{Benchmark.measure { times.times { check s } }.total}"
  # puts "check2: #{Benchmark.measure { times.times { check2 s } }.total}"

  puts "check1: #{Benchmark.measure { times.times { check s } }.total}"
  # puts "check2: #{Benchmark.measure { times.times { check2 s } }.total}"
end

tests :check
# tests :check2

benches
