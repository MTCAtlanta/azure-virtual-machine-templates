$args=@{
    'scalesetDNSPrefix'='vmss'+[System.Guid]::NewGuid().toString();
###    'newStorageAccountName'=[System.Guid]::NewGuid().toString().Replace('-','').Substring(1,24);
    'newStorageAccountName'='d509a48cbb34c22bd85750e7';
    'resourceGroupName'='vmssrg01';
    'location'='eastus2';
    'scaleSetVMSize'='Standard_D3';
    'customImageStorageAccountName'='dxcustom';
    'customImageContainer'='vhds';
    'customImageBlobName'='2012R2Custom.vhd';
}

.\deployScaleSet.ps1 @args 