require File.expand_path('../lib/version.rb', __FILE__)

Gem::Specification.new do |s|
  s.name = 'has_editable_password'
  s.version = VERSION
  s.date = '2013-12-14'
  s.summary = 'has_secure_password with safe updating capabilities.'
  s.description = 'HasEditablePassword extends has_secure_password with updating capabilities. On password update, the old password or a recovery token is asked.'
  s.author = 'Francesco Boffa'
  s.email = 'fra.boffa@gmail.com'
  s.homepage = 'http://rubygems.org/gems/has_editable_password'
  s.license = 'MIT'

  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'activemodel'
  s.add_runtime_dependency 'bcrypt-ruby', '~> 3.0.0'
  
  s.files = Dir.glob("lib/**/*")
  s.test_files = Dir.glob("spec/**/*")
end
