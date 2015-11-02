<#
.SYNOPSIS
    Copies files from a local folder to an Azure blob storage container.
.DESCRIPTION
    Copies files (in parallel) from a local folder to a named Azure storage 
    blob container.  The copy operation can optionally recurse the local folder 
    using the -Recurse switch.  The storage container is assumed to already exist 
    unless the -CreateContainer switch is provided.

    Note: This script requires an Azure Storage Account to run.  The storage account 
    can be specified by setting the subscription configuration.  For example:
        Set-AzureSubscription -SubscriptionName "MySubscription" -CurrentStorageAccount "MyStorageAccount"
.EXAMPLE
    .\CopyFilesToAzureStorageContainer -LocalPath "c:\users\<myUserName>\documents" `
        -StorageContainer "myuserdocuments" -Recurse -CreateStorageContainer
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    # The full path to copy files from.
    [Parameter(Mandatory = $true)]
    [string]$LocalPath,

    # The name of the storage container to copy files to.
    [Parameter(Mandatory = $true)]
    [string]$StorageContainer,

    # If specified, will recurse the LocalPath specified.
    [Parameter(Mandatory = $false)]
    [switch]$RecurseLocalPath,

    # If specified, will create the storage container.
    [Parameter(Mandatory = $false)]
    [switch]$CreateStorageContainer,

    # If specified, will copy files to the container if the container already exists.
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# The script has been tested on Powershell 3.0
Set-StrictMode -Version 3

# Following modifies the Write-Verbose behavior to turn the messages on globally for this session
$VerbosePreference = "Continue"

# Check if Windows Azure Powershell is avaiable
if ((Get-Module -ListAvailable Azure) -eq $null)
{
    throw "Windows Azure Powershell not found! Please install from http://www.windowsazure.com/en-us/downloads/#cmd-line-tools"
}

workflow UploadFilesInParallel
{
    param(
        # The name of the storage container to copy files to.
        [Parameter(Mandatory = $true)]
        [string]$StorageContainer,

        # An array of files to copy to the storage container.
        [Parameter(Mandatory = $true)]
        [System.Object[]]$Files
    )

    if ($Files.Count -gt 0)
    {
        foreach -parallel ($file in $Files) 
        {
            $blobFileName = Split-Path -Path $file.FullName -NoQualifier
            try
            {
                Set-AzureStorageBlobContent -Container $StorageContainer `
                    -File $file.FullName -Blob $blobFileName `
                    -ConcurrentTaskCount 0 -Force
            }
            catch
            {
                $warningMessage = "Unable to upload file " + $file.FullName
                Write-Warning -Message $warningMessage
            }
        }
    }
}

# Ensure the local path given exists. Create it if switch specified to do so.
if (-not (Test-Path $LocalPath -IsValid))
{
    throw "Source path '$LocalPath' does not exist.  Specify an existing path."
}

# Get a list of files from the local folder.
if ($RecurseLocalPath.IsPresent)
{
    $files = ls -Path $LocalPath -File -Recurse
}
else
{
    $files = ls -Path $LocalPath -File
}

if ($files -ne $null -and $files.Count -gt 0)
{
    # Create the storage container.
    if ($CreateStorageContainer.IsPresent)
    {
        $existingContainer = Get-AzureStorageContainer | 
            Where-Object { $_.Name -like $StorageContainer }

        if ($existingContainer)
        {
            $msg = "Storage container '" + $StorageContainer + "' already exists."
            if (!$Force.IsPresent -and !$PSCmdlet.ShouldContinue(
                    "Copy files to existing container?", $msg))
            {
                throw "Specify a different storage container name."
            }
        }
        else
        {
            if ($PSCmdlet.ShouldProcess($StorageContainer, "Create Container"))
            {
                $newContainer = New-AzureStorageContainer -Name $StorageContainer
                "Storage container '" + $newContainer.Name + "' created."
            }
        }
    }

    # Upload the files to storage container.
    $fileCount = $files.Count
    if ($PSCmdlet.ShouldProcess($StorageContainer, "Copy $fileCount files"))
    {
        $time = [DateTime]::UtcNow
        UploadFilesInParallel -StorageContainer $StorageContainer -Files $files
        $duration = [DateTime]::UtcNow - $time

        "Uploaded " + $files.Count + " files to blob container '" + $StorageContainer + "'."
        "Total upload time: " + $duration.TotalMinutes + " minutes."
    }
}
else
{
    Write-Warning "No files found."
}