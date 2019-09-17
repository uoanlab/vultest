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

module Option
  private

  def create_vulenv_dir(dir)
    path = ''
    path_elm = dir.split('/')

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
end
