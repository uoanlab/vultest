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

require_relative './attack/exploit'
require_relative './env/vulenv'
require_relative './report/vultest_report'
require_relative './utility'

class ProcessVultest
  attr_reader :cve
  attr_accessor :attack, :test_dir

  include Exploit
  include Vulenv
  include VultestReport
  

  def initialize
    @cve = nil

    @test_dir = ENV.key?('TESTDIR') ? ENV['TESTDIR'] : './test_dir'
    
    @attack = {host: nil, user: 'root', passwd: 'toor'}
    @attack[:host] = ENV['ATTACKHOST'] if ENV.key?('ATTACKHOST')
    @attack[:user] = ENV['ATTACKERUSER'] if ENV.key?('ATTACKERUSER')
    @attack[:passwd] = ENV['ATTACKPASSWD'] if ENV.key?('ATTACKPASSWD')

    @config_path = {vulenv: nil, attack: nil}
  end

  def create_vulenv(cve)
    unless cve =~ /^(CVE|cve)-\d+\d+/i then Utility.print_message('error', 'Incorrect CVE')
    else @cve = cve
    end

    @config_path = select(@cve)

    if @config_path[:vulenv].nil? || @config_path[:attack].nil?
      Utility.print_message('error', 'Cannot test vulnerability') 
      @cve = nil
      return
    end

    if create(@config_path[:vulenv], @test_dir) == 'error'
      Utility.print_message('error', 'Cannot start up vulnerable environment')
      @cve = nil
      return
    end
  end

  def attack_vulenv
    if @cve.nil?
      Utility.print_message('error', 'Firstly, executing test command')
      return
    end

    if @config_path[:attack].nil?
      Utility.print_message('error', 'Cannot search exploit configure')
      return
    end

    attack_vector = YAML.load_file(@config_path[:vulenv])['attack_vector']
    @attack[:host] = '192.168.33.10' if attack_vector == 'local'

    if @attack[:host].nil?
      Utility.print_message('error', 'Set attack machin ip address')
      return
    end

    prepare(@attack, @test_dir, @config_path[:vulenv]) if attack_vector == 'remote'
    execute(@attack[:host], @config_path[:attack])
  end

  def create_report
    if @cve.nil?
      Utility.print_message('error', 'You have to set CVE.')
      return
    end

    if @config_path[:vulenv].nil?
      Utility.print_message('error', 'Cannot have vulnerable environmently configure')
      return
    end

    report(@cve, @test_dir, @config_path)
    verify
  end

  def destroy_vulenv!
    if @cve.nil?
      Utility.print_message('error', 'Firstly, executing test command')
      return
    end
    destroy!(@test_dir)
  end

end
