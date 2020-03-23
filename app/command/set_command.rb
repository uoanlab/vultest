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

require './app/command/command'
require './modules/ui'
require './modules/util'

class SetCommand < Command
  attr_reader :control_vulenv, :attack_env

  def initialize(args)
    @control_vulenv = args[:control_vulenv]
    @attack_env = args[:attack_env]
  end

  def exec(type, value, set_proc)
    if type.nil? || value.nil?
      VultestUI.error('The usage of set command is incorrect')
      return
    end

    unless control_vulenv.nil? && attack_env.nil?
      VultestUI.error('Cannot change a setting in a vulnerable test')
      return
    end

    VultestUI.execute("#{type} => #{value}")

    type = type.downcase
    if type == 'testdir'
      type = :test_dir
      value = Util.create_dir(value)
    elsif type[0..5] == 'attack' then type = "#{type[0..5]}_#{type[6..]}".intern
    end
    set_proc.call(type, value)
  end
end
