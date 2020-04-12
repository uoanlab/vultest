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

require './lib/attack/method/metasploit'
require './modules/ui'

class AttackEnv
  attr_reader :host, :user, :password, :attack_vector, :attack_config, :attack_method

  def initialize(args)
    @host = args[:attack_host]
    @user = args[:attack_user]
    @password = args[:attack_passwd]

    @attack_vector = args[:attack_vector]
    @attack_config = args[:attack_config]

    prepare_attack_method
  end

  def execute_attack
    VultestUI.execute('Exploit attack')
    attack_method.execute
  end

  def fail_attack?
    attack_method.error[:flag]
  end

  def details_fail_attack
    attack_method.error
  end

  private

  def prepare_attack_method
    startup_msfserver if attack_vector == 'remote'
    @attack_method = ::Attack::Method::Metasploit.new(
      host: host,
      exploits: attack_config['metasploit']
    )
  end

  def startup_msfserver
    begin
      VultestUI.tty_spinner_begin('Metasploit server')
      Net::SSH.start(host, user, password: password) do |ssh|
        ssh.exec!("msfrpcd -a #{host} -p 55553 -U msf -P metasploit -S false \>/dev/null 2>&1")
        ssh.exec!("msfrpcd -a #{host} -p 55553 -U msf -P metasploit -S false")
      end
    rescue StandardError
      VultestUI.tty_spinner_end('error')
      VultestUI.warring('Run your attack machine now')

      TTY::Prompt.new.keypress(' If it is running now, puress ENTER key', keys: [:return])
      retry
    end
    VultestUI.tty_spinner_end('success')
  end
end
