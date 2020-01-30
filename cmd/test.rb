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

require './lib/vultest_case'
require './lib/vulenv/vulenv'
require './modules/ui'

module Test
  def test(args)
    cve = args.fetch(:cve, nil)
    vultest_case = args.fetch(:vultest_case, nil)
    vulenv_dir = args.fetch(:vulenv_dir, './test_dir')

    return 'vultest', nil, nil unless vultest_case.nil?

    unless cve =~ /^(CVE|cve)-\d+\d+/i
      VultestUI.error('The CVE entered is incorrect')
      return 'vultest', nil, nil
    end

    vultest_case = VultestCase.new(cve: cve)
    return 'vultest', nil, nil unless vultest_case.select_test_case?

    vulenv = Vulenv.new(cve: vultest_case.cve, config: vultest_case.config, vulenv_config: vultest_case.vulenv_config, vulenv_dir: vulenv_dir)

    if vulenv.create?
      vulenv.output_manually_setting if vulenv.vulenv_config['construction'].key?('prepare')
    else
      vulenv.error[:flag] = true
      VultestUI.warring('Can look at a report about error in construction of vulnerable environment')
    end

    return cve, vultest_case, vulenv
  end
end
