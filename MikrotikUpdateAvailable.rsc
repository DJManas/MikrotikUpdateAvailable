# *** Script setup variables ***
# Email where the notifications will be sent
:local notificationAddress "<your email here>"

# When no updates found, this switches if the script will write it into log
:local logNoUpdates false

# Notify only once per new version of software/firmware
:local onlyOnce true

# When user downloaded software using /system packages download, proceed with reboot
# When this is on and the user has upgraded the reouter, /system routerboard upgrade and reboot
:local update true
# *** Script setup variables ***

# *** Functions ***
# Wrong parameter
:global wrongParm do={
  # Input parms:
  #   func => function
  #   parm => parameter value
  # Return parms:
  #   None
  [ /log error ($func . " function, unknown '" . $parm . "' parameter") ]
  :error ($func ." function, unknown '" . $parm ."' parameter")
}

# Check if file exists
:global fileExists do={
  # Input parms:
  #   about =>
  #     software -> packages
  #     firmware -> firmware
  # Return parms:
  #   true -> file exists
  #   false -> file doesn't exist
  # Check if parameter has correct value
  :global wrongParm;
  :local fileName ""
  if ($about = "software") do={
    :set fileName ($about . "-" . [ /system package update get latest-version ] . ".txt")
  } else={
    if ($about = "firmware") do={
      :set fileName ($about . "-" . [ /system routerboard get upgrade-firmware ] . ".txt")
    } else={
      [$wrongParm func="fileExists" parm="about"]
    }
  }

  # Return if file exists
  :return [:tobool ([ /file find name=$fileName] != "")]
}

# Create file which means that firmware has already been checked
# file is created in memory so after reboot it is deleted
:global createFile do={
  # Input parms:
  # about =>
  #   software -> packages
  #   firmware -> firmware
  # Check if parameter has correct value and create filename
  :global wrongParm
  :local fileName ""
  if ($about = "software") do={
    :set fileName ($about . "-" . [ /system package update get latest-version ])
  } else={
    if ($about = "firmware") do={
      :set fileName ($about . "-" . [ /system routerboard get upgrade-firmware ])
    } else={
      [$wrongParm func="createFile" parm="about"]
    }
  }

  # Create new file with contents of /file print screen
  [ /file print file=$fileName ]
  # Wait second just to make sure file is created
  :delay 1
  # Clear its contents
  :do {
    [ /file set $fileName contents="" ]
  } on-error={ :put "Error" }
}

# Check if email is configured /tool e-mail
:global isEmailConfigured do={
  # Input parms:
  #   None
  # Output:
  #   true -> is configured,
  #   false -> is not configured
  :return (![:tobool ([ /tool e-mail get address ] = "0.0.0.0" and [ /tool e-mail get from] = "<>")])
}

# Compare versions
:global isNewVersion do={
  # Input parms:
  # versionType =>
  #   software -> packages
  #   firmware -> firmware
  # Return parms:
  #   true -> yes new version is available
  #   false -> no new version is NOT available
  :global wrongParm;
  if ($versionType = "software") do={
    :return (:tobool ([ /system package update get installed-version ] != [ /system package update get latest-version ]))
  } else={
    if ($versionType = "firmware") do {
      :return [:tobool ([ /system routerboard get current-firmware ] != [ /system routerboard get upgrade-firmware ])]
    } else={
      [$wrongParm func="isNewVersion" parm="versionType"]
    }
  }
}

# Process notification
:global notify do={
  # Input parms:
  #   addr    => email send notification to
  #   about   => what is new: software or firmware
  #   once    => notify only once
  #   update  => when upgrade file is downloaded manually by user, reboot to upgrade
  # Return parms:
  #   None
  # Check if about has correct value
  :global wrongParm
  :global notifyAbout
  :global createFile
  :global fileExists
  if ($about = "software") do={
  } else={
    if ($about = "firmware") do={
    } else {
      [$wrongParm func="notify" parm="about"]
    }
  }

  # Process notification
  if ($once) do={
    # When not exist, notify
    if (![$fileExists about=$about]) do={
      [$notifyAbout addr=$addr about=$about]
      [$createFile about=$about]
    }
  } else={
    [$notifyAbout addr=$addr about=$about]
  }
}

# Sends notification email and adds line into log
:global notifyAbout do={
  # Input parms:
  #   addr  => email send notification to
  #   about => what is new: software or firmware
  #   once  => notify only once
  # Return parms:
  #   None
  [ /tool e-mail send to=$addr subject=( [ /system identity get name ] . ": New " . $about . " available") ]
  [ /log warning ("New " . $about . " available") ]
}

# Checks if router package upgrade file exists
:global upgradeFileExists do={
  # Input parms
  #   None
  # Return parms:
  #   true  => file exists
  #   false => file doesn't exist
  # Concatenate file
  # routeros-<architecture name>-<new version>.npk
  :local fileName ("routeros-" . [ /system resource get architecture-name ] . "-" . [ /system package update get latest-version ] . ".npk")

  # Return whether the file exists
  :return [:tobool ([ /file find name=$fileName] != "")]
}

# Upgrade
:global upgradeRouter do={
  # Input parms:
  #   about =>
  #     software  => packages
  #     firmware  => firmware
  # Return parms:
  #   None
  # Check if about has correct value
  :global upgradeFileExists;
  :global wrongParm;
  if ($about = "software") do={
    if ([$upgradeFileExists]) do={
      [ /system reboot ]
    }
  } else={
    if ($about = "firmware") do={
      # Upgrade
      [ /system routerboard upgrade ]

      # Reboot
      [ /system reboot ]
    } else {
      [$wrongParm func="notify" parm="about"]
    }
  }
}

# *** Main script ***
# Check if E-Mail is configured, when not, throw error
# Notice this only checks if some values are filled in, it doesn't check if the
# router really sends the email
if (![$isEmailConfigured]) do={
  # Log to log and then throw error to console and exit
  [ /log error "Please configure /tool e-mail tool for this script to work!!!" ]
  [ :error "Please configure /tool e-mail tool for this script to work!!!" ]
}

# Get new versions, please notice, that new firmware might get noticed after upgrade of the main packages
[ /system package update check-for-updates ]

# Software check
if ([$isNewVersion versionType="software"]) do={
  [$notify addr=$notificationAddress about="software" once=$onlyOnce update=$update]

  if ($update) do={
    [$upgradeRouter about="software"]
  }
} else={
  if ($logNoUpdates) do={
    [ /log info "No new software!" ]
  }

  # Firmware check - It is logical only to upgrade firmware, when no software is found,
  # new software could bring new firmware
  if ([$isNewVersion versionType="firmware"]) do={
    [$notify addr=$notificationAddress about="firmware" once=$onlyOnce update=$update]

    if ($update) do={
      [$upgradeRouter about="firmware"]
    }
  } else={
    if ($logNoUpdates) do={
      [ /log info "No new firmware!" ]
    }
  }

}
