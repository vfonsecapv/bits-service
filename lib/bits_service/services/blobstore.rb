Dir[File.expand_path('../blobstore/**/*.rb', __FILE__)].each do |file|
  require file
end
