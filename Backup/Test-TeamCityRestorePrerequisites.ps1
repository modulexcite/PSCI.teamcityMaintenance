<#
The MIT License (MIT)

Copyright (c) 2015 Objectivity Bespoke Software Specialists

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

function Test-TeamCityRestorePrerequisites {
    <#
    .SYNOPSIS
    Ensures TeamCity Restore prerequisites are met. 

    .PARAMETER BackupFile
    Path to the backup file.

    .PARAMETER DatabasePropertiesFile
    Path to database.properties file. Can be empty if connection stored in backup should be used. See Get-TeamCityRestorePlan for details.

    .PARAMETER RestoreToInternalDatabase
    If true, restore will be made to the internal database (hsqldb). See Get-TeamCityRestorePlan for details.

    .PARAMETER OverwriteExistingData
    If true, all existing TeamCity data will be overwritten.

    .EXAMPLE
    Test-TeamCityRestorePrerequisites -BackupFile $BackupFile -DatabasePropertiesFile $DatabasePropertiesFile -RestoreToInternalDatabase:$RestoreToInternalDatabase -OverwriteExistingData:$OverwriteExistingData
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $BackupFile, 
        
        [Parameter(Mandatory=$false)]
        [string] 
        $DatabasePropertiesFile,

        [Parameter(Mandatory=$false)]
        [switch] 
        $RestoreToInternalDatabase,

        [Parameter(Mandatory=$false)]
        [switch] 
        $OverwriteExistingData
    )
 
    if (!(Test-Path -LiteralPath $BackupFile)) {
        Write-Log -Critical "Backup file '$BackupFile' does not exist"
    }

    if ($DatabasePropertiesFile -and (!(Test-Path -LiteralPath $DatabasePropertiesFile))) {
        Write-Log -Critical "Cannot access database properties file at '$DatabasePropertiesFile'."
    }
    if ($DatabasePropertiesFile -and $RestoreToInternalDatabase) {
        Write-Log -Critical 'You supplied both $DatabasePropertiesFile and $RestoreToInternalDatabase. This is not allowed - see Get-TeamCityRestorePlan for details.'
    }

    $teamCityPaths = Get-TeamCityPaths

    if ((Get-ChildItem $teamCityPaths.TeamCityDataDir | measure).Count -ne 0) {
        if ($OverwriteExistingData) {
            Write-Log -Warn "TeamCity data exists at '$($teamCityPaths.TeamCityDataDir)'. All existing data will be overwritten!"
            Request-UserInputToContinue
        } else {
            Write-Log -Critical "TeamCity data exists at '$($teamCityPaths.TeamCityDataDir)'. Please ensure it can be overwritten and turn on the switch 'OverwriteExistingData'."
        }
    }

    return $teamCityPaths
}