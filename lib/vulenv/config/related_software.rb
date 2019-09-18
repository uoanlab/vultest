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

require './lib/vulenv/config/software'

module RelatedSoftware
  include Software

  private

  def related_software(args = {})
    args[:softwares].each do |software|
      method = software.key?('method') ? software['method'] : args[:default_method]
      select_method(software: software, role_dir: args[:role_dir], method: method)
    end
  end
end
