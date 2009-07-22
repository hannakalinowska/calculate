#! /usr/bin/ruby
$KCODE = 'u'

class Card
  WIDTH = 71 # px - width of the image
  HEIGHT = 96 # px - height of the image

  attr_accessor :value, :colour

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

    text = "#{text}.#{colour}"
    text
  end

  # cards that are set at the start of the game
  def self.restricted?(value, colour)
    return true if [[1, 0], [2, 2], [3, 1], [4, 0]].include?([value, colour])
    return false
  end
end

class Pile
  attr_accessor :cards, :image
  
  def initialize(border)
    @cards = Array.new
    @border = border
    @border.hide
    @image = nil
  end

  def activate
    @border.show
  end

  def deactivate
    @border.hide
  end

  def last
    @cards.last
  end

  def <<(card)
    @cards << card
    @image.path = @cards.last.image unless @image.nil?
  end

  def card
    @cards.last
  end

  def card!
    card = @cards.pop
    @image.path = @cards.last.image
    card
  end

  def has_cards_left?
    !@cards.empty?
  end

  def is_deck?
    false
  end 

  def is_bottom_pile?
    false
  end

  def is_top_pile?
    false
  end
end

class Deck < Pile 
  def initialize(border, random = true)
    @cards = Array.new
    0.upto(51) do |i|
      @cards << Card.new((i % 13) + 1, i / 13) unless Card.restricted?((i % 13) + 1, i / 13)
    end
    if random
      @cards.shuffle!
    end

    @border = border
    @border.hide
  end

  def first
    @cards.first
  end

  def card
    @cards.first
  end

  def card!
    card = @cards.shift
    @image.path = @cards.first.image
    card
  end

  def is_deck?
    true
  end
end

class TopPile < Pile
  def is_top_pile?
    true
  end
end

class BottomPile < Pile
  attr_accessor :stack, :border_stack

  def initialize(border)
    @cards = Array.new
    @border = border
    @border.hide
    @image = nil
    @all_images = Array.new
#    @all_images << $app.image('cards/empty.png', :left => Board::BORDER_WIDTH, :top => Board::BORDER_WIDTH)
  end

  def is_bottom_pile?
    true
  end

  def <<(card)
    @cards << card
    @stack.before(@border_stack) do
      @all_images << $app.image(@cards[-2].image, :top => 20 * @all_images.length + Board::BORDER_WIDTH, :left => Board::BORDER_WIDTH) unless @cards.length < 2
    end
    @stack.style(:height => 2 * Board::BORDER_WIDTH + Card::HEIGHT + 20 * @cards.length)
    @border_stack.move(@border_stack.left, 20 * (@cards.length - 1))
    @image.path = @cards.last.image unless @image.nil?
  end

  def card!
    card = @cards.pop
    @stack.style(:height => 2 * Board::BORDER_WIDTH + Card::HEIGHT + 20 * @cards.length)
    @border_stack.move(@border_stack.left, 20 * (@cards.length - 1))
    if @cards.empty?
      @image.path = 'cards/empty.png'
    else
      @image.path = @cards.last.image
    end
    card
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
  end
end

class Board
  BORDER_COLOUR = '#F6D353'
  BORDER_WIDTH = 3

  attr_accessor :deck, :piles, :source_pile, :source_pile_number, :target_pile

  def initialize
    @source_pile = nil
    @source_pile_number = nil
    @target_pile = nil
    @card = nil

#    setup_board
  end

  def setup_board
    @deck = Deck.new
    @piles = Array.new # [@deck, Pile.new, Pile.new, Pile.new, Pile.new, Pile.new, Pile.new, Pile.new, Pile.new] # ouch!
    @piles[1] << Card.new(1, 0)
    @piles[2] << Card.new(2, 2)
    @piles[3] << Card.new(3, 1)
    @piles[4] << Card.new(4, 3)
  end

end

