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

require_relative './software'

module VulSoftware
  include Software

  private

  def vul_software(args = {})
    method = args[:vul_software].key?('method') ? args[:vul_software]['method'] : args[:default_method]
    select_method(software: args[:vul_software], role_dir: args[:role_dir], method: method)
  end
end
