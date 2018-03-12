# MikrotikUpdateAvailable #

This script simply checks for firmware/software update and notifies user on
specified email address.

You have to configure /tool e-mail to make this to work and change <Your email>
for your email. When it is not set, the script raises error into the log.

You can set few variables at the begining of the script:

*:local notificationAddress "<your email here>"* Replace text in quotes with your email address

*:local logNoUpdates false*
  - true - When no updates has been found, write it to /log
  - false - When no updates has been found, do not write it to /log

*:local onlyOnce true*
  - true - Will notify you only once per new version, it uses /file memory filename
  - false - Will notify you everytime the script is run
