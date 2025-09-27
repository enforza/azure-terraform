# Azure Terraform Templates for Enforza Gateway

This repository contains production-ready Terraform templates for deploying Enforza Gateway infrastructure on Microsoft Azure.

## 🏗️ Architecture Options

### 1. Simple Single AZ (`simple-single-az/`)
- **Cost**: ~$30/month
- **Availability**: Single AZ deployment
- **Use Case**: Development, testing, small deployments
- **Features**:
  - Single Enforza Gateway VM
  - Basic networking (VNet, subnets, NSG)
  - Public IP for management access
  - Automatic Enforza agent installation

### 2. High Availability Multi-AZ (`ha-multi-az/`)
- **Cost**: ~$70/month
- **Availability**: Multi-AZ with internal load balancer
- **Use Case**: Production deployments requiring HA
- **Features**:
  - 2x Enforza Gateway VMs across availability zones
  - Internal load balancer for traffic distribution
  - Route tables directing private subnet traffic through gateways
  - Automatic failover capabilities

### 3. HA Multi-AZ with DNAT (`ha-multi-az-with-dnat/`)
- **Cost**: ~$90/month
- **Availability**: Multi-AZ with dual load balancer setup
- **Use Case**: Production with external DNAT/DNS requirements
- **Features**:
  - All features from HA Multi-AZ
  - External internet-facing load balancer
  - DNS name assignment for external access
  - Test VM for DNAT validation
  - Dual load balancer architecture (internal + external)

## 🚀 Quick Start

### Prerequisites
- Azure CLI installed and authenticated
- Terraform >= 1.0 installed
- An Enforza company ID (contact Enforza for registration)

### Deployment Steps

1. **Choose your deployment type** and navigate to the appropriate directory:
   ```bash
   cd simple-single-az/    # or ha-multi-az/ or ha-multi-az-with-dnat/
   ```

2. **Copy and customize the variables file**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

3. **Initialize and deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## 📋 Required Configuration

All deployments require these minimum variables in your `terraform.tfvars`:

```hcl
# Azure subscription ID
subscription_id = "your-subscription-id-here"

# Enforza company ID (provided during Enforza registration)
enforza_companyId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Choose ONE authentication method:
# Option 1: Password (minimum 12 characters)
admin_password = "YourSecurePassword123!"

# Option 2: SSH key (preferred)
# ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
```

## 🔧 Optional Configuration

```hcl
# Azure region (default: uksouth)
location = "uksouth"

# VM size (default: Standard_B1s)
vm_size = "Standard_B2s"

# Network configuration
vnet_address_space = ["10.0.0.0/16"]
public_subnet_prefix = "10.0.1.0/24"
private_subnet_1_prefix = "10.0.10.0/24"
private_subnet_2_prefix = "10.0.20.0/24"
```

## 🌐 Network Architecture

### Traffic Flow
```
Internet
    ↓
External Load Balancer (DNAT deployments only)
    ↓
Enforza Gateway VMs
    ↓
Internal Load Balancer
    ↓
Private Subnet Resources
```

### IP Addressing
- **VNet**: 10.0.0.0/16
- **Public Subnet**: 10.0.1.0/24 (Gateway VMs)
- **Private Subnet 1**: 10.0.10.0/24 (Your resources)
- **Private Subnet 2**: 10.0.20.0/24 (Your resources)
- **Internal LB IP**: 10.0.1.100

## 🔐 Security Features

- **Network Security Groups**: Configurable firewall rules
- **SSH Key Authentication**: Preferred over passwords
- **Private Subnets**: Resources isolated from direct internet access
- **Load Balancer Health Probes**: Automatic failover detection
- **Azure Availability Zones**: Geographic redundancy

## 📊 Cost Optimization

| Feature | Simple | HA Multi-AZ | HA with DNAT |
|---------|--------|-------------|--------------|
| VMs | 1x B1s | 2x B1s | 2x B1s + Test VM |
| Load Balancers | None | 1 Internal | 2 (Internal + External) |
| Public IPs | 1 | 2 | 3 + DNS |
| Monthly Cost | ~$30 | ~$70 | ~$90 |

## 🧪 Testing

The `ha-multi-az-with-dnat` deployment includes a test VM for DNAT validation:
- **Location**: Private subnet (10.0.10.10)
- **Service**: Nginx web server
- **Access**: Configure Enforza DNAT rules to route external traffic
- **Test Page**: Beautiful HTML page confirming DNAT functionality

## 📝 Outputs

After deployment, Terraform provides useful information:
- Gateway VM public IPs for SSH access
- Load balancer IPs and FQDNs
- Network configuration details
- SSH connection commands

## 🛡️ Production Considerations

### Security
- Use SSH keys instead of passwords
- Customize NSG rules for your specific requirements
- Enable Azure Security Center recommendations
- Consider Azure Bastion for enhanced security

### Monitoring
- Enable Azure Monitor for VM insights
- Configure log analytics workspace
- Set up alerting for gateway health
- Monitor load balancer metrics

### Backup & Recovery
- Enable Azure Backup for VM disks
- Document your Enforza configuration
- Test disaster recovery procedures
- Maintain infrastructure as code practices

## 🆘 Troubleshooting

### Common Issues

1. **VM Won't Start**
   - Check VM size availability in your region
   - Verify subscription quotas
   - Review error messages in Azure portal

2. **Enforza Agent Not Installing**
   - Verify company ID is correct
   - Check internet connectivity from VMs
   - Review cloud-init logs: `/var/log/cloud-init-output.log`

3. **Load Balancer Issues**
   - Verify health probe configuration
   - Check NSG rules allow probe traffic
   - Review backend pool membership

### Support
- Azure issues: Use Azure Support
- Terraform issues: Check Terraform documentation
- Enforza issues: Contact Enforza support

## 📚 Additional Resources

- [Enforza Documentation](https://docs.enforza.com)
- [Azure Terraform Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)

## 🤝 Contributing

This repository is maintained by Enforza. For issues or feature requests:
1. Check existing issues
2. Create detailed bug reports
3. Propose improvements via pull requests

---

**⚡ Quick Deploy Commands:**

```bash
# Simple deployment
git clone https://github.com/enforza/azure-terraform.git
cd azure-terraform/simple-single-az
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init && terraform apply
```

**Need Help?** Contact Enforza support or check our documentation.