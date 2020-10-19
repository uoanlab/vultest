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

require 'yaml'

module DataObject
  class TestCase
    attr_reader :file
  
    def initialize(args)
      @file = {
        vulenv_config: args[:vulenv_config_file],
        attack_config: args[:attack_config_file]
      }
    end
  
    def vulenv_config
      YAML.load_file(
        "#{BASE_CONFIG['vultest_db_path']}/#{file[:vulenv_config]}"
      )['host']
    end
  
    def attack_config
      YAML.load_file(
        "#{BASE_CONFIG['vultest_db_path']}/#{file[:attack_config]}"
      )['attack']
    end
  
    def vulnerability
      YAML.load_file(
        "#{BASE_CONFIG['vultest_db_path']}/#{file[:vulenv_config]}"
      )['vulnerability']
    end
  
    def version
      YAML.load_file(
        "#{BASE_CONFIG['vultest_db_path']}/#{file[:vulenv_config]}"
      )['host'].fetch('version', '1.0')
    end
  end
end
