# HA Multi-AZ Enforza Gateway with External DNAT Load Balancer# HA Multi-AZ Enforza Gateway with External DNAT Load Balancer# HA Multi-AZ Enforza Gateway# HA Multi-AZ Enforza Gateway

This Terraform configuration deploys a **high availability Enforza Gateway solution** with both **internal load balancing** for private subnet routing and an **internet-facing load balancer** with DNS name for external access. The Enforza gateways handle all DNAT functionality.

## 🏗️ Architecture OverviewThis Terraform configuration deploys a **high availability Enforza Gateway solution** with both **internal load balancing** for private subnet routing and an **internet-facing load balancer** with DNS name for external access and DNAT functionality.This Terraform configuration creates a highly available Azure networking setup with two Enforza gateway servers deployed across different Availability Zones, load-balanced for redundancy and high availability.This Terraform configuration creates a highly available Azure networking setup with two Enforza gateway servers deployed across different Availability Zones, load-balanced for redundancy and high availability.

- **2 Enforza Gateways** deployed across Azure availability zones 1 & 2

- **Internal Load Balancer** (10.0.1.100) for private subnet routing

- **External Load Balancer** with public IP and DNS name for internet access## 🏗️ Architecture Overview## Architecture## Architecture

- **Dual load balancer setup**: Both forward ALL traffic to gateways (protocol = "All")

## 🌐 Network Design

- **2 Enforza Gateways** deployed across Azure availability zones 1 & 2```

```

Internet- **Internal Load Balancer** (10.0.1.100) for private subnet routing

    ↓

[External LB] ← Public IP + DNS Name- **External Load Balancer** with public IP and DNS name for internet accessInternetInternet

    ↓ Forward ALL Traffic

[Gateway-1 AZ1] ← [Gateway-2 AZ2] ← Enforza handles DNAT- **Dual load balancer setup**: Internal for routing + External for DNAT/DNS

    ↓ Internal routing

[Internal LB] ← 10.0.1.100    |    |

    ↓ Route private traffic

[Private Subnet 1] + [Private Subnet 2]## 🌐 Network Design

```

    ├─ Public IPs (Gateway 1 & 2)    ├─ Public IPs (Gateway 1 & 2)

### Subnets

- **Public Subnet**: `10.0.1.0/24` (contains gateways and internal LB)```

- **Private Subnet 1**: `10.0.10.0/24` (routes via internal LB)

- **Private Subnet 2**: `10.0.20.0/24` (routes via internal LB)Internet | |

### Load Balancer Configuration ↓

#### Internal Load Balancer (10.0.1.100)[External LB] ← Public IP + DNS Name┌───▼────────────────────────────────────────────┐┌───▼────────────────────────────────────────────┐

- **Purpose**: Routes traffic from private subnets to healthy gateways

- **Protocol**: All traffic (protocol = "All", port = 0) ↓ Load Balance

- **Health Probe**: TCP/22 to gateways

[Gateway-1 AZ1] ← [Gateway-2 AZ2]│ VNet: 10.0.0.0/16 ││ VNet: 10.0.0.0/16 │

#### External Load Balancer (Public IP + DNS)

- **Purpose**: Provides internet access with DNS name and forwards all traffic to gateways ↓ Internal routing

- **Protocol**: All traffic (protocol = "All", port = 0) - same as internal LB

- **Health Probe**: TCP/22 to gateways[Internal LB] ← 10.0.1.100│ ││ │

- **DNS**: Automatic FQDN assignment for easy access

- **DNAT**: Enforza gateways handle all DNAT functionality ↓ Route private traffic

## 💰 Cost Estimate[Private Subnet 1] + [Private Subnet 2]│ ┌─────────────────────────────────────────────┐││ ┌─────────────────────────────────────────────┐│

