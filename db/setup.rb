require 'sqlite3'

db = SQLite3::Database.new("vultest.db")

sql = <<SQL
CREATE TABLE configs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  cve_name VARCHAR(200) NOT NULL,
  config_path VARCHAR(200)
);
SQL
db.execute(sql)

db.execute('INSERT INTO configs (cve_name, config_path) values (?, ?)', 'CVE-2017-16995', 'vulconfig/cve-2017-16995.yml')

db.close
