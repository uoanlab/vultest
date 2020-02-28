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
require 'pastel'
require 'optparse'
require 'tty-font'
require 'tty-prompt'

require './app/lib/cmd'

class App
  attr_reader :setting, :vultest_case, :vulenv, :attack_env

  include Command

  def initialize
    puts Pastel.new.red(TTY::Font.new(:"3d").write('VULTEST'))

    @setting = {}
    @setting[:test_dir] = ENV.fetch('TESTDIR', './test_dir')
    @setting[:attack_host] = ENV.fetch('ATTACKHOST', nil)
    @setting[:attack_user] = ENV.fetch('ATTACKERUSER', 'root')
    @setting [:attack_passwd] = ENV.fetch('ATTACKPASSWD', 'toor')

    @vultest_case = nil
    @vulenv = nil
    @attack_env = nil
  end

  def console
    console = {}
    console[:prompt] = TTY::Prompt.new(active_color: :cyan, help_color: :bright_white, track_history: true)
    console[:name] = 'vultest'

    loop do
      cmd = console[:prompt].ask("#{console[:name]} >")
      cmd.nil? ? next : cmd = cmd.split(' ')

      case cmd[0]
      when /test/i
        console[:name] = @vultest_case.cve if test?(cmd[1])
      when /destroy/i
        destroy? unless console[:prompt].no?('Delete vulnerable environment?')
      when /exploit/i then exploit?
      when /report/i then report?
      when /set/i then set?(cmd[1], cmd[2])
      when /back/i
        next if vultest_case.nil?

        if console[:prompt].yes?("Finish the vultest for #{vultest_case.cve}")
          console[:name] = 'vultest'
          @vultest_case = @vulenv = @attack_env = nil
        end
      when /exit/i then break
      else console[:prompt].error("vultest: command not found: #{cmd[0]}")
      end
    end
  end

  def cli
    opts = ARGV.getopts('', 'cve:', 'test:yes', 'attack_user:', 'attack_passwd:', 'attack_host:', 'dir:', 'destroy:no')

    if opts['cve'].nil?
      VultestUI.error('Input CVE')
      return
    end

    @setting[:test_dir] = opts['dir'] unless opts['dir'].nil?
    @setting[:attack_host] = opts['attack_host'] unless opts['attack_host'].nil?
    @setting[:attack_user] = opts['attack_user'] unless opts['attack_user'].nil?
    @setting [:attack_passwd] = opts['attack_passwd'] unless opts['attack_passwd'].nil?

    return unless test?(opts['cve'])

    if vulenv.error[:flag]
      report?
      return
    end

    return if opts['test'] == 'no'

    TTY::Prompt.new.keypress('If you start the attack, puress ENTER key', keys: [:return])
    unless exploit?
      report?
      return
    end

    report?
    destroy? if opts['destroy'] == 'yes'
  end
end