Approximately **$80-100/month** vs ~$900/month for Azure Firewall:```

- 2x Standard_B1s VMs: ~$30/month each

- 2x Load Balancers: ~$20/month each │ │ Public Subnet: 10.0.1.0/24 │││ │ Public Subnet: 10.0.1.0/24 ││

- Public IPs, storage, networking: ~$10/month

### Subnets

## 🚀 Deployment Instructions

- **Public Subnet**: `10.0.1.0/24` (contains gateways and internal LB)│ │ │││ │ ││

### 1. Prerequisites

- Azure CLI installed and authenticated- **Private Subnet 1**: `10.0.10.0/24` (routes via internal LB)

- Terraform installed (>= 1.0)

- Azure subscription with appropriate permissions- **Private Subnet 2**: `10.0.20.0/24` (routes via internal LB)│ │ ┌─────────────┐ ┌─────────────────────────┐│││ │ ┌─────────────┐ ┌─────────────────────────┐││

### 2. Authentication

```bash

# Login to Azure### Load Balancer Configuration│ │ │Enforza GW 1 │  │    Load Balancer        ││││ │ │Gateway 1    │  │    Load Balancer        │││

az login



# Set subscription

az account set --subscription "your-subscription-id"#### Internal Load Balancer (10.0.1.100)│ │ │10.0.1.4     │  │    10.0.1.100           ││││ │ │10.0.1.4     │  │    10.0.1.100           │││

```

- **Purpose**: Routes traffic from private subnets to healthy gateways

### 3. Configuration

````bash- **Protocol**: All traffic (protocol = "All", port = 0)│ │ │AZ-1         │◄─┤    (Internal)          ││││ │ │AZ-1         │◄─┤    (Internal)          │││

# Copy and customize the configuration

cp terraform.tfvars.example terraform.tfvars- **Health Probe**: TCP/22 to gateways

nano terraform.tfvars

```│ │ └─────────────┘  │                         ││││ │ └─────────────┘  │                         │││



**Required variables:**#### External Load Balancer (Public IP + DNS)

- `subscription_id`: Your Azure subscription ID

- `enforza_companyId`: Your Enforza company ID from the portal- **Purpose**: Provides internet access with DNS name and port mapping│ │                  │                         ││││ │                  │                         │││

- `admin_password` OR `ssh_public_key`: Choose one authentication method

- **Ports**: HTTP(80), HTTPS(443), DNS(53), SSH(2222→22)

### 4. Deploy

```bash- **Health Probe**: TCP/22 to gateways│ │ ┌─────────────┐  │                         ││││ │ ┌─────────────┐  │                         │││

# Initialize Terraform

terraform init- **DNS**: Automatic FQDN assignment for easy access



# Review the plan│ │ │Enforza GW 2 │  │                         ││││ │ │Gateway 2    │  │                         │││

terraform plan

## 💰 Cost Estimate

# Deploy the infrastructure

terraform apply│ │ │10.0.1.5     │◄─┤                         ││││ │ │10.0.1.5     │◄─┤                         │││

````

Approximately **$80-100/month** vs ~$900/month for Azure Firewall:

## 🔑 Access Methods

- 2x Standard_B1s VMs: ~$30/month each│ │ │AZ-2 │ └─────────────────────────┘│││ │ │AZ-2 │ └─────────────────────────┘││

After deployment, you'll have multiple access options:

- 2x Load Balancers: ~$20/month each

### SSH Access

````bash- Public IPs, storage, networking: ~$10/month│ │ └─────────────┘            ▲                │││ │ └─────────────┘            ▲                ││

# Direct access to gateways (recommended for management)

ssh azureuser@<gateway-1-public-ip>

ssh azureuser@<gateway-2-public-ip>

```## 🚀 Deployment Instructions│ └─────────────────────────────┼────────────────┘││ └─────────────────────────────┼────────────────┘│



### External Access via DNS

The external load balancer provides a DNS name like:

`enforza-ha-gw-<random>.uksouth.cloudapp.azure.com`### 1. Prerequisites│                               │                 ││                               │                 │



**All traffic forwarded to gateways:**- Azure CLI installed and authenticated

- External LB forwards ALL protocols and ports to healthy gateways

- Enforza gateways handle DNAT, port mapping, and traffic processing- Terraform installed (>= 1.0)│ ┌──────────────────────┐      │                 ││ ┌──────────────────────┐      │                 │

