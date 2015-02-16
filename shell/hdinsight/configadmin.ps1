param (
  [bool]$beforeServiceStart
)

function Find-User ($username)
{
	$computer = [ADSI]("WinNT://$ENV:COMPUTERNAME,computer")
	$users = $computer.psbase.children | where { $_.psbase.schemaclassname -eq "User" }
	foreach( $user in $users )
	{
		if( $user.Name -eq $username )
		{
			return $true
		}
	}
	return $false
}

function CreateAdminAccount(
  [String]
  [Parameter( Position=0, Mandatory=$true )]
  $username,
  [String]
  [Parameter( Position=1, Mandatory=$true )]
  $password
)
{
  if (!(Find-User $username))
  {
    try {
      $computer = [ADSI]("WinNT://$ENV:COMPUTERNAME,computer")
      $user = $computer.Create("User", $username)
      $user.SetPassword($password)
      $user.SetInfo()
      $cmd = "net.exe localgroup administrators ""$ENV:COMPUTERNAME\$username"" /add"
      Invoke-CmdChk $cmd
    } catch [Exception]
    {
      return $false
    }
  }
  else
  {
    return $false
  }
  return $true
}

function AddToRdpGroup(
  [String]
  [Parameter( Position=0, Mandatory=$true )]
  $adminusername
)
{
  $rdpgroup = 'Remote Desktop Users'
  try {
    $cmd = "net.exe localgroup ""$rdpgroup"" ""$ENV:COMPUTERNAME\$adminusername"" /add"
    Invoke-CmdChk $cmd
  } catch [Exception]
  {
    return $false
  }
  return $true
}

function Invoke-Cmd ($command)
{
	Write-Output $command
	$out = cmd.exe /C "$command" 2>&1
    Write-Output $out
	return $out
}

function Invoke-CmdChk ($command)
{
  Write-OutPut $command
  $out = cmd.exe /C "$command" 2>&1
  Write-Output $out
  if (-not ($LastExitCode  -eq 0))
  {
      throw "Command `"$out`" failed with exit code $LastExitCode "
  }
  return $out
}

function empty-null($obj)
{
   if ($obj -ne $null) { $obj }
}

function UpdateXmlConfig(
    [string]
    [parameter( Position=0, Mandatory=$true )]
    $fileName,
    [hashtable]
    [parameter( Position=1 )]
    $config = @{} )
{
  $xml = New-Object System.Xml.XmlDocument
  $xml.PreserveWhitespace = $true
  $xml.Load($fileName)

  foreach( $key in empty-null $config.Keys )
  {
    $value = $config[$key]
    $found = $False
    $xml.SelectNodes('/configuration/property') | ? { $_.name -eq $key } | % { $_.value = $value; $found = $True }
    if ( -not $found )
    {
      $xml["configuration"].AppendChild($xml.CreateWhitespace("`r`n  ")) | Out-Null
      $newItem = $xml.CreateElement("property")
      $newItem.AppendChild($xml.CreateWhitespace("`r`n    ")) | Out-Null
      $newItem.AppendChild($xml.CreateElement("name")) | Out-Null
      $newItem.AppendChild($xml.CreateWhitespace("`r`n    ")) | Out-Null
      $newItem.AppendChild($xml.CreateElement("value")) | Out-Null
      $newItem.AppendChild($xml.CreateWhitespace("`r`n  ")) | Out-Null
      $newItem.name = $key
      $newItem.value = $value
      $xml["configuration"].AppendChild($newItem) | Out-Null
      $xml["configuration"].AppendChild($xml.CreateWhitespace("`r`n")) | Out-Null
    }
  }
  $xml.Save($fileName)
  $xml.ReleasePath
}

function Main()
{
    $adminUsername = ""
    $adminPassword = ""

    # Create the Administrators account
    CreateAdminAccount $adminUsername $adminPassword
    AddToRdpGroup $adminUsername

    return
}

Main
winrm set winrm/config/client '@{TrustedHosts="*"}'
