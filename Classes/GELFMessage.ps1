Class GELFMessage {
<#
.SYNOPSIS
    A Class to hold messages in GELF formatting. Automatically populates common
    fields on object creation (timestap/host)
.DESCRIPTION
    Objects to hold log message data with methods to convert this data to
    usable formats for shipment. Usable by GELFSenders or other modules like PSGELF
.NOTES
    This Class would not be possible without other contributions to open source!

    PSGELF:
        Some parts of this Class definition were heavily influenced by the PSGELF
        module. Go check them out for an alternative to this code:
        https://github.com/jeremymcgee73/PSGELF/blob/master/PSGELF
    
    OTHER:
        A whitelist of pseudo-primitive .NET types was taken from Jonathan Conway:
        https://gist.github.com/jonathanconway/3330614

    THANK YOU!

    Author: Brendan Bergen
    Date: Oct, 2018
#>
    #---------------
    # STATIC MEMBERS
    #---------------

    static [Int] $LV_EMERGENCY   = 0
    static [Int] $LV_ALERT       = 1
    static [Int] $LV_CRITICAL    = 2
    static [Int] $LV_ERROR       = 3
    static [Int] $LV_WARNING     = 4
    static [Int] $LV_NOTICE      = 5
    static [Int] $LV_INFORMATION = 6
    static [Int] $LV_DEBUG       = 7

    static [Byte[]] $CHUNK_HEADER_MAGIC_BYTES = @([byte]0x1e,[byte]0x0f)
    static [Byte] $GELF_MESSAGE_TERMINATING_BYTE = [Byte]0x00

    # the docs say you could set this to over 8000... but our GrayLog server
    # chokes on that size for UDP. Feel free to play around with these and let
    # me know if you can afford less chunking than we can.
    static [Int]    $CHUNK_THRESHOLD_BYTES    = 1000
    static [Int]    $CHUNK_SIZE_BYTES         = 1000
    static [Int]    $MAX_NUMBER_CHUNKS        = 128

    #-----------
    # PROPERTIES
    #-----------
    [ValidateNotNullOrEmpty()][String]    $version
    [ValidateNotNullOrEmpty()][String]    $host
    [ValidateNotNullOrEmpty()][String]    $short_message
    [ValidateNotNullOrEmpty()][Int]       $level
    [ValidateNotNull()]       [String]    $full_message
    [ValidateNotNull()]       [DateTime]  $timestamp
    [ValidateNotNull()]       [HashTable] $additional_fields

    #-------------
    # CONSTRUCTORS
    #-------------
    GELFMessage (
        [String] $sm
    )
    <#
    .SYNOPSIS
        Construct a GELFMessage with the only required field: short_message
    .DESCRIPTION
        Construct a GELFMessage given a short_message.
        version, host, full_message, timestamp, and level are automatically set.
    #>
    {
        $this.version           = "1.1"
        $this.host              = $([GELFMessage]::GetCurrentIpAddress())
        $this.short_message     = $sm
        $this.full_message      = ""
        $this.timestamp         = (Get-Date -Date (Get-Date)).ToUniversalTime()
        $this.level             = [GELFMessage]::LV_CRITICAL
        $this.additional_fields = @{}
    }

    GELFMessage (
        [String] $sm,
        [String] $fm,
        [Int]    $lv,
        [Object] $af
    )
    <#
    .SYNOPSIS
        Construct a GELFMessage with a decent balance of manually-set fields.
    .DESCRIPTION
        Construct a GELFMessage given short_message, full_message, level, and
        any additional fields.
        version, host, and timestap are automatically set.
    #>
    {
        # might throw.
        $afHash = [GELFMessage]::ValidateAdditionalFieldsCandidate( $af )
        [GELFMessage]::ValidateLevelCandidate( $lv )

        $this.version           = "1.1"
        $this.host              = $([GELFMessage]::GetCurrentIpAddress())
        $this.short_message     = $sm
        $this.full_message      = $fm
        $this.timestamp         = (Get-Date -Date (Get-Date)).ToUniversalTime()
        $this.level             = $lv
        $this.additional_fields = $afHash
    }

    GELFMessage (
        [String]   $sm,
        [String]   $fm,
        [Int]      $lv,
        [Object]   $af,
        [String]   $ho,
        [DateTime] $ts
    )
    <#
    .SYNOPSIS
        Construct a GELFMessage given all possible fields.
    .DESCRIPTION
        Construct a GELFMessage with full control of all fields except version.
    #>
    {
        # might throw.
        $afHash = [GELFMessage]::ValidateAdditionalFieldsCandidate( $af )
        [GELFMessage]::ValidateLevelCandidate( $lv )

        $this.version           = "1.1"
        $this.host              = $ho
        $this.short_message     = $sm
        $this.full_message      = $fm
        $this.timestamp         = $ts
        $this.level             = $lv
        $this.additional_fields = $afHash
    }
        

    #--------
    # METHODS
    #--------
    <#
    .SYNOPSIS
        Validate an object containing additional fields of a GELFMessage.
    .DESCRIPTION
        Given an object, determine if that object contains valid data to be
        converted to additional fields in GELF format. If valid, returns a
        HashTable containing key/value pairs to be used in the GELF.
    #>
    [HashTable] static ValidateAdditionalFieldsCandidate ( [Object] $obj ) {
        # Convert Object to HashTable
        $hash = @{}
        if ( $obj.GetType().Name -ne "HashTable" ) {
            $props =  @( $obj | Get-Member | Where-Object -Property MemberType -EQ NoteProperty )
            $props += @( $obj | Get-Member | Where-Object -Property MemberType -EQ Property )
            foreach ( $p in $props ) {
                $name = $p.Name
                $hash[$name] = $obj.$($name)
            }
        }
        else {
            $hash = [HashTable] $obj
        }

        # validate all keys in the hash
        $badNames = @( "id" )
        # whitelist borrowed from https://gist.github.com/jonathanconway/3330614
        # thanks!
        $typeWhitelist = @(
            "String",
            "Decimal",
            "DateTime",
            "DateTimeOffset",
            "TimeSpan",
            "Guid"
        )
        $hash.GetEnumerator() | ForEach-Object {
            # validate types (must be primitive-esque)
            $type = $_.Value.GetType()
            if ( !( ( $type.IsPrimitive ) -or ($type.Name -in $typeWhiteList) ) ) {
                throw "additional fields must only contain primitive-esque types! Bad type was $($type.Name)."
            }
            # validate no bad properties (see PSGELF)
            if ( $_.Name.ToLower() -in $badNames ) {
                throw "additional fields must not be any of: $($badNames)!"
            }
        }
        return $hash
    }

    <#
    .SYNOPSIS
        Validate an integer is a valid level for a GELFMessage.
    .DESCRIPTION
        Validate that a given integer is a valid GELF level.
    #>
    [Void] static ValidateLevelCandidate ( [Int] $lv ) {
        if ( ($lv -lt 0) -or ($lv -gt 7) ) {
            throw "invalid level! Must be 0 [emergency] - 7 [debug]."
        }
    }

    <#
    .SYNOPSIS
        Attempt to determine the current host's IP.
    .DESCRIPTION
        Attempt to find the current IP Address for the creator of this GELFMessage.
    #>
    [String] static GetCurrentIpAddress () {
        try {
            return (Get-NetIPAddress | Where-Object -Property "InterfaceAlias" -EQ "Ethernet" | Where-Object -Property "AddressFamily" -EQ "IPv4").IPAddress
        }
        catch {
            try {
                return (Get-NetIPAddress | Where-Object -Property "InterfaceAlias" -EQ "Wi-Fi" | Where-Object -Property "AddressFamily" -EQ "IPv4").IPAddress
            }
            catch {
                return "UNKNOWN"
            }
        }
    }

    <#
    .SYNOPSIS
        Create a String representation of this GELFMessage instance.
    #>
    [String] ToString () {
        $str = ""
        $str += "version: $($this.version)`n"
        $str += "host: $($this.host)`n"
        $str += "short_message: $($this.short_message)`n"
        $str += "full_message: $($this.full_message)`n"
        $str += "timestamp: $($this.timestamp)`n"
        $str += "level: $($this.level)`n"
        foreach ( $k in $this.additional_fields.Keys ) {
            $str += "_$($k): $($this.additional_fields[$k])`n"
        }
        return $str
    }

    <#
    .SYNOPSIS
        Convert this GELFMessage instance to a PSObject.
    .DESCRIPTION
        Convert this to a PSObject, with the additional_fields moved "up" to be
        data items of the result. All items moved are prepended with an underscore
        and converted to the String type.
    #>
    [PSObject] ConvertToPSObject () {
        $newProp = @{}
        $curProp = @( $this | Get-Member | Where-Object -Property MemberType -EQ Property )
        foreach ( $p in $curProp ) {
            $name = $p.Name
            if ( $name -ne "additional_fields" ) {
                $newProp[$name] = $this.$name
            }
            else {
                $adtnl = $this.$name
                $adtnl.GetEnumerator() | ForEach-Object {
                    $newProp["_$($_.Name)"] = [String] $_.Value
                }
            }
        }
        $obj = New-Object PSObject -Property $newProp
        return $obj
    }

    <#
    .SYNOPSIS
        Convert this GELFMessage instance to GELF-legible bytes for TCP/UDP.
    .DESCRIPTION
        Perform all formatting required for this to be converted to valid
        GELF-legible bytes for TCP/UDP protocols.
    #>
    [Byte[]] ConvertToGELFByteArray () {
        $obj = $this.ConvertToPSObject()

        # never fear; this "compress" only removes spaces and newlines! (mandatory)
        $json = ($obj | ConvertTo-Json -Compress)
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($json)
        $bytes += [GELFMessage]::GELF_MESSAGE_TERMINATING_BYTE
        return $bytes
    }

    <#
    .SYNOPSIS
        Convert this GELFMessage into reasonable chunks for UDP.
    .DESCRIPTION
        Perform all formatting required for this to be converted to a valid set
        of GELF-legible bytes so the server can re-construct them once they reach
        the server. Supports compression if you prefer consuming CPU over network.
        See http://docs.graylog.org/en/2.4/pages/gelf.html for more details on chunking.
    .NOTES
        Checkout the PSGELF module, which contains my inspiration for this method!
        Thank you!
        https://github.com/jeremymcgee73/PSGELF/blob/master/PSGELF/Public/Send-PSGelfUDPFromObject.ps1
    #>
    [System.Collections.Generic.List[Byte[]]] ConvertToChunkedByteList () {
        # backwards compatibility. No Compression.
        return $this.ConvertToChunkedByteList( $False )
    }
    [System.Collections.Generic.List[Byte[]]] ConvertToChunkedByteList ( [Boolean] $compress ) {
        $gmsg = $this.ConvertToGELFByteArray()

        if ( $compress ) {
            Write-Host "Original message: $($gmsg.length) bytes"
            $output = [System.IO.MemoryStream]::new()
            $gzipStream = New-Object System.IO.Compression.GzipStream $output, ([IO.Compression.CompressionMode]::Compress)
                        
            $gzipStream.Write($gmsg, 0, $gmsg.Length)
            $gzipStream.Close()
            $gmsg = [Byte[]] $output.ToArray()
            Write-Host "Compressed message: $($gmsg.length) bytes"
        }

        $result = New-Object System.Collections.Generic.List[Byte[]]

        if( $gmsg.Length -ge [GELFMessage]::CHUNK_THRESHOLD_BYTES ) {
            $numChunks = [Math]::ceiling($gmsg.Length / [GELFMessage]::CHUNK_SIZE_BYTES ) - 1
            [Byte] $totalChunks = $($numChunks + 1)

            if($totalChunks -ge [GELFMessage]::MAX_NUMBER_CHUNKS ) {
                throw "There are too many chunks to send. The maxium number of chunks is $([GELFMessage]::MAX_NUMBER_CHUNKS)."
            }

            # 8-byte MessageId for the sequence of chunked messages
            $random = New-Object System.Random
            $curMessageID = New-Object Byte[] 8
            $random.NextBytes($curMessageID)

            for ( [Byte] $curChunkNum = 0; $curChunkNum -lt $totalChunks; $curChunkNum++ ) {
                $startPacketIndex = $curChunkNum * [GELFMessage]::CHUNK_SIZE_BYTES
                $endPacketIndex = [Math]::Min(
                    ($startPacketIndex + [GELFMessage]::CHUNK_SIZE_BYTES - 1),
                    ($gmsg.length - 1)
                )

                [Byte[]] $packetData = $gmsg[$startPacketIndex .. $endPacketIndex]
                [Byte[]] $packetHeader = [GELFMessage]::CHUNK_HEADER_MAGIC_BYTES + $curMessageID + $curChunkNum + $totalChunks

                [Byte[]] $chunkPacket = $packetHeader + $packetData
                $result.Add( $chunkPacket ) | Out-Null
            }
        }
        else {
            $result.Add( $gmsg ) | Out-Null
        }
        return  $result
    }
}
