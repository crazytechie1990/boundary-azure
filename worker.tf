resource "azurerm_virtual_machine" "hub_vm" {
  name                  = "hubVM"
  location              = azurerm_resource_group.hub_rg.location
  resource_group_name   = azurerm_resource_group.hub_rg.name
  network_interface_ids = [azurerm_network_interface.hub_vm_nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "myOsDisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "hubvm"
    admin_username = "adminuser"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

}

resource "azurerm_network_interface" "hub_vm_nic" {
  name                = "hubVMNic"
  location            = azurerm_resource_group.hub_rg.location
  resource_group_name = azurerm_resource_group.hub_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.hub_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.hub_vm_public_ip.id
  }
}