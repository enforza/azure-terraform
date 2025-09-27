# HA Multi-AZ Enforza Gateway# HA Multi-AZ Enforza Gateway

This Terraform configuration creates a highly available Azure networking setup with two Enforza gateway servers deployed across different Availability Zones, load-balanced for redundancy and high availability.This Terraform configuration creates a highly available Azure networking setup with two Enforza gateway servers deployed across different Availability Zones, load-balanced for redundancy and high availability.

## Architecture## Architecture

```

InternetInternet

    |    |

    ├─ Public IPs (Gateway 1 & 2)    ├─ Public IPs (Gateway 1 & 2)

    |    |

┌───▼────────────────────────────────────────────┐┌───▼────────────────────────────────────────────┐

│ VNet: 10.0.0.0/16                             ││ VNet: 10.0.0.0/16                             │

│                                                ││                                                │

│ ┌─────────────────────────────────────────────┐││ ┌─────────────────────────────────────────────┐│

│ │ Public Subnet: 10.0.1.0/24                 │││ │ Public Subnet: 10.0.1.0/24                 ││

│ │                                             │││ │                                             ││

│ │ ┌─────────────┐  ┌─────────────────────────┐│││ │ ┌─────────────┐  ┌─────────────────────────┐││

│ │ │Enforza GW 1 │  │    Load Balancer        ││││ │ │Gateway 1    │  │    Load Balancer        │││

│ │ │10.0.1.4     │  │    10.0.1.100           ││││ │ │10.0.1.4     │  │    10.0.1.100           │││

│ │ │AZ-1         │◄─┤    (Internal)          ││││ │ │AZ-1         │◄─┤    (Internal)          │││

│ │ └─────────────┘  │                         ││││ │ └─────────────┘  │                         │││

│ │                  │                         ││││ │                  │                         │││

│ │ ┌─────────────┐  │                         ││││ │ ┌─────────────┐  │                         │││

│ │ │Enforza GW 2 │  │                         ││││ │ │Gateway 2    │  │                         │││

│ │ │10.0.1.5     │◄─┤                         ││││ │ │10.0.1.5     │◄─┤                         │││

│ │ │AZ-2         │  └─────────────────────────┘│││ │ │AZ-2         │  └─────────────────────────┘││

│ │ └─────────────┘            ▲                │││ │ └─────────────┘            ▲                ││

│ └─────────────────────────────┼────────────────┘││ └─────────────────────────────┼────────────────┘│

│                               │                 ││                               │                 │

│ ┌──────────────────────┐      │                 ││ ┌──────────────────────┐      │                 │

│ │ Private Subnet 1     │      │                 ││ │ Private Subnet 1     │      │                 │

│ │ 10.0.10.0/24         │──────┘                 ││ │ 10.0.10.0/24         │──────┘                 │

│ │ (routes via LB)      │                        ││ │ (routes via LB)      │                        │

│ └──────────────────────┘                        ││ └──────────────────────┘                        │

│                                                 ││                                                 │

│ ┌──────────────────────┐                        ││ ┌──────────────────────┐                        │

│ │ Private Subnet 2     │                        ││ │ Private Subnet 2     │                        │

│ │ 10.0.20.0/24         │────────────────────────┘│ │ 10.0.20.0/24         │────────────────────────┘

│ │ (routes via LB)      │                         │ │ (routes via LB)      │

│ └──────────────────────┘                         │ └──────────────────────┘

└─────────────────────────────────────────────────┘└─────────────────────────────────────────────────┘

```

## Components Created│ │ │10.0.1.5 │◄─┤ ││││ └──────────────────────┘ │

### Network Infrastructure│ │ │AZ-2 │ └─────────────────────────┘││└────────────────────────────────────────────────┘

- **VNet**: 10.0.0.0/16 address space

