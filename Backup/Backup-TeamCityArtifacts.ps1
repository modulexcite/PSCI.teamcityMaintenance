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

function Backup-TeamCityArtifacts {
    <#
    .SYNOPSIS
    Creates backup of artifacts from all Pinned Builds. 

    .PARAMETER Server
    TeamCity Server name.

    .PARAMETER TeamcityPaths
    Object containing information about TeamCity paths - generated by Get-TeamcityPaths.

    .PARAMETER TeamcityBackupPaths
    Object containing information about backup paths - generated by Get-TeamcityBackupPaths.

    .EXAMPLE
    Backup-TeamCityArtifacts -Server $Server -TeamcityPaths $TeamcityPaths -TeamcityBackupPaths $TeamcityBackupPaths
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $Server, 

        [Parameter(Mandatory=$true)]
        [PSCustomObject] 
        $TeamcityPaths, 
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject] 
        $TeamcityBackupPaths
    )

    Write-Log -Info 'Creating Artifacts backup' -Emphasize
    $outputBackupDir = $TeamcityBackupPaths.ArtifactsDir
    $currentTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $buildInfos = Get-TeamCityPinnedBuildsInfo -Server $Server
    if ($buildInfos.Count -eq 0) {
        Write-Log -Info 'Creating _NoPinnedBuilds file'
        [void](New-Item -Path (Join-Path -Path $outputBackupDir -ChildPath "TeamCity_Artifacts_${currentTimestamp}_NoPinnedBuilds") -ItemType File -Force)
        return
    }

    $buildDirs = $buildInfos.buildRelativeDir
    $notExistingDirs = $buildDirs | Where-Object { !(Test-Path -LiteralPath (Join-Path -Path $TeamcityPaths.TeamCityDataDir -ChildPath $_)) }
    if ($notExistingDirs) {
        Write-Log -Warn ('Following directories do not exist and will be ignored: {0}' -f ($notExistingDirs -join "`n"))
        $buildDirs = $buildDirs | Where-Object { $_ -notin $notExistingDirs }
    }
    $outputFileName = Join-Path -Path $outputBackupDir -ChildPath "TeamCity_Artifacts_${currentTimestamp}.7z"
    Write-Log -Info "Creating file $outputFileName"
    Compress-With7Zip -PathsToCompress $buildDirs -OutputFile $outputFileName -WorkingDirectory $TeamcityPaths.TeamCityDataDir
    Write-Log -Info 'TeamCity backup Pinned Builds succeeded.'
}
