require 'yaml'

config_file = File.join(File.expand_path(File.dirname(__FILE__)), 'config.yml')

# Checking config file presence
raise 'Unable to find config.yml' unless File.exist?(config_file)

# Loading config file
config = YAML::load(File.open(config_file))

# Loading ActiveSupport if needed
require 'active_support/all' if config['clear_old_backups']

# Checking config values
raise "Unable to find tar (it should be #{config['tar_bin']})" unless File.exist?(config['tar_bin'])
raise "Unable to find directory to backup (it should be #{config['dir_to_backup']})" unless File.exist?(config['dir_to_backup'])
raise "Unable to find destination path (it should be #{config['destination_path']})" unless config['remote_backup'] || (!config['remote_backup'] && File.exist?(config['destination_path']))
raise "Unable to find temporary path (it should be #{config['temporary_path']})" unless File.exist?(config['temporary_path'])
config['fixed_name'] = '' unless config['fixed_name']
config['silent'] = false  unless config['silent']

now = Time.now

# Creates dynamic backup name based on date/hour. 201105121627.tar.gz means 2011-05-12 16:27
config['fixed_name'] = now.strftime("%Y%m%d%H%M") + '.tar.gz' if config['fixed_name'].empty?

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
    if config['clear_old_backups']
      # Cleaning old backups
      old_backup_to_delete = (now - 3.days).strftime("%Y%m%d%H%M") + '.tar.gz'
      ftp.delete(old_backup_to_delete)
    end
    ftp.close
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
    puts 'ERROR'
  end
  if config['clear_old_backups']
    # Cleaning old backups
    old_backup_to_delete = (now - 7.days).strftime("%Y%m%d") + '*'
    print "Deleting old backup .. " unless config['silent']
    if system('rm ' + File.join(config['destination_path'], old_backup_to_delete))
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
if system('rm ' + full_temporary_path)
  puts 'OK' unless config['silent']
else
  puts 'ERROR'
end