# frozen_string_literal: true

begin
  #noinspection RubyResolve
  require './Popcount/popcount'
rescue LoadError
  puts 'Cannot load C extension for popcount, using Ruby implementation'

  def _popcount(x)
    r = 0

    while x > 0
      x &= x - 1
      r += 1
    end

    r
  end

  # @param [Integer] x
  # @return [Integer]
  def popcount(x)
    $popcount_cache[x] ||= _popcount x
  end
  $popcount_cache = {}
end
