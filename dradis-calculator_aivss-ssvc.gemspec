$:.push File.expand_path('../lib', __FILE__)

require 'dradis/plugins/calculators/aivss_ssvc/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.platform = Gem::Platform::RUBY
  spec.name = 'dradis-calculator_aivss-ssvc'
  spec.version = Dradis::Plugins::Calculators::AIVSSSSVC::VERSION::STRING
  spec.summary = 'This plugin adds an AIVSS-SSVC score calculator to Dradis.'
  spec.description = 'Display an OWASP AIVSS-SSVC calculator in Dradis Framework.'

  spec.license = 'GPL-2'

  spec.authors = ['Dradis Team']
  spec.homepage = 'https://dradis.com/support/guides/projects/calculators.html'

  spec.files = `git ls-files`.split($\)
  spec.executables = spec.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})

  spec.add_dependency 'dradis-plugins', '>= 4.0'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
end
