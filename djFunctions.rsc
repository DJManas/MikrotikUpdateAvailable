# Variable telling, that this script is loaded or not
:global djFunctions true

:global decToHex do={
  # Convert decimal character to hexadecimal
  #----------------------
  # Input:
  #   $number - Decimal Number
  # Return:
  #   Hexadecmial Number
  #----------------------
  # When number is lower than 10, return its value
  if ($number <= 10) do={
    :return $number
  }
  
  # Otherwise count
  :local tempNumber
  :local result
  :set tempNumber $number

  :while ($tempNumber > 0) do={
    # Store remainder
    :local remainder
    :set remainder ($tempNumber % 16)
    # Set new number
    :set tempNumber [:tonum ($tempNumber / 16)]

    # Convert remainder to number
    if ($remainder >= 10) do={
      if ($remainder = 10) do={
        :set result ("A" . $result)
      } else={
        if ($remainder = 11) do={
          :set result ("B" . $result)
        } else={
          if ($remainder = 12) do={
            :set result ("C" . $result)
          } else={
            if ($remainder = 13) do={
              :set result ("D" . $result)
            } else={
              if ($remainder = 14) do={
                :set result ("E" . $result)
              } else={
                :set result ("F" . $result)
              }
            }
          }
        }
      }
    } else={
      :set result ([:tostr $remainder] . $result)
    }
  }

  :return $result
}

:global fileExists do={
  # Check if file exists
  #----------------------
  # Input:
  #   $fileName - fileName of file to check
  # Return:
  #   Boolean whether exist or not
  #----------------------
  # Return if file exists
  :return [:tobool ([ /file find name=$fileName] != "")]
}

:global getDecChar do={
  # Convert hexadecimal character to char
  # Could have used array of values and substitute, but using \hex interpetation
  # which is supported by Mikrotik, although its a little fuzzy.
  #----------------------
  # Input:
  #   $charNumber - Hexadecimal number of character
  # Return:
  #   Character
  #----------------------
  # We will use decToHex function
  :global decToHex
  # Init result variable
  :local result
  # Get hexadecimal number
  :local evalStatement "\"\\$[$decToHex number=$charNumber]\""
  # Create e.g. string "\61", which represents letter a, but return it as a function
  :local function
  :set function [:parse ":tostr $evalStatement"]
  # Substitute function to letter
  :set result [$function]
  # Return letter
  :return $result
}

:global changeService do={
  # Changes service parameters
  #----------------------
  # Input:
  #   $s          - service name
  #   $sParameter - service parameter
  #   $sValue     - parameter value
  #   $sAddrOrig  - bool, if true put $value
  # Return:
  #   Bool, whether changed or not
  #----------------------
  :global stringReplace

  if ($sAddrOrig = nil) do={
    :set $sAddrOrig false
  }


  do {
    # According to the parameter do, only special handling at IP address
    if ($sParameter = "address") do={
      if ($sAddrOrig = false) do={
        # Whether to change value
        :local chValue false
        # Get addresses of the current ftp
        :local ftpAddress [:tostr [/ip service get [find where name=$s] address]]

        # If there is some address, add localhost if not already added
        if ([:len $ftpAddress] > 0) do={
          # Check if value is already in address list
          if (![:tobool [:find [:tostr $ftpAddress] $sValue -1]]) do={
            # Add address
            :set $ftpAddress ($ftpAddress . "," . $sValue)
            # Set if I can change
            :set $chValue true
          }
        } else={
          # We will add value only if service is disabled
          if ([/ip service get [find where name=$s] disabled] = true) do={ 
            # Set value
            :set $ftpAddress $sValue
            # Change flag
            :set $chValue true
          }
        }
              
        # Only when should change
        if ($chValue = true) do={
          # If needed, replace ; with , to save address
          :set $ftpAddress [$stringReplace str=$ftpAddress what=";" with=","]

          # Set new value
          /ip service set [find where name=$s] address=$ftpAddress
        }
      } else={
        :set $sValue [$stringReplace str=$sValue what=";" with=","]
        :put $sValue
        /ip service set [find where name=$s] address=$sValue
      }
    } else={
      :local runScript
      if ($sParameter = "disabled") do={
        :local dsbled
        if ($sValue = true) do={
          :set $dsbled "yes"
        } else={
          :set $dsbled "no"
        }

        [:parse ("/ip service set [find where name=\"$s\"] $sParameter=\"$dsbled\"")]
      } else={
        [:parse "/ip service set [find where name=\"$s\"] $sParameter=\"$sValue\""]
      }
    }
  } on-error {
    :return false
  }

  :return true
}

