module VultestOptionExecute
  class << self
    def execute(vultest_processing, options)
      return if options['cve'].nil?

      cve = options['cve']
      vultest_processing.attack[:host] = options['attack_host'] unless options['attack_host'].nil?
      vultest_processing.attack[:user] = options['attack_user'] unless options['attack_user'].nil?
      vultest_processing.attack[:passwd] = options['attack_passwd'] unless options['attack_passwd'].nil?
      vultest_processing.test_dir = options['dir'] unless options['dir'].nil?

      vultest_processing.create_vulenv(cve)
      return if options['test'] == 'no'

      sleep(10)
      vultest_processing.attack_vulenv
      vultest_processing.execute_vultest_report
      vultest_processing.destroy_vulenv! if options['destroy'] == 'yes'
    end
  end
end
