Gem::Specification.new do |spec|
  spec.name          = 'lita-vote'
  spec.version       = '0.1.0'
  spec.authors       = ['John Celoria']
  spec.email         = ['jceloria@gmail.com']
  spec.description   = 'Used for calling votes in a chat room'
  spec.summary       = 'Has the caller enter a poll command to start off a vote in a room'
  spec.homepage      = 'TODO: Add a homepage'
  spec.license       = 'MIT'
  spec.metadata      = { 'lita_plugin_type' => 'handler' }

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'lita', '>= 4.7'
  spec.add_runtime_dependency 'mongo'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '>= 3.0.0'
end
