# Set variable, it will get filled when correct script is loaded
:global djFunctions
# Global variables should also be defined here to use them, still forgeting that
:global gUpdateLastNewVersion
:global gUpdateEmailNotification
:global gUpdateNotificationOnlyOnce
:global gUpdateDoBackup
:global gUpdateAutoInstall
:global gUpdateAutoTime

# When variable not set, execute correct script
if (!$djFunctions) do={
  # !!!! HardCoded, if you need, please change script name here. !!!!
  :execute script="djFunctions"

  # Double check if loaded
  if (!$djFunctions) do={
    :error "Script djFunctions is not present in the system!"
  }
}

# We need to include the functions from djFunctions function to work
:global prompt
:global logMessage
:global fileExists
:global updateFile
:global renameFile
:global isNewFirmware
:global isNewSoftware
:global shiftDate

:local setup do={
  # Setup procedure
  # 1.    Setup /tool e-mail
  # 2.    Check if configuration file exists on flash
  # 2.1   Setup notification receiver address
  # 2.2   Setup flag only once or every run to send notification
  # 2.3   Setup flag automatic update
  :global prompt
  :global logMessage
  :global fileExists
  :global updateFile
  :global renameFile
  :global gUpdateLastNewVersion
  :global gUpdateEmailNotification
  :global gUpdateNotificationOnlyOnce
  :global gUpdateDoBackup
  :global gUpdateAutoInstall
  :global gUpdateAutoTime

  # 1.    Setup /tool e-mail
  # Read SMTP
  if ([/tool e-mail get address] = "0.0.0.0") do={
    :local smtp [$prompt message="Please enter SMTP server:"]

    if ($smtp != "") do={
      [/tool e-mail set address=$smtp]
    }
    
    # Port, default is 25 but I need to ask if its ok
    if ([:len [/tool e-mail get port]] = 0 || [/tool e-mail get port] = 25) do={
      :local port [$prompt message="Please enter SMTP port:"]

      if ($port != "") do={
        [/tool e-mail set port=$port]
      }
    }

    # TLS
    :local tlsDefaultValues {"yes"; "no"; "tls-only"}
    :local tls [$prompt message="TLS, values yes, no, tls-only" defaultValues=$tlsDefaultValues]
    [/tool e-mail set start-tls=$tls]

    # Email from
    # TODO: Email address format check
    if ([/tool e-mail get from] = "" or [/tool e-mail get from] = "<>") do={
      :local emailFrom [$prompt message="Please enter FROM email address:"]

      if ($emailFrom != "") do={
        [/tool e-mail set from=$emailFrom]
      }
    }

    # Login name
    if ([/tool e-mail get user] = "") do={
      :local emailUser [$prompt message="Please enter email account login name:"]

      if ($emailUser != "") do={
        [/tool e-mail set user=$emailUser]
      }
    }

    # Login password
    # TODO: Add asterisks to prompt function
    if ([/tool e-mail get password] = "") do={
      :local emailPass [$prompt message="Please enter email password:"]

      if ($emailPass != "") do={
        [/tool e-mail set password=$emailPass]
      }
    }

    # Send test EMAIL
    /tool e-mail send to=[/tool e-mail get from] subject=("Email configuration: " . [/system identity get name]) body="Test OK!"
  }

  # 2.    Check if configuration file exists on flash
  if ([$fileExists fileName="flash/updateSettings.rsc"] = true) do={
    # Check if variables defined, if not, load script
    # I want to avoid rewrite of variables, when user changes them
    if ($gUpdateEmailNotification = nil or $gUpdateEmailNotification = "") do={
      # Load file, will add script to /system script under name updateSettings
      /import "flash/updateSettings.rsc"
      # Execute the script to load variables
      :execute script="updateSettings"
      # Delete script
      /system script remove "updateSettings"
    }
  } else={
    # Get email to send notifications
    :set gUpdateEmailNotification [$prompt message="Please enter update notification address to send notifications to:"]
    # Set default bool values
    #:set boolDefaultValues {"true"; "false"}
    # Ask for notification only once per vserion (until reboot)
    # TODO: Implement default booleans
    :set gUpdateNotificationOnlyOnce [$prompt message="Notify once per version (true, false):"]
    # Ask for auto install option
    # TODO: Implement default booleans
    :set gUpdateAutoInstall [$prompt message="Automatic installation (true, false):"]
    # Ask for sending backup when updating
    # TODO: Implement default booleans
    :set gUpdateDoBackup [$prompt message="Send backup before upgrading (true, false):"]
    # If autoupdate set time (its not working when assigning to global variable, so I made local
    # it works, but not gets saved into settings file, tried to do :set, but it sets it, but do not upgrade
    # it in variable in environment, strange behavior
    :local autoTime
    if ($gUpdateAutoInstall = true) do={
      # :set autoTime [$prompt message="Please set hour of upgrade HH:MM:SS, leave empty for no Hour"]
      :set gUpdateAutoTime [$prompt message="Please set hour of upgrade HH:MM:SS, leave empty for no Hour"]
    } else={
      :global gUpdateAutoTime ""
    }

    # Prepare configuration file contents
    :local contents ""
    # RSC will add value to /system script
    :set $contents ("/system script\n")
    :set $contents ($contents . "add name=\"updateSettings\" source=\"\n")
    # 2.1   Setup notification receiver address
    :set $contents ($contents . ":global gUpdateEmailNotification \\\"" . $gUpdateEmailNotification . "\\\"\n")
    # 2.2   Setup flag only once or every run to send notification
    :set $contents ($contents . ":global gUpdateNotificationOnlyOnce $gUpdateNotificationOnlyOnce\n")
    # 2.3   Setup flag automatic update
    :set $contents ($contents . ":global gUpdateAutoInstall $gUpdateAutoInstall\n")
    # 2.4   Ask if I should do backup before upgrade
    :set $contents ($contents . ":global gUpdateDoBackup $gUpdateDoBackup\n")
    # 2.5   Deferred time
    :set $contents ($contents . ":global gUpdateAutoTime \\\"" . [:tostr $autoTime] . "\\\"\n")
    :set $contents ($contents . "\"")

    # Write contents to file, only TXT one
    [$updateFile fileName="flash/updateSettings" contents=$contents]
    # Rename file using FTP obfuscation
    [$renameFile fromFile="/flash/updateSettings.txt" toFile="/flash/updateSettings.rsc"]
  }
}