- No port restrictions - full transparent forwarding

- Azure subscription with appropriate permissions

## 📊 Key Features

│ │ Private Subnet 1     │      │                 ││ │ Private Subnet 1     │      │                 │

### High Availability

- **Multi-AZ**: Gateways spread across availability zones### 2. Authentication

- **Health Probes**: Automatic failover for unhealthy gateways

- **Load Balancing**: Traffic distributed across healthy instances```bash│ │ 10.0.10.0/24         │──────┘                 ││ │ 10.0.10.0/24         │──────┘                 │



### Network Routing# Login to Azure

- **Private Subnets**: Route all traffic via internal LB (10.0.1.100)

- **Internet Access**: External LB provides public access point with DNS nameaz login│ │ (routes via LB)      │                        ││ │ (routes via LB)      │                        │

- **IP Forwarding**: Enabled on gateway NICs for proper routing

- **Full Transparency**: Both load balancers forward all traffic (protocol = "All")



### Security & DNAT# Set subscription│ └──────────────────────┘                        ││ └──────────────────────┘                        │

- **Enforza DNAT**: Gateways handle all DNAT, port mapping, and traffic processing

- **NSG**: Permissive rules on gateways (Enforza agent handles security)az account set --subscription "your-subscription-id"

- **Enforza Agent**: Automatically installed and configured

- **Multiple Auth**: Support for password or SSH key authentication```│                                                 ││                                                 │



## 🛠️ Customization Options



### VM Sizing### 3. Configuration│ ┌──────────────────────┐                        ││ ┌──────────────────────┐                        │

```hcl

vm_size = "Standard_B2s"  # Upgrade for more performance```bash

````

# Copy and customize the configuration│ │ Private Subnet 2 │ ││ │ Private Subnet 2 │ │

### Network Configuration

````hclcp terraform.tfvars.example terraform.tfvars

vnet_address_space = ["172.16.0.0/16"]

public_subnet_prefix = "172.16.1.0/24"nano terraform.tfvars│ │ 10.0.20.0/24         │────────────────────────┘│ │ 10.0.20.0/24         │────────────────────────┘

private_subnet_1_prefix = "172.16.10.0/24"

private_subnet_2_prefix = "172.16.20.0/24"```

````

│ │ (routes via LB) │ │ │ (routes via LB) │

### Geographic Region

`````hcl**Required variables:**

location = "eastus2"  # Change deployment region

```- `subscription_id`: Your Azure subscription ID│ └──────────────────────┘                         │ └──────────────────────┘



## 📋 Outputs- `enforza_companyId`: Your Enforza company ID from the portal



The deployment provides comprehensive outputs:- `admin_password` OR `ssh_public_key`: Choose one authentication method└─────────────────────────────────────────────────┘└─────────────────────────────────────────────────┘



- **Gateway IPs**: Public and private addresses of both gateways

- **Load Balancer Info**: Both internal and external LB details

- **DNS Information**: External LB FQDN and IP### 4. Deploy```

- **Connection Details**: SSH commands and access methods

- **Network Summary**: Complete network configuration overview```bash



## 🔧 Use Cases# Initialize Terraform## Components Created│ │ │10.0.1.5 │◄─┤ ││││ └──────────────────────┘ │



### Perfect For:terraform init

- **DNS Services**: External LB provides stable DNS name

- **Full DNAT**: Enforza gateways handle all port mapping and traffic processing### Network Infrastructure│ │ │AZ-2 │ └─────────────────────────┘││└────────────────────────────────────────────────┘

- **High Availability**: Multi-AZ deployment with automatic failover

- **Cost Savings**: Significant cost reduction vs Azure Firewall# Review the plan

- **Hybrid Access**: Both private routing and internet accessibility

- **Transparent Forwarding**: No port restrictions on external accessterraform plan- **VNet**: 10.0.0.0/16 address space



### Example Usage:

- Point DNS records to the external LB FQDN

- Route private subnet traffic through internal LB# Deploy the infrastructure- **Public Subnet**: 10.0.1.0/24 (contains both Enforza gateways and load balancer)│ │ └─────────────┘ ▲ ││```

