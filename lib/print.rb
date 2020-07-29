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

module Print
  class << self
    def execute(msg)
      puts("[#{Rainbow('*').blue}] #{msg}")
    end

    def error(msg)
      puts("[#{Rainbow('-').red}] #{msg}")
    end

    def warring(msg)
      puts("[#{Rainbow('!').yellow}] #{msg}")
    end

    def command(msg)
      puts("[#{Rainbow('>').green}] #{msg}")
    end

    def stdout(msg)
      puts msg
    end

    def part(msg)
      puts(Rainbow('+' * 20 + " #{msg} Part " + '+' * 20).aqua)
    end

    def result(status)
      case status
      when 'success' then puts('Result: ' + Rainbow('Success').cyan + '(See Report)')
      when 'fail' then puts('Result: ' + Rainbow('Fail').red + '(See Report)')
      else puts('Result: ' + Rainbow('No judgment').aliceblue + '(See Report)')
      end
    end

    def spinner_begin(msg)
      @spinner = TTY::Spinner.new(
        "[:spinner] #{msg}",
        success_mark: Rainbow('+').cyan.to_s,
        error_mark: Rainbow('-').red.to_s
      )
      @spinner.auto_spin
    end

    def spinner_end(status)
      status == 'success' ? @spinner.success : @spinner.error
    end
  end
end
