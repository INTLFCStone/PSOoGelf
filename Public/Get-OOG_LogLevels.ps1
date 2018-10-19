Function Get-OOG_LogLevels {
<#
.SYNOPSIS
    Return name bindings for all GELFMessage log levels.
.DESCRIPTION
    Provide a lookup hash for log levels by common names.
.NOTES
    Author: Brendan Bergen
    Date: Oct, 2018
#>
[cmdletbinding()]
    Param ()
    Process {
        # Note: PowerShell supports case-insensitive keys... Debug = debug = DeBuG
        return @{
            'Debug'       = $([GELFMessage]::LV_DEBUG)

            'Information' = $([GELFMessage]::LV_INFORMATION)
            'Info'        = $([GELFMessage]::LV_INFORMATION)

            'Notice'      = $([GELFMessage]::LV_NOTICE)

            'Warning'     = $([GELFMessage]::LV_WARNING)
            'Warn'        = $([GELFMessage]::LV_WARNING)

            'Error'       = $([GELFMessage]::LV_ERROR)
            'Err'         = $([GELFMessage]::LV_ERROR)

            'Critical'    = $([GELFMessage]::LV_CRITICAL)
            'Crit'        = $([GELFMessage]::LV_CRITICAL)

            'Alert'       = $([GELFMessage]::LV_ALERT)

            'Emergency'   = $([GELFMessage]::LV_EMERGENCY)
        }
    }
}
