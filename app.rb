#! /usr/bin/ruby
$KCODE = 'u'

class Card
  WIDTH = 71 # px - width of the image
  HEIGHT = 96 # px - height of the image

  attr_accessor :value, :colour

  @@width = 100;
  @@height = 130;

  def initialize(value = nil, colour = nil)
    @value = value || rand(13) + 1
    @colour = colour || rand(4)
  end

  def self.width
    @@width
  end
  def self.height
    @@height
  end

  def image
    filename = 'cards/'
    filename += case colour
               when 0: 'h'
               when 1: 'd'
               when 2: 's'
               when 3: 'c'
               end
    filename += case value
                when 11: 'j'
                when 12: 'q'
                when 13: 'k'
                else
                  value.to_s
                end
    filename += '.png'
  end

  def to_s
    text = ''
    text = case @value
    when 1: 'A'
    when 11: 'J'
    when 12: 'Q'
    when 13: 'K'
    else
      value.to_s
    end

#    text += case colour
#            when 0: ♥
#            when 1: ♦
#            when 2: ♠
#            when 3: ♣
#            end
    text = "#{text}.#{colour}"
    text
  end

  def self.restricted?(value, colour)
    return true if [[1, 0], [2, 2], [3, 1], [4, 0]].include?([value, colour])
    return false
  end
end

class Deck
  attr_accessor :cards

  def initialize(random = true)
    @cards = Array.new
    0.upto(51) do |i|
      @cards << Card.new((i % 13) + 1, i / 13) unless Card.restricted?((i % 13) + 1, i / 13)
    end
    if random
      @cards.shuffle!
    end
  end

  def first
    @cards.first
  end

  def card
    @cards.shift
  end
end

class Pile 
  attr_accessor :cards
  
  def initialize 
    @cards = Array.new
  end

  def last
    @cards.last
  end

  def <<(card)
    @cards << card
  end

  def card
    @cards.pop
  end

  def empty?
    @cards.length == 0
  end 
end

class Game
  def initialize
    new_game
  end

  def new_game
    @board = Board.new

    draw
  end

  def draw
#    @board.draw
  end
end

class Board
  BORDER_COLOUR = '#F6D353'
  BORDER_WIDTH = 3

  attr_accessor :deck, :piles, :source_pile, :target_pile

  def initialize
    @source_pile = nil
    @target_pile = nil
    @card = nil

    setup_board
  end

  def setup_board
    @deck = Deck.new
    @piles = [@deck, Pile.new, Pile.new, Pile.new, Pile.new, Pile.new, Pile.new, Pile.new, Pile.new] # ouch!
    @piles[1] << Card.new(1, 0)
    @piles[2] << Card.new(2, 2)
    @piles[3] << Card.new(3, 1)
    @piles[4] << Card.new(4, 3)
  end

end

Shoes.app(:title => 'Calculate!', :width => 800, :height => 600) do
  def activate(pile_number)
    @board.source_pile = @board.piles[pile_number]
    @borders.each do |border|
      border.hide
    end
    @borders[pile_number].show
  end

  def deactivate(pile_number)
    @board.source_pile = nil
    @borders[pile_number].hide
  end

  def play(pile_number)
    card = @board.source_pile.card

    if (1 .. 4) === pile_number
      if @board.piles[pile_number].card.value + to == card.value
        @board.piles[pile_number] << card
        @images[pile_number] = card.image
      else
#        puts "Against the rules!"
      end
    elsif (5 .. 8) === pile_number
      @board.piles[pile_number] << card
      @images[pile_number] = card.image
    else 
#      puts "Wrong 'to' pile!"
    end
    deactivate(pile_number)
  end

  def action(pile_number)
    pile_groups = [[0], [1, 2, 3, 4], [5, 6, 7, 8]]
    if @board.source_pile.nil?
      if pile_groups[0].include?(pile_number)
        activate(pile_number)
      elsif pile_groups[2].include?(pile_number) and !@board.piles[pile_number].empty?
        activate(pile_number)
      else
        # incorrect move
      end
    elsif @board.source_pile == @board.deck
      if pile_groups[0].include?(pile_number)
        deactivate(pile_number)
      else
        play(pile_number)
      end
    else
      if pile_groups[1].include?(pile_number)
        play(pile_number)
      elsif pile_groups[2].include?(pile_number)
        activate(pile_number)
      else
        # incorrect move
      end
    end
  end

  $app = self
#  @game = Game.new
  @board = Board.new 
  @borders = Array.new
  @images = Array.new

  stack :width => 1.0 do
    flow :top => 0.01, :left => 0.01 do
      # top
      flow :width => 0.4 do
        flow :width => Card::WIDTH, :height => Card::HEIGHT do 
          # deck
          @images[0] = image @board.deck.card.image
          @borders[0] = border Board::BORDER_COLOUR, :strokewidth => Board::BORDER_WIDTH
          @borders[0].hide
          click do
            action(0)
          end
        end
      end # end deck
      flow :width => 0.6 do
        # top piles
        1.upto(4) do |i|
          left = (i - 1) * 0.2
          left += (i - 1) * 0.01 if i > 1
          stack :left => left, :width => Card::WIDTH, :height => Card::HEIGHT do
            @images[i] = image @board.piles[i].card.image
            @borders[i] = border Board::BORDER_COLOUR, :strokewidth => Board::BORDER_WIDTH
            @borders[i].hide
            click do
              action(i)
            end
          end
        end
      end # end top piles
    end # end top

    flow :top => 110, :left => 0.41, :width => 0.6 do
      # bottom
      5.upto(8) do |i|
        left = (i - 5) * 0.2
        left += (i - 5) * 0.01 if i - 5 > 0
        stack :left => left, :width => Card::WIDTH, :height => Card::HEIGHT do
          @images[i] = image 'cards/empty.png'
          @borders[i] = border Board::BORDER_COLOUR, :strokewidth => Board::BORDER_WIDTH
          @borders[i].hide
          click do
            action(i)
          end
        end # end stack
      end
    end # end bottom
  end

  button 'Quit' do
    exit
  end


=begin
loop do
  card = nil
  from_pile = nil
  puts "#{"%4s" % deck.first} [0]            #{"%4s" % piles[0].last} [1]    #{"%4s" % piles[1].last} [2]    #{"%4s" % piles[2].last} [3]    #{"%4s" % piles[3].last} [4]"
  puts "                    #{"%4s" % piles[4].last} [5]    #{"%4s" % piles[5].last} [6]    #{"%4s" % piles[6].last} [7]    #{"%4s" % piles[7].last} [8]"

  print "Choose pile (from to): "
  from, to = gets.split(/\s+/)
  break if from.strip == 'q'
  from = from.to_i
  to = to.to_i
  if from == 0
    card = deck.first
    from_pile = deck
  elsif (1 .. 4) === from
    puts "Against the rules!"
    redo
  elsif (5 .. 8) === from
    card = piles[from - 1].last
    from_pile = piles[from -1]
  else
    puts "Wrong 'from' pile!"
  end

  if (1 .. 4) === to
    if piles[to - 1].last.value + to == card.value
      piles[to - 1] << from_pile.card
    else
      puts "Against the rules!"
      redo
    end
  elsif (5 .. 8) === to
    piles[to - 1] << from_pile.card
  else 
    puts "Wrong 'to' pile!"
    redo
  end
end

puts "Bye!"
=end
end
