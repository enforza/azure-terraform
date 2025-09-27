# Simple Single-AZ Enforza Gateway

This Terraform configuration creates a basic Azure networking setup with an Enforza server acting as a gateway/router for private subnets.

## Architecture

```
Internet
    |
    ├─ Public IP (Gateway)
    |
┌───▼────────────────────────────────────────────┐
│ VNet: 10.0.0.0/16                             │
│                                                │
│ ┌─────────────────┐  ┌──────────────────────┐  │
│ │ Public Subnet   │  │ Private Subnet 1     │  │
│ │ 10.0.1.0/24     │  │ 10.0.10.0/24         │  │
│ │                 │  │ (routes via gateway) │  │
│ │ ┌─────────────┐ │  │                      │  │
│ │ │Enforza Gateway│ │  └──────────────────────┘  │
│ │ │10.0.1.4     │ │                            │
│ │ │IP Forward:ON│ │  ┌──────────────────────┐  │
│ │ └─────────────┘ │  │ Private Subnet 2     │  │
│ └─────────────────┘  │ 10.0.20.0/24         │  │
│                      │ (routes via gateway) │  │
│                      └──────────────────────┘  │
└────────────────────────────────────────────────┘
```

## Components Created

### Network Infrastructure

- **VNet**: 10.0.0.0/16 address space
- **Public Subnet**: 10.0.1.0/24 (contains Enforza gateway)
- **Private Subnet 1**: 10.0.10.0/24 (routes via gateway)
- **Private Subnet 2**: 10.0.20.0/24 (routes via gateway)

### Enforza Gateway Server

- **VM**: Standard_B1s Enforza 22.04 LTS
- **Role**: Router/Gateway with IP forwarding enabled
- **IP**: Static 10.0.1.4 (private) + dynamic public IP
- **Security**: NSG with "permit any any" rules
- **Features**:
  - Enforza agent automatically installed
  - IP forwarding enabled at OS level
  - iptables NAT/masquerading configured
  - Routes traffic from private subnets to internet
  - Apache web server with status page

### Route Tables

- **Private Subnets**: Default route (0.0.0.0/0) → Gateway (10.0.1.4)
- **Internet Access**: Private subnet VMs route through gateway for outbound

## Quick Start

1. **Authenticate to Azure**:

   ```bash
   az login
   ```

2. **Configure variables**:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with:
   # - Your subscription ID
   # - Your Enforza company ID
   # - Authentication method (password or SSH key)
   ```

3. **Deploy**:

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Test gateway**:

   ```bash
   # SSH to gateway
   ssh azureuser@<gateway_public_ip>

   # Check IP forwarding
   cat /proc/sys/net/ipv4/ip_forward  # should be 1

   # View status page
   curl http://<gateway_public_ip>
   ```

## Authentication Options

Choose **ONE** method in `terraform.tfvars`:

### Option 1: Password Authentication

```hcl
admin_password = "YourSecurePassword123!"
```

### Option 2: SSH Key Authentication (Recommended)

```hcl
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E... your-key-here"
```

### Enforza Company ID

```hcl
enforza_companyId = "d4ff4171-cdaa-40f8-8663-748e22b15c7c"
```

## Usage Examples

### Deploy Private VMs (Optional)

After creating the gateway, you can deploy VMs in the private subnets. They will automatically route internet traffic through the gateway:

```hcl
# Example: Add to main.tf to create private VM
resource "azurerm_network_interface" "private_vm" {
  name                = "private-vm-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private_1.id  # or private_2
    private_ip_address_allocation = "Dynamic"
  }
}
```

### Monitor Traffic

SSH to the gateway and monitor routing:

```bash
# Watch traffic flowing through gateway
sudo tcpdump -i any -n host 10.0.10.0/24 or host 10.0.20.0/24

# Check routing table
ip route show

# View iptables NAT rules
sudo iptables -t nat -L
```

### Test Connectivity from Private VMs

```bash
# From a private subnet VM (once deployed)
curl ifconfig.me  # Should show gateway's public IP
ping 8.8.8.8      # Should work via gateway
```

## Cost Estimate

**Monthly cost: ~$25-35** (UK South region)

- Standard_B1s VM: ~$15-20/month
- Storage (Premium SSD): ~$5/month
- Public IP: ~$3/month
- Networking: ~$2-7/month

## Customization

### Change VM Size

```hcl
vm_size = "Standard_B2s"  # More powerful
vm_size = "Standard_B1ls" # Even cheaper (burstable)
```

### Modify Network Ranges

```hcl
vnet_address_space = ["192.168.0.0/16"]
public_subnet_prefix = "192.168.1.0/24"
private_subnet_1_prefix = "192.168.10.0/24"
private_subnet_2_prefix = "192.168.20.0/24"
```

### Advanced Gateway Features

The Enforza gateway can be enhanced with:

- **Firewall rules**: More restrictive iptables
- **VPN server**: OpenVPN or WireGuard
- **Traffic monitoring**: ntopng, Prometheus
- **Load balancing**: HAProxy for multiple backends

## Troubleshooting

### Gateway not routing traffic?

1. Check IP forwarding: `cat /proc/sys/net/ipv4/ip_forward` should be `1`
2. Verify iptables NAT: `sudo iptables -t nat -L`
3. Check route table: `az network route-table route list`

### Can't SSH to gateway?

1. Verify NSG rules allow SSH (should be "permit any any")
2. Check authentication method matches terraform.tfvars
3. Ensure public IP is assigned: `az network public-ip show`

### Private VMs can't reach internet?

1. Verify route table association with private subnets
2. Check gateway's NAT rules are active
3. Ensure VMs in private subnets have route to 0.0.0.0/0 via 10.0.1.4

## Security Note

This configuration uses "permit any any" NSG rules for simplicity. In production:

- Restrict SSH to specific source IPs
- Implement more granular firewall rules
- Consider Azure Bastion for secure access
- Use Key Vault for credentials

## Clean Up

```bash
terraform destroy
```

This will remove all created resources and stop billing.
