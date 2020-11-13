# mikrotikUpdateAvailable - Rework #

This is the new version of the script, which is a little more advanced. But I am letting the original script to be available as well. If you are interested in the previous version, scroll down.

For this script to work you need only 2 things.

1. Create new script named exactly djFunctions in */system scripts*, sure you can rename it, but then you need to rename it in the other script. Then copy contents of file **djFunctions.rsc** into it.

2. Create new script in */system scripts*, name is on you and insert contents of file **MikrotikUpdateAvailable-rework.rsc** into it.

Then open please **New terminal** and insert: **/system script run &lt;name of the script from point 2&gt;**

You you will be prompted for:

- Setting up the values in */tool e-mail*, if not already set. When you set it up, test email will be sent to FROM email.
- Set up the values for correct script run:
  - **Please enter update notification address to send notifications to**: To this address you will be notified about new version,
  - **Notify once per version (true, false)**: If notification, about new version, should be sent once or every time the script is run,
  - **Automatic installation (true, false)**: If update should be installed on script run automatically,
  - **Send backup before upgrading (true, false)**: If actual backup should be sent in the notification,
  - **Please set hour of upgrade HH:MM:SS, leave empty for no Hour**: If auto update is enabled, you will be asked to enter time. So e.g. script will run in 2 a.m., but you can say here, that it should automatically install it at 8 a.m.
- It creates file *flash/updateSettings.rsc*, which is loaded on restart,
- It checks if new updates are available,
- According to settings:
  - Sends emails with actual backup (2 emails, one with backup, second one with generated password),
  - Upgrades software,
  - Restarts or waits for restart,
  - Upgrades firmware (it is ment to plan this on restart)

**Please notice**, that after initial setup it is ok, that this script is run using scheduler.

## More technical view ##

### Variables ###

These variables will be visible in */system script environment* and can be changed there:

- **gUpdateEmailNotification** - Email, where notifications will be sent,
- **gUpdateNotificationOnlyOnce** - (**true**/**false**) If true, notifications will be only once per version, else everytime the script is run and new version is available,
- **gUpdateAutoInstall** - (**true**/**false**) If true, the system will be automatically upgraded, if **gUpdateAutoTime** is set, it will be defered to that time, otherwise it needs to be upgraded manually,
- **gUpdateDoBackup** - (**true**/**false**) Whether to do backup and send it in notification email. If set to true 2 emails will be sent, once notification with backup file, second with password generated for this backup.
- **gUpdateAutoTime** - (HH:MM:SS) If auto update is set, this variable tels when to upgrade. It plans script for reboot for that time. If you run this script at 9 pm and have set this variable to 01:00:00 (should exactly be this pattern), new script will be created and planned for 1 a.m. with /system restart command, the download is done by this script.

**Please notice**:

- true and false should be written exactly in lowercase, also the HH:MM:SS should be held, because I don't do any check so the script will fail if entered incorrectly.
- Each update contains software and firmware, so I recommend 2 schedules of this script:
  - One instance on daily basis, it checks for new versions and informs user, etc.
  - Second instance should be planned on **startup**, will be launched when router reboots, checks if there is new firmware and does the upgrade straight away.

## TODO ##

- Add string functions
  - Email address format check,
  - Splitstring,
- Add asterisks when asking for password,
- Implement default values for setup prompt script,
- Implement bool values (not only true/false),
- Think about sending backup right before upgrade, not in notification,
- Think if it is necessary to send 2 emails, one with backup, second with password,
- Add support for different channels, when sending notification email with URL,
- I am lazy, so I will try to parse the mikrotik changed page to insert changenotes into email body.

---

## MikrotikUpdateAvailable - Old Version ##

---

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
