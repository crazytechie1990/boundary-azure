resource "azurerm_resource_group" "spoke_rg" {
  name     = "spokeResourceGroup"
  location = "East US"
}

resource "azurerm_virtual_network" "spoke_vnet" {
  name                = "spokeVNet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name
}

resource "azurerm_subnet" "spoke_vm_subnet" {
  name                 = "vmSubnet"
  resource_group_name  = azurerm_resource_group.spoke_rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "spoke_postgres_subnet" {
  name                 = "postgresSubnet"
  resource_group_name  = azurerm_resource_group.spoke_rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = ["10.1.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_network_security_group" "spoke_subnet_nsg" {
  name                = "spokeSubnetNSG"
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name

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
    name                       = "AllowAll3389"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
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

resource "azurerm_subnet_network_security_group_association" "spoke_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.spoke_vm_subnet.id
  network_security_group_id = azurerm_network_security_group.spoke_subnet_nsg.id
}

resource "azurerm_virtual_network_peering" "hub_to_spoke_peering" {
  name                      = "hubToSpokePeering"
  resource_group_name       = azurerm_resource_group.hub_rg.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub_peering" {
  name                      = "spokeToHubPeering"
  resource_group_name       = azurerm_resource_group.spoke_rg.name
  virtual_network_name      = azurerm_virtual_network.spoke_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_machine" "spoke_ubuntu_vm" {
  name                  = "spokeUbuntuVM"
  location              = azurerm_resource_group.spoke_rg.location
  resource_group_name   = azurerm_resource_group.spoke_rg.name
  network_interface_ids = [azurerm_network_interface.spoke_vm_nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "spokeOsDisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "spokeubuntuvm"
    admin_username = "adminuser"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_network_interface" "spoke_vm_nic" {
  name                = "spokeVMNic"
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke_vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "spoke_windows_vm" {
  name                  = "spokeWindowsVM"
  location              = azurerm_resource_group.spoke_rg.location
  resource_group_name   = azurerm_resource_group.spoke_rg.name
  network_interface_ids = [azurerm_network_interface.spoke_vm_nic1.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "spokeWindowsOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_profile {
    computer_name  = "spokewindowsvm"
    admin_username = "adminuser"
    admin_password = "Password1234!"
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }
}

resource "azurerm_network_interface" "spoke_vm_nic1" {
  name                = "spokeVMNic1"
  location            = azurerm_resource_group.spoke_rg.location
  resource_group_name = azurerm_resource_group.spoke_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke_vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# resource "azurerm_private_dns_zone" "example" {
#   name                = "example.postgres.database.azure.com"
#   resource_group_name = azurerm_resource_group.spoke_rg.name
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "example" {
#   name                  = "exampleVnetZone.com"
#   private_dns_zone_name = azurerm_private_dns_zone.example.name
#   virtual_network_id    = azurerm_virtual_network.spoke_vnet.id
#   resource_group_name = azurerm_resource_group.spoke_rg.name
# }

# resource "azurerm_postgresql_flexible_server" "example" {
#   name                   = "example-psqlflexibleserversac"
#   location            = azurerm_resource_group.spoke_rg.location
#   resource_group_name = azurerm_resource_group.spoke_rg.name
#   version                = "12"
#   delegated_subnet_id    = azurerm_subnet.spoke_postgres_subnet.id
#   private_dns_zone_id    = azurerm_private_dns_zone.example.id
#   administrator_login    = "psqladmin"
#   administrator_password = "H@Sh1CoR3!"
#   zone                   = "1"

#   storage_mb = 32768

#   sku_name   = "GP_Standard_D4s_v3"

# }
// https://developer.hashicorp.com/hcp/docs/boundary/self-managed-workers/install-self-managed-workers
// https://developer.hashicorp.com/boundary/tutorials/hcp-administration/hcp-ssh-cred-injection