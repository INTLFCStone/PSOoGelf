Function New-OOG_GELFSenderTCP {
<#
.SYNOPSIS
    Construct a new GELFSender for TCP Protocol
.DESCRIPTION
    Construct an object to send GELFMessages over TCP. Optionally supports
	encryption over SSL.
.PARAMETER $GelfServer
    An identifier for a GELF server (IP or Domain Name)
.PARAMETER $GelfPort
    Port number on the GelfServer to connect to
.PARAMETER $Encrypt
    Set this flag to use an encrypted SSL tunnel to the server.
.PARAMETER $TimeoutInMilli
    Number of Milliseconds to wait until an attempted connection to the server
    times-out.
.NOTES
    Author: Brendan Bergen
    Date: Oct, 2018
#>
[cmdletbinding()]
    Param (
        [Parameter(Mandatory)] [String] $GelfServer,
        [Parameter(Mandatory)] [Int]    $GelfPort,
        [Parameter(         )] [Switch] $Encrypt,
        [Parameter(         )] [Int]    $TimeoutInMilli=5000
    )
    Process {
        return [GELFSenderTCP]::new(
            $GelfServer,
            $GelfPort,
            $Encrypt,
            $TimeoutInMilli
        )
    }
}
