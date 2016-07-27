Function Get-UnityNTPServer {

  <#
      .SYNOPSIS
      Information about NTP Servers.
      .DESCRIPTION
      Information about NTP Servers.
      You need to have an active session with the array.
      .NOTES
      Written by Erwan Quelin under MIT licence - https://github.com/equelin/Unity-Powershell/blob/master/LICENSE
      .LINK
      https://github.com/equelin/Unity-Powershell
      .PARAMETER Session
      Specifies an UnitySession Object.
      .EXAMPLE
      Get-UnityNTPServer

      Retrieve informations about the NTP Servers.
  #>

  [CmdletBinding(DefaultParameterSetName="ByName")]
  Param (
    [Parameter(Mandatory = $false,HelpMessage = 'EMC Unity Session')]
    $session = ($global:DefaultUnitySession | where-object {$_.IsConnected -eq $true})
  )

  Begin {
    Write-Verbose "Executing function: $($MyInvocation.MyCommand)"

    #Initialazing variables
    $ResultCollection = @()
    $URI = '/api/types/ntpServer/instances' #URI for the ressource (example: /api/types/lun/instances)
    $TypeName = 'UnityNTPServer'
  }

  Process {
    Foreach ($sess in $session) {

      Write-Verbose "Processing Session: $($sess.Server) with SessionId: $($sess.SessionId)"

      If ($Sess.TestConnection()) {

        #Building the URL from Object Type.
        $URL = Get-URLFromObjectType -Server $sess.Server -URI $URI -TypeName $TypeName -Compact

        Write-Verbose "URL: $URL"

        #Sending the request
        $request = Send-UnityRequest -uri $URL -Session $Sess -Method 'GET'

        #Formating the result. Converting it from JSON to a Powershell object
        $Results = ($request.content | ConvertFrom-Json).entries.content

        #Building the result collection (Add ressource type)
        If ($Results) {
      
          $ResultCollection = ConvertTo-Hashtable -Data $Results

          Foreach ($Result in $ResultCollection) {

            # Instantiate object
            $Object = [UnityNTPServer]$Result

            # Output results
            $Object
          }
        }
      } else {
        Write-Host "You are no longer connected to EMC Unity array: $($Sess.Server)"
      }
    }
  }
}
