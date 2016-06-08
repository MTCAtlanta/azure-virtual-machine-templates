param(
    [Parameter(Mandatory=$true)]
    [string]$location,
    [Parameter(Mandatory=$true)]
    [string]$resourceGroupName,
    [string]$customImageStorageAccountName='sdaviesarmne',
    [string]$customImageContainer='images',
    [string]$customImageBlobName='IISBase-osDisk.vhd',
    [Parameter(Mandatory=$true)]
    [string]$newStorageAccountName,
    [Parameter(Mandatory=$true)]
    [string]$newStorageAccountType,
    [string]$newImageContainer='images',
    [string]$newImageBlobName='IISBase-osDisk.vhd',
    [string]$repoUri='https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vmss-windows-customimage/',
    [string]$storageAccountTemplate='templates/storageaccount.json',
    [Parameter(Mandatory=$true)]
    [string]$scaleSetName,
    [int]$scaleSetInstanceCount=2,
    [Parameter(Mandatory=$true)]
    [string]$scaleSetVMSize,
    [Parameter(Mandatory=$true)]
    [string]$scaleSetDNSPrefix,
    [PSCredential]$scaleSetVMCredentials=(Get-Credential -Message 'Enter Credentials for new scale set VMs'),
    [string]$scaleSetTemplate='azuredeploy.json'
)

# Create Resource Group for Scale Set deployment in the target Region
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location


# Verify that Storage Account Name is Globally Unique
$newStorageAccountName=$newStorageAccountName.ToLowerInvariant()
if (-not (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $newStorageAccountName -ErrorAction SilentlyContinue))
{
    if (Test-AzureName -Storage -Name $newStorageAccountName -ErrorAction Stop)
    {
        throw "Storage Account Name is not Globally Unique. Please use a different Storage Account Name and try again."
    }
}


# Verify that Scale Set DNS Name is Globally Unique
$scaleSetDNSPrefix=$scaleSetDNSPrefix.ToLowerInvariant()
if (-not (Get-AzureRmPublicIpAddress  -ResourceGroupName $resourceGroupName | where Location -eq $location).DnsSettings.DomainNameLabel -eq  $scaleSetDNSPrefix)
{
    if (-not (Test-AzureRmDnsAvailability -DomainQualifiedName $scaleSetDNSPrefix -Location $location -ErrorAction Stop))
    {
        throw "Scale Set DNS Name is not Globally Unique. Please use a different Scale Set DNS Name and try again."
    }
}