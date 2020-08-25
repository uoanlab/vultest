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
require 'uri'
require 'net/http'

require 'lib/print'

module Attack
  module Tool
    class HTTP
      attr_reader :target_url, :attack_request_setting, :request, :response, :error

      def initialize(args)
        @target_url = args[:exploits]['url']

        @attack_request_setting = {
          url: args[:exploits]['request']['url'],
          method: args[:exploits]['request']['method'],
          header: args[:exploits]['request'].fetch('header', []),
          body: args[:exploits]['request'].fetch('body', nil)
        }

        @request = { header: {}, body: nil }
        @response = { header: {}, body: nil }
      end

      def exec
        url = attack_request_setting[:url]
        uri = URI.parse(attack_request_setting[:url])

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = url.start_with?('https') ? true : false

        req = create_req(url, uri)
        res = create_res(req)

        if res.msg == 'OK'
          Print.result('No Judement')
          return
        end

        @error = {
          code: res.code,
          header: response[:header],
          body: response[:body]
        }
        Print.result('failure')
      end

      private

      def create_res(req)
        res = http.request(req)
        res.each_header { |key, value| @response[:header][key] = value }
        @response[:body] = res.body
        res
      end

      def create_req(url, uri)
        req =
          case attack_request_setting[:method]
          when 'get' then Net::HTTP::Get.new(uri.request_uri)
          when 'post' then Net::HTTP::Post.new(uri.request_uri)
          end

        headers = create_headers(url, uri)
        headers.each { |key, value| req.add_field(key, value) }

        req.set_form_data(attack_request_setting[:body]) unless attack_request_setting[:body].nil?

        req.each_header { |key, value| @request[:header][key] = value }
        @request[:body] = req.body
      end

      def create_headers(url, uri)
        headers = attack_request_setting[:header]

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = url.start_with?('https') ? true : false

        req = Net::HTTP::Head.new(uri.request_uri)
        attack_request_setting[:header].each { |key, value| req.add_field(key, value) }

        res = http.request(req)

        additional_headers = {}
        additional_headers['Cookie'] = res['Set-Cookie'] if res.key?('Set-Cookie')

        headers.marge!(additional_headers)

        headers
      end
    end
  end
end
