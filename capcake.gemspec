lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'capcake'
  spec.version       = '3.0.1'
  spec.authors       = ['Jad Bitar']
  spec.email         = ['bitarjad@gmail.com']
  spec.description   = %q{CakePHP deployment for Capistrano 3.x}
  spec.summary       = %q{Native integration with popular CakePHP plugins (i.e. AssetCompress, Migrations)}
  spec.homepage      = 'https://github.com/jadb/capcake'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'capistrano', '~> 3.0', '>= 3.0.0'
  spec.add_dependency 'capistrano-composer', '~> 0', '>= 0.0.3'
  spec.add_dependency 'capistrano-file-permissions', '~> 0', '>= 0.0.1'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake', '~> 0'
end
