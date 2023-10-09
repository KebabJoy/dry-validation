source 'https://rubygems.org'

gemspec

group :test do
  gem 'i18n', require: false
  platform :mri do
    gem 'simplecov', require: false
  end
  gem 'dry-struct'
end
gem 'dry-monads'

gem 'dry-logic', git: 'https://gitlab.overteam.ru/overteam/med/dry-logic.git', branch: 'release-0.5-r3'
gem 'dry-types', git: 'https://gitlab.overteam.ru/overteam/med/dry-types.git', branch: 'release-0.14-r3'
group :tools do
  gem 'pry-byebug', platform: :mri
  gem 'pry', platform: :jruby

  unless ENV['TRAVIS']
    gem 'mutant', git: 'https://github.com/mbj/mutant'
    gem 'mutant-rspec', git: 'https://github.com/mbj/mutant'
  end
end

group :benchmarks do
  gem 'hotch', platform: :mri
  gem 'activemodel', '~> 5.0.0.rc'
  gem 'actionpack', '~> 5.0.0.rc'
  gem 'benchmark-ips'
  gem 'virtus'
end
