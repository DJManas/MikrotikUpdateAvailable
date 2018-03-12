# Variables for script to be run correctly
:local notificationAddress "<your email here>"
:local logNoUpdates false
:local onlyOnce true

# Check if E-Mail is configured, when not, throw error
# Notice this only checks if some values are filled in, it doesn't check if the
# router really sends the email
if ( [ /tool e-mail get address ] = "0.0.0.0" and [ /tool e-mail get from] = "<>") do {
  # Log to log and then throw error to console and exit
  [ /log error "Please configure /tool e-mail tool for this script to work!!!" ]
  [ :error "Please configure /tool e-mail tool for this script to work!!!" ]
}

# Get new versions, please notice, that new firmware might get noticed after upgrade of the main packages
[ /system package update check-for-updates ]

# Notify user of new firmware version
:global newFirmwareAvailable do={
  [ /tool e-mail send to=$addr subject=( [ /system identity get name ] . ": New firmware available") ]
  [ /log warning "New firmware available" ]
}

# Do the string comparison of Firmware part
if ([ /system routerboard get current-firmware ] != [ /system routerboard get upgrade-firmware ]) do {
  if ($onlyOnce = true) do={
    if ([ /file find name=("Firmware " . [ /system routerboard get upgrade-firmware ] . ".txt")] = "") do {
      [$newFirmwareAvailable addr=$notificationAddress]
      [ /file print file=("Firmware " . [ /system routerboard get upgrade-firmware ])]
      :delay 1
      [ /file set ("Firmware " . [ /system routerboard get upgrade-firmware ]) contents="" ]
    }
  } else {
    [$newFirmwareAvailable addr=$notificationAddress]
  }
} else {
  if ($logNoUpdates = true) do={
    [ /log info "No new firmware" ]
  }
}

# Notify user of new software version
:global newSoftwareAvailable do={
  [ /tool e-mail send to=$addr subject=([ /system identity get name ] . ": New software available") ]
  [ /log warning "New software available" ]
}

# Do the string comparison of packages part
if ([ /system package update get installed-version ] != [ /system package update get latest-version ]) do {
  # If you want it only once, otherwise everytime send email
  if ($onlyOnce = true) do={
    # Check if software version file exists
    if ([ /file find name=("Software " . [ /system package update get latest-version ] . ".txt")] = "") do {
      [ /file print file=("Software " . [ /system package update get latest-version ])]
      :delay 1
      [ /file set ("Software " . [ /system package update get latest-version ]) contents="" ]
      [$newSoftwareAvailable addr=$notificationAddress]
    }
  } else {
    [$newSoftwareAvailable addr=$notificationAddress]
  }
} else {
  if ($logNoUpdates = true) do={
    [ /log info "No new software" ]
  }
}