- Access any service/port via external LB (gateways handle DNAT)

- SSH management via individual gateway public IPsterraform apply



## 🚨 Important Notes```- **Private Subnet 1**: 10.0.10.0/24 (routes via load balancer)



1. **Enforza Handles DNAT**: Gateways process all DNAT, port mapping, and traffic rules

2. **Full Traffic Forwarding**: Both load balancers use protocol="All" for complete transparency

3. **Health Monitoring**: Both load balancers monitor gateway health via TCP/22## 🔑 Access Methods- **Private Subnet 2**: 10.0.20.0/24 (routes via load balancer)│ └─────────────────────────────┼────────────────┘│

4. **Cost Efficiency**: ~90% cost reduction compared to Azure Firewall

5. **DNS Stability**: External LB FQDN provides stable endpoint for DNS records

6. **No Port Restrictions**: External LB forwards all traffic to gateways for processing

After deployment, you'll have multiple access options:### HA Enforza Gateway Setup│ │ │## Components Created

## 📞 Support



For Enforza-specific configuration and DNAT setup, refer to your Enforza portal and documentation.
### SSH Access- **Gateway 1**: enforza-ha-gateway-1 (10.0.1.4) in AZ-1

```bash

# Direct access to gateways- **Gateway 2**: enforza-ha-gateway-2 (10.0.1.5) in AZ-2│ ┌──────────────────────┐ │ │

ssh azureuser@<gateway-1-public-ip>

ssh azureuser@<gateway-2-public-ip>- **VM Size**: Standard_B1s with Ubuntu 22.04 LTS (but configured as Enforza Gateway)



# Via External Load Balancer DNS name (port 2222)- **Public IPs**: Each gateway has its own public IP for management│ │ Private Subnet 1 │ │ │### Network Infrastructure

ssh -p 2222 azureuser@<external-lb-fqdn>

```- **Security**: NSG with "permit any any" rules



### DNS/DNAT Access- **Features**: Enforza agent automatically installed on both gateways│ │ 10.0.10.0/24 │──────┘ │

The external load balancer provides a DNS name like:

`enforza-ha-gw-<random>.uksouth.cloudapp.azure.com`### High Availability Components│ │ (routes via LB) │ │- **VNet**: 10.0.0.0/16 address space



**Load balanced ports:**- **Internal Load Balancer**: 10.0.1.100 (distributes traffic between gateways)

- **HTTP**: Port 80 → gateways

- **HTTPS**: Port 443 → gateways  - **Health Probes**: TCP port 22 health checks│ └──────────────────────┘ │- **Public Subnet**: 10.0.1.0/24 (contains Ubuntu gateway)

- **DNS**: Port 53 → gateways

- **SSH**: Port 2222 → gateway port 22- **Backend Pool**: Both gateways in load balancer backend



## 📊 Key Features- **Availability Zones**: Gateways distributed across first two AZs in region│ │- **Private Subnet 1**: 10.0.10.0/24 (routes via gateway)



### High Availability### Route Tables│ ┌──────────────────────┐ │- **Private Subnet 2**: 10.0.20.0/24 (routes via gateway)

- **Multi-AZ**: Gateways spread across availability zones

- **Health Probes**: Automatic failover for unhealthy gateways- **Private Subnets**: Default route (0.0.0.0/0) → Load Balancer (10.0.1.100)

- **Load Balancing**: Traffic distributed across healthy instances

- **Load Balancer**: Distributes traffic to healthy gateways│ │ Private Subnet 2 │ │

### Network Routing

- **Private Subnets**: Route all traffic via internal LB (10.0.1.100)- **Internet Access**: Private subnet VMs route through HA gateway cluster

- **Internet Access**: External LB provides public access point

- **IP Forwarding**: Enabled on gateway NICs for proper routing│ │ 10.0.20.0/24 │────────────────────────┘### Ubuntu Gateway Server



### Security## Quick Start

- **NSG**: Permissive rules on gateways (Enforza agent handles security)

