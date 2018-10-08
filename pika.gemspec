lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pika/version'

Gem::Specification.new do |spec|
  spec.name          = 'pika'
  spec.version       = Pika::VERSION
  spec.authors       = ['Steve Jabour', 'Michael Harrison']
  spec.email         = ['steve@jabour.me', 'mike.harrison@summit.com']
  spec.summary       = 'A gem based on the PSL pika library'
  spec.homepage      = 'http://github.com/atsjj/pika'

  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  # spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  # spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'bunny', '~> 2.9', '>= 2.9.2'
  spec.add_dependency 'dry-configurable', '~> 0.7.0'
  spec.add_dependency 'dry-container', '~> 0.6.0'
  spec.add_dependency 'dry-core', '~> 0.4.7'
  spec.add_dependency 'dry-initializer', '~> 2.5.0'
  spec.add_dependency 'dry-struct', '~> 0.5.1'
  spec.add_dependency 'dry-types', '~> 0.13.2'
  spec.add_dependency 'oj', '~> 3.0', '>= 3.0.6'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'

  spec.add_runtime_dependency 'railties'
end
