$args=@{
    'scalesetDNSPrefix'='vmss'+[System.Guid]::NewGuid().toString();
    'newStorageAccountName'=[System.Guid]::NewGuid().toString().Replace('-','').Substring(1,24);
    'resourceGroupName'='vmsspocrg';
    'location'='eastus2';
    'scaleSetVMSize'='Standard_D3';
    'customImageStorageAccountName'='dxcustom';
    'customImageContainer'='vhds';
    'customImageBlobName'='2012R2Custom.vhd';
    'modulesUrl'='https://github.com/MTCAtlanta/azure-virtual-machine-templates/raw/master/vmss-custom-win-iis/ConfigureWebServer.ps1.zip';
    'webdeploypkg'='https://github.com/MTCAtlanta/azure-virtual-machine-templates/blob/master/vmss-custom-win-iis/WebApplication.zip';
}

.\deployScaleSet.ps1 @args 