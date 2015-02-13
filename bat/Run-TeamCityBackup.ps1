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

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    $OutputBackupDir,
    
    [Parameter(Mandatory=$false)]
    [string]
    $SecondaryBackupDir,

    [Parameter(Mandatory=$true)]
    [string]
    $PasswordFile,

    [Parameter(Mandatory=$false)]
    [int]
    $PrimaryRetentionInDays,

    [Parameter(Mandatory=$false)]
    [int]
    $SecondaryRetentionInDays,

    [Parameter(Mandatory=$false)]
    [string]
    $MailSmtpServer,

    [Parameter(Mandatory=$false)]
    [string]
    $MailFrom,

    [Parameter(Mandatory=$false)]
    [string]
    $MailRecipients,

    [Parameter(Mandatory=$false)]
    [string]
    $MailUser,

    [Parameter(Mandatory=$false)]
    [string]
    $MailPassword

)

$Global:ErrorActionPreference = 'Stop'

Import-Module "$PSScriptRoot\..\..\..\PSCI.psm1"

$PSCIGlobalConfiguration.LogFile = "$($OutputBackupDir)\TeamCity_backup.log"
$PSCIGlobalConfiguration.LogEventLogSource = 'TeamCity backup job'
$PSCIGlobalConfiguration.LogEventLogCreateSourceIfNotExists = $true

$mailOptions = @{
    To = $MailRecipients
    From = $MailFrom
    SmtpServer = $MailSmtpServer
}

if ($MailUser -and $MailPassword) { 
    $mailOptions.Credential = ConvertTo-PSCredential -User $MailUser -Password $MailPassword
}

$mailBody = ''
$mailSubject = ''
try {
    $backupFile = Backup-TeamCityData -OutputBackupDir $OutputBackupDir -SecondaryBackupDir $SecondaryBackupDir -PasswordFile $PasswordFile -PrimaryRetentionInDays $PrimaryRetentionInDays -SecondaryRetentionInDays $SecondaryRetentionInDays
    Write-EventLog -LogName Application -Source $PSCIGlobalConfiguration.LogEventLogSource -EntryType Info -EventID 1 -Message ("TeamCity backup completed succesfully - created file ${backupFile}.")
    $backupFileName = Split-Path -Path $backupFile -Leaf
    $mailSubject = '[TeamCity] Backup success'
    $mailBody = "TeamCity backup completed successfully. File '$backupFileName' created"
} catch {
    $mailSubject = '[TeamCity] Backup failure'
    $mailBody = "TeamCity backup failed: $_"
    Write-ErrorRecord
} finally {
    $mailBody += ".`n`nContents of '${OutputBackupDir}':`n"
    $mailBody += (Get-ChildItem -Path $OutputBackupDir -Filter "*.zip" | Select-Object -ExpandProperty Name | Sort-Object) -join "`n"
    if ($SecondaryBackupDir) {
        $mailBody += "`n`nContents of '${SecondaryBackupDir}':`n"
        $mailBody += (Get-ChildItem -Path $SecondaryBackupDir -Filter "*.zip" | Select-Object -ExpandProperty Name | Sort-Object) -join "`n"
    }
    Send-MailMessage @mailOptions -Subject $mailSubject -Body $mailBody
}