:global notify do={
  # Process notification
  #----------------------
  # Input parms:
  #   $email    => email send notification to
  #   $body     => Message for body
  #   $fileName => File to be sent
  # Return parms:
  #   None
  #----------------------
  if ($fileName = nil or $fileName = "") do={
    [ /tool e-mail send to=$email subject=( [ /system identity get name ] . ": Updates available") body=$body]
  } else={
    [ /tool e-mail send to=$email subject=( [ /system identity get name ] . ": Updates available") body=$body file=$fileName]
  }
}

:local notifyAboutNewSoftware do={
  # Notify about software, for code reusability
  #----------------------
  # Input parms:
  #   $version        => new software version
  #   $withoutBackup  => without backup, used to send backup only once per new version, when notifying every run
  # Return parms:
  #   None
  #----------------------
  # If do backup is set, send it with notification
  # TODO: Think about sending it when upgrading
  # Set parameter
  #if ($withoutBackup = nil or $withoutBackup = "") do={
  #  :local withoutBackup false
  #}
  :global gUpdateDoBackup
  :global gUpdateEmailNotification
  :global notify

  if ($gUpdateDoBackup = true and $withoutBackup = false) do={
    # Do backup
    # prepare password, will be sent in another email
    :local pwd ([/system resource get cpu-load] . [/system identity get name] . [/system resource get free-memory])
    # Prepare file Name
    :local fileName ([ /system identity get name] . " - ". [ /system package update get installed-version ])
    # Create backup
    /system backup save encryption=aes-sha256 password=$pwd name=$fileName
    # Delay is necesary to finish backup and give email time to load the file
    :delay 2
    # Send email
    [$notify email=$gUpdateEmailNotification body=("Version: " . [:tostr $version] . " available! Please see changelogs!\nhttps://mikrotik.com/download/changelogs") fileName=$fileName]
    # Send password in different email, I should check in another mikrotik if the password works, if there is space
    [$notify email=$gUpdateEmailNotification body=("Version: " . [:tostr $version] . "\nPassword: " . $pwd)]
    # Delay before removing
    :delay 2
    # Remove
    /file remove "$fileName"
  } else= {
    # Just notify
    [$notify email=$gUpdateEmailNotification body=("Version: " . [:tostr $version] . " available! Please see changelogs!\nhttps://mikrotik.com/download/changelogs")]
  }
}

