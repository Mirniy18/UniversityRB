# frozen_string_literal: true

require 'English'
require 'benchmark'
require 'pp'
require_relative 'popcount'

# @param [Array<Array<Integer>>] grid
def solve(grid, &solution_handler)
  by_row = Array.new(9, 0)
  by_col = Array.new(9, 0)
  by_box = Array.new(9, 0)

  zeros = []

  grid.each_with_index do |row, y|
    row.each_with_index do |v, x|
      bit = 1 << v

      by_row[y] |= bit
      by_col[x] |= bit
      by_box[xy2box x, y] |= bit

      zeros << [x, y] if v == 0
    end
  end

  solve_sub grid, by_row, by_col, by_box, zeros, &solution_handler
end

# @param [Array<Array<Integer>>] grid
# @param [Array<Integer>] by_row
# @param [Array<Integer>] by_col
# @param [Array<Integer>] by_box
# @param [Array<[Integer, Integer]>] empty_cells
# @param [Proc] solution_handler
def solve_sub(grid, by_row, by_col, by_box, empty_cells, &solution_handler)
  x, y = delete_best empty_cells, by_row, by_col, by_box

  if x.nil?
    yield grid if block_given?
    return
  end

  box_i = xy2box x, y

  m_row = by_row[y]
  m_col = by_col[x]
  m_box = by_box[box_i]

  get_options(m_row | m_col | m_box).each do |v|
    grid[y][x] = v

    bit = 1 << v

    by_row[y] |= bit
    by_col[x] |= bit
    by_box[box_i] |= bit

    solve_sub grid, by_row, by_col, by_box, empty_cells, &solution_handler

    by_row[y] = m_row
    by_col[x] = m_col
    by_box[box_i] = m_box
  end

  grid[y][x] = 0
  empty_cells << [x, y]

  nil
end

# @param [Array<Integer>] empty_cells
# @param [Array<Integer>] by_row
# @param [Array<Integer>] by_col
# @param [Array<Integer>] by_box
# @return [[Integer, Integer], nil]
def delete_best(empty_cells, by_row, by_col, by_box)
  j = nil
  max_c = 0

  empty_cells.each_with_index do |(x, y), i|
    c = popcount((by_row[y] | by_col[x] | by_box[xy2box x, y]) >> 1)

    break j = i if c == 8
    
    max_c, j = c, i if c > max_c
  end

  empty_cells.delete_at j if j
end

# @param [Integer] mask
# @return [Array<Integer>]
def get_options(mask)
  (1..9).filter { |v| (mask & 1 << v) == 0 }
end

# @param [Integer] x
# @param [Integer] y
# @return [Integer]
def xy2box(x, y)
  y - y % 3 + x / 3
end

sudoku = [[0, 0, 0, 0, 7, 0, 0, 0, 0],
          [6, 0, 0, 1, 9, 5, 0, 0, 0],
          [0, 9, 8, 0, 0, 0, 0, 6, 0],
          [8, 0, 0, 0, 6, 0, 0, 0, 3],
          [4, 0, 0, 8, 0, 3, 0, 0, 1],
          [7, 0, 0, 0, 2, 0, 0, 0, 6],
          [0, 6, 0, 0, 0, 0, 2, 8, 0],
          [0, 0, 0, 4, 1, 9, 0, 0, 5],
          [0, 0, 0, 0, 8, 0, 0, 7, 9]]

solve(sudoku) { |grid| PP.pp grid, $DEFAULT_OUTPUT, 29 }

2.times do
  times = 500
  puts "#{times} runs in #{Benchmark.measure { times.times { solve sudoku } }.total.round 4} s"
end
