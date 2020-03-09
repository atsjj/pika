lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pika/version'

Gem::Specification.new do |spec|
  spec.name          = 'pika'
  spec.version       = Pika::VERSION
  spec.summary       = 'A gem based on the PSL pika library'
  spec.homepage      = 'http://github.com/atsjj/pika'
  spec.license       = 'MIT'
  spec.authors       = ['Steve Jabour']
  spec.email         = ['steve@jabour.me']
  spec.files         = Dir['lib/**/*', 'Rakefile']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 12.0', '>= 12.3.3'
  spec.add_development_dependency 'minitest', '~> 5.0'

  spec.add_runtime_dependency 'activesupport', '~> 6.0.0', '>= 6.0.0'
  spec.add_runtime_dependency 'bunny', '~> 2.14.1', '>= 2.14.1'
  spec.add_runtime_dependency 'concurrent-ruby', '~> 1.1.0', '>= 1.1.0'
  spec.add_runtime_dependency 'dry-configurable', '~> 0.8.0', '>= 0.8.0'
  spec.add_runtime_dependency 'dry-container', '~> 0.7.0', '>= 0.7.0'
  spec.add_runtime_dependency 'dry-core', '~> 0.4.0', '>= 0.4.0'
  spec.add_runtime_dependency 'dry-initializer', '~> 3.0.0', '>= 3.0.0'
  spec.add_runtime_dependency 'dry-struct', '~> 1.3.0', '>= 1.3.0'
  spec.add_runtime_dependency 'dry-types', '~> 1.3.0', '>= 1.3.0'
  spec.add_runtime_dependency 'oj', '~> 3.10.0', '>= 3.10.0'
  spec.add_runtime_dependency 'railties', '~> 6.0.0', '>= 6.0.0'
end
