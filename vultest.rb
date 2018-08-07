require 'yaml'

config = YAML.load_file("./vulconfig/cve-2017-16995.yml")
p config

cve = config["cve"]
p cve
