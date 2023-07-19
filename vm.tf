provider "azurerm" {
  version   = "3.65.0"
  features {}  
}

resource "azurerm_resource_group" "resourcegroup" {
  name     = "test-vm"
  location = "westus"
  tags = {
    project = "challange"
  }
}

resource "azurerm_virtual_network" "network" {
  name                = "${azurerm_resource_group.resourcegroup.name}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  tags                = azurerm_resource_group.resourcegroup.tags
}

resource "azurerm_subnet" "subnet" {
  name                 = "${azurerm_resource_group.resourcegroup.name}-subnet"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "publicip" {
  count               = 4
  name                = "${azurerm_resource_group.resourcegroup.name}-publicip-${count.index+1}"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic" {
  count                       = 4
  name                        = "vm${count.index+1}-NIC"
  location                    = azurerm_resource_group.resourcegroup.location
  resource_group_name         = azurerm_resource_group.resourcegroup.name

  ip_configuration {
    name                          = "vm${count.index+1}-NicConfiguration"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip[count.index].id
  }

  tags = azurerm_resource_group.resourcegroup.tags
}

resource "azurerm_virtual_machine" "vm" {
  count                 = 4
  name                  = "vm${count.index+1}"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  vm_size               = "Standard_B4ms"

  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  storage_os_disk {
    name              = "vm${count.index+1}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "vm${count.index+1}"
    admin_username = "demoadmin"
    admin_password = "$om3s3cretPassWord"
  }

  os_profile_windows_config {
    enable_automatic_upgrades = true
    provision_vm_agent        = true
  }

  tags = azurerm_resource_group.resourcegroup.tags
}
