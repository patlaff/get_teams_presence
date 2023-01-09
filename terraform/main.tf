resource "azurerm_resource_group" "this" {
  name     = "${local.name_prefix}-rg"
  location = local.location
  tags     = local.common_tags
}

resource "azurerm_servicebus_namespace" "this" {
  name                = "${local.name_prefix}-sb"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_servicebus_queue" "this" {
  name         = "${local.name_prefix}-queue"
  namespace_id = azurerm_servicebus_namespace.this.id
  enable_partitioning = true
}

resource "azurerm_servicebus_queue_authorization_rule" "this" {
  name     = "${local.name_prefix}-queue-rule"
  queue_id = azurerm_servicebus_queue.this.id

  listen = true
  send   = true
  manage = true
}

// Create an instance of logic app and configure the tags
resource "azurerm_logic_app_workflow" "this" {
  name                = "${local.name_prefix}-la"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

// Deploy the ARM template to configure the workflow in the Logic App

data "template_file" "workflow" {
  template = file(local.arm_file_path)
}

// Deploy the ARM template workflow
resource "azurerm_template_deployment" "this" {
  depends_on = [azurerm_logic_app_workflow.this]

  resource_group_name = azurerm_resource_group.this.name
  parameters = merge({
    "workflowName" = azurerm_logic_app_workflow.this.name
    "location"     = azurerm_resource_group.this.location
  }, var.parameters)

  template_body = data.template_file.workflow.template
}