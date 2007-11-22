unless Capistrano::Configuration.respond_to?(:instance)
  abort "deprec2 requires Capistrano 2"
end
require "#{File.dirname(__FILE__)}/recipes/sources"
require "#{File.dirname(__FILE__)}/recipes/deprec"
require "#{File.dirname(__FILE__)}/recipes/deprecated"
require "#{File.dirname(__FILE__)}/recipes/canonical"
require "#{File.dirname(__FILE__)}/recipes/user"
require "#{File.dirname(__FILE__)}/recipes/ssh"
require "#{File.dirname(__FILE__)}/recipes/nginx"
require "#{File.dirname(__FILE__)}/recipes/apache"
require "#{File.dirname(__FILE__)}/recipes/php"
require "#{File.dirname(__FILE__)}/recipes/subversion"
require "#{File.dirname(__FILE__)}/recipes/trac"
require "#{File.dirname(__FILE__)}/recipes/ruby"
require "#{File.dirname(__FILE__)}/recipes/rails"
require "#{File.dirname(__FILE__)}/recipes/mongrel"
require "#{File.dirname(__FILE__)}/recipes/mysql"
require "#{File.dirname(__FILE__)}/recipes/postgres"
require "#{File.dirname(__FILE__)}/recipes/postfix"
require "#{File.dirname(__FILE__)}/recipes/memcache"
require "#{File.dirname(__FILE__)}/recipes/vmware"

# this will be pulled out into ubuntu plugin
require "#{File.dirname(__FILE__)}/recipes/ubuntu"