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

require 'bundler/setup'
require 'fileutils'
module User
  private

  def user(args)
    FileUtils.mkdir_p("#{args[:role_dir]}/user")
    FileUtils.mkdir_p("#{args[:role_dir]}/user/tasks")
    FileUtils.mkdir_p("#{args[:role_dir]}/user/vars")

    FileUtils.cp_r(
      './lib/vulenv/tools/data/ansible/roles/user/tasks/main.yml',
      "#{args[:role_dir]}/user/tasks/main.yml"
    )

    File.open("#{args[:role_dir]}/user/vars/main.yml", 'w') do |vars_file|
      args[:users].each do |user|
        user ? vars_file.puts("user: #{user}") : vars_file.puts('user: test')
      end
    end
  end
end
