module TheHelper
  class StudentT
    attr_reader :v

    def initialize(v)
      raise ArgumentError if v <= 0

      @v = v.to_f
      @v_inv = 1.0 / v

      @pdf_factor = Math.gamma((v + 1) * 0.5) / (Math.sqrt(v * Math::PI) * Math.gamma(v * 0.5))
      @pdf_exponent = -(v + 1) * 0.5

      define_singleton_method(:icdf, case v
                                     when 1
                                       proc { |y| Math.tan(Math::PI * (y - 0.5)) }
                                     when 2
                                       proc do |y|
                                         return Float::INFINITY if y == 1
                                         return -Float::INFINITY if y == 0

                                         (2 * y - 1) * Math.sqrt(2 / (4 * y * (1 - y)))
                                       end
                                     when 4
                                       proc do |y|
                                         a = Math.sqrt(4 * y * (1 - y))

                                         [0, 2, -2][y <=> 0.5] * Math.sqrt((Math.cos(Math.acos(a) / 3) / a) - 1)
                                       end
                                     else
                                       proc { raise NotImplementedError }
                                     end)
    end

    def pdf(x)
      @pdf_factor * (1 + x * x * @v_inv) ** @pdf_exponent
    end

    def pdf_max_value
      pdf 0
    end

    # @return [Integer, nil]
    def mean
      0 if @v > 1
    end

    # @return [Float, nil]
    def variance
      return @v / (@v - 2) if @v > 2

      Float::INFINITY if @v > 1
    end
  end

  # @param [Range<Float>] interval
  # @param [StudentT] distribution
  # @param [Integer] n
  def self.inverse(interval, distribution, n = 1)
    loop.lazy.map { distribution.icdf rand 0.0..1.0 }.filter { |x| interval.include? x }.take(n).to_a
  end

  # @param [Range<Float>] interval
  # @param [StudentT] distribution
  # @param [Integer] n
  def self.neumann(interval, distribution, n = 1)
    y_max = distribution.pdf_max_value

    result = Array.new n

    i = 0

    loop do
      x = rand interval
      y = rand 0..y_max

      next unless distribution.pdf(x) > y

      result[i] = x

      i += 1
      break if i == n
    end

    result
  end

  # @param [Float] x0
  # @param [Range<Float>] interval
  # @param [StudentT] distribution
  # @param [Integer] n
  def self.metropolis(x0, interval, distribution, n = 1)
    x = x0
    delta = 0.2

    n.times.map do
      x1 = x + (rand(0.0..2.0) - 1) * delta

      alpha = interval.include?(x1) ? distribution.pdf(x1) / distribution.pdf(x) : 0

      x = x1 if alpha >= 1 || rand(0.0..1.0) < alpha

      x
    end
  end

  # @param [Float] x0
  # @param [Range<Float>] interval
  # @param [StudentT] distribution
  # @param [Integer] n
  # @param [Integer] burn_in
  def self.metropolis_with_burn_in(x0, interval, distribution, n = 1, burn_in = 1_000)
    TheHelper.metropolis(x0, interval, distribution, n + burn_in)[burn_in..]
  end

  def self.mean(sum, n)
    sum / n
  end

  def self.variance(xs, n, mean)
    (xs.map { |x| x - mean }.inject { |acc, t| acc + t * t }) / n
  end

  def self.bins(a, bin_width = 0.1)
    w_half = bin_width * 0.5
    w_inv = 1.0 / bin_width

    s = bin_width.to_f.to_s
    r = s.length - s.index('.') - 1

    tally = a.map { |x| (((x + w_half) * w_inv).floor * bin_width).round r }.tally

    tally_sum = tally.map { |_, y| y }.sum

    tally.map { |x, y| [x, y / (tally_sum * bin_width)] }
  end

  # @param [Integer] n
  # @param [Range<Float>] interval
  # @param [Float] v
  # @param [Float] w
  # @param [Integer] methods
  def self.calc_chart_data(n, interval, v, w, methods)
    raise if n <= 0 || v <= 0 || w <= 0

    d = TheHelper::StudentT.new v

    raw = []

    raw << { name: 'Inverse', data: TheHelper.inverse(interval, d, n) } unless methods & 1 == 0
    raw << { name: 'Neumann', data: TheHelper.neumann(interval, d, n) } unless methods & 2 == 0
    raw << { name: 'Metropolis', data: TheHelper.metropolis_with_burn_in(0.0, interval, d, n) } unless methods & 4 == 0

    raw
  end

  def self._fmt4json(x)
    return 'undefined' if x.nil?
    return x if x.is_a?(String)

    [x, '∞', '-∞'][x.infinite? || 0]
  end

  # @param [Array<Float>] xs
  def self._calc_mean_and_variance(xs)
    n = xs.length

    mean = self.mean xs.sum, n

    [_fmt4json(mean), _fmt4json(variance(xs, n, mean))]
  end

  # @param [Float] v
  # @param [Hash{String->Array<Float>}] raw
  def self.calc_mean_and_variance(v, raw)
    a = raw.map { |d| [d[:name], _calc_mean_and_variance(d[:data])] }

    d = StudentT.new v

    [['Analytic', [_fmt4json(d.mean), _fmt4json(d.variance)]], *a].to_h
  end
end
