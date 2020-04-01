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
require './lib/vultest_case'
require './lib/vulenv/control_vulenv'
require './modules/ui'

class DestroyCommand < Command
  attr_reader :control_vulenv

  def initialize(args)
    @control_vulenv = args[:control_vulenv]
  end

  def execute
    if control_vulenv.nil?
      VultestUI.error('Doesn\'t exist a vulnerabule environment')
      return
    end

    return unless control_vulenv.destroy?

    VultestUI.execute("Delete the vulnerable environment for #{control_vulenv.cve}")
    @control_vulenv = nil
  end
end