- **Public Subnet**: 10.0.1.0/24 (contains both Enforza gateways and load balancer)│ │ └─────────────┘ ▲ ││```

- **Private Subnet 1**: 10.0.10.0/24 (routes via load balancer)

- **Private Subnet 2**: 10.0.20.0/24 (routes via load balancer)│ └─────────────────────────────┼────────────────┘│

### HA Enforza Gateway Setup│ │ │## Components Created

- **Gateway 1**: enforza-ha-gateway-1 (10.0.1.4) in AZ-1

- **Gateway 2**: enforza-ha-gateway-2 (10.0.1.5) in AZ-2│ ┌──────────────────────┐ │ │

- **VM Size**: Standard_B1s with Ubuntu 22.04 LTS (but configured as Enforza Gateway)

- **Public IPs**: Each gateway has its own public IP for management│ │ Private Subnet 1 │ │ │### Network Infrastructure

- **Security**: NSG with "permit any any" rules

- **Features**: Enforza agent automatically installed on both gateways│ │ 10.0.10.0/24 │──────┘ │

### High Availability Components│ │ (routes via LB) │ │- **VNet**: 10.0.0.0/16 address space

- **Internal Load Balancer**: 10.0.1.100 (distributes traffic between gateways)

- **Health Probes**: TCP port 22 health checks│ └──────────────────────┘ │- **Public Subnet**: 10.0.1.0/24 (contains Ubuntu gateway)

- **Backend Pool**: Both gateways in load balancer backend

- **Availability Zones**: Gateways distributed across first two AZs in region│ │- **Private Subnet 1**: 10.0.10.0/24 (routes via gateway)

### Route Tables│ ┌──────────────────────┐ │- **Private Subnet 2**: 10.0.20.0/24 (routes via gateway)

- **Private Subnets**: Default route (0.0.0.0/0) → Load Balancer (10.0.1.100)

- **Load Balancer**: Distributes traffic to healthy gateways│ │ Private Subnet 2 │ │

- **Internet Access**: Private subnet VMs route through HA gateway cluster

│ │ 10.0.20.0/24 │────────────────────────┘### Ubuntu Gateway Server

## Quick Start

│ │ (routes via LB) │

1. **Authenticate to Azure**:

   ````bash│ └──────────────────────┘                         - **VM**: Standard_B1s Ubuntu 22.04 LTS

   az login

   ```└─────────────────────────────────────────────────┘- **Role**: Router/Gateway with IP forwarding enabled

   ````

2. **Configure variables**:```- **IP**: Static 10.0.1.4 (private) + dynamic public IP

   ```bash

   cp terraform.tfvars.example terraform.tfvars- **Security**: NSG with "permit any any" rules

   # Edit terraform.tfvars with:

   # - Your subscription ID## Components Created- **Features**:

   # - Your Enforza company ID

   # - Authentication method (password or SSH key)  - Enforza agent automatically installed

   ```

### Network Infrastructure - IP forwarding enabled at OS level

3. **Deploy**:

   ````bash- **VNet**: 10.0.0.0/16 address space  - iptables NAT/masquerading configured

   terraform init

   terraform plan- **Public Subnet**: 10.0.1.0/24 (contains both gateways and load balancer)  - Routes traffic from private subnets to internet

   terraform apply

   ```- **Private Subnet 1**: 10.0.10.0/24 (routes via load balancer)  - Apache web server with status page

   ````

4. **Test HA gateways**:- **Private Subnet 2**: 10.0.20.0/24 (routes via load balancer)

   ````bash

   # SSH to gateway 1### Route Tables

   ssh azureuser@<gateway_1_public_ip>

   ### HA Gateway Setup

   # SSH to gateway 2

   ssh azureuser@<gateway_2_public_ip>- **Gateway 1**: enforza-ha-gateway-1 (10.0.1.4) in AZ-1- **Private Subnets**: Default route (0.0.0.0/0) → Gateway (10.0.1.4)



   # Check load balancer health- **Gateway 2**: enforza-ha-gateway-2 (10.0.1.5) in AZ-2- **Internet Access**: Private subnet VMs route through gateway for outbound

   az network lb show --resource-group enforza-ha-multi-az-gateway --name enforza-ha-gateway-lb

   ```- **VM Size**: Standard_B1s Ubuntu 22.04 LTS each
   ````

## Authentication Options- **Public IPs**: Each gateway has its own public IP for management## Quick Start

Choose **ONE** method in `terraform.tfvars`:- **Security**: NSG with "permit any any" rules

### Option 1: Password Authentication- **Features**: Enforza agent automatically installed on both gateways1. **Authenticate to Azure**:

```hcl

admin_password = "YourSecurePassword123!"

```

### High Availability Components ```bash

### Option 2: SSH Key Authentication (Recommended)

````hcl- **Internal Load Balancer**: 10.0.1.100 (distributes traffic between gateways)   az login

ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E... your-key-here"

```- **Health Probes**: TCP port 22 health checks   ```



### Enforza Company ID- **Backend Pool**: Both gateways in load balancer backend

