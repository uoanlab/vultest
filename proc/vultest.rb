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

require './lib/vulenv/vulenv'
require './lib/attack/attack'
require './lib/report/vultest'
require './lib/report/error/attack'
require './lib/report/error/vulenv'
require './lib/ui'

class ProcessVultest
  attr_reader :cve
  attr_accessor :attacker, :test_dir

  def initialize
    @cve = nil
    @test_dir = ENV.key?('TESTDIR') ? ENV['TESTDIR'] : './test_dir'
    @attacker = { host: nil, user: 'root', passwd: 'toor' }
    @attacker[:host] = ENV['ATTACKHOST'] if ENV.key?('ATTACKHOST')
    @attacker[:user] = ENV['ATTACKERUSER'] if ENV.key?('ATTACKERUSER')
    @attacker[:passwd] = ENV['ATTACKPASSWD'] if ENV.key?('ATTACKPASSWD')
  end

  def start_vultest(cve)
    unless cve =~ /^(CVE|cve)-\d+\d+/i
      VultestUI.error('The CVE entered is incorrect')
      return
    end

    create_vulenv(cve)
    VultestUI.warring('Can look at a report about failure of creating the vulnerable environment') unless @vulenv.stderr.nil?
  end

  def start_attack
    if @vulenv.nil?
      VultestUI.error('There is not the vulnerable environment which is attack target')
      return
    end

    return unless prepare_attack_host?

    VultestUI.warring('Can look at a report about failure of attack') unless execute_attack
  end

  def start_vultest_report
    return if error_vulenv_report?
    return if error_attack_report?

    vultest_report = VultestReport.new(cve: @cve, report_dir: @test_dir, vulenv_config: @vulenv.vulenv_config, attack_config: @vulenv.attack_config)
    vultest_report.create_report

    @attack.verify
  end

  def destroy_vulenv!
    if @vulenv.nil?
      VultestUI.error("There is not the vulnerable environment for #{@cve}")
      return
    end

    @vulenv.destroy!
    @vulenv = nil

    VultestUI.execute("Delete the vulnerable environment for #{@cve}")
  end

  def connection_attack_host?
    return false if @attack.nil?

    return false if @attack.msf_api.nil?

    true
  end

  private

  def create_vulenv(cve)
    @vulenv = Vulenv.new(cve: cve, vulenv_dir: @test_dir)

    return unless @vulenv.select_vulenv?(cve)

    @vulenv.create
    @cve = cve
  end

  def prepare_attack_host?
    @attack = Attack.new

    if @vulenv.vulenv_config['attack_vector'] == 'local'
      @attacker[:host] = '192.168.177.177'
    elsif @vulenv.vulenv_config['attack_vector']
      if @attacker[:host].nil?
        VultestUI.error('Cannot find the attack host')
        VultestUI.warring('Execute : SET ATTACKHOST attack_host_ip_address')
        return false
      end
      @attack.prepare(host: @attacker[:host], user: @attacker[:user], passwd: @attacker[:passwd])
    end

    @attack.connect_metasploit(@attacker[:host])
    true
  end

  def execute_attack
    @attack.execute?(attack_host: @attacker[:host], msf_modules: @vulenv.attack_config['metasploit_module'])
  end

  def error_vulenv_report?
    if @vulenv.nil?
      VultestUI.error('There is no a vulnerable environment')
      return true
    end

    unless @vulenv.stderr.nil?
      VultestUI.execute('Output error report about vulnerable environment')
      error_report = ErrorVulenvReport.new(report_dir: @test_dir, stderr: @vulenv.stderr, vulenv_config: @vulenv.vulenv_config)
      error_report.create_report
      return true
    end

    false
  end

  def error_attack_report?
    if @attack.nil?
      VultestUI.error('Execute exploit command')
      return true
    end

    unless @attack.error_module.empty?
      VultestUI.execute('Output error report about attack')
      error_report = ErrorAttackReport.new(report_dir: @test_dir, vulenv_config: @vulenv.vulenv_config, attack_config: @vulenv.attack_config)
      error_report.create_report(@attack.error_module)
      return true
    end

    false
  end
end