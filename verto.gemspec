# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'verto/version'

Gem::Specification.new do |spec|
  spec.name          = 'verto'
  spec.version       = Verto::VERSION
  spec.authors       = ['Carlos Atkinson']
  spec.email         = ['carlos.atks@gmail.com']

  spec.summary       = 'Verto helps you to versionate your project'
  spec.homepage      = 'https://github.com/catks/verto'
  spec.license       = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/catks/verto'
  spec.metadata['changelog_uri'] = 'https://github.com/catks/verto/blob/master/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.5'

  spec.add_dependency             'dry-auto_inject', '~> 0.7.0'
  spec.add_dependency             'dry-configurable', '~> 0.9.0'
  spec.add_dependency             'dry-container', '~> 0.7.0'
  spec.add_dependency             'dry-core', '~> 0.6.0'
  spec.add_dependency             'mustache', '~> 1.1.1'
  spec.add_dependency             'thor', '~> 1.0.1'
  spec.add_dependency             'tty-editor', '~> 0.7.0'
  spec.add_dependency             'tty-prompt', '~> 0.23.1'
  spec.add_dependency             'vseries', '~> 0.2'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'pry-byebug', '~> 3.9.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov', '~> 0.17.0'
end
