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
    [string]$repoUri='https://github.com/MTCAtlanta/azure-virtual-machine-templates/tree/master/vmss-custom-win-iis/',
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


# Create a new Storage Account for the image
$parameters=@{"location"="$location";"newStorageAccountName"="$newStorageAccountName";"storageAccountType"="$newStorageAccountType"}
$templateUri="$repoUri$storageAccountTemplate"

New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri $templateUri -TemplateParameterObject $parameters -Name 'CreateStorageAccount'

# Copy the blob from the source to the new storage account

$destkey=(Get-AzureRmStorageAccountKey -Name $newStorageAccountName -ResourceGroupName $resourceGroupName).Key1