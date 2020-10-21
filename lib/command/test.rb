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

module Command
  module Test
    class << self
      def exec(args)
        cve = args[:cve]
        core = args[:core]
        vulenv_dir = args[:vulenv_dir]

        return core unless core.nil?

        unless cve =~ /^(CVE|cve)-\d+\d+/i
          Print.error('The CVE entered is incorrect')
          return nil
        end

        core = Core.new
        return nil unless core.select_vultest_case?(cve: cve)

        unless core.create_vulenv?(vulenv_dir: vulenv_dir)
          Print.warring(
            'Can look at a report about error in host of vulnerable environment'
          )
        end

        core
      end
    end
  end
end
