require 'rainbow'
require 'tty-command'
require 'tty-prompt'
require 'tty-spinner'
require 'tty-table'
require 'yaml'

module Utility
  @execute_symbol = Rainbow('[*]').blue
  @caution_symbol = Rainbow('[>]').indianred
  @error_symbol = Rainbow('[-]').red
  @output_symbol = Rainbow('[o]').magenta
  @success_mark = Rainbow('+').cyan
  @error_mark = Rainbow('-').red


  def print_message (type, message)
    if type == 'execute' then
      puts "#{@execute_symbol} #{message}"
    elsif type == 'caution'
      puts "#{@caution_symbol} #{message}"
    elsif type == 'error'
      puts "#{@error_symbol} #{message}"
    elsif type == 'output'
      puts "#{@output_symbol} #{message}"
    else
      puts "#{message}"
    end
  end

  def tty_spinner_begin(message)
    @spinner = TTY::Spinner.new("[:spinner] #{message}", success_mark: "#{@success_mark}", error_mark: "#{@error_mark}")
    @spinner.auto_spin
  end

  def tty_spinner_end (status)
    status == 'success' ? @spinner.success : @spinner.error
  end

  def tty_prompt (message, list)
    prompt = TTY::Prompt.new
    return prompt.enum_select("#{@caution_symbol} #{message}", list)
  end

  def get_config
    return YAML.load_file('./config.yml')
  end

  module_function :print_message
  module_function :tty_prompt
  module_function :tty_spinner_begin
  module_function :tty_spinner_end
  module_function :get_config

end
