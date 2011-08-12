require 'yaml'

config_file = File.join(File.expand_path(File.dirname(__FILE__)), 'config.yml')

# Checking config file presence
raise 'Unable to find config.yml' unless File.exist?(config_file)

# Loading config file
config = YAML::load(File.open(config_file))

now = Time.now
date_format = "%Y%m%d%H%M"

# Checking config values
raise "Unable to find tar (it should be #{config['tar_bin']})" unless File.exist?(config['tar_bin'])
raise "Unable to find directory to backup (it should be #{config['dir_to_backup']})" unless File.exist?(config['dir_to_backup'])
raise "Unable to find destination path (it should be #{config['destination_path']})" unless config['remote_backup'] || (!config['remote_backup'] && File.exist?(config['destination_path']))
raise "Unable to find temporary path (it should be #{config['temporary_path']})" unless File.exist?(config['temporary_path'])
config['fixed_name'] = '' unless config['fixed_name']
config['silent'] = false  unless config['silent']

# Checks data for remote backup
if config['remote_backup']
  config['remote_type'] = config['remote_type'].downcase
  raise 'remote_type not set' unless config['remote_type']
  raise 'unknown remote_type value' unless ['ftp', 'sftp'].include?(config['remote_type'])
  
  raise "#{config['remote_type'].upcase} host not set"      unless config['remote_host'] || config['remote_host'].empty?
  raise "#{config['remote_type'].upcase} username not set"  unless config['remote_username'] || config['remote_username'].empty?
  raise "#{config['remote_type'].upcase} password not set"  unless config['remote_password'] || config['remote_password'].empty?
  raise "#{config['remote_type'].upcase} port not set"      unless config['remote_port'] || config['remote_port'].empty?
  require 'net/ssh' if config['remote_type'] == 'sftp'
  require "net/#{config['remote_type']}"
end

# Creates dynamic backup name based on date/hour. backup201105121627.tar.gz means 2011-05-12 16:27
config['fixed_name'] = 'backup' + now.strftime(date_format) + '.tar.gz' if config['fixed_name'].empty?

# Executing pre_backup_command
unless config['pre_backup_command'].empty?
  print "Executing pre_backup_command ('#{config['pre_backup_command']}') .. "
  if system(config['pre_backup_command'])
    puts 'OK' unless config['silent']
  else
    puts 'ERROR'
    exit
  end
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
  begin
    print "FTP (#{config['remote_host']}) .. " unless config['silent']
    if config['remote_type'] == 'ftp'
      ftp = Net::FTP.new(config['remote_host'], config['remote_username'], config['remote_password'])
      ftp.chdir(config['destination_path'])
      ftp.put(full_temporary_path)
    else
      sftp = Net::SFTP.start(config['remote_host'], config['remote_username'], :password => config['remote_password'], :port => config['remote_port'])
      sftp.put_file full_temporary_path full_destination_path
    end
    puts "OK" unless config['silent']
    ftp.close
  rescue Net::FTPPermError
    puts 'ERROR (Permission problem)'
    exit
  end
else
  print "local destination (#{full_destination_path}) .. " unless config['silent']
  if full_temporary_path == full_destination_path
    puts "NOT NEEDED (temporary directory is the same of final destination)" unless config['silent']
  else
    if system('cp ' + full_temporary_path + ' ' + full_destination_path)
      puts 'OK' unless config['silent']
    else
      puts 'ERROR'
    end
  end
end

# Executing post_backup_command
unless config['post_backup_command'].empty?
  print "Executing post_backup_command ('#{config['post_backup_command']}') .. "
  if system(config['post_backup_command'])
    puts 'OK' unless config['silent']
  else
    puts 'ERROR'
    exit
  end
end

# Cleaning temporary destination
print 'Cleaning temp file .. ' unless config['silent']
if full_temporary_path == full_destination_path
  puts "NOT NEEDED (temporary directory is the same of final destination)" unless config['silent']
else
  if system('rm ' + full_temporary_path)
    puts 'OK' unless config['silent']
  else
    puts 'ERROR'
  end
end