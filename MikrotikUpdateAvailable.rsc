# Get new version
[ /system package update check-for-updates ]

# Firmware part
:local actualFirmware [ /system routerboard get current-firmware ]
:local newFirmware [ /system routerboard get upgrade-firmware ]
:local notificationAddress "<your email here>"

# System software
:local actualSoftware [ /system package update get installed-version ]
:local newSoftware [ /system package update get latest-version ]

# Define functions
:global compareVersions do={
  # Variables
  :local oldMajor -1
  :local oldMinor -1
  :local oldBuild -1

  # Parse old
  :local major -1
  :local minor -1
  :local build -1
  :local start 0

  :for i from=0 to=([:len $oldVersion] - 1) do={
    :if ( [:pick $oldVersion $i] = "." ) do={
      :if (major = -1) do={
        :set major [:tonum [:pick $oldVersion $start $i]]
        :set start ( $i + 1 )
      } else={
        if (minor = -1) do={
          :set minor [:tonum [:pick $oldVersion $start $i]]
          :set start ( $i + 1 )
        }
      }
    }
  }

  # Last part of the string
  if (minor = -1) do={
    :set minor [:tonum [:pick $oldVersion $start [:len $oldVersion]]]
  } else={
    :set build [:tonum [:pick $oldVersion $start [:len $oldVersion]]]
  }

  # Set old
  :set oldMajor $major
  :set oldMinor $minor
  :set oldBuild $build

  # Clear
  :set major -1
  :set minor -1
  :set build -1
  :set start 0

  # Parse new
  :for i from=0 to=([:len $newVersion] - 1) do={
    :if ( [:pick $newVersion $i] = "." ) do={
      :if (major = -1) do={
        :set major [:tonum [:pick $newVersion $start $i]]
        :set start ( $i + 1 )
      } else={
        if (minor = -1) do={
          :set minor [:tonum [:pick $newVersion $start $i]]
          :set start ( $i + 1 )
        }
      }
    }
  }

  # Last part of the string
  if (minor = -1) do={
    :set minor [:tonum [:pick $newVersion $start [:len $newVersion]]]
  } else={
    :set build [:tonum [:pick $newVersion $start [:len $newVersion]]]
  }

  # Do the check
  :if ($oldMajor = $major and $oldMinor = $minor and $oldBuild = $build) do={
    :return false
  } else={
    :return true
  }
}

# Compare firmware
:if ([$compareVersions oldVersion=$actualFirmware newVersion=$newFirmware] = true) do={
  [ /tool e-mail send to=$notificationAddress subject=( [ /system identity get name ] . ": New firmware available") ]
  [ /log warning "New firmware available" ]
} else={
  [ /log info "No new firmware" ]
}

# Compare software
:if ([$compareVersions oldVersion=$actualSoftware newVersion=$newSoftware] = true) do={
  [ /tool e-mail send to=$notificationAddress subject=( [ /system identity get name ] . ": New software available") ]
  [ /log warning "New software available" ]
} else={
  [ /log info "No new software" ]
}