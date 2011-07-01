require 'yaml'

config_file = File.join(File.expand_path(File.dirname(__FILE__)), 'config.yml')

# Checking config file presence
raise 'Unable to find config.yml' unless File.exist?(config_file)

# Loading config file
config = YAML::load(File.open(config_file))

now = Time.now
date_format = "%Y%m%d"

if config['clear_old_backups']
  # Loading ActiveSupport if needed
  require 'active_support/all'
  
  def generate_list_of_deleting_files(now, date_format, config, all_files, format = 'local')
    if config['preserve_list_of_old_backup'].any?
      config['preserve_list_of_old_backup'] << 0 # 0 identifies the today's backup
      to_preserve = []
      if config['remote_backup']
      else
        
      end
      config['preserve_list_of_old_backup'].each do |save_me|
        if format == 'local'
          to_preserve << File.join(config['destination_path'], 'backup' + (now - save_me.days).strftime(date_format) + '.tar.gz')
        else
          to_preserve << 'backup' + (now - save_me.days).strftime(date_format) + '.tar.gz'
        end
      end
    end
    return (all_files - to_preserve)
  end
  
end

# Checking config values
raise "Unable to find tar (it should be #{config['tar_bin']})" unless File.exist?(config['tar_bin'])
raise "Unable to find directory to backup (it should be #{config['dir_to_backup']})" unless File.exist?(config['dir_to_backup'])
raise "Unable to find destination path (it should be #{config['destination_path']})" unless config['remote_backup'] || (!config['remote_backup'] && File.exist?(config['destination_path']))
raise "Unable to find temporary path (it should be #{config['temporary_path']})" unless File.exist?(config['temporary_path'])
config['fixed_name'] = '' unless config['fixed_name']
config['silent'] = false  unless config['silent']
raise "There is a non expected value in 'preserve_list_of_old_backup'" if !config['preserve_list_of_old_backup'].is_a?(Array) || config['preserve_list_of_old_backup'].select {|i| !i.is_a?(Fixnum)}.any?

# Checks data for remote backup
if config['remote_backup']
  raise 'FTP host not set'      unless config['remote_host'] || config['remote_host'].empty?
  raise 'FTP username not set'  unless config['remote_username'] || config['remote_username'].empty?
  raise 'FTP password not set'  unless config['remote_password'] || config['remote_password'].empty?
  require 'net/ftp'
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
    ftp = Net::FTP.new(config['remote_host'], config['remote_username'], config['remote_password'])
    ftp.chdir(config['destination_path'])
    ftp.put(full_temporary_path)
    puts "OK" unless config['silent']
    if config['clear_old_backups']
      # Cleaning old backups
      all_remote_files = ftp.list
      all_files = []
      all_remote_files.each do |file|
        got = file.match(/.+ (backup[0-9]{8}.tar.gz)/)
        all_files << got[1] if got && got[1]
      end
      old_backups_to_delete = generate_list_of_deleting_files(now, date_format, config, all_files, 'ftp')
      if old_backups_to_delete.any?
        puts "Deleting old backup .. " unless config['silent']
        old_backups_to_delete.each do |file_to_delete|
          print "Deleting '#{file_to_delete}' .. "
          ftp.delete(file_to_delete)
          puts 'OK' unless config['silent']
        end
      end
    end
    ftp.close
  rescue Net::FTPPermError
    puts 'ERROR (Permission problem)'
    exit
  end
else
  print "local destination (#{full_destination_path}) .. " unless config['silent']
  if system('mv ' + full_temporary_path + ' ' + full_destination_path)
    puts 'OK' unless config['silent']
  else
    puts 'ERROR'
  end
  if config['clear_old_backups']
    # Cleaning old backups
    all_files = Dir.glob(File.join(config['destination_path'], 'backup*.tar.gz'))
    old_backups_to_delete = generate_list_of_deleting_files(now, date_format, config, all_files)
    if old_backups_to_delete.any?
      puts "Deleting old backup .. " unless config['silent']
      old_backups_to_delete.each do |file_to_delete|
        print "Deleting '#{file_to_delete}' .. "
        if system('rm ' + file_to_delete)
          puts 'OK' unless config['silent']
        else
          puts 'ERROR'
        end
      end
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