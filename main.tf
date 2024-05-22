terraform{
  required_providers{
    azurerm={
      source="hashicorp/azurerm"
      version= ">=3.70.0" #this version is for azurerm, NOT terraform version
    }
  }
  required_version=">=1.4.0" #this version is for Terraform Version, NOT azurerm
}

provider "azurerm"{
  features {
    key_vault {
      purge_soft_deleted_keys_on_destroy = true
      recover_soft_deleted_keys          = true
    }
  }
  skip_provider_registration="true"
  
  subscription_id=var.subscription_id
  client_id=var.client_id
  client_secret=var.client_secret
  tenant_id=var.tenant_id
}

resource "azurerm_resource_group" "my_rg" {
  name     = "myResourceGroup"
  location = "CanadaCentral"
}

# This current work progress works, so revert to this if basic linux configuration works well.

# Resources for creating a linux virtual machine

resource "azurerm_virtual_network" "my_vnet" {
  name                = "myVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.my_rg.location
  resource_group_name = azurerm_resource_group.my_rg.name
}

resource "azurerm_subnet" "my_subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.my_rg.name
  virtual_network_name = azurerm_virtual_network.my_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "my_nic" {
  name                = "myNIC"
  location            = azurerm_resource_group.my_rg.location
  resource_group_name = azurerm_resource_group.my_rg.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.my_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "my_linux_vm" {
  for_each            = { for vm in local.vm_config : vm.name => vm }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.my_rg.name
  location            = azurerm_resource_group.my_rg.location
  size                = each.value.size
  admin_username      = each.value.admin_username
  network_interface_ids = [
    azurerm_network_interface.my_nic.id,
  ]

  admin_ssh_key {
    username   = each.value.admin_username
    public_key = each.value.ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  custom_data = base64decode(each.value.custom_data)
}

