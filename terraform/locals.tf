locals {
    name_prefix = "auth-check"
    location = "eastus2"
    common_tags = {
        Owner = "Pat Lafferty"
        Market = "Philadelphia"
        Manager = "Shanker Mageshwaran"
        Project = "InnovationLab"
    }

    arm_file_path = "../Azure/Auth-Notification-App.json"
    arm_params = {
        "logicAppName" = "Auth-Notification-LogicApp"
        "When_a_message_is_received_in_a_queue_(auto-complete)Frequency" = "Minute"
        "When_a_message_is_received_in_a_queue_(auto-complete)Interval" = 1
        "owner_Tag" = "patlaff728@gmail.com"
        "office365_name" = "office365"
        "office365_displayName" = "patlaff728@gmail.com"
        "servicebus_name" = "servicebus"
        "servicebus_displayName" = "Auth-Notification-Queue"
        "servicebus_namespace_name" = "Auth-Notification-Queue"
        "servicebus_resourceGroupName" = "Auth-Notification"
        "servicebus_accessKey_name" = "RootManageSharedAccessKey"
    }
}