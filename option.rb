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

require_relative './process/vultest'

module VultestOptionExecute
  class << self
    def execute_vultest(options)
      vultest_processing = ProcessVultest.new
      return if options['cve'].nil?

      cve = options['cve']
      vultest_processing.attack[:host] = options['attack_host'] unless options['attack_host'].nil?
      vultest_processing.attack[:user] = options['attack_user'] unless options['attack_user'].nil?
      vultest_processing.attack[:passwd] = options['attack_passwd'] unless options['attack_passwd'].nil?
      vultest_processing.test_dir = options['dir'] unless options['dir'].nil?

      vultest_processing.create_vulenv(cve)
      return if options['test'] == 'no'

      sleep(10)
      vultest_processing.attack_vulenv
      vultest_processing.execute_vultest_report
      vultest_processing.destroy_vulenv! if options['destroy'] == 'yes'
    end
  end
end