```hcl

enforza_companyId = "d4ff4171-cdaa-40f8-8663-748e22b15c7c"- **Availability Zones**: Gateways distributed across first two AZs in region2. **Configure variables**:

````

## High Availability Features

### Route Tables ```bash

### Automatic Failover

- **Load Balancer Health Probes**: Continuously monitor gateway health- **Private Subnets**: Default route (0.0.0.0/0) → Load Balancer (10.0.1.100) cp terraform.tfvars.example terraform.tfvars

- **Traffic Distribution**: Healthy gateways automatically receive traffic

- **Zone Redundancy**: Gateways in separate AZs for zone-level failure protection- **Load Balancer**: Distributes traffic to healthy gateways # Edit terraform.tfvars with:

### Scaling and Resilience- **Internet Access**: Private subnet VMs route through HA gateway cluster # - Your subscription ID

- **Active-Active**: Both gateways handle traffic simultaneously

- **No Single Point of Failure**: Load balancer distributes across healthy nodes # - Your Enforza company ID

- **Zone Isolation**: AZ-1 failure doesn't affect AZ-2 gateway

## Quick Start # - Authentication method (password or SSH key)

## Cost Estimate

````

**Monthly cost: ~$60-80** (UK South region)

- 2x Standard_B1s VMs: ~$30-40/month1. **Authenticate to Azure**:

- Storage (Premium SSD): ~$10/month

- 2x Public IPs: ~$6/month   ```bash3. **Deploy**:

- Load Balancer Standard: ~$5/month

- Networking: ~$5-15/month   az login



*Still significantly cheaper than Azure Firewall (~$900/month)*   ```   ```bash



## Benefits Over Single Gateway   terraform init



✅ **High Availability**: No single point of failure  2. **Configure variables**:   terraform plan

✅ **Zone Redundancy**: Protection against AZ-level outages

✅ **Load Distribution**: Better performance under load     ```bash   terraform apply

✅ **Automatic Failover**: Seamless traffic redirection

✅ **Scalable**: Easy to add more gateways     cp terraform.tfvars.example terraform.tfvars   ```

✅ **Cost Effective**: Still ~90% cheaper than Azure Firewall

# Edit terraform.tfvars with:

## Troubleshooting

# - Your subscription ID4. **Test gateway**:

### Gateway HA Issues

1. **Check AZ availability**: `az vm list-skus --location uksouth --zone-details`   # - Your Enforza company ID

2. **Verify load balancer health**: All backend pool members should be healthy

3. **Test individual gateways**: SSH to each gateway and verify Enforza agent   # - Authentication method (password or SSH key)   ```bash



### Load Balancer Issues   ```   # SSH to gateway

1. **Check backend pool**: `az network lb address-pool show`

2. **Verify health probes**: Ensure gateways respond on probe port   ssh azureuser@<gateway_public_ip>

3. **Route table verification**: Confirm private subnets route to LB IP

3. **Deploy**:

### Private VMs can't reach internet?

1. **Verify route table association**: Private subnets → Load Balancer   ```bash   # Check IP forwarding

2. **Check gateway health**: Both gateways should be healthy in LB

3. **Enforza agent status**: Verify agents are running on both gateways   terraform init   cat /proc/sys/net/ipv4/ip_forward  # should be 1



## Key Points   terraform plan



- **Enforza Gateway**: The VMs become Enforza Gateways through the automatic agent installation   terraform apply   # View status page

- **Not Ubuntu Gateways**: While running on Ubuntu, they function as Enforza security appliances

- **Automatic Configuration**: All gateway functionality is handled by the Enforza agent   ```   curl http://<gateway_public_ip>

- **Zero Manual Setup**: No need to configure routing, iptables, or forwarding manually

````

## Clean Up

````bash4. **Test HA gateways**:

terraform destroy

```   ```bash## Authentication Options



This will remove all created resources and stop billing.   # SSH to gateway 1

   ssh azureuser@<gateway_1_public_ip>Choose **ONE** method in `terraform.tfvars`:



   # SSH to gateway 2  ### Option 1: Password Authentication

   ssh azureuser@<gateway_2_public_ip>

   ```hcl

   # Check load balancer healthadmin_password = "YourSecurePassword123!"

   az network lb show --resource-group enforza-ha-multi-az-gateway --name enforza-ha-gateway-lb```

````

### Option 2: SSH Key Authentication (Recommended)

## Authentication Options