Shoes.app(:title => 'Calculate!', :width => 600, :height => 480) do
  STARTING_CARDS = [Card.new(1, 0), Card.new(2, 2), Card.new(3, 1), Card.new(4, 3)]
  
  def setup_board
    @piles = Array.new # [@deck, Pile.new, Pile.new, Pile.new, Pile.new, Pile.new, Pile.new, Pile.new, Pile.new] # ouch!

    clear

    stack :width => 1.0 do
      flow :top => 10, :left => 10 do
        #top buttons
        button 'New game' do
          setup_board
        end
        
        button 'Quit' do
          exit
        end
      end
      flow :top => 50, :left => 10 do
        # top
        flow :width => 0.4 do
          flow :width => Card::WIDTH + 2 * Board::BORDER_WIDTH, :height => Card::HEIGHT + 2 * Board::BORDER_WIDTH do 
            # deck
            @piles[0] = Deck.new(border Board::BORDER_COLOUR, :strokewidth => Board::BORDER_WIDTH)
            flow :top => Board::BORDER_WIDTH, :left => Board::BORDER_WIDTH do
              @piles[0].image = image @piles[0].card.image
            end
            click do
              action(0)
            end
          end
        end # end deck
        flow :width => 0.6 do
          # top piles
          1.upto(4) do |i|
            left = (i - 1) * (Card::WIDTH + 2 * Board::BORDER_WIDTH)
            left += (i - 1) * 10 if i > 1
            stack :left => left, :width => Card::WIDTH + 2 * Board::BORDER_WIDTH, :height => Card::HEIGHT + 2 * Board::BORDER_WIDTH do
              @piles[i] = TopPile.new(border Board::BORDER_COLOUR, :strokewidth => Board::BORDER_WIDTH)
              flow :top => Board::BORDER_WIDTH, :left => Board::BORDER_WIDTH do
                @piles[i].image = image 'cards/empty.png' # fake image just to have something
              end
              @piles[i] << STARTING_CARDS[i - 1]
              click do
                action(i)
              end
            end
          end
        end # end top piles
      end # end top

      flow :top => 160, :left => 0.42, :width => 0.6 do
        # bottom
        5.upto(8) do |i|
          left = (i - 5) * (Card::WIDTH + 2 * Board::BORDER_WIDTH)
          left += (i - 5) * 10 if i - 5 > 0
          main_stack = stack :left => left, :width => Card::WIDTH + 2 * Board::BORDER_WIDTH do
#            background red
            @piles[i] = BottomPile.new(border Board::BORDER_COLOUR, :strokewidth => Board::BORDER_WIDTH)
            @piles[i].stack = stack
            @piles[i].border_stack = stack :left => left, :width => Card::WIDTH + 2 * Board::BORDER_WIDTH, :height => Card::HEIGHT + 2 * Board::BORDER_WIDTH, :scroll => true do
              @piles[i].image = image 'cards/empty.png', :top => Board::BORDER_WIDTH, :left => Board::BORDER_WIDTH
              click do
                action(i)
              end
            end
          end # end stack
        end
      end # end bottom
    end
  end

  def activate(pile_number)
    @piles[pile_number].activate
    @source_pile = @piles[pile_number]
    @source_pile_number = pile_number
  end

  def deactivate
    @source_pile.deactivate unless @source_pile.nil?
    @source_pile = nil
    @source_pile_number = nil
    @piles.each {|pile| pile.deactivate}
  end

  def incorrect_move
    deactivate
  end

  def play(pile_number)
    card = @source_pile.card

    if @target_pile.is_top_pile?
      if (@target_pile.card.value - 1 + pile_number) % 13 + 1 == card.value
        @target_pile << @source_pile.card!
      else
        incorrect_move
      end
    elsif @target_pile.is_bottom_pile?
      @target_pile << @source_pile.card!
    else 
      incorrect_move
    end

    deactivate
  end

  def action(pile_number)
    pile_groups = [[0], [1, 2, 3, 4], [5, 6, 7, 8]]
    @target_pile = @piles[pile_number]

    if @source_pile.nil?
      if @target_pile.is_deck?
        activate(pile_number)
      elsif @target_pile.is_bottom_pile? and @target_pile.has_cards_left?
        activate(pile_number)
      else
        incorrect_move
      end
    elsif @source_pile == @target_pile
      deactivate
    elsif @source_pile.is_deck?
      if @target_pile.is_deck?
        deactivate
      else
        play(pile_number)
      end
    else
      if @target_pile.is_top_pile?
        play(pile_number)
      else #if @target_pile.is_bottom_pile?
        deactivate
        activate(pile_number)
#      else
#        incorrect_move
      end
    end
  end

  $app = self
#  @game = Game.new
#  @board = Board.new 

  setup_board

  #
  # My testing area
  #
#  @test_stack = stack do
#    para "My testing area"
#    my_image = image 'cards/h1.png'
#    image 'cards/h2.png' 
#    image 'cards/h3.png'
#
#    button 'test' do
#      @game = Game.new
#      @game.draw
#      @test_stack.border red, :strokewidth => 5
#    end
#  end

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
