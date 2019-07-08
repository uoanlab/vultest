module AssistContent
  private

  def content_tasks(db_path, env_config, content_ansible_dir)
    FileUtils.mkdir_p("#{content_ansible_dir}/#{env_config['cve']}/tasks")
    FileUtils.cp_r(
      "#{db_path}/data/#{env_config['construction']['content']}/tasks/main.yml",
      "#{content_ansible_dir}/#{env_config['cve']}/tasks/main.yml"
    )
  end

  def content_vars(db_path, env_config, content_ansible_dir)
    FileUtils.mkdir_p("#{content_ansible_dir}/#{env_config['cve']}/tasks/vars")
    FileUtils.cp_r(
      "#{db_path}/data/#{env_config['construction']['content']}/vars/main.yml",
      "#{content_ansible_dir}/#{env_config['cve']}/vars/main.yml"
    )
  end

  def content_files(db_path, env_config, content_ansible_dir)
    FileUtils.mkdir_p("#{content_ansible_dir}/#{env_config['cve']}/files")
    Dir.glob("#{db_path}/data/#{env_config['construction']['content']}/files/*") do |path|
      content = path.split('/')
      FileUtils.cp_r(
        "#{db_path}/data/#{env_config['construction']['content']}/files/#{content[content.size - 1]}",
        "#{content_ansible_dir}/#{env_config['cve']}/files/#{content[content.size - 1]}"
      )
    end
  end
end
