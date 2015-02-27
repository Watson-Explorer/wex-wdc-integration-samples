require 'warbler'
Warbler::Task.new("warr")

task :default => :war

task :war do 
  Rake::Task["warr"].invoke
  # This moves the openssl jars from the stdlib jar into the WEB-INF/lib
  # directory as a workaround for https://github.com/jruby/jruby/issues/1119
  jars_to_shimmy = [ 'kryptcore', 'kryptproviderjdk', 'jopenssl' ]  # '*bc*'

  sh 'rm -rf WEB-INF'
  sh 'rm -rf META-INF'
  
  sh 'unzip proxy.war "WEB-INF/lib/jruby-stdlib-*.jar"'

  jars_to_shimmy.each do |jar|
    sh "unzip WEB-INF/lib/jruby-stdlib-*.jar META-INF/jruby.home/lib/ruby/shared/#{jar}.jar"
    sh "mv META-INF/jruby.home/lib/ruby/shared/#{jar}.jar WEB-INF/lib"
    sh "zip proxy.war WEB-INF/lib/#{jar}.jar"
    # sh "jar -uf proxy.war WEB-INF/lib/#{jar}.jar"
  end

  sh 'rm -rf WEB-INF'
  sh 'rm -rf META-INF'
end