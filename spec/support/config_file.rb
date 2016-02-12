module ConfigFileHelpers
  def create_config_file(config={})
    file = Tempfile.new('test_config')
    file.write(YAML.dump(config.deep_stringify_keys))
    file.close
    file.path
  end
end
