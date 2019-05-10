=begin
Copyright [2019] [Kohei Akasaka]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=end

require_relative '../db'
require_relative '../utility'

module VultestReport

  def report(cve, vulenv_config_path, attack_config_path)
    Utility.print_message('default', 'vultest report')
    Utility.print_message('default', "==============")

    # Get CVE description
    cve_info = DB.get_cve_info(cve)
    unless cve_info['description'].nil?
      for str_range in 1..cve_info['description'].size/100
        new_line_place = cve_info['description'].index(" ", str_range * 100) + 1
        cve_info['description'].insert(new_line_place, "\n    ")
      end
    end
    print "\n"

    Utility.print_message('defalut', '  CVE description')
    Utility.print_message('defalut', "  ===============")
    print "\n"
    Utility.print_message('defalut', "    #{cve_info['description']}")
    print "\n"

    # Get cpe
    Utility.print_message('default', '  Affect software version (CPE)')
    Utility.print_message('defalut', "  ==============================")
    print "\n"
    cpe = DB.get_cpe(cve)
    cpe.each do |cpe_info|
      Utility.print_message('defalut', "    #{cpe_info}")
    end
    print "\n"

    # Output target host
    Utility.print_message('default', '  target host')
    Utility.print_message('defalut', "  ============")
    print "\n"

    vulenv_config = YAML.load_file(vulenv_config_path)

    # Output target host operation system
    Utility.print_message('default', '    operation system')
    Utility.print_message('defalut', "    ================")
    print "\n"
    Utility.print_message('default', "      #{vulenv_config['construction']['os']['name']} : #{vulenv_config['construction']['os']['version']}")
    print "\n"

    # Output vulnerable software
    if vulenv_config['construction'].key?('vul_software')
      Utility.print_message('default', '    vulnerable software')
      Utility.print_message('defalut', "    ====================")
      print "\n"
      Utility.print_message('default', "      #{vulenv_config['construction']['vul_software']['name']} : #{vulenv_config['construction']['vul_software']['version']}")
      print "\n"
    end

    # Output related software
    if vulenv_config['construction'].key?('related_software')
      Utility.print_message('default', '    related software')
      Utility.print_message('defalut', "    ====================")
      print "\n"

      vulenv_config['construction']['related_software'].each do |software|
        Utility.print_message('default', "      #{software['name']} : #{software['version']}")
      end
      print "\n"

    end


    # Output configuration of attack target host
    if vulenv_config.key?('report')
      Utility.print_message('default', '  Configuration of attack target host')
      Utility.print_message('defalut', "  ===================================")
      print "\n"
      msgs = vulenv_config['report']
      msgs['msg'].each do |msg|
        Utility.print_message('defalut', "    #{msg}")
      end
      print "\n"
    end

    attack_config = YAML.load_file(attack_config_path)
    Utility.print_message('default', '  Attack method')
    Utility.print_message('defalut', "  ===============")
    print "\n"

    attack_methods = attack_config['metasploit_module']
    attack_methods.each do |attack_method|
      Utility.print_message('default', "    module_name : #{attack_method['module_name']}")
      attack_method['options'].each do |option|
        Utility.print_message('default', "      #{option['name']} : #{option['var']}")
      end
      print "\n"
    end
  end

  module_function :report
end
