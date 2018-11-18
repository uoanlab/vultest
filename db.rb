require 'sqlite3'
require 'tty-table'
require 'yaml'

module DB
  @config = YAML.load_file('./config.yml')

  def get_cve_info(cve)
    db = SQLite3::Database.new("#{@config['vultest_db_path']}/db/cve.sqlite3")
    db.results_as_hash = true
    cve_info = {}

    db.execute('select * from cve where cve=?', cve) do |info|
      cve_info['nvd_id'] = info['nvd_id']
      cve_info['description'] = info['description']
    end
    db.close

    return cve_info
  end

  def get_cwe(cve)
    db = SQLite3::Database.new("#{@config['vultest_db_path']}/db/cwe.sqlite3")
    db.results_as_hash = true
    cwe = nil
    db.execute('select * from cwe where cve=?', cve) do |cwe_info|
      cwe = cwe == nil ? cwe_info['cwe'] : "#{cwe}\n#{cwe_info['cwe']}"
    end
    db.close

    return cwe
  end

  def get_cpe(cve)
    db = SQLite3::Database.new("#{@config['vultest_db_path']}/db/cpe.sqlite3")
    db.results_as_hash = true
    cpe = []
    db.execute('select * from cpe where cve=?', cve) do |cpe_info|
      cpe.push(cpe_info['cpe'])
    end
    db.close

    return cpe
  end

  def get_cvss_v2 (cve)
    db = SQLite3::Database.new("#{@config['vultest_db_path']}/db/cvss_v2.sqlite3")
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
    db = SQLite3::Database.new("#{@config['vultest_db_path']}/db/cvss_v3.sqlite3")
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

  def get_vulconfigs(cve)
    db = SQLite3::Database.new("#{@config['vultest_db_path']}/db/vultest.sqlite3")
    db.results_as_hash = true

    vulconfigs = []
    db.execute('select * from configs where cve_name=?', cve) do |config|
      vulconfig = {}
      vulconfig['name'] = config['name']
      vulconfig['config_path'] = config['config_path']
      vulconfig['module_path'] = config['module_path']
      vulconfigs.push(vulconfig)
    end
    db.close
    return vulconfigs
  end

  module_function :get_cve_info
  module_function :get_cwe
  module_function :get_cpe
  module_function :get_cvss_v2
  module_function :get_cvss_v3
  module_function :get_vulconfigs

end
