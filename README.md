#Introduction
Create and Send GELF formatted messages.

The Objects herein are a sister-module to PSGELF. Classes are defined for
managing GELF messages and sending these messages to a Graylog server, which
might be useful for more advanced/customized modules to be created (i.e factory
methods/orchestrators). The objects completely abstract away formatting messages
for creating and sending GELF, all in native PowerShell.

#Example 1 - Leverage the Functions (Object factories)
```Powershell
Import-Module PSOoGelf

# Construct a Sender to ship the GELF messages. TCP objects are also available!
$udpSender = New-OOG_GELFSenderUDP `
                 -GelfServer "my.server.com" `
                 -GelfPort "12345"

# construct a simple message using defaults
$msg1 = New-OOG_GELFMessage -short_message "hello world"

# construct a more complex message
$msg2 = New-OOG_GELFMessage `
            -short_message "hello world" `
            -full_message "This is my longer message" `
            -level 5 `
            -additional @{ 'facility' = "MyFacility" }

# construct a message from a custom object or hash to create custom fields in the
# GELF
$obj = [PSCustomObject] @{
    'facility' = "aUniqueFacilityName"
    'myNumber' = 123.45
    'myGuid'   = [Guid]::newGuid()
}
$msg3 = New-OOG_GELFMessage `
            -short_message "object" `
            -full_message "sending a custom object" `
            -level 0 `
            -additional $obj

# take complete control of all message fields
$msg4 = New-OOG_GELFMessage `
            -short_message "important message" `
            -full_message "WHAT!? I KNOW I sent this yesterday... didn't you get it?" `
            -level 6 `
            -additional @{} `
            -host "not.an.ip.from.jamaica" `
            -timestamp [DateTime]::Today.AddDays( -1 )

# send the messages
$udpSender.SendGELFMessage( $msg1 )
$udpSender.SendGELFMessage( $msg2 )
$udpSender.SendGELFMessage( $msg3 )
$udpSender.SendGELFMessage( $msg4 )
```

#Example 2 - 'Using' the Objects Directly
```Powershell
using module @{ModuleName='PSOoGelf'; RequiredVersion='1.0.0.0'}
# *** using is required to get access to the Class definitions ***

#-----------------------------------------------------------
# For UDP:
#-----------------------------------------------------------
#                                  server           port
$udpSender = [GELFSenderUDP]::new( "my.server.com", 12345 )
$msg = [GELFMessage]::new(
    "UDP: Hello World",
    "My very first message!",
    [GELFMessage]::LV_DEBUG,
    @{
        'facility'   = 'PSOoGelf'
        'otherfield' = 123456789
    }
)
$udpSender.SendGELFMessage( $msg )

#-----------------------------------------------------------
# For TCP
#-----------------------------------------------------------
#                                  server       port   isEncrypted  timeoutInMilli
$tcpSender = [GELFSenderTCP]::new( "127.0.0.1", 12345, $False,      5000 )
$msg = [GELFMessage]::new(
    "TCP: Hello World"
    "Slightly more serious...",
    [GELFMessage]::LV_CRITICAL,
    @{
        'facility'                = 'PSOoGelf'
        'exceptionLineOrWhatever' = 123
    }
)
$tcpSender.SendGELFMessage( $msg )
```

#CREDIT
Without a doubt, I was inspired heavily by PSGELF while writing this module! Please check out
their repo for easy logging of Windows Events (Get-WinEvent) and other objects as well!
