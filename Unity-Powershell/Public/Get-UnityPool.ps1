Function Get-UnityPool {

  <#
      .SYNOPSIS
      Queries the EMC Unity array to retrieve informations about pool.
      .DESCRIPTION
      Queries the EMC Unity array to retrieve informations about pool.
      You need to have an active session with the array.
      .NOTES
      Written by Erwan Quelin under MIT licence - https://github.com/equelin/Unity-Powershell/blob/master/LICENSE
      .LINK
      https://github.com/equelin/Unity-Powershell
      .PARAMETER Session
      Specifies an UnitySession Object.
      .PARAMETER Name
      Specifies the object name.
      .PARAMETER ID
      Specifies the object ID.
      .EXAMPLE
      Get-UnityPool

      Retrieve information about pool
      .EXAMPLE
      Get-UnityPool -Name 'POOL01'

      Retrieves information about pool named POOL01
  #>

  [CmdletBinding(DefaultParameterSetName="ByName")]
  Param (
    [Parameter(Mandatory = $false,HelpMessage = 'EMC Unity Session')]
    $session = ($global:DefaultUnitySession | where-object {$_.IsConnected -eq $true}),
    [Parameter(Mandatory = $false,ParameterSetName="ByName",ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,HelpMessage = 'Pool Name')]
    [String[]]$Name='*',
    [Parameter(Mandatory = $false,ParameterSetName="ByID",ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,HelpMessage = 'Pool ID')]
    [String[]]$ID='*'
  )

  Begin {
    Write-Verbose "Executing function: $($MyInvocation.MyCommand)"

    #Initialazing variables
    $ResultCollection = @()
    $URI = '/api/types/pool/instances' #URI
    $TypeName = 'UnityPool'

    Switch ($Session.apiVersion) {
      '4.0' {$Exception = 'compressionSizeSaved','compressionPercent','compressionRatio','hasCompressionEnabledLuns'}
      'Default' {$Exception = ''}
    }   
  }

  Process {
    Foreach ($sess in $session) {

      Write-Verbose "Processing Session: $($sess.Server) with SessionId: $($sess.SessionId)"

      If ($Sess.TestConnection()) {

        #Building the URL from Object Type.
        $URL = Get-URLFromObjectType -Server $sess.Server -URI $URI -TypeName $TypeName -Exception $Exception -Compact

        Write-Verbose "URL: $URL"

        #Sending the request
        $request = Send-UnityRequest -uri $URL -Session $Sess -Method 'GET'

        #Formating the result. Converting it from JSON to a Powershell object
        $Results = ($request.content | ConvertFrom-Json).entries.content

        #Building the result collection (Add ressource type)
        If ($Results) {

          $ResultsFiltered = @()

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
              $Object = New-Object -TypeName $TypeName -Property $Result

              # Output results
              $Object
            } # End Foreach ($Result in $ResultCollection)
          } # End If ($ResultsFiltered) 
        } # End If ($Results)
      } # End If ($Sess.TestConnection()) 
    } # End Foreach ($sess in $session)
  } # End Process
} # End Function
