# MikrotikUpdateAvailable #

This script simply checks for firmware/software update and notifies user on specified email address.

You have to configure */tool e-mail* to make this to work. When it is not set, the script raises error into the log and if run in console, it will put it into console.

You can set few variables at the begining of the script:

## :local notificationAddress "**\<your email here\>**" ##

Replace text in quotes with your valid email address.

## :local logNoUpdates false ##

- true - When no updates has been found, write it to */log*
- false - When no updates has been found, do not write it to */log*

## :local onlyOnce true ##

- true - Will notify you only once per new version, it uses */file* memory filename
- false - Will notify you everytime the script is run

## :local update true ##

This option automatically upgrades firmware, when new firmware is available. But when new software is available, it waits until you manually launch */system package update download*. This will tell the script that you want to upgrade router and it will upgrade it on next launch, whether set.

- true - Automatically update on next script runtime, when update available
- false - Do not automatically update on next runtime, when update available
