# Copyright [2020] [University of Aizu]
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
require 'net/ssh'
require 'tty-prompt'

require './lib/attack/metasploit'
require './modules/ui'

module Environment
  class AttackEnv
    attr_reader :host, :user, :password, :attack_config, :attack

    def initialize(args)
      @host = args[:host]
      @user = args[:user]
      @password = args[:password]
      @attack_config = args[:attack_config]

      @attack = Attack::Metasploit.new(
        host: host,
        exploits: attack_config['metasploit']
      )
    end

    def execute_attack
      VultestUI.execute('Exploit attack')
      attack.execute
    end

    def fail_attack?
      attack.error[:flag]
    end

    def details_fail_attack
      attack.error
    end
  end
end
