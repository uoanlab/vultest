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
require 'optparse'
require 'pastel'
require 'tty-font'

require_relative './attack/exploit'
require_relative './env/vulenv'
require_relative './report/vultest_report'
require_relative './utility'


test_dir = './test'
test_dir = ENV['TESTDIR'] if ENV.key?('TESTDIR')

attacker = nil
attacker = ENV['ATTACKER'] if ENV.key?('ATTACKER')

cve = nil
vulenv_config_path = nil
attack_config_path = nil

if ARGV.size != 0
  options = ARGV.getopts('h', 'cve:', 'test:yes', 'attacker:', 'dir:', 'destroy:')

  exit! if options['cve'].nil?
  cve = options['cve']

  attacker = options['attacker'] unless options['attacker'].nil?
  test_dir = options['dir'] unless options['dir'].nil?

  vulenv_config_path, attack_config_path = Vulenv.select(cve)

  if vulenv_config_path.nil? || attack_config_path.nil?
    Utility.print_message('error', 'Cannot test vulnerability') 
    exit!
  end

  if Vulenv.create(vulenv_config_path, test_dir) == 'error'
    Utility.print_message('error', 'Cannot start up vulnerable environment')
    exit!
  end

  exit! if options['test'] == 'no'

  sleep(10)
  if attack_config_path.nil? 
    Utility.print_message('error', 'Cannot search exploit configure')
    exit!
  end

  vulenv_config = YAML.load_file(vulenv_config_path)
  if vulenv_config['attack_vector'] != 'remote'
    attacker = '192.168.33.10'
  end

  if attacker.nil?
    Utility.print_message('error', 'Set attack machin ip address')
    exit!
  end

  Exploit.prepare(attacker, test_dir, vulenv_config_path) if vulenv_config['attack_vector'] == 'remote'
  Exploit.exploit(attacker, attack_config_path)

  if cve.nil?
    Utility.print_message('error', 'You have to set CVE.')
    exit!
  end

  if vulenv_config_path.nil?
    Utility.print_message('error', 'Cannot have vulnerable environmently configure')
    exit!
  end

  VultestReport.report(cve, test_dir, vulenv_config_path, attack_config_path)
  Exploit.verify

  Vulenv.destroy(test_dir) if options['destroy'] == 'yes'
  exit!
end

font = TTY::Font.new(:"3d")
pastel = Pastel.new
puts pastel.red(font.write("VULTEST"))

prompt = 'vultest'

loop do
  print "#{prompt} > "
  command = gets.chomp.split(" ")

  case command[0]
  when /test/i
    cve = command[1]

    vulenv_config_path, attack_config_path = Vulenv.select(cve)

    if vulenv_config_path.nil? || attack_config_path.nil?
      Utility.print_message('error', 'Cannot test vulnerability') 
      next
    end

    if Vulenv.create(vulenv_config_path, test_dir) == 'error'
      Utility.print_message('error', 'Cannot start up vulnerable environment')
      next
    end

    prompt = cve

  when /exit/i
    break

  when /exploit/i
    if attack_config_path.nil? 
      Utility.print_message('error', 'Cannot search exploit configure')
      next
    end

    vulenv_config = YAML.load_file(vulenv_config_path)
    if vulenv_config['attack_vector'] != 'remote'
      attacker = '192.168.33.10'
    end

    if attacker.nil?
      Utility.print_message('error', 'Set attack machin ip address')
      next
    end

    Exploit.prepare(attacker, test_dir, vulenv_config_path) if vulenv_config['attack_vector'] == 'remote'
    Exploit.exploit(attacker, attack_config_path)

  when /set/i
    if command.length != 3
      Utility.print_message('error', 'Inadequate option')
      next
    end

    test_dir = 
      if command[1] =~ /testdir/i
        path = ''
        path_elm = command[2].split("/")

        path_elm.each do |elm|
          path.concat('/') unless path.empty?
          if elm[0] == '$'
            elm.slice!(0)
            ENV.key?(elm) ? path.concat(ENV[elm]) : path.concat(elm)
          else
            path.concat(elm)
          end
        end
        path
      end

    attacker = command[2]

  when /report/i
    if cve.nil?
      Utility.print_message('error', 'You have to set CVE.')
      next
    end

    if vulenv_config_path.nil?
      Utility.print_message('error', 'Cannot have vulnerable environmently configure')
      next
    end

    VultestReport.report(cve, test_dir, vulenv_config_path, attack_config_path)
    Exploit.verify

  when /destroy/i
    Vulenv.destroy(test_dir)

  when /back/i
    prompt = 'vultest'

  when nil
    next

  else
    Utility.print_message('error', 'command not found')
  end

end
