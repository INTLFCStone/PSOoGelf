Class GELFSender {
<#
.SYNOPSIS
    Object to send GELFMessages to a server/port. USED AS AN INTERFACE!
.NOTES
    Author: Brendan Bergen
    Date: Oct, 2018
#>
    [String] $GelfServer
    [Int]    $GelfPort

    <#
    .SYNOPSIS
        Default constructor. Does nothing. Called by Classes that inherit.
    #>
    GELFSender () {
    }

    <#
    .SYNOPSIS
        The sole method required by all GELFSenders. Should be overridden by
        Classes that use this "interface"
    #>
    [Void] SendGELFMessage ( [GELFMessage] $msg ) {
        throw "Unsupported Exception! Treat GELFSender as an interface!"
    }
}


Class GELFSenderTCP : GELFSender {
<#
.SYNOPSIS
    Object to send GELFMessages to a server/port over TCP.
.NOTES
    This Class would not be possible without other contributions to open source!

    PSGELF:
        Some parts of this Class definition were heavily influenced by the PSGELF
        module. Go check them out for an alternative to this code:
        https://github.com/jeremymcgee73/PSGELF/blob/master/PSGELF
    
    THANK YOU!

    Author: Brendan Bergen
    Date: Oct, 2018
#>
    [Bool] $Encrypt
    [Int]  $TimeoutInMilli

    <#
    .SYNOPSIS
        Construct an instance of GELFSenderTCP with all required parameters.
    #>
    GELFSenderTCP ( [String] $gs, [Int] $gp, [bool] $e, [int] $t ) {
        $this.GelfServer     = $gs
        $this.GelfPort       = $gp
        $this.Encrypt        = $e
        $this.TimeoutInMilli = $t
    }

    <#
    .SYNOPSIS
        Send a GELFMessage using this
    .DESCRIPTION
        Send a GELFMessage using the current state of this instance (TCP).
    .PARAMETER $msg
        The GELFMessage object to send.
    .NOTES
        Checkout the PSGELF module, which contains my inspiration for this method!
        Thank you!
        https://github.com/jeremymcgee73/PSGELF/blob/master/PSGELF/Public/Send-PSGelfTCPFromObject.ps1
    #>
    [Void] SendGELFMessage ( [GELFMessage] $msg ) {
        $gmsg = $msg.ConvertToGELFByteArray()

        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        try {
            $connection = $tcpClient.ConnectAsync($this.GelfServer,$this.GelfPort)
            if(!($connection.Wait($this.TimeoutInMilli))) {
                throw "The connection timed out!"
            }

            $tcpStream = $tcpClient.GetStream()
            if ($this.Encrypt) {
                $sslStream = New-Object System.Net.Security.SslStream $tcpStream, $false, { return $true }, $null
                try {
                    $sslStream.AuthenticateAsClient($this.GelfServer)
                    Write-Verbose "Sending $($gmsg.length) bytes to $($this.GelfServer)"
                    $sslStream.Write($gmsg, 0, $gmsg.Length)
                }
                catch { throw }
                finally {
                    $sslStream.Close()
                }
            }
            else {
                try {
                    Write-Verbose "Sending $($gmsg.length) bytes to $($this.GelfServer)"
                    $tcpStream.Write($gmsg, 0, $gmsg.Length)
                }
                catch { throw }
                finally {
                    $tcpStream.Close()
                }
            }
        }
        catch {
            Write-Error "Sending GELF message over TCP failed!" -ErrorAction "Continue"
            throw
        }
        finally {
            $tcpClient.Close()
        }
    }
}


Class GELFSenderUDP : GELFSender {
<#
.SYNOPSIS
    Object to send GELFMessages to a server/port over UDP.
.NOTES
    This Class would not be possible without other contributions to open source!

    PSGELF:
        Some parts of this Class definition were heavily influenced by the PSGELF
        module. Go check them out for an alternative to this code:
        https://github.com/jeremymcgee73/PSGELF/blob/master/PSGELF
    
    THANK YOU!

    Author: Brendan Bergen
    Date: Oct, 2018
#>

    <#
    .SYNOPSIS
        Construct an instance of GELFSenderUDP with all required parameters.
    #>
    GELFSenderUDP ( [String] $gs, [int] $gp ) {
        $this.GelfServer = $gs
        $this.GelfPort   = $gp
    }

    <#
    .SYNOPSIS
        Send a GELFMessage using this
    .DESCRIPTION
        Send a GELFMessage using the current state of this instance (TCP).
    .PARAMETER $msg
        The GELFMessage object to send.
    .NOTES
        Checkout the PSGELF module, which contains my inspiration for this method!
        Thank you!
        https://github.com/jeremymcgee73/PSGELF/blob/master/PSGELF/Public/Send-PSGelfUDPFromObject.ps1
    #>
    [Void] SendGELFMessage ( [GELFMessage] $msg ) {
        $chunks = $msg.ConvertToChunkedByteList()
        $udpClient = New-Object System.Net.Sockets.UdpClient
        try {
            $udpClient.Connect( $this.GelfServer, $this.GelfPort )
        }
        catch {
            Write-Error "Unable to establish connection to $($this.GelfServer):$($this.GelfPort)" -ErrorAction "Continue"
            throw
        }

        try {
            foreach ( $c in $chunks ) {
                Write-Verbose "Sending $($c.length) bytes to $($this.GelfServer)"
                try {
                    $send = $udpClient.Send( $c, $c.Length )
                }
                catch {
                    Write-Error "Unable to send via UDP client!" -ErrorAction "Continue"
                    throw
                }
            }
        }
        catch {
            throw
        }
        finally {
            $udpClient.Close()
        }
    }
}
