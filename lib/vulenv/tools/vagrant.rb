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

require 'fileutils'
require 'open3'

class Vagrant
  def initialize(args = {})
    @env_dir = args[:env_dir]
    @os_name = args[:os_name]
    @os_version = args[:os_version]
  end

  def create
    FileUtils.cp_r("./lib/vulenv/tools/data/vagrant/#{@os_name}/#{@os_version}/Vagrantfile", "#{@env_dir}/Vagrantfile")

    return unless @os_name == 'windows'

    Dir.chdir("#{@env_dir}") do
      Open3.capture3('wget https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1')
    end
  end
end
