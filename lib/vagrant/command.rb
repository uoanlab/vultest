# Copyright [2020] [University of Aizu]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'bundler/setup'
require 'open3'
require 'tty-prompt'

require 'lib/print'

module Vagrant
  class Command
    attr_reader :stdout

    def initialize
      @stdout = nil
    end

    def start_up?
      Print.spinner_begin('Start up')
      stdout, _stderr, status = Open3.capture3('vagrant up')
      if status.exitstatus.zero?
        Print.spinner_end('success')
        return true
      end

      Print.spinner_end('error')
      @stdout = stdout
      false
    end

    def reload?
      Print.spinner_begin('Reload')
      stdout, _stderr, status = Open3.capture3('vagrant reload')
      if status.exitstatus.zero?
        Print.spinner_end('success')
        return true
      end

      Print.spinner_end('error')
      @stdout = stdout
      false
    end

    def hard_setup?(msg_list)
      msg_list.each { |msg| Print.stdout(" #{msg}") }
      Open3.capture3('vagrant halt')
      TTY::Prompt.new.keypress('Please press enter key, when ready', keys: [:return])
      start_up
    end

    def destroy!
      Print.spinner_begin('Destroy the environment')
      _stdout, _stderr, status = Open3.capture3('vagrant destroy -f')
      unless status.exitstatus.zero?
        Print.spinner_end('error')
        return false
      end
      Print.spinner_end('success')
      true
    end
  end
end
