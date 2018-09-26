###########################
# Find configuration files
###########################

# Find and process cake-config.json
Param(
    [string] $cakelocation
)

[string] $ConfigurationFile = (Join-Path $cakelocation cake-config.json)

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

$config = Get-Content -Raw $AssetsFile |  ConvertFrom-Json
if (!$config) {
    throw "Error trying to load configuration!"
} 

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

$downloadlist = New-Object System.Collections.Generic.List[System.Object]
$assetsfolder = (Join-Path $config.DeployFolder assets)

# Create list of items in container
if($AzureExists){

  $containerlist = Get-AzureStorageBlob -Container $containerName -Context $ctx -ErrorAction Stop

  $pos = 0
  foreach ($_ in $containerlist){

  $downloadlist.Add($_[$pos].name)

  $pos++
  }
}

##################################################
# Check for existing Files in Deploy\Assets Folder
##################################################

$localassets = $null

$localassets = Get-ChildItem -path $(Join-Path $assetsfolder *) -include *.zip

if (!(Test-Path $assetsfolder)) {

  "Assets Folder does not exist"
  "Creating Assets Folder"

  New-Item -ItemType Directory -Force -Path $assetsfolder

}
else{

  $pos = 0
  foreach ($_ in $localassets){

    $downloadlist.Add($_[$pos].name)

    $pos++
  }

}
  
###########################
# Download Required Files
###########################

 $credentials = Get-Credential -Message "Please provide dev.sitecore.com credentials"

 Import-Module .\DownloadFileWithCredentials.psm1 -Force

	Function Download-Asset {
    param(   [PSCustomObject]
        $packagename,
        $Credentials,
        $assetsfolder
		$assetsjson
    )
    foreach ($package in $Packages) {
        if ($package.id -eq "xp" -or $package.id -eq "sat") {
            # Skip Sitecore Azure Toolkit and XP package - previously downloaded
            continue;
        }

        if (!(Test-Path $packagesFolder)) {
            New-Item -ItemType Directory -Force -Path $packagesFolder
        }
       
        if ($package.isGroup -and $package.download -eq $true) {
            $submodules = $package.modules
            $args = @{
                Packages         = $submodules
                PackagesFolder   = $PackagesFolder
                Credentials      = $Credentials
                DownloadJsonPath = $DownloadJsonPath
            }
            Process-Packages @args
        }
        elseif ($true -eq $package.download -and (!($package.PSObject.Properties.name -match "isGroup") ) ) {
            Write-Host ("Downloading {0}  -  if required" -f $package.name )
            $destination = $package.packagePath
            if (!(Test-Path $destination)) {
                $params = @{
                    Credentials = $credentials
                    Source      = $package.url
                    Destination = $destination
                }
                Install-SitecoreConfiguration  @params  -WorkingDirectory $(Join-Path $PWD "logs")  
            }
            if ($package.convert) {
                Write-Host ("Converting {0} to SCWDP" -f $package.name) -ForegroundColor Green
                ConvertTo-SCModuleWebDeployPackage  -Path $destination -Destination $PackagesFolder -Force
            }
        }
    }

}