:global isNewFirmware do={
  # Is new version available?
  #----------------------
  # Input:
  #   N/A
  # Return:
  #   Boolean
  #----------------------
  :return [:tobool ([ /system routerboard get current-firmware ] != [ /system routerboard get upgrade-firmware ])]
}

:global isNewSoftware do={
  # Is new version available?
  #----------------------
  # Input:
  #   N/A
  # Return:
  #   Boolean
  #----------------------
  :return (:tobool ([ /system package update get installed-version ] != [ /system package update get latest-version ]))
}

:global logMessage do={
  # Log into log, maybe raise error
  #----------------------
  # Input:
  #   $message      - Message
  #   $messageType  - Message type info, warning, error, debug, default error
  #----------------------
  # TODO: Handle Debug and Warning messages properly
  if (($messageType = "") || ($messageType = nil)) do={
    :set $messageType "error"
  }

  if ($messageType = "error") do={
    [:parse "/log $messageType \"$message\""]
    :error $message
  } else={
    if ($messageType = "debug") do={
      [:parse ("/log $messageType \"$message\"")]
      :put $message
    } else={
      [:parse ("/log $messageType \"$message\"")]
    }
  }
}

:global prompt do={
  :global getDecChar
  :local result
  :local continueReading true

  # Display message for the user, if defined
  if ($message != nil && $message != "") do={
    :put $message
  }
  :put ""

  do {
    :local actualKey
    :local tmpString
    :set actualKey [ /terminal inkey ]

    # Enter key pressed, exit
    if ($actualKey = 13) do={
      # Check if default value is set
      if ([:len $defaultValues] > 0) do={
        :local canExit false
        :foreach value in=$defaultValues do={
          if ($result = $value) do={
            set canExit true
          }
        }
        :set continueReading (:tobool !$canExit)
      } else={
        :set continueReading false
      }
    } else={
      if ($actualKey = 8) do={
        :set tmpString ""

        for i from=0 to=([:len $result] - 2) do={
          :set tmpString ($tmpString . [:pick $result $i])
        }
        :set result $tmpString
      } else={
        :set result ($result . [$getDecChar charNumber=$actualKey])
      }
    }
    [ /terminal cuu ]
    [ /terminal el ]
    :put $result
  } while=($continueReading = true)

  # TODO: Handle bools properly
  :return $result
}

:global renameFile do={
  # Rename file
  #----------------------
  # Input:
  #   $fromFile - File name
  #   $toFile   - contents
  # Return:
  #   Boolean if moved
  #----------------------
  :global logMessage
  :global changeService
  # Need to create user with password for fetch command
  :local passwd ("\"" . [/system resource get cpu-load] . [/system identity get name] . [/system resource get free-memory] . "\"")

  # Clean, if user exists
  if ([:len [/user find name=("renameFile")]] > 0) do={
    /user remove "renameFile"
  }

  # Clean, if group exists
  if ([:len [/user group find name=("renameFile")]] > 0) do={
    /user group remove "renameFile"
  }
  
  # Create group
  /user group add name=renameFile policy=ftp,read,write comment="File Rename group"
  # Create user
  /user add name=renameFile group=renameFile address=127.0.0.1/32 comment="Rename file" password=[:tostr $passwd] disabled=no

  # Copy
  do {
    # To return back previous version of address
    :local previousAddress [:tostr [/ip service get [find where name="ftp"] address]]
    :local ftpDisabled [/ip service get [find where name="ftp"] disabled]

    # If FTP is disabled, enable it for localhost
    if ($ftpDisabled = true) do={
      :put "Disabled"
      if ([$changeService s="ftp" sParameter="address" sValue="127.0.0.1"] = true) do={
        [$changeService s="ftp" sParameter="disabled" sValue=false]
        :put "Enabling"
      }
    }

    # Rename using fetch command using generated user
    /tool fetch address=127.0.0.1 mode=ftp user=renameFile password=[:tostr $passwd] src-path=$fromFile dst-path=$toFile
    :local tmpString
    for i from=1 to=([:len $fromFile]-1) do={
      :set $tmpString ($tmpString . [:pick $fromFile $i])
    }

    # Remove source file
    /file remove $tmpString
    # Remove user
    /user remove "renameFile"
    # Remove group
    /user group remove "renameFile"

    # If ftp was disabled, disable it again
    if ($ftpDisabled = true) do={
      [$changeService s="ftp" sParameter="address" sValue=$previousAddress sAddrOrig=true]
      [$changeService s="ftp" sParameter="disabled" sValue=true]
    }
  } on-error {
    [$logMessage message="Error in renaming file"]
  }
}

