resource "azurerm_resource_group" "hub_rg" {
  name     = "hubResourceGroup"
  location = "East US"
}

resource "azurerm_virtual_network" "hub_vnet" {
  name                = "hubVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
}

resource "azurerm_subnet" "hub_subnet" {
  name                 = "hubSubnet"
  resource_group_name  = azurerm_resource_group.hub_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

// Additional subnet for Application Gateway
# resource "azurerm_subnet" "hub_appgw_subnet" {
#   name                 = "hubAppGwSubnet"
#   resource_group_name  = azurerm_resource_group.hub_rg.name
#   virtual_network_name = azurerm_virtual_network.hub_vnet.name
#   address_prefixes     = ["10.0.2.0/24"]
# }

resource "azurerm_network_security_group" "hub_subnet_nsg" {
  name                = "hubSubnetNSG"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAll9202"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9202"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

   security_rule {
    name                       = "AllowAll80"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "hub_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.hub_subnet.id
  network_security_group_id = azurerm_network_security_group.hub_subnet_nsg.id
}

resource "azurerm_public_ip" "hub_vm_public_ip" {
  name                = "hubVMPublicIp"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name
  allocation_method   = "Dynamic"
}

# resource "azurerm_public_ip" "hub_appgw_public_ip" {
#   name                = "hubAppGwPublicIp"
#   location            = azurerm_resource_group.hub_rg.location
#   resource_group_name = azurerm_resource_group.hub_rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# resource "azurerm_application_gateway" "hub_appgw" {
#   name                = "hubAppGw"
#   location            = azurerm_resource_group.hub_rg.location
#   resource_group_name = azurerm_resource_group.hub_rg.name

#   sku {
#     name     = "Standard_v2"
#     tier     = "Standard_v2"
#     capacity = 2
#   }

#   gateway_ip_configuration {
#     name      = "appGwIpConfig"
#     subnet_id = azurerm_subnet.hub_appgw_subnet.id
#   }

#   frontend_port {
#     name = "httpPort"
#     port = 80
#   }

#   frontend_ip_configuration {
#     name                 = "appGwFrontendIp"
#     public_ip_address_id = azurerm_public_ip.hub_appgw_public_ip.id
#   }

#   backend_address_pool {
#     name = "appGwBackendPool"
#     ip_addresses = ["${azurerm_public_ip.hub_vm_public_ip.ip_address}"]
#   }

#   backend_http_settings {
#     name                  = "appGwBackendHttpSettings"
#     cookie_based_affinity = "Disabled"
#     path                  = "/"
#     port                  = 80
#     protocol              = "Http"
#     request_timeout       = 20
#   }

#   http_listener {
#     name                           = "appGwHttpListener"
#     frontend_ip_configuration_name = "appGwFrontendIp"
#     frontend_port_name             = "httpPort"
#     protocol                       = "Http"
#     host_name                      = "boundary.sachin.org.uk"
#   }

#   request_routing_rule {
#     name                       = "appGwRule1"
#     priority = 1
#     rule_type                  = "Basic"
#     http_listener_name         = "appGwHttpListener"
#     backend_address_pool_name  = "appGwBackendPool"
#     backend_http_settings_name = "appGwBackendHttpSettings"
#   }
# }