#!/usr/bin/env ruby -wKU
# Deployment script for Wordpress sites.

# needless to say, you should make sure you have these dependencies
require 'rubygems'
require 'erubis'
require 'fileutils'

branch = ARGV[0] || "master"

# read yaml variables
config = YAML.load(File.read("deploy/deploy-config.yml"))

puts "Deploying #{config["sitename"]}"
puts

# export to a directory
# we use backticks to silence output
puts "Exporting branch #{branch} to package"
`mkdir package`
`git archive #{branch} > package/package.tar`
`cd package && tar -xvf package.tar && rm package.tar && rm -rf deploy && rm -rf nodeploy && rm deploy.rb`

# set up db
puts "Configuring Database"
config_template = File.read("deploy/deploy-config.erb")
template = Erubis::Eruby.new(config_template)
output =  template.result(:dbpwd => config["dbpwd"], :dbname => config["dbname"], :dbuser => config["dbuser"], :secure_keys => config["secure_keys_block"], :siteurl => config["siteurl"])

File.open("package/wp-config.php", 'w') do |f| 
  f.write(output)
end

# # set up advanced cache
puts "Configuring Advanced Cache"
cache_template = File.read("deploy/deploy-advanced-cache.erb")
template = Erubis::Eruby.new(cache_template)
output =  template.result(:path_for_super_cache => config["path_for_super_cache"])
 
File.open("package/wp-content/advanced-cache.php", 'w') do |f| 
  f.write(output)
end

# run rsync
# TODO: rvzni is running as DRY RUN
#       rvzi is for PRODUCTION
# be VERY CAREFUL with --delete
puts "Deploying content with rsync"
# system("rsync -rvzni -essh package/ #{config['deploy_user']}@#{config['deploy_server']}:#{config['deploy_path']}")
system("rsync -rvzi -essh package/ #{config['deploy_user']}@#{config['deploy_server']}:#{config['deploy_path']}")
 
puts "Deleting package directory."
FileUtils.rm_r("package")
