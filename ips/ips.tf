# Configure the Microsoft Azure Provider
provider "azurerm" {
    subscription_id = "XX"
    client_id       = "XX"
    client_secret   = "XX"
    tenant_id       = "XX"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "group" {
    name     = "IPSApps"
    location = "UK West"

    tags {
        environment = "Web App Test"
    }
}

# Create an App Service Plan with Linux
resource "azurerm_app_service_plan" "appserviceplan" {
  name                = "${azurerm_resource_group.group.name}-plan"
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"

  # Define Linux as Host OS
  kind = "Linux"

  # Choose size
  sku {
    tier = "Standard"
    size = "S1"
  }

  properties {
    reserved = true # Mandatory for Linux plans
  }
}

# Create an Azure Web App for Containers in that App Service Plan
resource "azurerm_app_service" "ipsAPI" {
  name                = "${azurerm_resource_group.group.name}-ipsAPI"
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  app_service_plan_id = "${azurerm_app_service_plan.appserviceplan.id}"

  # Do not attach Storage by default
  app_settings {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    WEBSITES_PORT = 5000

    
    # Settings for private Container Registires  
    DOCKER_REGISTRY_SERVER_URL      = "https://ipsapps.azurecr.io"
    DOCKER_CUSTOM_IMAGE_NAME        = "ipsapps.azurecr.io/onsdigital/ips_db_api:31",
    DOCKER_REGISTRY_SERVER_USERNAME = "INSERTUSER"
    DOCKER_REGISTRY_SERVER_PASSWORD = "INSERTPASS"
    
  }
    /*
  # Configure Docker Image to load on start
  site_config {
    linux_fx_version = "DOCKER|appsvcsample/static-site:latest"
    always_on        = "true"
  }
  */

  identity {
    type = "SystemAssigned"
  }
}

# Create an Azure Web App for Containers in that App Service Plan
resource "azurerm_app_service" "ipsAPI" {
  name                = "${azurerm_resource_group.group.name}-ipsAPI"
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  app_service_plan_id = "${azurerm_app_service_plan.appserviceplan.id}"

  # Do not attach Storage by default
  app_settings {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    WEBSITES_PORT = 5000

    
    # Settings for private Container Registires  
    DOCKER_REGISTRY_SERVER_URL      = ""
    DOCKER_REGISTRY_SERVER_USERNAME = ""
    DOCKER_REGISTRY_SERVER_PASSWORD = ""
    
  }
    /*
  # Configure Docker Image to load on start
  site_config {
    linux_fx_version = "DOCKER|appsvcsample/static-site:latest"
    always_on        = "true"
  }
  */

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_mysql_server" "test" {
  name                = "ipsdb"
  location            = "${azurerm_resource_group.group.location}"
  resource_group_name = "${azurerm_resource_group.group.name}"

  sku {
    name     = "B_Gen5_1"
    capacity = 1
    tier     = "Basic"
    family   = "Gen5"
  }

  storage_profile {
    storage_mb            = 5120
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
  }

  administrator_login          = "INSERTUSER"
  administrator_login_password = "INSERTPASS"
  version                      = "5.7"
  ssl_enforcement              = "Disabled"
}

resource "azurerm_mysql_database" "db" {
  name                = "ips"
  resource_group_name = "${azurerm_resource_group.group.name}"
  server_name         = "${azurerm_mysql_server.test.name}"
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

resource "azurerm_mysql_firewall_rule" "test" {
  name                = "AllowAll"
  resource_group_name = "${azurerm_resource_group.group.name}"
  server_name         = "${azurerm_mysql_server.test.name}"
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}
