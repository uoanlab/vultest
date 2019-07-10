# Copyright [2019] [University of Aizu]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'bundler/setup'
require 'rainbow'
require 'tty-spinner'
require 'tty-prompt'

module VultestUI
  @execute_symbol = Rainbow('[*]').blue
  @caution_symbol = Rainbow('[>]').indianred
  @error_symbol = Rainbow('[-]').red
  @output_symbol = Rainbow('[o]').magenta
  @success_mark = Rainbow('+').cyan
  @error_mark = Rainbow('-').red

  class << self
    def print_vultest_message(type, message)
      if type == 'execute'
        puts("#{@execute_symbol} #{message}")
      elsif type == 'caution'
        puts("#{@caution_symbol} #{message}")
      elsif type == 'error'
        puts("#{@error_symbol} #{message}")
      elsif type == 'output'
        puts("#{@output_symbol} #{message}")
      end
    end

    def tty_spinner_begin(message)
      @spinner = TTY::Spinner.new("[:spinner] #{message}", success_mark: @success_mark.to_s, error_mark: @error_mark.to_s)
      @spinner.auto_spin
    end

    def tty_spinner_end(status)
      status == 'success' ? @spinner.success : @spinner.error
    end

    def tty_prompt(message, list)
      prompt = TTY::Prompt.new
      prompt.enum_select("#{@caution_symbol} #{message}", list)
    end
  end
end