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
  attr_reader :cve, :exploit
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

  def attack_vulenv
    return if @vulenv.nil?

    @attack[:host] = '192.168.33.10' if @vulenv.vulenv_config['attack_vector'] == 'local'

    @exploit = Exploit.new

    if @vulenv.vulenv_config['attack_vector'] == 'remote'
      @exploit.prepare_exploit(
        host: @attack[:host],
        user: @attack[:user],
        passwd: @attack[:passwd],
        target_dir: @test_dir,
        target_config: @vulenv.vulenv_config
      )
    end

    @exploit.connect_metasploit(@attack[:host])
    @exploit.execute_exploit(attack_host: @attack[:host], msf_modules: @vulenv.attack_config['metasploit_module'])
  end

  def execute_vultest_report
    if @cve.nil?
      VultestUI.print_vultest_message('error', 'You have to set CVE.')
      return
    end

    create_report(cve: @cve, test_dir: @test_dir, vulenv_config: @vulenv.vulenv_config, attack_config: @vulenv.attack_config)
    @exploit.verify_exploit
  end

  def destroy_vulenv!
    if @cve.nil?
      VultestUI.print_vultest_message('error', 'Firstly, executing test command')
      return
    end
    @vulenv.destroy!
  end

  private

  def create_vulenv
    @vulenv = Vulenv.new(cve: @cve, vulenv_dir: @test_dir)
    @vulenv.create
  end
end
