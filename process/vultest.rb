# Copyright [2019] [University of Aizu]
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

require_relative '../env/vulenv'
require_relative '../attack/exploit'
require_relative '../report/vultest'
require_relative '../ui'

class ProcessVultest
  attr_reader :cve, :vulenv, :exploit
  attr_accessor :attack, :test_dir

  include VultestReport

  def initialize
    @cve = nil
    @test_dir = ENV.key?('TESTDIR') ? ENV['TESTDIR'] : './test_dir'
    @attack = { host: nil, user: 'root', passwd: 'toor' }
    @attack[:host] = ENV['ATTACKHOST'] if ENV.key?('ATTACKHOST')
    @attack[:user] = ENV['ATTACKERUSER'] if ENV.key?('ATTACKERUSER')
    @attack[:passwd] = ENV['ATTACKPASSWD'] if ENV.key?('ATTACKPASSWD')
  end

  def start_vultest(cve)
    @cve = cve
    create_vulenv
  end

  def start_attack
    if @vulenv.nil?
      VultestUI.print_vultest_message('error', 'There is not the vulnerable environment which is attack target')
      return
    end

    execute_attack if prepare_attack_host
  end

  def start_vultest_report
    if @vulenv.nil?
      VultestUI.print_vultest_message('error', 'There is no a vulnerable environment')
      return
    end

    if @exploit.nil?
      VultestUI.print_vultest_message('error', 'Execute exploit command')
      return
    end

    create_report(cve: @cve, test_dir: @test_dir, vulenv_config: @vulenv.vulenv_config, attack_config: @vulenv.attack_config)
    @exploit.verify_exploit
  end

  def destroy_vulenv!
    @vulenv.destroy!
    @vulenv = nil

    VultestUI.print_vultest_message('execute', "Delete the vulnerable environment by #{@cve}")
  end

  private

  def create_vulenv
    @vulenv = Vulenv.new(cve: @cve, vulenv_dir: @test_dir)
    @vulenv.create
  end

  def prepare_attack_host
    @exploit = Exploit.new

    if @vulenv.vulenv_config['attack_vector'] == 'local'
      @attack[:host] = '192.168.33.10'
    elsif @vulenv.vulenv_config['attack_vector']
      if @attack[:host].nil?
        VultestUI.print_vultest_message('error', 'Cannot find the attack host')
        VultestUI.print_vultest_message('warring', 'Execute : SET ATTACKHOST attack_host_ip_address')
        return false
      end
      @exploit.prepare_exploit(host: @attack[:host], user: @attack[:user], passwd: @attack[:passwd])
    end

    @exploit.connect_metasploit(@attack[:host])
    true
  end

  def execute_attack
    @exploit.execute_exploit(attack_host: @attack[:host], msf_modules: @vulenv.attack_config['metasploit_module'])
  end
end
