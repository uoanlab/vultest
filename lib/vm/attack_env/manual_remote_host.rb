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

require './lib/environment/attack_env'

module VM
  module AttackEnv
    class ManualRemoteHost
      attr_reader :attack_config, :operating_environment

      def initialize(args)
        startup_msfserver(args[:host], args[:user], args[:password])

        @attack_config = args[:attack_config]
        @operating_environment = Environment::AttackEnv.new(
          host: args[:host],
          user: args[:user],
          password: args[:password],
          attack_config: args[:attack_config]
        )
      end

      private

      def startup_msfserver(host, user, password)
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
  end
end
