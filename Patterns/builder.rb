# frozen_string_literal: true

class Food
  attr_accessor :kcal, :carbohydrates, :fat, :protein, :water, :vitamins, :minerals, :note

  def initialize(kcal)
    @kcal = kcal
    yield(self) if block_given?
    return if block_given?

    @carbohydrates = @fat = @protein = @water = 0
    @vitamins = {}
    @minerals = {}
  end
end

class FoodBuilder
  def initialize(kcal)
    @f = Food.new(kcal)
  end

  def carbohydrates(g)
    @f.carbohydrates = g
    self
  end

  def fat(g)
    @f.fat = g
    self
  end

  def protein(g)
    @f.protein = g
    self
  end

  def water(g)
    @f.water = g
    self
  end

  def macronutrients(carbohydrates, fat, protein)
    @f.carbohydrates = carbohydrates
    @f.fat = fat
    @f.protein = protein
    self
  end

  def vitamins(x)
    @f.vitamins = x
    self
  end

  def vitamins_from_str(s)
    @f.vitamins = Hash[s.split(',')
                        .map { |x| x.chomp.split }
                        .map { |name, weight| [name.to_sym, weight[0...-2].to_f * (weight[-2..] == 'ug' ? 1e-3 : 1)] }]
    self
  end

  def vitamin_mg(name, mg)
    @f.vitamins[name] = mg
    self
  end

  def vitamin_ug(name, ug)
    @f.vitamins[name] = ug / 1_000
    self
  end

  def minerals(x)
    @f.minerals = x
  end

  def mineral_mg(name, mg)
    @f.minerals[name] = mg
    self
  end

  def mineral_ug(name, ug)
    @f.minerals[name] = ug / 1_000
    self
  end

  def note(s)
    if @f.note.nil?
      @f.note = s
    else
      @f.note += "\n#{s}"
    end

    self
  end

  def berry_note
    note 'This is a berry.'
    self
  end

  def read_note_from_file(path)
    note File.read path
    self
  end

  def get
    @f
  end
end

tomato1 = Food.new(18) do |x|
  x.carbohydrates = 3.9
  x.fat = 0
  x.protein = 0
  x.water = 0
  x.vitamins = { C: 14, K: 0.0079 }
  x.minerals = {}
  x.note = 'This is a berry.'
end

tomato2 = FoodBuilder.new(18)
                     .carbohydrates(3.9)
                     .vitamin_mg(:C, 14).vitamin_ug(:K, 7.9)
                     .berry_note
                     .get

tomato3 = FoodBuilder.new(18)
                     .macronutrients(3.9, 0.2, 0.9)
                     .vitamins_from_str('C 14mg, E 0.54mg, K 7.9ug')
                     .mineral_mg(:Ca, 10)
                     .mineral_mg(:Fe, 0.27)
                     .note('The answer is:')
                     # .read_note_from_file('D:\theAnswer.txt')
                     .get

p tomato1
p tomato2
p tomato3
