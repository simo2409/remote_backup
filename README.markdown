remote_backup
=============

remote_backup is a simple 'day-to-day backupper' tool to make backup of a directory and store it locally or remotely (using FTP). Backups are compressed creating a tar.gz file.
remote_backup is built to create and manage daily backups, it's a strong assumption in the whole code.

Before using remote_backup you need to edit his config.yml file where there are all settings.

Features list
-------------
* It can backup a directory locally or remotely (over FTP)
* It has a clear config file to customize his behaviour and to cover your backup needs
* It stores backup files with a meaningful filename (but you can use a fixed name if you want)
* It can execute commands before and/or after the backup process
* It can delete old backups
* It works under ruby 1.9.2

Dependencies
------------
* ruby
* rubygem
* YAML rubygem
* ActiveSupport rubygem (just if you want remote_backup deletes old backups)

Settings explanation
--------------------
* **dir_to_backup** the directory that you want to backup
* **fixed_name** you can set a filename for the backup, it it's empty remote_backup will generate a dynamic filename using date and time (for example 201105121627.tar.gz that means "backupped on 2011-05-12 at 16:27")
* **remote_backup** if it's true means that you want to put your backup file on a remote FTP server
* **remote_host** this is the host of your FTP server (if you are doing a local backup you don't need to fill it)
* **remote_username** this is the username of the user of your FTP server (if you are doing a local backup you don't need to fill it)
* **remote_password** this is the password of the user of your FTP server (if you are doing a local backup you don't need to fill it)
* **destination_path** this is the path where you want to store your backup file. If you are doing a remote backup this path will be used to place backup file in your FTP
* **clear_old_backups** if it's true means that you want remote_backup manage deletion of old backups file (it works just if you DON'T use **fixed_name** setting)
* **preserve_list_of_old_backup** this is an array with numeric values. Each value respresents the days AGO you want to preserve. For example if there is the '1' it means 'yesterday' (1 day ago), if it's '2' (2 days ago), and so on. remote_backup will delete all files in destination named "backupXXXXXXXX.tar.gz" (where Xs are numbers) except the ones explicity defined in this array. If today is 2011-06-29 and my array is [1], remote_backup will preserve the file 'backup20110628.tar.gz' and it will delete all others files matching with the 'backupXXXXXXXX.tar.gz' pattern (obviously remote_backup preserves the 'fresh' backup of the day automatically, you don't need to specify that in the array)
* **pre_backup_command** this is the command to execute before the backup
* **post_backup_command** this is the command to execute after the backup
* **silent** if it's true remote_backup will not produce output (except for errors)
* **temporary_path** this is where remote_backup store the backup file before placing it on the final destination
* **tar_bin** this is the path of tar command on your computer