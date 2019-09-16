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

module Content
  private

  def content_tasks(args = {})
    FileUtils.mkdir_p("#{args[:role_dir]}/#{args[:cve]}/tasks")
    FileUtils.cp_r(
      "#{args[:db]}/data/#{args[:content_info]}/tasks/main.yml",
      "#{args[:role_dir]}/#{args[:cve]}/tasks/main.yml"
    )
  end

  def content_vars(args = {})
    FileUtils.mkdir_p("#{args[:role_dir]}/#{args[:cve]}/tasks/vars")
    FileUtils.cp_r(
      "#{args[:db]}/data/#{args[:content_info]}/vars/main.yml",
      "#{args[:role_dir]}/#{args[:cve]}/var/main.yml"
    )
  end

  def content_files(args = {})
    FileUtils.mkdir_p("#{args[:role_dir]}/#{args[:cve]}/files")
    Dir.glob("#{args[:db]}/data/#{args[:content_info]}/files/*") do |path|
      content = path.split('/')
      FileUtils.cp_r(
        "#{args[:db]}/data/#{args[:content_info]}/files/#{content[content.size - 1]}",
        "#{args[:role_dir]}/#{args[:cve]}/files/#{content[content.size - 1]}"
      )
    end
  end
end
