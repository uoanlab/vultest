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

module CVEReport
  private

  def report_cve_description(report_file, cve)
    cve_info = DB.get_cve_info(cve)
    unless cve_info['description'].nil?
      (cve_info['description'].size / 100).times do |str_range|
        new_line_place = cve_info['description'].index(' ', (str_range + 1) * 100) + 1
        cve_info['description'].insert(new_line_place, "\n    ")
      end
    end
    report_file.puts("## CVE Description\n")
    report_file.puts("#{cve_info['description']}\n")
    report_file.puts("\n")
  end

  def report_cpe(report_file, cve)
    report_file.puts("## Affect Software Version (CPE)\n")
    cpe = DB.get_cpe(cve)
    cpe.each do |cpe_info|
      output_cpe_info = ''
      cpe_info.each_char do |c|
        if c == '*' then output_cpe_info = output_cpe_info + '\\' + c
        else output_cpe_info += c
        end
      end
      report_file.puts("- #{output_cpe_info}")
    end
    report_file.puts("\n")
  end
end
