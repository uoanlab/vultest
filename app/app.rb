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

require 'lib/print'

class App
  attr_reader :setting, :vultest_case, :vulenv, :attack_env

  def initialize
    Print.stdout(Pastel.new.red(TTY::Font.new(:"3d").write('VULTEST')))

    @setting = {}
    @setting[:test_dir] = ENV.fetch('TESTDIR', './test_dir')
    @setting [:attack_dir] = ENV.fetch('ATTACKDIR', './attack_dir')
    @setting[:attack_host] = ENV.fetch('ATTACKHOST', nil)
    @setting[:attack_user] = ENV.fetch('ATTACKERUSER', 'root')
    @setting [:attack_passwd] = ENV.fetch('ATTACKPASSWD', 'toor')
  end

  def execute
    raise NotImplementedError
  end
end
