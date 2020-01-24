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

require './lib/ui'

module Destroy
  def destroy(args)
    prompt = args[:prompt]
    vulenv = args.fetch(:vulenv, nil)

    if vulenv.nil?
      VultestUI.error('Doesn\'t exist a vulnerabule environment')
      return vulenv
    end
    return vulenv if prompt.no?('Delete vulnerable environment?')

    return vulenv unless vulenv.destroy!

    VultestUI.execute("Delete the vulnerable environment for #{vulenv.cve}")
    return nil
  end
end
