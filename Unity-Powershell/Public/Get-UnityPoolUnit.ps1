Function Get-UnityPoolUnit {

  <#
      .SYNOPSIS
      Queries the EMC Unity array to retrieve informations about poolUnit.
      .DESCRIPTION
      Querries the EMC Unity array to retrieve informations about poolUnit.
      You need to have an active session with the array.
      .NOTES
      Written by Erwan Quelin under MIT licence
      .LINK
      https://github.com/equelin/Unity-Powershell
      .PARAMETER Session
      Specifies an UnitySession Object.
      .PARAMETER Name
      Specifies the object name.
      .PARAMETER ID
      Specifies the object ID.
      .EXAMPLE
      Get-UnityPoolUnit

      Retrieve information about poolUnit
      .EXAMPLE
      Get-UnityPoolUnit -Name 'POOL01'

      Retrieves information about poolUnit named POOL01
  #>

  [CmdletBinding(DefaultParameterSetName="ByName")]
  Param (
    [Parameter(Mandatory = $false,HelpMessage = 'EMC Unity Session')]
    $session = ($global:DefaultUnitySession | where-object {$_.IsConnected -eq $true}),
    [Parameter(Mandatory = $false,ParameterSetName="ByName",ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,HelpMessage = 'LUN Name')]
    [String[]]$Name='*',
    [Parameter(Mandatory = $false,ParameterSetName="ByID",ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,HelpMessage = 'LUN ID')]
    [String[]]$ID='*'
  )

  Begin {
    Write-Verbose "Executing function: $($MyInvocation.MyCommand)"

    #Initialazing variables
    $ResultCollection = @()
    $URI = '/api/types/poolUnit/instances' #URI
    $TypeName = 'UnityPoolUnit'
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

          # Results filtering
          Switch ($PsCmdlet.ParameterSetName) {
            'ByName' {
              $ResultsFiltered += Find-FromFilter -Parameter 'Name' -Filter $Name -Data $Results
            }
            'ByID' {
              $ResultsFiltered += Find-FromFilter -Parameter 'ID' -Filter $ID -Data $Results
            }
          }

          If ($ResultsFiltered) {
            
            $ResultCollection = ConvertTo-Hashtable -Data $ResultsFiltered

            Foreach ($Result in $ResultCollection) {

              # Instantiate object
              $Object = [UnityPoolUnit]$Result

              # Output results
              $Object
            }
          }
        }
      } else {
        Write-Host "You are no longer connected to EMC Unity array: $($Sess.Server)"
      }
    }
  }
}