# *******************
# *******************
# *** Main script ***
# *******************
# *******************
# Firstly SETUP, if it is not SETUP, it will not work, this needs to be run in terminal, it will not open it
[$setup]

# Get new versions, please notice, that new firmware might get noticed after upgrade of the main packages
/system package update check-for-updates

# Check if software changed
if ([$isNewSoftware] = true) do={
  # Just get new version for further processing
  :local newSoftwareVersion [/system package update get latest-version]

  # Make record in log
  [$logMessage messageType="info" message=("New software available: " . [:tostr $newSoftwareVersion])]
  # Download change logs for sending in an email
  # TODO: Make default different branch than stable
  # TODO: Parse html
  #/tool fetch url="https://mikrotik.com/download/changelogs" dst-path="changelogs.htm"
  
  # Check if already notified to notify, when flag only once pressed
  if (($gUpdateNotificationOnlyOnce = true) || ($gUpdateNotificationOnlyOnce = "true")) do={
    # Check if last version not
    if (($gUpdateLastNewVersion = nil) || ($gUpdateLastNewVersion = "") || ($gUpdateLastNewVersion != $newSoftwareVersion)) do={
      # Set new version, to not process until next update
      :set $gUpdateLastNewVersion $newSoftwareVersion

      [$notifyAboutNewSoftware version=$newSoftwareVersion withoutBackup=false]
    }
  } else {
    # Notify every run
    # Send backup only once per version
    if (($gUpdateLastNewVersion = nil) || ($gUpdateLastNewVersion = "") || ($gUpdateLastNewVersion != $newSoftwareVersion)) do={
      # Set new version, to not process until next update
      :set $gUpdateLastNewVersion $newSoftwareVersion
      [$notifyAboutNewSoftware version=$newSoftwareVersion withoutBackup=false]
    } else={
      [$notifyAboutNewSoftware version=$newSoftwareVersion withoutBackup=true]
    }
  }
  
  if ($gUpdateAutoInstall = true) do={
    if ($gUpdateAutoTime = "") do={
      /system package update download
      /system reboot
    } else={
      :local actualTime [/system clock get time]
      :local actualDate [/system clock get date]
      :local actualHour [:pick $actualTime 0 2]
      :local actualMinute [:pick $actualTime 3 5]
      :local runHour [:pick $gUpdateAutoTime 0 2]
      :local runMinute [:pick $gUpdateAutoTime 3 5]

      # Decide if I should move date 1 day ahead
      :local runDate
      if ($runHour < $actualHour) do={
        :set $runDate [$shiftDate date=$actualDate days=1]
      } else={
        :set $actualMinute ($actualMinute + 2)
        if ($runHour = $actualHour && $runMinute <= $actualMinute) do={
          :set $runDate [$shiftDate date=$actualDate days=1]
        } else={
          :set $runDate $actualDate
        }
      }

      # Prepare update
      /system package update download

      # Prepare reboot script
      if ([:tobool [/system scheduler find where name="performUpdate"]] = true) do={
        # Script exists, change parameters
        /system scheduler set [find where name="performUpdate"] interval="00:00:00"
        /system scheduler set [find where name="performUpdate"] disabled="no"
        /system scheduler set [find where name="performUpdate"] start-date=$runDate
        /system scheduler set [find where name="performUpdate"] start-time=$gUpdateAutoTime
        /system scheduler set [find where name="performUpdate"] on-event="/reboot"
      } else {
        /system scheduler add name="performUpdate" interval="00:00:00" start-date=$runDate start-time=$gUpdateAutoTime on-event="/system reboot"
      }
    }
  }
}

if ([$isNewFirmware] = true) do={
  /system routerboard upgrade
  /system reboot
}
