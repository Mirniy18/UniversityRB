# frozen_string_literal: true

items = %w[Rock Paper Scissors]

loop do
  print 'Enter your choice (0 - rock, 1 - paper, 2 - scissors, 3 - exit): '

  user = Integer($stdin.gets.chomp, exception: false)

  next if user.nil? || !user.between?(0, 3)

  break if user == 3

  ai = rand(3)

  puts("Your choice is #{items[user]}")
  puts("AI   choice is #{items[ai]}")

  if user == ai
    puts 'Stalemate'
    next
  end

  if ai == (user + 1) % 3
    puts 'You lose. ('
  else
    puts 'You win. )'
  end
end
