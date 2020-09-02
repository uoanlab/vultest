# Copyright [202] [University of Aizu]
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
require 'erb'
require 'json'

module Report
  class Attack
    def initialize(args)
      @report_dir = args[:report_dir]
      @attack = args[:attack]
    end

    def create
      if @attack.attack_method.instance_of?(::Attack::Method::Metasploit::Core)
        create_metasploit
      elsif @attack.attack_method.instance_of?(::Attack::Method::HTTP)
        create_http
      end
    end

    private

    def create_metasploit
      erb = ERB.new(File.read(REPORT_ATTACK_TEMPLATE_PATH), trim_mode: 2)

      attack_tool = 'Metasploit'
      attack_methods = @attack.attack_config['metasploit']

      File.open("#{@report_dir}/report.md", 'a+') { |f| f.puts(erb.result(binding)) }
    end

    def create_http
      erb = ERB.new(File.read(REPORT_ATTACK_TEMPLATE_PATH), trim_mode: 2)

      attack_tool = 'HTTP'
      target_url = @attack.attack_method.target_url
      attack_url = @attack.attack_method.attack_request_setting[:url]
      attack_http_method = @attack.attack_method.attack_request_setting[:method]
      request_header = @attack.attack_method.request[:header]
      request_body = @attack.attack_method.request[:body]
      response_header = @attack.attack_method.response[:header]
      response_body = JSON.pretty_generate(JSON.parse(@attack.attack_method.response[:body]))

      File.open("#{@report_dir}/report.md", 'a+') { |f| f.puts(erb.result(binding)) }
    end
  end
end
