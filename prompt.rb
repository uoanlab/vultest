require 'pastel'
require 'tty-font'

class Prompt
  def initialize
    self.title
    @prompt = 'vultest'
  end

  def get_input_command
    return @input_list
  end

  def set_prompt(prompt)
    @prompt = prompt
  end

  def title
    font = TTY::Font.new(:"3d")
    pastel = Pastel.new
    puts pastel.red(font.write("VULTEST"))
  end

  def print_prompt
    print "#{@prompt} > "
    input = gets
    input = input.chomp!
    input_list = input.split(" ")

    @input_list = input_list
  end

end

