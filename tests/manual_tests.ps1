<#
TODO: This should be converted to a pester test set.

Validates the construction and methods of GELFMessages, as well
as sending them via GELFSender objects. ACTUALLY SENDS DATA TO
YOUR PROVIDED GELF SERVER! The connections to the server to test
against are determined by environment variables.

#>
$ErrorActionPreference="Stop"
Import-Module .\PSOoGelf.psd1 -Verbose -Force
$VerbosePreference="Continue"

###############################################################################
# TEST MESSAGES
###############################################################################
# test "typical" message
write-host "==========================================="
$msg1 = New-OOG_GELFMessage `
            -short_message "hi" `
            -full_message "hello world" `
            -level 6 `
            -additional @{ 'facility' = 'PSOoGELFTesting' }
write-host "----"
$str = $msg1.ToString()
$str
write-host "----"
$obj = $msg1.ConvertToPSObject()
$obj
write-host "----"
$ary = $msg1.ConvertToGELFByteArray()
write-host "Number bytes: $($ary.Length)"
write-host "----"
$list = $msg1.ConvertToChunkedByteList()
write-host "Number chunks: $($list.Count)"
write-host "----"



# test chunking message
write-host "==========================================="
# generate a random object (containing info of currently installed modules). Hopefully long enough to spark chunking, but not necessarily...
$bigObj = [PSCustomObject]::new()
$bigObj | Add-Member -NotePropertyName 'facility' -NotePropertyValue 'PSOoGELFTesting'
Get-InstalledModule | ForEach-Object {
    $bigObj | Add-Member -NotePropertyName   "$($_.Name)" -NotePropertyValue $_.Description
    #$bigObj | Add-Member -NotePropertyName "a_$($_.Name)" -NotePropertyValue $_.Description   # if more bytes needed...
}

$msg2 = New-OOG_GELFMessage `
            -short_message "goodbye" `
            -full_message "goodbye world" `
            -level 0 `
            -additional $bigObj
write-host "----"
$str = $msg2.ToString()
$str
write-host "----"
$obj = $msg2.ConvertToPSObject()
#$obj
$ary = $msg2.ConvertToGELFByteArray()
write-host "Number bytes: $($ary.Length)"
write-host "----"
$list = $msg2.ConvertToChunkedByteList()
write-host "Number chunks: $($list.Count)"
write-host "----"



# test message with primitive-esque types
write-host "==========================================="
$adtnl = @{
    'facility' = 'PSOoGELFTesting'
    'datetime' = (Get-Date)
    'decimal'  = [Decimal] 123.45
    'guid'     = [Guid]::NewGuid()
}
$msg3 = New-OOG_GELFMessage `
            -short_message "primitive" `
            -full_message "primitive additional fields" `
            -level 4 `
            -additional $adtnl
write-host "----"
$str = $msg3.ToString()
$str
write-host "----"
$obj = $msg3.ConvertToPSObject()
$obj
write-host "----"
$ary = $msg3.ConvertToGELFByteArray()
write-host "Number bytes: $($ary.Length)"
write-host "----"
$list = $msg3.ConvertToChunkedByteList()
write-host "Number chunks: $($list.Count)"
write-host "----"



# test message with non primitive-esque types
write-host "==========================================="
$adtnl = @{
    'facility' = 'PSOoGELFTesting'
    'badthing' = @{ 'a' = 'b' }
}
$passed = $False
try {
    $msgerr = New-OOG_GELFMessage `
                  -short_message "bad add" `
                  -full_message "bad additional fields" `
                  -level 0
                  -additional $adtnl
}
catch {
    $passed = $True
    write-host "Invalid additional field was properly refused."
}
if ( ! $passed ) { throw "A bad additional field was accepted!" }




###############################################################################
# TEST SENDERS - uses local $env vars, and sends data to your server!
###############################################################################
write-host "TESTING UDP"
$udpSender = New-OOG_GELFSenderUDP -GelfServer $env:GELF_NONPROD_UDP_SERVER -GelfPort $env:GELF_NONPROD_UDP_PORT
write-host "    TESTING UDP MSG1"
$udpSender.SendGELFMessage( $msg1 )
write-host "    TESTING UDP MSG2"
$udpSender.SendGELFMessage( $msg2 )
write-host "    TESTING UDP MSG3"
$udpSender.SendGELFMessage( $msg3 )

write-host "TESTING TCP (unencrypted)"
$tcpSender = New-OOG_GELFSenderTCP -GelfServer $env:GELF_NONPROD_TCP_SERVER -GelfPort $env:GELF_NONPROD_TCP_PORT -TimeoutInMilli 5000
write-host "    TESTING TCP MSG1"
$tcpSender.SendGELFMessage( $msg1 )
write-host "    TESTING TCP MSG2"
$tcpSender.SendGELFMessage( $msg2 )
write-host "    TESTING TCP MSG3"
$tcpSender.SendGELFMessage( $msg3 )

#write-host "TESTING TCP (encrypted)"
#$tcpSender = New-OOG_GELFSenderTCP -GelfServer $env:GELF_NONPROD_TCP_SERVER -GelfPort $env:GELF_NONPROD_TCP_PORT -TimeoutInMilli 5000 -Encrypt
#write-host "    TESTING TCPE MSG1"
#$tcpSender.SendGELFMessage( $msg1 )
#write-host "    TESTING TCPE MSG2"
#$tcpSender.SendGELFMessage( $msg2 )
#write-host "    TESTING TCPE MSG3"
#$tcpSender.SendGELFMessage( $msg3 )
