$args=@{
    'scalesetDNSPrefix'='vmss'+[System.Guid]::NewGuid().toString();
    'newStorageAccountName'=[System.Guid]::NewGuid().toString().Replace('-','').Substring(1,24);
    'resourceGroupName'='vmssrg01';
    'location'='eastus2';
    'scaleSetName'='windowscustom';
    'scaleSetVMSize'='Standard_D3';
    'newStorageAccountType'='Standard_LRS';
}

.\deployScaleSet.ps1 @args 