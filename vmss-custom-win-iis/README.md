### Deploy a VM Scale Set based on a Windows Custom Image and configure website via DCS Template ###

This template deploys a VM Scale Set from a user provided Windows Custom Image

The template allows a URL to a custom image to be provided as a parameter at run time. The custom image should be contained in a storage account which is in the same location as the VM Scale Set is created in, in addtion the storage account which contains the image should also be under the same subscription that the scale set is being created in.

In addtion to the scale set the template creates a public IP address and load balances HTTP traffic on port 80 to each VM in the scale set. The load balancer can be customised by parameters passed to the template.

Alternatively, admins can download PowerShell scripts located in the 'scripts' folder which will use a source custom image, this script will create a new resource group and storage account, copy the source custom image from a storage container with access policy set to "Blob" then deploy the tempate using the newly created demo instance.  Use this script as follows:

```
.\run-deployScaleSet.ps1

```
The run-deployScaleSet.ps1 script has a common set of parameters that can be modified prior to runtime without impacting the target deployScaleSet.ps1 script. 

The sample Windows Custom Image is based on Windows Server 2012 R2. 

As part of the Scale Set deployment, a sample DSC template is run which installs IIS settings and deploys a sample web application. The web application location and DSC template location can both be modified as input parameters. By default this application is exposed on port 80

**Note: This image may not have all the latest windows updates applied to it**

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FMTCAtlanta%2Fazure-virtual-machine-templates%2Fmaster%2Fvmss-custom-win-iis%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

