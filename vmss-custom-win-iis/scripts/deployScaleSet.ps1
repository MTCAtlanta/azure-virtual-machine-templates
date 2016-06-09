#################################################################
########## Section: Define and modify input parameters ##########
#################################################################

param(
    [Parameter(Mandatory=$true)]
    [string]$scaleSetDNSPrefix,
    [Parameter(Mandatory=$true)]
    [string]$newStorageAccountName,
    [Parameter(Mandatory=$true)]
    [string]$resourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$location,
    [Parameter(Mandatory=$true)]
    [string]$scaleSetVMSize,
    [Parameter(Mandatory=$true)]
    [string]$customImageStorageAccountName,
    [Parameter(Mandatory=$true)]
    [string]$customImageContainer,
    [Parameter(Mandatory=$true)]
    [string]$customImageBlobName,
    [Parameter(Mandatory=$true)]
    [string]$modulesUrl,
    [Parameter(Mandatory=$true)]
    [string]$webdeploypkg,
    [string]$newStorageAccountType='Standard_LRS',
    [string]$newImageContainer='images',
    [string]$newImageBlobName='IISBase-osDisk.vhd',
    [string]$repoUri='https://raw.githubusercontent.com/MTCAtlanta/azure-virtual-machine-templates/master/vmss-custom-win-iis/',
    [string]$storageAccountTemplate='templates/storageaccount.json',
    [string]$scaleSetName='wincustom',
    [int]$scaleSetInstanceCount=2,
    [PSCredential]$scaleSetVMCredentials=(Get-Credential -Message 'Enter Credentials for new scale set VMs'),
    [string]$scaleSetTemplate='azuredeploy.json',
    [string]$SubName,
    [string]$virtualNetwork,
    [string]$subnet,
    [string]$vNetResourceGroup='vNetResourceGroup'
)


#################################################################
### Section: Query Admin for Information on Target Environment ##
#################################################################

# Prompt admin for the Subscription where the Scale Set will be deployed
$SubName =
(Get-AzureRmSubscription |
        Out-GridView `
        -Title "Select an Azure Subscription to deploy Scale Set (The Subscription must already contain the target virtual network) ..." `
        -PassThru).SubscriptionName 

# Prompt admin for the Virtual Network where the Scale Set will deploy
$virtualNetworkConfig =
(Get-AzureRmVirtualNetwork |  Select-Object -Property Name, Subnets, Location, ResourceGroupName |
        Out-GridView `
        -Title "Select the Virtual Network where the Scale Set will be deployed ..." `
        -PassThru)

$virtualNetwork = $virtualNetworkConfig.Name

$vNetResourceGroup = $virtualNetworkConfig.ResourceGroupName

# Prompt admin for the subnet where the Scale Set will deploy
$subnet =
($virtualNetworkConfig.Subnets |  Select-Object -Property Name, AddressPrefix |
        Out-GridView `
        -Title "Select the subnet in $virtualNetwork where the Scale Set will be deployed ..." `
        -PassThru).Name


#################################################################
## Section: Create Resources - Resource Group/Storage/Scale Set #
#################################################################

# Set Resource Group where Scale Set will be deployed (must already contain target virtual network)
Select-AzureRmSubscription -SubscriptionName $SubName

# Create or modify Resource Group for Scale Set deployment in the target Region
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

# Create a new Storage Account for the image and store Primary Key for copy operation
$parameters=@{"location"="$location";"newStorageAccountName"="$newStorageAccountName";"storageAccountType"="$newStorageAccountType"}
$templateUri="$repoUri$storageAccountTemplate"

New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri $templateUri -TemplateParameterObject $parameters -Name 'CreateStorageAccount'

$destkey=(Get-AzureRmStorageAccountKey -Name $newStorageAccountName -ResourceGroupName $resourceGroupName).Key1

# Copy the blob from the source storage account to the target storage account that was just created
$destcontext=New-AzureStorageContext -StorageAccountName $newStorageAccountName -StorageAccountKey $destkey -Protocol Https
$srccontext=New-AzureStorageContext -StorageAccountName $customImageStorageAccountName -Anonymous -Protocol Https

$destcontainer=Get-AzureStorageContainer -Context $destcontext -Name $newImageContainer -ErrorAction SilentlyContinue

if ($destcontainer -eq $null){
    New-AzureStorageContainer -Context $destcontext -Name $newImageContainer
}
    
Get-AzureStorageBlob -Container $customImageContainer -Context $srccontext -Blob $customImageBlobName | Start-CopyAzureStorageBlob -DestContext $destContext -DestContainer $newImageContainer -DestBlob $newImageBlobName -ErrorVariable $copyerror -ErrorAction Continue|Get-AzureStorageBlobCopyState -WaitForComplete


# Grab new image URI and deploy the scale set using the image as the source
$sourceImageVhdUri=(Get-AzureStorageBlob -Container $newImageContainer -Context $destContext -Blob $newImageBlobName).ICloudBlob.StorageUri.PrimaryUri.AbsoluteUri

$parameters=@{"vmSSName"="$scaleSetName";"instanceCount"=$scaleSetInstanceCount;"vmSize"="$scaleSetVMSize";"dnsNamePrefix"="$scaleSetDNSPrefix";"adminUsername"=$scaleSetVMCredentials.UserName;"adminPassword"=$scaleSetVMCredentials.GetNetworkCredential().Password;"virtualNetwork"=$virtualNetwork;"subnet"=$subnet;"vNetResourceGroup"=$vnetResourceGroup;"location"="$location";"sourceImageVhdUri"="$sourceImageVhdUri";"modulesUrl"="$modulesURL";"webdeploypkg"="$webdeploypkg"}
$templateUri="$repoUri$scaleSetTemplate"

New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri $templateUri -TemplateParameterObject $parameters -Name 'CreateScaleSet'