# Note that this kind of requiring all files can potentially cause issues when
# files have dependencies on others that conflict with the ordering of this listing
# We might want to unroll this loop to avoid this issue.
Dir[File.expand_path('../**/*.rb', __FILE__)].sort.each { |f| require f }
