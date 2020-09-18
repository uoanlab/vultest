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
require 'tty-prompt'

module Vulenv
  module Start
    class << self
      def exec?(args)
        env_dir = args[:env_dir]
        env_config = args[:env_config]
        vagrant = args[:vagrant]

        return false unless vagrant.startup?

        if env_config.key?('reload') && env_config['reload']
          return false unless vagrant.reload?
        end

        if env_config.key('hard_setup')
          return false unless hard_setup(vagrant, env_config)
        end

        manual_setting(env_dir, env_config) if env_config.key?('prepare')

        true
      end

      private

      def hard_setup(vagrant, env_config)
        env_config['hard_setup']['msg'].each do |msg|
          Print.command(msg.to_s)
        end
        vagrant.halt

        TTY::Prompt.new.keypress('Please press enter key, when ready', keys: [:return])
        return false unless vagrant.startup?

        true
      end

      def manual_setting(env_dir, env_config)
        Print.warring('Following execute command')
        Print.command("1. cd #{env_dir}")
        Print.command('2. vagrant ssh')
        env_config['prepare']['msg'].each.with_index(3) do |msg, i|
          Print.command("#{i}. #{msg}")
        end
      end
    end
  end
end
