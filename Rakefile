require 'rake/testtask'

$:.unshift 'lib'

desc "Start an IRB session preloaded with this library"
task :console do
  sh "ASTERISK_VOICEMAIL_ROOT='./test/fixtures/' irb -rlib/active_mailbox.rb -I./lib"
end

require 'sdoc_helpers'
desc "Push a new version to Gemcutter"
task :publish do
  require 'active_mailbox/version'

  ver = ActiveMailbox::Version

  sh "gem build active_mailbox.gemspec"
  sh "gem push active_mailbox-#{ver}.gem"
  sh "git tag -a -m 'ActiveMailbox v#{ver}' v#{ver}"
  sh "git push origin v#{ver}"
  sh "git push origin master"
  sh "git clean -fd"
  sh "rake pages"
end

task :default => :test

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test' << '.'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end
