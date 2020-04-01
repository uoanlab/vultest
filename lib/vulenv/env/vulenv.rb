# Copyright [2020] [University of Aizu]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'bundler/setup'

class Vulenv
  attr_reader :os, :vul_software, :related_software

  def initialize(args)
    config = args[:vulenv_config]['construction']

    @os = { name: config['os']['name'], version: config['os']['version'], vulnerability: config['os']['vulnerability'] }
    @vul_software = { name: config['vul_software']['name'], version: config['vul_software']['version'] } if config.key?('vul_software')

    return unless config.key?('related_software')

    @related_software = config['related_software'].map { |s| { name: s['name'], version: s.fetch('version', 'The latest version of the repository') } }
  end

  def basic_structure
    {
      os: os,
      vul_software: vul_software,
      related_software: related_software
    }
  end

  def details_structure
    {
      base_version_of_os: base_version_of_os,
      related_software: related_software_details,
      ip_list: ip_list,
      port_list: port_list,
      service_list: service_list
    }
  end

  private

  def base_version_of_os
    raise NotImplementedError
  end

  def related_software_details
    related_software
  end

  def ip_list
    raise NotImplementedError
  end

  def port_list
    raise NotImplementedError
  end

  def service_list
    raise NotImplementedError
  end
end
