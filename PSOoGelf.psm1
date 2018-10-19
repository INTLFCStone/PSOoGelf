Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#-------------------------------------------------------------------------------
# PULL IN FUNCTIONS FROM TREE
#-------------------------------------------------------------------------------
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 )

$dirsToImport = @($Public + $Private)

Foreach( $f in $dirsToImport ) {
    try {
        . $f.fullname
    }
    catch {
        write-error "Failed to import function $($f.fullname): $_"
    }
}

#-------------------------------------------------------------------------------
# EXPORT PUBLIC FUNCTIONS
#-------------------------------------------------------------------------------
Export-ModuleMember -Function $Public.Basename


#-------------------------------------------------------------------------------
# PULL IN CLASSES FROM TREE
#-------------------------------------------------------------------------------
$Classes = @( Get-ChildItem -Path $PSScriptRoot\Classes\*.ps1 )
foreach ( $f in $Classes ) {
    try {
        . $f.fullname
    }
    catch {
        Write-Error "Unable to import classes from $($f.fullname): $_"
    }
}
