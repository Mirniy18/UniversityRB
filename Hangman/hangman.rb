# frozen_string_literal: true

LIVES = 6

def play(secret)
  lives = LIVES

  secret_len = secret.length

  word = '_' * secret_len

  loop do
    print "Lives: #{'o' * lives}#{' ' * (LIVES - lives)}, Word: #{word}, Guess: "

    next_word = (gets || '').each_char do |guess|
      if 'A' <= guess && guess <= 'Z'
        guess.downcase!
      elsif !('a' <= guess && guess <= 'z')
        next
      end

      changed = false

      secret.each_char.each_with_index do |c, i|
        if c == guess
          word[i] = c
          changed = true
        end
      end

      if changed
        unless word.include? '_'
          puts "You win (the word is #{secret}). ("
          break true
        end
      else
        if lives == 1
          puts "You lose (the word is #{secret}). ("
          break true
        end

        lives -= 1
      end
    end

    break if next_word == true
  end
end

loop do
  begin
    secret = File.read('Hangman/words.txt').split.sample
  rescue Errno::ENOENT
    puts 'Dictionary not found'
    break
  end

  if secret.nil? || secret.length.zero? || secret.each_char.any? { |c| !('a' <= c && c <= 'z') }
    puts 'Dictionary is broken'
    break
  end

  play secret
end
