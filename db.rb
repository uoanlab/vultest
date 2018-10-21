require 'sqlite3'
require 'tty-table'

module DB
  def get_vulconfigs(cve)
    db = SQLite3::Database.new('./db/vultest.db')
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

  module_function :get_vulconfigs
end
