###########################
# Find configuration files
###########################

# Find and process cake-config.json
Param(
    [string] $ConfigurationFile
)

if (!(Test-Path $ConfigurationFile)) {
    Write-Host "Configuration file '$($ConfigurationFile)' not found." -ForegroundColor Red
    Write-Host  "Please ensure there is a cake-config.json configuration file at '$($cakelocation)'" -ForegroundColor Red
    Exit 1
}

$config = Get-Content -Raw $ConfigurationFile |  ConvertFrom-Json
if (!$config) {
    throw "Error trying to load configuration!"
} 

# Find and process assets.json
[string] $AssetsFile = $([io.path]::combine($config.ProjectFolder, 'Azure Paas', 'Sitecore 9.0.2', 'XP0 Single', 'assets.json'))

if (!(Test-Path $AssetsFile)) {
    Write-Host "Assets file '$($AssetsFile)' not found." -ForegroundColor Red
    Write-Host  "Please ensure there is a assets.json file at '$($AssetsFile)'" -ForegroundColor Red
    Exit 1
}

$assetconfig = Get-Content -Raw $AssetsFile |  ConvertFrom-Json
if (!$assetconfig) {
    throw "Error trying to load Assest File!"
} 

###################################
# Paramters
###################################
$downloadlist = New-Object System.Collections.Generic.List[System.Object]
$assetsfolder = (Join-Path $config.DeployFolder assets)

####################################
# Check for existing Files in Azure
####################################

$containerName = "azure-toolkit"
$AzureExists = $null
$containerlist= $null

# Get the current storage account and context
$sa = Get-AzureRmStorageAccount
$ctx = $sa.Context


try {
  "Verifying the existence of the current Azure container..."

  # Check if the container name already exists
  Get-AzureStorageContainer -Container $containerName -Context $ctx -ErrorAction Stop

  $AzureExists = $true;

}
catch {

  "No Storage Account found in Azure"
  "Continuing"

  $AzureExists = $false;

}

# Create list of items in container
if($AzureExists){

  "Gathering List of files in Azure"

  $containerlist = Get-AzureStorageBlob -Container $containerName -Context $ctx -ErrorAction Stop

  foreach ($_ in $containerlist){

  $downloadlist.Add($_.name)

  }
}

##################################################
# Check for existing Files in Deploy\Assets Folder
##################################################

if (!(Test-Path $assetsfolder)) {

  "Assets Folder does not exist"
  "Creating Assets Folder"

  New-Item -ItemType Directory -Force -Path $assetsfolder

}

"Gathering List of local files"

$localassets = Get-ChildItem -path $(Join-Path $assetsfolder *) -include *.zip

foreach($_ in $localassets){

  $downloadlist.Add($_.name)

  }



###########################
# Download Required Files
###########################

 Import-Module .\DownloadFileWithCredentials.psm1 -Force

 $credentials = Get-Credential -Message "Please provide dev.sitecore.com credentials"

	Function Download-Asset {
    param(   [PSCustomObject]
        $assetename,
        $Credentials,
        $assetsfolder,
		$sourceuri
    )

        if (!(Test-Path $assetsfolder)) {
            New-Item -ItemType Directory -Force -Path $assetsfolder
        }
       

        Write-Host ("Downloading" -f $assetname )

        if (!(Test-Path $destination)) {
			$params = @{
                    Source      = $sourceuri
                    Destination = $assetsfolder
					Credentials = $Credentials
            }
				
            Invoke-DownloadFileWithCredentialsTask  @params  
		}
		
	}

foreach ($prereq in $assetconfig.prerequisites)
{

	$prereq
	foreach ($_ in $downloadlist)
	{
		if ($prereq.filename -eq $_.name)
		{
			continue
		}
		else
		{
			Download-Asset -assetname $_.name -Credentials $Credentials -assetsfolder $assetsfolder -sourceuri $prereq.url
		}
	}
}