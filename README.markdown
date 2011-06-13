remote_backup
=============

remote_backup is a simple tool to make backup of a directory and store it locally or remotely (using FTP). Backups are compressed creating a tar.gz file.

Before using remote_backup you need to edit his config.yml file where there are all settings.

Settings explanation
--------------------
* **dir_to_backup** the directory that you want to backup
* **fixed_name** you can set a filename for the backup, it it's empty remote_backup will generate a dynamic filename using date and time (for example 201105121627.tar.gz that means "backupped on 2011-05-12 at 16:27")
* **remote_backup** if it's true means that you want to put your backup file on a remote FTP server
* **remote_host** this is the host of your FTP server (if you are doing a local backup you don't need to fill it)
* **remote_username** this is the username of the user of your FTP server (if you are doing a local backup you don't need to fill it)
* **remote_password** this is the password of the user of your FTP server (if you are doing a local backup you don't need to fill it)
* **destination_path** this is the path where you want to store your backup file. If you are doing a remote backup this path will be used to place backup file in your FTP
* **silent** if it's true remote_backup will not produce output (except for errors)
* **temporary_path** this is where remote_backup store the backup file before placing it on the final destination
* **tar_bin** this is the path of tar command on your computer