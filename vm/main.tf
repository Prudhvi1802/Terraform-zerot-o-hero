resource "azurerm_resource_group" "t-rg" {
  name     = var.resource_group_name
  location = var.location
  tags {
    environment = var.environment
    project     = var.project
  }
  
}
resource "azurerm_virtual_network" "t-vnet" {
  name                = var.vnet_name
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.t-rg.location
  resource_group_name = azurerm_resource_group.t-rg.name
  tags = {
    environment = var.environment
    project     = var.project
  }
  depends_on = [azurerm_resource_group.t-rg]
  
}

resource "azurerm_subnet" "t-subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.t-rg.name
  virtual_network_name = azurerm_virtual_network.t-vnet.name
  address_prefixes     = [var.subnet_address_prefix]
  depends_on = [ azurerm_virtual_network.t-vnet ]
}
resource "azurerm_network_interface" "t-nic" {
  name                = var.nic_name
  location            = azurerm_resource_group.t-rg.location
  resource_group_name = azurerm_resource_group.t-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.t-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = "azurerm_public_ip.t-pip.id"
  }
  tags = {
    environment = var.environment
    project     = var.project
  }
  depends_on = [azurerm_resource_group.t-rg]
}
resource "azurerm_public_ip" "t-pip" {
  name                = var.pip_name
  location            = azurerm_resource_group.t-rg.location
  resource_group_name = azurerm_resource_group.t-rg.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
  tags = {
    environment = var.environment
    project     = var.project
  }
  depends_on = [azurerm_resource_group.t-rg]
}
resource "azurerm_network_security_group" "t-nsg" {
  name                = var.nsg_name
  location            = azurerm_resource_group.t-rg.location
  resource_group_name = azurerm_resource_group.t-rg.name
  tags = {
    environment = var.environment
    project     = var.project
  }
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  depends_on = [azurerm_resource_group.t-rg]
}
resource "azurerm_network_interface_security_group_association" "t-nic-nsg-assoc" {
  network_interface_id      = azurerm_network_interface.t-nic.id
  network_security_group_id = azurerm_network_security_group.t-nsg.id
  depends_on = [azurerm_network_interface.t-nic, azurerm_network_security_group.t-nsg]
}
resource "azurerm_linux_virtual_machine" "t-vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.t-rg.name
  location            = azurerm_resource_group.t-rg.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.t-nic.id
  ]

   os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.vm_image_publisher
    offer     = var.vm_image_offer
    sku       = var.vm_image_sku
    version   = "latest"
  }
  tags = {
    environment = var.environment
    project     = var.project
  }
  depends_on = [azurerm_network_interface.t-nic, azurerm_network_interface_security_group_association.t-nic-nsg-assoc]
}
