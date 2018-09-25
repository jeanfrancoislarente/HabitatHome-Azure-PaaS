$cake_config = Get-Content 'C:\Users\auzunov\Source\Repos\HabitatHome-Azure-PaaS\Azure PaaS\Cake\cake-config.json' -raw | ConvertFrom-Json
$deployemtId = $cake_config.AzureDeploymentID
$location = $cake_config.AzureGeoLocation
$sitecoreAdminPassword = $cake_config.SitecoreLoginAdminPassword
$licenseXml = $cake_config.SitecoreLicenseXMLPath
$sqlServerLogin = $cake_config.SqlServerLoginAdminAccount
$sqlServerPassword = $cake_config.SqlServerLoginAdminPassword
$authCertificatePassword = $cake_config.XConnectCertificatePassword

$azuredeploy_template = Get-Content 'C:\Users\auzunov\Downloads\ARM_deploy\!Deployment\Azure PaaS\Sitecore 9.0.2\Xp Single\azuredeploy.parameters.json' -raw | ConvertFrom-Json
$azuredeploy_template.parameters | % {
    $_.deploymentId.value = $deployemtId
    $_.location.value = $location
    $_.sitecoreAdminPassword.value = $sitecoreAdminPassword
    $_.licenseXml.value = $licenseXml
    $_.sqlServerLogin.value = $sqlServerLogin
    $_.sqlServerPassword.value = $sqlServerPassword
    $_.authCertificatePassword.value = $authCertificatePassword
}
$azuredeploy_template | ConvertTo-Json -Depth 20 | Set-Content 'C:\Users\auzunov\Downloads\ARM_deploy\!Deployment\Azure PaaS\Sitecore 9.0.2\Xp Single\azuredeploy.parameters - Copy.json'