Connect-AzAccount

$account = (Get-AzContext).Account
$location = 'eastus'
$RG_Name = 'Auth-Notification'
$SB_Name = 'Auth-Notification-Queue'
$Queue_Name = 'authqueue' #this value cannot be changed
$LA_Template_Uri = 'https://raw.githubusercontent.com/patlaff/get_teams_presence/master/Azure/logicapp_template.json'
$param_file_path = ((Split-Path $invocation.MyCommand.Path) + '\Auth-Notification-App.parameters.json')

Get-AzResourceGroup `
    -Name $RG_Name `
    -ErrorVariable noRG `
    -ErrorAction SilentlyContinue

if ($noRG)
{
    New-AzResourceGroup `
        -Name $RG_Name `
        -Location $location
}
else
{
    Write-Host "Resource Group, $RG_Name, already exists"
}

$SB_Namespace = Get-AzServiceBusNamespace `
    -ResourceGroup $RG_Name `
    -NamespaceName $SB_Name `
    -ErrorVariable noSB `
    -ErrorAction SilentlyContinue

if ($noSB)
{
    $SB_Namespace = New-AzServiceBusNamespace `
        -ResourceGroupName $RG_Name `
        -Location $location `
        -Name $SB_Name
    New-AzServiceBusQueue -ResourceGroupName $RG_Name -Namespace $SB_Namespace.Name -Name $Queue_Name
    $newQueue = $TRUE
}
else
{
    Write-Host "Service Bus Namespace, $SB_Name, already exists in Resource Group, $RG_Name."
}

$SB_Queue = Get-AzServiceBusQueue -ResourceGroupName $RG_Name -Namespace $SB_Namespace.Name -Name $Queue_Name -ErrorVariable noQueue -ErrorAction SilentlyContinue

if ($noQueue)
{
    New-AzServiceBusQueue `
        -ResourceGroupName $RG_Name `
        -Namespace $SB_Namespace.Name `
        -Name $Queue_Name
    Write-Host "Service Bus Queue, $Queue_Name, created on Namespace, $SB_Name"
}
elseif ($newQueue)
{
    Write-Host "Service Bus Queue, $Queue_Name, created on Namespace, $SB_Name"
}
else
{
    Write-Host "Service Bus Queue, $Queue_Name, already exists on Namespace, $SB_Name, in Resource Group, $RG_Name."
}

$invocation = (Get-Variable MyInvocation).Value
$parameter_json = Get-Content -Raw -Path $param_file_path | ConvertFrom-Json
$parameter_json.parameters.owner_Tag.value = $account
$parameter_json.parameters.office365_displayName.value = $account
$parameter_json.parameters.servicebus_displayName.value = $SB_Name
$parameter_json.parameters.servicebus_namespace_name.value = $SB_Name
$parameter_json.parameters.servicebus_resourceGroupName.value = $RG_Name

$parameter_json | ConvertTo-Json | Set-Content $param_file_path

New-AzResourceGroupDeployment `
    -ResourceGroupName $RG_Name `
    -TemplateUri $LA_Template_Uri `
    -TemplateParameterFile $param_file_path