:global shiftDate do={
  ################################################################### func_shiftDate - add days to date
  #  Input: date, days
  #    date - "jan/1/2017"
  #    days - number
  # correct only for years >1918
  ################################################################### uncomment for testing
  #:local date "jan/01/2100"
  #:local days 2560
  ########################################
  :local mdays  {31;28;31;30;31;30;31;31;30;31;30;31}
  :local months {"jan"=1;"feb"=2;"mar"=3;"apr"=4;"may"=5;"jun"=6;"jul"=7;"aug"=8;"sep"=9;"oct"=10;"nov"=11;"dec"=12}
  :local monthr  {"jan";"feb";"mar";"apr";"may";"jun";"jul";"aug";"sep";"oct";"nov";"dec"}

  :local dd [:tonum [:pick $date 4 6]]
  :local yy [:tonum [:pick $date 7 11]]
  :local month [:pick $date 0 3]

  :local mm (:$months->$month)
  :set dd ($dd+$days)

  :local dm [:pick $mdays ($mm-1)]
  :if ($mm=2 && (($yy&3=0 && ($yy/100*100 != $yy)) || $yy/400*400=$yy) ) do={ :set dm 29 }

  :while ($dd>$dm) do={
    :set dd ($dd-$dm)
    :set mm ($mm+1)
    :if ($mm>12) do={
      :set mm 1
      :set yy ($yy+1)
    }
    :set dm [:pick $mdays ($mm-1)]
    :if ($mm=2 &&  (($yy&3=0 && ($yy/100*100 != $yy)) || $yy/400*400=$yy) ) do={ :set dm 29 }
  };
  :local res "$[:pick $monthr ($mm-1)]/"
  :if ($dd<10) do={ :set res ($res."0") }
  :set $res "$res$dd/$yy"
  :return $res
}

:global stringReplace do={
  # Replace substring in string with
  #----------------------
  # Input:
  #   $str  - String to perform replacement
  #   $what = What to replace
  #   $with - String to replace using
  # Return:
  #   New string
  #----------------------
  # TODO: Handle empty input
  :local result
  :local length [:len $what]
  for i from=0 to=([:len $str]-$length) step=1 do={
    :local ch [:pick $str $i ($i+$length)]

    if ($ch = $what) do={
      
      if ([:len $result] = 0) do={
        :set $result $with
      } else={
        :set $result ($result . $with)
      }
    } else={
      if ([:len $result] = 0) do={
        :set $result [:pick $str $i]
      } else={
        :set $result ($result . [:pick $str $i])
      }
    }
  }
  :return $result
}

:global updateFile do={
  # Update file
  #----------------------
  # Input:
  #   $fileName - File name
  #   $contents - contents
  # Return:
  #   Boolean if created
  #----------------------
  # If file doesn't exists, create it
  :global fileExists
  :global logMessage

  if ([$fileExists fileName=$fileName] = false) do={
    :do {
      [:parse "/file print file=\"$fileName\"" ]
    } on-error={
      [$logMessage message=("Error in creating file: " . $fileName)]
    }
    # Wait second just to make sure file is created
    :delay 2
  }
  
  # File will have TXT extension, so I append it to $fileName
  :set $fileName ($fileName . ".txt")

  # Fill contents
  :do {
    #[:parse "/file set \"$fileName\" contents=\"$contents" ]
    /file set $fileName contents=$contents
  } on-error={
    [$logMessage message=("Error in updating file: " . $fileName)]
  }
}