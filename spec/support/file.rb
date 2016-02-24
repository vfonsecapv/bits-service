module FileHelpers
  def blob_path(root_dir, directory_key, key)
    File.join(
      root_dir,
      directory_key,
      key[0..1],
      key[2..3],
      key
    )
  end
end
