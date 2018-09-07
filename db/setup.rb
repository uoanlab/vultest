require 'sqlite3'

db = SQLite3::Database.new("vultest.db")

sql = <<SQL
CREATE TABLE configs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  cve_name VARCHAR(200) NOT NULL,
  config_path VARCHAR(200),
  module_path VARCHAR(200)
);
SQL
db.execute(sql)

db.execute('INSERT INTO configs (cve_name, config_path, module_path) values (?, ?, ?)', 'CVE-2016-4557', 'config/env/cve-2016-4557.yml', 'config/attack/cve-2016-4557-module.yml')

db.execute('INSERT INTO configs (cve_name, config_path, module_path) values (?, ?, ?)', 'CVE-2015-1328', 'config/env/cve-2015-1328.yml', 'config/attack/cve-2015-1328-module.yml')

db.execute('INSERT INTO configs (cve_name, config_path, module_path) values (?, ?, ?)', 'CVE-2017-16995', 'config/env/cve-2017-16995.yml', 'config/attack/cve-2017-16995-module.yml')

db.execute('INSERT INTO configs (cve_name, config_path, module_path) values (?, ?, ?)', 'CVE-2014-6271', 'config/env/shellshock.yml', 'config/attack/shellshock.yml')

db.close
