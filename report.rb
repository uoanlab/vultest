require 'sqlite3'
require 'tty-table'

require_relative './db'

module Report

  def print_cve(cve)

    cve_info = DB.get_cve_info(cve)
    unless cve_info['description'].nil?
      for str_range in 1..cve_info['description'].size/100
        new_line_place = cve_info['description'].index(" ", str_range * 100) + 1
        cve_info['description'].insert(new_line_place, "\n")
      end
    end

    cwe = DB.get_cwe(cve)
    cpe = DB.get_cpe(cve)

    header = [cve, '']
    table = TTY::Table.new header, [
      ['nvd id',      cve_info['nvd_id']],
      ['cwe',         cwe],
      ['description', cve_info['description']],
      ['cpe',         cpe]
    ]
    table.render(:ascii, multiline: true).each_line do |line|
      puts line.chomp
    end
  end

  def print_cvss_v2 (cve)
    cvss_v2 = DB.get_cvss_v2 (cve)

    header = ['CVSS v2', ''] 
    table = TTY::Table.new header, [
      ['vector',                 cvss_v2['vector']],
      ['access vector',          cvss_v2['access_vector']],
      ['access complexity',      cvss_v2['access_complexity']],
      ['authentication',         cvss_v2['authentication']],
      ['confidentiality impact', cvss_v2['confidentiality_impact']],
      ['integrity impact',       cvss_v2['integrity_impact']],
      ['availability impact',    cvss_v2['availability_impact']],
      ['base score',             cvss_v2['base_score']],
    ]

    table.render(:ascii, multiline: true).each_line do |line|
      puts line.chomp
    end

    return cvss_v2
  end

  def print_cvss_v3 (cve)
    cvss_v3 = DB.get_cvss_v3(cve)
    return nil if cvss_v3.empty?

    header = ['CVSS v3', ''] 
    table = TTY::Table.new header, [
      ['vector',                 cvss_v3['vector']],
      ['attack vector',          cvss_v3['attack_vector']],
      ['attack complexity',      cvss_v3['attack_complexity']],
      ['privileges required',    cvss_v3['privileges_required']],
      ['user interaction',       cvss_v3['user_interaction']],
      ['scope',                  cvss_v3['scope']],
      ['confidentiality impact', cvss_v3['confidentiality_impact']],
      ['integrity impact',       cvss_v3['integrity_impact']],
      ['availability impact',    cvss_v3['availability_impact']],
      ['base score',             cvss_v3['base_score']],
      ['base severity',          cvss_v3['base_severity']]
    ]

    table.render(:ascii, multiline: true).each_line do |line|
      puts line.chomp
    end

    return cvss_v3
  end

  module_function :print_cve
  module_function :print_cvss_v2
  module_function :print_cvss_v3
end

