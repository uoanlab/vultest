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
    def execute_vultest(args)
      vultest_process = ProcessVultest.new
      return if args['cve'].nil?

      cve = args['cve']
      vultest_process.attack[:host] = args['attack_host'] unless args['attack_host'].nil?
      vultest_process.attack[:user] = args['attack_user'] unless args['attack_user'].nil?
      vultest_process.attack[:passwd] = args['attack_passwd'] unless args['attack_passwd'].nil?
      vultest_process.test_dir = args['dir'] unless args['dir'].nil?

      vultest_process.start_vultest(cve)
      return if args['test'] == 'no'

      sleep(10)
      vultest_process.start_attack
      vultest_process.start_vultest_report
      vultest_process.destroy_vulenv! if args['destroy'] == 'yes'
    end
  end
end
