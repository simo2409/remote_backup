remote_backup
=============

remote_backup is a simple 'day-to-day backupper' tool to make backup of a directory and store it locally or remotely (using FTP). Backups are compressed creating a tar.gz file.
remote_backup is built to create and manage daily backups, it's a strong assumption in the whole code.

Before using remote_backup you need to edit his config.yml file where there are all settings.

Features list
-------------
* It can backup a directory locally or remotely (over FTP or SFTP)
* It has a clear config file to customize his behaviour and to cover your backup needs
* It stores backup files with a meaningful filename (but you can use a fixed name if you want)
* It can execute commands before and/or after the backup process
* It works under ruby 1.9.2

Dependencies
------------
* ruby
* rubygem
* YAML rubygem
* net/ssh and net/sftp (only if you enable remote_backup and use 'sftp' as remote_type)

Settings explanation
--------------------
* **dir_to_backup** the directory that you want to backup
* **fixed_name** you can set a filename for the backup, it it's empty remote_backup will generate a dynamic filename using date and time (for example 201105121627.tar.gz that means "backupped on 2011-05-12 at 16:27")
* **remote_backup** if it's true means that you want to put your backup file on a remote FTP server
* **remote_type** it's the protocol you want to use, it can be 'ftp' or 'sftp'
* **remote_host** this is the host of your FTP server (if you are doing a local backup you don't need to fill it)
* **remote_username** this is the username of the user of your server (if you are doing a local backup you don't need to fill it)
* **remote_password** this is the password of the user of your server (if you are doing a local backup you don't need to fill it)
* **remote_port** this is the port of the host of the server (usually it's 21 for FTP and 22 for SFTP)
* **destination_path** this is the path where you want to store your backup file. If you are doing a remote backup this path will be used to place backup file in your FTP
* **pre_backup_command** this is the command to execute before the backup
* **post_backup_command** this is the command to execute after the backup
* **silent** if it's true remote_backup will not produce output (except for errors)
* **temporary_path** this is where remote_backup store the backup file before placing it on the final destination
* **tar_bin** this is the path of tar command on your computer