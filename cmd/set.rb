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

require './lib/util'

module Setting
  def set(args)
    prompt = args[:prompt]
    setting = args[:setting]
    vulenv = args.fetch(:vulenv, nil)
    attack_env = args.fetch(:attack_env, nil)

    input = {}
    input[:type] = args.fetch(:type, nil)
    input[:value] = args.fetch(:value, nil)

    if input[:type].nil? || input[:value].nil?
      prompt.error('The usage of set command is incorrect')
      return
    end

    unless vulenv.nil? && attack_env.nil?
      prompt.error('Cannot change a setting in a vulnerable test')
      return
    end

    setting_set_value(setting, input[:type], input[:value]) ? prompt.ok("#{input[:type]} => #{input[:value]}") : prompt.error("Invalid option (#{type})")
  end

  def setting_set_value(setting, type, value)
    case type
    when /testdir/i then setting[:test_dir] = Util.create_dir(value)
    when /attackhost/i then setting[:attack_host] = value
    when /attackuser/i then setting[:attack_user] = value
    when /attackpasswd/i then setting[:attack_passwd] = value
    else return false
    end

    return true
  end
end
