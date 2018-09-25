$SitecoreCloudModulePath = "C:\Users\auzunov\Downloads\ARM_deploy\1_Sitecore Azure Toolkit\tools\Sitecore.Cloud.Cmdlets.psm1"
$SourceFolderPath = "C:\_deployment\website_packaged"
$DestinationFolderPath = "C:\_deployment\website_packaged\convert to WDP\WPD"
$CargoPayloadFolderPath = "C:\_deployment\website_packaged\convert to WDP\Components\CargoPayloads"
$AdditionalWdpContentsFolderPath = "C:\_deployment\website_packaged\convert to WDP\Components\AdditionalFiles"
$ParameterXmlFolderPath = "C:\_deployment\website_packaged\convert to WDP\Components\MsDeployXmls"
$ConfigFilePath = "C:\_deployment\website_packaged\convert to WDP\Components\Configs\website.config.json"

Import-Module $SitecoreCloudModulePath -Verbose
Start-SitecoreAzureModulePackaging -SourceFolderPath $SourceFolderPath `
                                   -DestinationFolderPath $DestinationFolderPath `
                                   -CargoPayloadFolderPath $CargoPayloadFolderPath `
                                   -AdditionalWdpContentsFolderPath $AdditionalWdpContentsFolderPath `
                                   -ParameterXmlFolderPath $ParameterXmlFolderPath `
                                   -ConfigFilePath $ConfigFilePath `
                                   -Verbose