require 'sqlite3'
require 'tty-table'

module Report

  def get_cvss_v2 (cve)
    db = SQLite3::Database.new('./db/cvss_v2.sqlite3')
    db.results_as_hash = true
    cvss_v2 = {}
    db.execute('select * from cvss_v2 where cve=?', cve) do |cvss|
      cvss_v2['vector'] = cvss['vector_string']
      cvss_v2['access_vector'] = cvss['access_vector']
      cvss_v2['access_complexity'] = cvss['access_complexity']
      cvss_v2['authentication'] = cvss['authentication']
      cvss_v2['confidentiality_impact'] = cvss['confidentiality_impact']
      cvss_v2['integrity_impact'] = cvss['integrity_impact']
      cvss_v2['availability_impact'] = cvss['availability_impact']
      cvss_v2['base_score'] = cvss['base_score']
    end
    db.close

    return cvss_v2
  end

  def get_cvss_v3 (cve)
    db = SQLite3::Database.new('./db/cvss_v3.sqlite3')
    db.results_as_hash = true
    cvss_v3 = {}

    db.execute('select * from cvss_v3 where cve=?', cve) do |cvss|
      cvss_v3['vector'] = cvss['vector_string']
      cvss_v3['attack_vector'] = cvss['attack_vector']
      cvss_v3['attack_complexity'] = cvss['attack_complexity']
      cvss_v3['privileges_required'] = cvss['privileges_required']
      cvss_v3['user_interaction'] = cvss['user_interaction']
      cvss_v3['scope'] = cvss['scope']
      cvss_v3['confidentiality_impact'] = cvss['confidentiality_impact']
      cvss_v3['integrity_impact'] = cvss['integrity_impact']
      cvss_v3['availability_impact'] = cvss['availability_impact']
      cvss_v3['base_score'] = cvss['base_score']
      cvss_v3['base_severity'] = cvss['base_severity']
    end
    db.close

    return cvss_v3
  end

  def print_cve(cve)
    # Get CVE infomation
    db = SQLite3::Database.new('./db/cve.sqlite3')
    db.results_as_hash = true
    nvd_id = nil
    description = nil
    db.execute('select * from cve where cve=?', cve) do |cve_info|
      nvd_id = cve_info['nvd_id']
      description = cve_info['description']
    end

    unless description.nil?
      for str_range in 1..description.size/100
        new_line_place = description.index(" ", str_range * 100) + 1
        description.insert(new_line_place, "\n")
      end
    end
    db.close

    # Get CWE infomation
    db = SQLite3::Database.new('./db/cwe.sqlite3')
    db.results_as_hash = true
    cwe = nil
    db.execute('select * from cwe where cve=?', cve) do |cwe_info|
      cwe = cwe == nil ? cwe_info['cwe'] : "#{cwe}\n#{cwe_info['cwe']}"
    end
    db.close

    db = SQLite3::Database.new('./db/cpe.sqlite3')
    db.results_as_hash = true
    cpe = nil
    db.execute('select * from cpe where cve=?', cve) do |cpe_info|
      cpe = cpe == nil ? cpe_info['cpe'] : "#{cpe}\n#{cpe_info['cpe']}"
    end
    db.close

    header = [cve, '']
    table = TTY::Table.new header, [
      ['nvd id',      nvd_id],
      ['cwe',         cwe],
      ['description', description],
      ['cpe',         cpe]
    ]
    table.render(:ascii, multiline: true).each_line do |line|
      puts line.chomp
    end
  end

  def print_cvss(cve)
    cvss_v2 = self.get_cvss_v2(cve)
    cvss_v3 = self.get_cvss_v3(cve)

    header = ['CVSS v2', 'CVSS v2 content', 'CVSS v3', 'CVSS v3 content'] 
    table = TTY::Table.new header, [
      ['vector',                 cvss_v2['vector'],                 'vector',                 cvss_v3['vector']],
      ['access vector',          cvss_v2['access_vector'],          'attack vector',          cvss_v3['attack_vector']],
      ['access complexity',      cvss_v2['access_complexity'],      'attack complexity',      cvss_v3['attack_complexity']],
      ['authentication',         cvss_v2['authentication'],         '',                       ''],
      ['',                       '',                                'privileges required',    cvss_v3['privileges_required']],
      ['',                       '',                                'user interaction',       cvss_v3['user_interaction']],
      ['',                       '',                                'scope',                  cvss_v3['scope']],
      ['confidentiality impact', cvss_v2['confidentiality_impact'], 'confidentiality impact', cvss_v3['confidentiality_impact']],
      ['integrity impact',       cvss_v2['integrity_impact'],       'integrity impact',       cvss_v3['integrity_impact']],
      ['availability impact',    cvss_v2['availability_impact'],    'availability impact',    cvss_v3['availability_impact']],
      ['base score',             cvss_v2['base_score'],             'base score',             cvss_v3['base_score']],
      ['',                       '',                                'base severity',          cvss_v3['base_severity']]
    ]

    table.render(:ascii, multiline: true, column_widths: 4, resize: true).each_line do |line|
      puts line.chomp
    end
  end

  def print_cvss_v2 (cve)
    cvss_v2 = self.get_cvss_v2 (cve)

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
    cvss_v3 = self.get_cvss_v3(cve)
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

  module_function :get_cvss_v2
  module_function :get_cvss_v3
  module_function :print_cve
  module_function :print_cvss
  module_function :print_cvss_v2
  module_function :print_cvss_v3
end

=begin
Report.print_cve('CVE-2014-6271')
Report.print_cvss_v2('CVE-2014-6271')
Report.print_cvss_v3('CVE-2014-6271')
=end

Report.print_cve('CVE-2018-10900')
Report.print_cvss_v2('CVE-2018-10900')
Report.print_cvss_v3('CVE-2018-10900')

Report.print_cve('CVE-2016-8655')

