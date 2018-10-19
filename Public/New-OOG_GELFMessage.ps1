Function New-OOG_GELFMessage {
<#
.SYNOPSIS
    Construct a new GELFMessage Object
.DESCRIPTION
    Construct an Object that represents a message to send to a GELF server which
	is compatible with GELFSender Objects.
.PARAMETER $short_message
    The GELF short_message of the log message
.PARAMETER $full_message
    The GELF full_message of the log message
.PARAMETER $level
    The GELF level of the log message (should use [GELFMessage]::LV_* constants!)
.PARAMETER $additional
    Object containing other fields to be added to the log message.
.NOTES
    Author: Brendan Bergen
    Date: Oct, 2018
#>
[cmdletbinding()]
    Param (
        [Parameter(ParameterSetName='1Param',Mandatory)]
        [Parameter(ParameterSetName='4Param',Mandatory)]
        [Parameter(ParameterSetName='6Param',Mandatory)]
            [String] $short_message,
        [Parameter(ParameterSetName='4Param',Mandatory)]
        [Parameter(ParameterSetName='6Param',Mandatory)]
            [String] $full_message,
        [Parameter(ParameterSetName='4Param',Mandatory)]
        [Parameter(ParameterSetName='6Param',Mandatory)]
            [Int] $level,
        [Parameter(ParameterSetName='4Param',Mandatory)]
        [Parameter(ParameterSetName='6Param',Mandatory)]
            [Object] $additional,
        [Parameter(ParameterSetName='6Param',Mandatory)]
            [String] $hostname,
        [Parameter(ParameterSetName='6Param',Mandatory)]
            [DateTime] $timestamp
    )
    Process {
        switch ( $PSCmdlet.ParameterSetName ) {
            "1Param" {
                return [GELFMessage]::new( $short_message )
            }
            "4Param" {
                return [GELFMessage]::new(
                    $short_message,
                    $full_message,
                    $level,
                    $additional
                )
            } 
            "6Param" {
                return [GELFMessage]::new(
                    $short_message,
                    $full_message,
                    $level,
                    $additional, 
                    $hostname,
                    $timestamp
                )
            }
            "default" { throw "Unknown ParameterSetName!" }
        }
    }
}
