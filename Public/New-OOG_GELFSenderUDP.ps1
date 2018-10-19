Function New-OOG_GELFSenderUDP {
<#
.SYNOPSIS
    Construct a new GELFSender for UDP Protocol
.DESCRIPTION
    Construct an object to send GELFMessages over UDP
.PARAMETER $GelfServer
    An identifier for a GELF server (IP or Domain Name)
.PARAMETER $GelfPort
    Port number on the GelfServer to connect to
.NOTES
    Author: Brendan Bergen
    Date: Oct, 2018
#>
[cmdletbinding()]
    Param (
        [Parameter(Mandatory)] [String] $GelfServer,
        [Parameter(Mandatory)] [Int]    $GelfPort,
        [Parameter(         )] [Switch] $Compress
    )
    Process {
        return [GELFSenderUDP]::new(
            $GelfServer,
            $GelfPort,
            $Compress.IsPresent
        )
    }
}
