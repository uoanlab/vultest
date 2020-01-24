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

module Back
  def back(args)
    prompt = args[:prompt]
    console_name = args[:name]
    vultest_case = args[:vultest_case]
    vulenv = args[:vulenv]
    attack_env = args[:attack_env]

    if prompt.yes?("Finish the vultest for #{vultest_case.cve}")
      console_name = 'vultest'
      vultest_case = vulenv = attack_env = nil
    end

    return console_name, vultest_case, vulenv, attack_env
  end
end
