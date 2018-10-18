require 'rainbow'
require 'tty-command'
require 'tty-prompt'
require 'tty-spinner'
require 'tty-table'

module Utility
  @execute_symbol = Rainbow('[*]').blue
  @caution_symbol = Rainbow('[>]').indianred
  @input_symbol = Rainbow('[i]').aqua
  @error_symbol = Rainbow('[-]').red
  @output_symbol = Rainbow('[o]').magenta
  @success_symbol = Rainbow('+').cyan
  @error_symbol = Rainbow('-').red


  def print_message (type, message)
    if type == 'execute' then
      puts "#{@execute_symbol} #{message}"
    elsif type == 'caution'
      puts "#{@caution_symbol} #{message}"
    elsif type == 'error'
      puts "#{@error_symbol} #{message}"
    elsif type == 'output'
      puts "#{@output_symbol} #{message}"
    elsif type == 'input'
      puts "#{@input_symbol} #{message}"
    else
      puts "#{message}"
    end
  end

  def tty_spinner_begin(message)
    @spinner = TTY::Spinner.new("[:spinner] #{message}", success_mark: "#{@success_symbol}", error_mark: "#{@error_symbol}")
    @spinner.auto_spin
  end

  def tty_spinner_end (status)
    status == 'success' ? @spinner.success : @spinner.error
  end

  def tty_prompt (message, list)
    prompt = TTY::Prompt.new
    return prompt.enum_select("#{@caution_symbol} #{message}", list)
  end

  module_function :print_message
  module_function :tty_prompt
  module_function :tty_spinner_begin
  module_function :tty_spinner_end

end