```hcl

Choose **ONE** method in `terraform.tfvars`:ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E... your-key-here"

```

### Option 1: Password Authentication

```````hcl### Enforza Company ID

admin_password = "YourSecurePassword123!"

``````hcl

enforza_companyId = "d4ff4171-cdaa-40f8-8663-748e22b15c7c"

### Option 2: SSH Key Authentication (Recommended)```

```hcl

ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E... your-key-here"## Usage Examples

```````

### Deploy Private VMs (Optional)

### Enforza Company ID

```````hclAfter creating the gateway, you can deploy VMs in the private subnets. They will automatically route internet traffic through the gateway:

enforza_companyId = "d4ff4171-cdaa-40f8-8663-748e22b15c7c"

``````hcl

# Example: Add to main.tf to create private VM

## High Availability Featuresresource "azurerm_network_interface" "private_vm" {

  name                = "private-vm-nic"

### Automatic Failover  location            = azurerm_resource_group.main.location

- **Load Balancer Health Probes**: Continuously monitor gateway health  resource_group_name = azurerm_resource_group.main.name

- **Traffic Distribution**: Healthy gateways automatically receive traffic

- **Zone Redundancy**: Gateways in separate AZs for zone-level failure protection  ip_configuration {

    name                          = "internal"

### Scaling and Resilience    subnet_id                     = azurerm_subnet.private_1.id  # or private_2

- **Active-Active**: Both gateways handle traffic simultaneously    private_ip_address_allocation = "Dynamic"

- **No Single Point of Failure**: Load balancer distributes across healthy nodes  }

- **Zone Isolation**: AZ-1 failure doesn't affect AZ-2 gateway}

```````

## Cost Estimate

### Monitor Traffic

**Monthly cost: ~$60-80** (UK South region)

- 2x Standard_B1s VMs: ~$30-40/monthSSH to the gateway and monitor routing:

- Storage (Premium SSD): ~$10/month

- 2x Public IPs: ~$6/month```bash

- Load Balancer Standard: ~$5/month# Watch traffic flowing through gateway

- Networking: ~$5-15/monthsudo tcpdump -i any -n host 10.0.10.0/24 or host 10.0.20.0/24

_Still significantly cheaper than Azure Firewall (~$900/month)_# Check routing table

ip route show

## Benefits Over Single Gateway

# View iptables NAT rules

✅ **High Availability**: No single point of failure sudo iptables -t nat -L

✅ **Zone Redundancy**: Protection against AZ-level outages ```

✅ **Load Distribution**: Better performance under load

✅ **Automatic Failover**: Seamless traffic redirection ### Test Connectivity from Private VMs

✅ **Scalable**: Easy to add more gateways

✅ **Cost Effective**: Still ~90% cheaper than Azure Firewall```bash

# From a private subnet VM (once deployed)

## Troubleshootingcurl ifconfig.me # Should show gateway's public IP

ping 8.8.8.8 # Should work via gateway

### Gateway HA Issues```

1. **Check AZ availability**: `az vm list-skus --location uksouth --zone-details`

2. **Verify load balancer health**: All backend pool members should be healthy## Cost Estimate

3. **Test individual gateways**: SSH to each gateway and verify Enforza agent

**Monthly cost: ~$25-35** (UK South region)

### Load Balancer Issues

1. **Check backend pool**: `az network lb address-pool show`- Standard_B1s VM: ~$15-20/month

2. **Verify health probes**: Ensure gateways respond on probe port- Storage (Premium SSD): ~$5/month

3. **Route table verification**: Confirm private subnets route to LB IP- Public IP: ~$3/month

- Networking: ~$2-7/month

### Private VMs can't reach internet?

1. **Verify route table association**: Private subnets → Load Balancer## Customization

2. **Check gateway health**: Both gateways should be healthy in LB

3. **Enforza agent status**: Verify agents are running on both gateways### Change VM Size

## Clean Up```hcl

```bashvm_size = "Standard_B2s"  # More powerful

terraform destroyvm_size = "Standard_B1ls" # Even cheaper (burstable)

```

This will remove all created resources and stop billing.### Modify Network Ranges

```hcl
vnet_address_space = ["192.168.0.0/16"]
public_subnet_prefix = "192.168.1.0/24"
private_subnet_1_prefix = "192.168.10.0/24"
private_subnet_2_prefix = "192.168.20.0/24"
```

### Advanced Gateway Features

The Ubuntu gateway can be enhanced with:

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
