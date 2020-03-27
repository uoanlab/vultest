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

require 'bundler/setup'
require 'fileutils'

class PreparePlaybook
  attr_reader :os, :env_config, :playbook_dir, :cve, :attack_vector

  def initialize(args)
    @os = args[:os]
    @env_config = args[:env_config]
    @playbook_dir = args[:playbook_dir]

    @cve = args[:cve]
    @attack_vector = args[:attack_vector]
  end

  def create
    content = "---\n"
    content << "- hosts: vagrant\n"

    unless os == 'windows'
      content << "  connection: local\n"
      content << "  become: yes \n"
      content << "  roles:\n"
    end

    content << "    - ../roles/user\n" if env_config.key?('user')

    env_config['related_software'].each { |software| content << "    - ../roles/#{software['name']}\n" } if env_config.key?('related_software')

    content << "    - ../roles/#{env_config['vul_software']['name']}\n" if env_config.key?('vul_software')

    content << "    - ../roles/#{cve}\n" if env_config.key?('content')
    content << "    - ../roles/metasploit\n" if attack_vector == 'local'

    env_config['services'].each { |service_name| content << "    - ../roles/service-#{service_name}\n" } if env_config.key?('services')

    File.open("#{playbook_dir}/main.yml", 'w') { |file| file.puts(content) }
  end
end
