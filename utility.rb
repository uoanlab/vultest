=begin
Copyright [2019] [Kohei Akasaka]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=end

require 'fileutils'
require 'msgpack'
require 'net/ssh'
require 'net/http'
require 'open3'
require 'optparse'
require 'pastel'
require 'rainbow'
require 'sqlite3'
require 'tty-command'
require 'tty-prompt'
require 'tty-spinner'
require 'tty-markdown'
require 'tty-table'
require 'uri'
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
