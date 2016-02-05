require 'rake'
require 'rspec/core/rake_task'

task default: ['spec:all']

namespace :spec do
  desc 'Run all specs'
  task :all => [:unit, :integration]

  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = "spec/unit/**/*_spec.rb"
  end

  RSpec::Core::RakeTask.new(:integration) do |t|
    t.pattern = "spec/integration/**/*_spec.rb"
  end

end
