module ConfigFileHelpers

  def create_config_file(config = {})
    file = Tempfile.new('test_config')
    file.write(YAML.dump(config))
    file.flush
    file.path
  end

end
