# frozen_string_literal: true

module Functions
  def self.sin(x)
    Math.sin(x)
  end

  def self.cos(x)
    Math.cos(x)
  end

  def self.pow(base, exp)
    base ** exp
  end

  def self.root(x, degree = 2)
    x ** (1.0 / degree)
  end

  def self.sum(*args)
    args.inject(:+) or 0
  end

  def self._42
    42
  end
end

def tokenize(text)
  regex = %r{([0-9.]+)|([+\-*/^])|([()])|([A-Za-z_][A-Za-z_0-9]*)|(,)|(.)}

  result = text.scan(regex).map do |number, sign, parentheses, func, comma, unexpected|
    if number
      [(Integer(number, exception: false) or number.to_f), :number]
    elsif sign
      [sign == '^' ? :** : sign.to_sym, :sign]
    elsif parentheses
      [parentheses, :parentheses]
    elsif func
      begin
        [Functions.singleton_method(func.to_sym), :func]
      rescue NameError
        raise NameError, "Unknown function #{func}"
      end
    elsif comma
      [comma, :comma]
    elsif unexpected.strip.length.zero?
      nil
    else
      raise ArgumentError, "Unexpected token #{unexpected}"
    end
  end

  result.filter_map { |x| x }
end

class Function
  attr_accessor :func, :arity, :precedence

  def initialize(func, arity)
    @func = func
    @arity = arity
    @precedence = 0
  end

  def inspect
    "#{@func.name}<#{arity}>"
  end
end

class Operator < Function
  def initialize(func, arity)
    super func, arity
    @precedence = case @func
                  when :+
                    4
                  when :-
                    @arity == 1 ? 1 : 4
                  when :*, :/
                    3
                  when :**
                    2
                  else
                    raise ArgumentError, "Unexpected sign #{@func}"
                  end
  end

  def inspect
    @arity == 2 ? @func : "(#{@func})"
  end
end

def parse_rpn(tokens)
  lexemes = []
  stack = []
  arities = []

  previous_type = nil
  
  add_operator = lambda do |operator|
    if operator.func != :**
      lexemes << stack.pop while stack[-1].is_a?(Operator) && stack[-1].precedence < operator.precedence
    end

    stack << operator
  end

  tokens.each do |token, type|
    case type
    when :number
      lexemes << token
    when :sign
      add_operator.(Operator.new(token, token == :- && %i[sign l_par].include?(previous_type) ? 1 : 2))
    when :parentheses
      if token == '('
        type = :l_par
        stack << token
      else
        type = :r_par

        if previous_type == :l_par
          stack.pop

          raise ArgumentError, 'Both parentheses without a function' unless stack[-1].is_a?(Function) && !stack[-1].is_a?(Operator)

          lexemes << stack.pop
          lexemes[-1].arity = arities.pop
        else
          loop do
            raise ArgumentError, 'Extra closing parenthesis' if stack.empty?

            t = stack.pop

            break if t == '('

            lexemes << t
          end

          if stack[-1].is_a?(Function) && !stack[-1].is_a?(Operator)
            lexemes << stack.pop
            lexemes[-1].arity = arities.pop + 1
          end
        end
      end
    when :func
      stack << Function.new(token, nil)
      arities << 0
    when :comma
      raise ArgumentError, 'Comma outside a function' if arities.empty?

      arities[-1] += 1

      loop do
        raise ArgumentError, 'Extra comma' if stack.empty?

        break if stack[-1] == '('

        lexemes << stack.pop
      end
    else
      raise ArgumentError, "Unexpected token type #{type}"
    end

    previous_type = type
  end

  stack.reverse_each do |lexeme|
    raise ArgumentError, 'Extra opening parenthesis' if lexeme == '('

    lexemes << lexeme
  end

  lexemes
end

def eval_rpn(expression)
  stack = []

  expression.each do |lexeme|
    stack << if lexeme.is_a? Function
               if lexeme.is_a? Operator
                 if (lexeme.arity == 1) && (lexeme.func == :-)
                   -stack.pop
                 elsif lexeme.func == :/
                   args = stack.pop(lexeme.arity)
                   tail = args[1..]
                   args[0] = args[0].to_f if tail && args[0] % tail.inject(:*) != 0
                   args.inject(lexeme.func)
                 else
                   stack.pop(lexeme.arity).inject(lexeme.func)
                 end
               else
                 lexeme.func.call(*stack.pop(lexeme.arity))
               end
             else
               lexeme
             end
  end

  raise ArgumentError unless stack.length == 1

  stack[0]
end

def format_pn(rpn, reverse)
  stack = []

  rpn.each do |lexeme|
    stack << if lexeme.is_a? Function
               operands = stack.pop(lexeme.arity).map { |x| x.instance_of?(String) ? "(#{x})" : x } * ' '
               func = lexeme.func == :** ? '^' : lexeme.func.name

               if reverse
                 "#{operands} #{func}"
               else
                 "#{func} #{operands}"
               end
             else
               lexeme
             end
  end

  raise ArgumentError unless stack.length == 1

  "(#{stack[0]})"
end

def eval_str(text)
  eval_rpn(parse_rpn(tokenize(text)))
end

def assert(expr, expected)
  actual = eval_str expr

  raise "expected #{expected}, got #{actual}" if actual != expected
end

def tests
  assert '42', 42
  assert '1-2', -1
  assert '2-1', 1
  assert '42+451', 493
  assert '2+3*4', 14
  assert '(2+3)*4', 20
  assert '2*-3', -6
  assert '(-2)+3', 1
  assert '(2+3)*4-pow(2, 10)', -1004
  assert '1/2', 0.5
  assert '4/2', 2
  assert '4/3', 4.0 / 3
  assert '2^3^4', 2 ** 3 ** 4
  assert '2*-3', -6
  assert 'root(16)', 4
  assert 'root(16, 4)', 2
  assert 'sum(1, 2, 3)', 6
  assert 'sum()', 0
  assert '_42()', 42

  puts 'All tests passed'
end

text = '451-2*42+1'

puts "Input: #{text}"
puts "Tokens: #{tokens = tokenize text}"
puts "RPN stack: #{parsed = parse_rpn tokens}"
puts "RPN: #{format_pn parsed, true}"
puts "NPN: #{format_pn parsed, false}"
puts "Evaluated: #{eval_rpn parsed}"

tests