- **Enforza Agent**: Automatically installed and configured│ │ (routes via LB) │

- **Multiple Auth**: Support for password or SSH key authentication

1. **Authenticate to Azure**:

## 🛠️ Customization Options

   ````bash│ └──────────────────────┘                         - **VM**: Standard_B1s Ubuntu 22.04 LTS

### VM Sizing

```hcl   az login

vm_size = "Standard_B2s"  # Upgrade for more performance

```   ```└─────────────────────────────────────────────────┘- **Role**: Router/Gateway with IP forwarding enabled



### Network Configuration     ````

```hcl

vnet_address_space = ["172.16.0.0/16"]2. **Configure variables**:```- **IP**: Static 10.0.1.4 (private) + dynamic public IP

public_subnet_prefix = "172.16.1.0/24"

private_subnet_1_prefix = "172.16.10.0/24"   ```bash

private_subnet_2_prefix = "172.16.20.0/24"

```   cp terraform.tfvars.example terraform.tfvars- **Security**: NSG with "permit any any" rules



### Geographic Region   # Edit terraform.tfvars with:

```hcl

location = "eastus2"  # Change deployment region   # - Your subscription ID## Components Created- **Features**:

`````

# - Your Enforza company ID

## 📋 Outputs

# - Authentication method (password or SSH key) - Enforza agent automatically installed

The deployment provides comprehensive outputs:

`````

- **Gateway IPs**: Public and private addresses of both gateways

- **Load Balancer Info**: Both internal and external LB details### Network Infrastructure - IP forwarding enabled at OS level

- **DNS Information**: External LB FQDN and IP

- **Connection Details**: SSH commands and access methods3. **Deploy**:

- **Network Summary**: Complete network configuration overview

````bash- **VNet**: 10.0.0.0/16 address space  - iptables NAT/masquerading configured

## 🔧 Use Cases

terraform init

### Perfect For:

- **DNS Services**: External LB provides stable DNS name   terraform plan- **Public Subnet**: 10.0.1.0/24 (contains both gateways and load balancer)  - Routes traffic from private subnets to internet

- **Port Mapping**: DNAT functionality with port translation

- **High Availability**: Multi-AZ deployment with automatic failover   terraform apply

- **Cost Savings**: Significant cost reduction vs Azure Firewall

- **Hybrid Access**: Both private routing and internet accessibility   ```- **Private Subnet 1**: 10.0.10.0/24 (routes via load balancer)  - Apache web server with status page



### Example Usage:   ````

- Point DNS records to the external LB FQDN

- Route private subnet traffic through internal LB4. **Test HA gateways**:- **Private Subnet 2**: 10.0.20.0/24 (routes via load balancer)

- Access services via load-balanced ports (80, 443, 53)

- SSH management via port 2222   ````bash



## 🚨 Important Notes   # SSH to gateway 1### Route Tables



1. **Enforza Agent**: Handles all gateway/firewall functionality automatically   ssh azureuser@<gateway_1_public_ip>

2. **Dual LB Design**: Internal LB for routing, External LB for access/DNS

3. **Health Monitoring**: Both load balancers monitor gateway health   ### HA Gateway Setup

4. **Cost Efficiency**: ~90% cost reduction compared to Azure Firewall

5. **DNS Stability**: External LB FQDN provides stable endpoint for DNS records   # SSH to gateway 2



## 📞 Support   ssh azureuser@<gateway_2_public_ip>- **Gateway 1**: enforza-ha-gateway-1 (10.0.1.4) in AZ-1- **Private Subnets**: Default route (0.0.0.0/0) → Gateway (10.0.1.4)



For Enforza-specific configuration and support, refer to your Enforza portal and documentation.

# Check load balancer health- **Gateway 2**: enforza-ha-gateway-2 (10.0.1.5) in AZ-2- **Internet Access**: Private subnet VMs route through gateway for outbound

az network lb show --resource-group enforza-ha-multi-az-gateway --name enforza-ha-gateway-lb

```- **VM Size**: Standard_B1s Ubuntu 22.04 LTS each
`````

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
