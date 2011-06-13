require 'yaml'

# Checking config file presence
raise 'Unable to find config.yml' unless File.exist?('./config.yml')

# Loading config file
config = YAML::load(File.open('./config.yml'))

# Checking config values
raise "Unable to find tar (it should be #{config['tar_bin']})" unless File.exist?(config['tar_bin'])
raise "Unable to find directory to backup (it should be #{config['dir_to_backup']})" unless File.exist?(config['dir_to_backup'])
raise "Unable to find destination path (it should be #{config['destination_path']})" unless config['remote_backup'] || (!config['remote_backup'] && File.exist?(config['destination_path']))
raise "Unable to find temporary path (it should be #{config['temporary_path']})" unless File.exist?(config['temporary_path'])
config['fixed_name'] = '' unless config['fixed_name']
config['silent'] = false  unless config['silent']

# Creates dynamic backup name based on date/hour. 201105121627.tar.gz means 2011-05-12 16:27
config['fixed_name'] = Time.now.strftime("%Y%m%d%H%M") + '.tar.gz' if config['fixed_name'].empty?

# Checks data for remote backup
if config['remote_backup']
  raise 'FTP host not set'      unless config['remote_host'] || config['remote_host'].empty?
  raise 'FTP username not set'  unless config['remote_username'] || config['remote_username'].empty?
  raise 'FTP password not set'  unless config['remote_password'] || config['remote_password'].empty?
  require 'net/ftp'
end

full_temporary_path = File.expand_path(File.join(config['temporary_path'], config['fixed_name']))
full_destination_path = File.join(config['destination_path'], config['fixed_name'])

# Compressing
print "Compressing into #{config['fixed_name']} .. " unless config['silent']
if system(config['tar_bin'] + ' -pczf ' + full_temporary_path + ' ' + config['dir_to_backup'])
  puts "OK" unless config['silent']
else
  puts 'ERROR (Unexpected error with tar)'
  exit
end

# Moving to destination
print "Moving #{config['fixed_name']} to " unless config['silent']
if config['remote_backup']
  print "FTP (#{config['remote_host']}) .. " unless config['silent']
  begin
    ftp = Net::FTP.new(config['remote_host'], config['remote_username'], config['remote_password'])
    ftp.chdir(config['destination_path'])
    ftp.put(full_temporary_path)
  rescue Net::FTPPermError
    puts 'ERROR (Permission problem)'
    exit
  end
  puts "OK" unless config['silent']
else
  print "local destination (#{full_destination_path}) .. " unless config['silent']
  if system('cp ' + full_temporary_path + ' ' + full_destination_path)
    puts 'OK' unless config['silent']
  else
    puts 'ERROR' unless config['silent']
  end
end

# Cleaning temporary destination
print 'Cleaning temp file .. ' unless config['silent']
if system('rm ' + full_temporary_path)
  puts 'OK' unless config['silent']
else
  puts 'ERROR' unless config['silent']
end