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

  def execute(type, value, &block)
    if type.nil? || value.nil?
      VultestUI.error('The usage of set command is incorrect')
      return
    end

    type = type.downcase
    if type == 'testdir'
      return unless require_for_setting_in_test_dir?

      VultestUI.execute("#{type} => #{value}")
      type = :test_dir
      value = Util.create_dir(value)
    elsif type[0..5] == 'attack'
      return unless require_for_setting_in_attack_config?

      VultestUI.execute("#{type} => #{value}")
      type = "#{type[0..5]}_#{type[6..]}".intern
    end

    block.call(type, value)
  end

  private

  def require_for_setting_in_test_dir?
    unless control_vulenv.nil?
      VultestUI.error('Cannot change a setting in a vulnerable test')
      return false
    end

    true
  end

  def require_for_setting_in_attack_config?
    unless attack_env.nil?
      VultestUI.error('Cannot change a setting in a vulnerable test')
      return false
    end
    true
  end
end
