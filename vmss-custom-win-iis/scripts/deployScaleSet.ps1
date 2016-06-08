#################################################################
########## Section: Define and modify input parameters ##########
#################################################################

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
    [string]$newStorageAccountType='Standard_LRS',
    [string]$newImageContainer='images',
    [string]$newImageBlobName='IISBase-osDisk.vhd',
    [string]$repoUri='https://raw.githubusercontent.com/MTCAtlanta/azure-virtual-machine-templates/master/vmss-custom-win-iis/',
    [string]$storageAccountTemplate='templates/storageaccount.json',
    [string]$scaleSetName='wincustom',
    [int]$scaleSetInstanceCount=2,
    [Parameter(Mandatory=$true)]
    [string]$scaleSetVMSize,
    [Parameter(Mandatory=$true)]
    [string]$scaleSetDNSPrefix,
    [PSCredential]$scaleSetVMCredentials=(Get-Credential -Message 'Enter Credentials for new scale set VMs'),
    [string]$scaleSetTemplate='azuredeploy.json'
)


#################################################################
#### Section: Pre-execution validation steps in this section ####
#################################################################

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


#################################################################
## Section: Create Resources - Resource Group/Storage/Scale Set #
#################################################################


# Create or modify Resource Group for Scale Set deployment in the target Region
###New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

# Create a new Storage Account for the image and store Primary Key for copy operation
$parameters=@{"location"="$location";"newStorageAccountName"="$newStorageAccountName";"storageAccountType"="$newStorageAccountType"}
$templateUri="$repoUri$storageAccountTemplate"

###New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri $templateUri -TemplateParameterObject $parameters -Name 'CreateStorageAccount'

$destkey=(Get-AzureRmStorageAccountKey -Name $newStorageAccountName -ResourceGroupName $resourceGroupName).Key1

# Copy the blob from the source storage account to the target storage account that was just created
$destcontext=New-AzureStorageContext -StorageAccountName $newStorageAccountName -StorageAccountKey $destkey -Protocol Https
$srccontext=New-AzureStorageContext -StorageAccountName $customImageStorageAccountName -Anonymous -Protocol Https

$destcontainer=Get-AzureStorageContainer -Context $destcontext -Name $newImageContainer -ErrorAction SilentlyContinue

if ($destcontainer -eq $null){
    New-AzureStorageContainer -Context $destcontext -Name $newImageContainer
}
    
###Get-AzureStorageBlob -Container $customImageContainer -Context $srccontext -Blob $customImageBlobName | Start-CopyAzureStorageBlob -DestContext $destContext -DestContainer $newImageContainer -DestBlob $newImageBlobName -ErrorVariable $copyerror -ErrorAction Continue|Get-AzureStorageBlobCopyState -WaitForComplete


# Grab new image URI and deploy the scale set using the image as the source
$sourceImageVhdUri=(Get-AzureStorageBlob -Container $newImageContainer -Context $destContext -Blob $newImageBlobName).ICloudBlob.StorageUri.PrimaryUri.AbsoluteUri

$sourceImageVhdUri

###$parameters=@{"vmSSName"="$scaleSetName";"instanceCount"=$scaleSetInstanceCount;"vmSize"="$scaleSetVMSize";"dnsNamePrefix"="$scaleSetDNSPrefix";"adminUsername"=$scaleSetVMCredentials.UserName;"adminPassword"=$scaleSetVMCredentials.GetNetworkCredential().Password;"location"="$location";"sourceImageVhdUri"="$sourceImageVhdUri"}
###$templateUri="$repoUri$scaleSetTemplate"

###New-AzureResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri $templateUri -TemplateParameterObject $parameters -Name 'createscaleset'