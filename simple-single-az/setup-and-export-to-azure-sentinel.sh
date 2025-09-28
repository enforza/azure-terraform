#!/usr/bin/env bash
# go-sentinel.sh - Setup Azure Monitor Agent and send logs to Sentinel
set -euo pipefail

TFVARS="${TFVARS_PATH:-./terraform.tfvars}"

# Check dependencies
command -v az >/dev/null 2>&1 || { echo "❌ Azure CLI is required but not installed."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "❌ jq is required but not installed."; exit 1; }

# Function to read values from tfvars
get_tfvar() {
  local key="$1" default="${2-}"
  local val=""
  val=$(sed -n -E \
    -e '/^[[:space:]]*#/d' \
    -e "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*\"([^\"]*)\".*/\1/p" \
    "$TFVARS" 2>/dev/null || true)
  [[ -n "${val:-}" ]] && printf '%s\n' "$val" || printf '%s\n' "$default"
}

# Read configuration from tfvars
SUB="$(get_tfvar subscription_id '')"
RG="$(get_tfvar resource_group_name 'enforza-simple-gateway')"
LOCATION="$(get_tfvar location 'uksouth')"
VM="$(get_tfvar vm_name 'enforza-gateway')"
VM_USER="$(get_tfvar admin_username 'azureuser')"

# Get VM public IP from Azure
VM_IP=$(az vm show -d --resource-group "$RG" --name "$VM" --query "publicIps" -o tsv 2>/dev/null || echo "Unknown")

# Validate required variables
[ -n "$SUB" ] || { echo "❌ subscription_id not found in $TFVARS"; exit 1; }

echo "🚀 Setting up Azure Monitor Agent and Sentinel integration"
echo "   Subscription: $SUB"
echo "   Resource Group: $RG" 
echo "   Location: $LOCATION"
echo "   VM Name: $VM"
echo "   VM IP: $VM_IP"
echo "   VM User: $VM_USER"
echo

# Set Azure subscription
az account set --subscription "$SUB"

# Register required providers
echo "📦 Registering Azure providers..."
az provider register --namespace Microsoft.Insights --wait
az provider register --namespace Microsoft.OperationalInsights --wait
az provider register --namespace Microsoft.SecurityInsights --wait

# Install Azure Monitor Agent on VM
echo "🔧 Installing Azure Monitor Agent on VM: $VM"
if [ "$(az vm extension list --resource-group "$RG" --vm-name "$VM" \
        --query "length([?name=='AzureMonitorLinuxAgent'])" -o tsv 2>/dev/null || echo 0)" = "0" ]; then
  echo "   Installing AMA extension..."
  az vm extension set \
    --resource-group "$RG" --vm-name "$VM" \
    --publisher Microsoft.Azure.Monitor --name AzureMonitorLinuxAgent \
    --enable-auto-upgrade true >/dev/null
  echo "   ✅ Azure Monitor Agent installed"
else
  echo "   ✅ Azure Monitor Agent already installed"
fi

# Ensure VM has system-assigned managed identity
echo "🔑 Setting up VM managed identity..."
IDENTITY_CHECK=$(az vm identity show --resource-group "$RG" --name "$VM" --query "systemAssignedIdentity" -o tsv 2>/dev/null || echo "None")

if [ "$IDENTITY_CHECK" = "None" ] || [ -z "$IDENTITY_CHECK" ]; then
  echo "   Enabling system-assigned managed identity..."
  IDENTITY_RESULT=$(az vm identity assign --resource-group "$RG" --name "$VM")
  PRINCIPAL_ID=$(echo "$IDENTITY_RESULT" | jq -r '.systemAssignedIdentity')
  echo "   ✅ Managed identity enabled: $PRINCIPAL_ID"
else
  PRINCIPAL_ID="$IDENTITY_CHECK"
  echo "   ✅ Managed identity already exists: $PRINCIPAL_ID"
fi

# Assign required roles to the managed identity
echo "🛡️  Assigning required permissions to managed identity..."
ROLE_ASSIGNMENT_CHECK=$(az role assignment list --assignee "$PRINCIPAL_ID" --role "Monitoring Metrics Publisher" --scope "/subscriptions/$SUB/resourceGroups/$RG" --query "length(@)" -o tsv 2>/dev/null || echo 0)

if [ "$ROLE_ASSIGNMENT_CHECK" = "0" ]; then
  echo "   Assigning 'Monitoring Metrics Publisher' role..."
  az role assignment create \
    --assignee "$PRINCIPAL_ID" \
    --role "Monitoring Metrics Publisher" \
    --scope "/subscriptions/$SUB/resourceGroups/$RG" >/dev/null
  echo "   ✅ Role assigned successfully"
  
  echo "   Restarting Azure Monitor Agent to apply new permissions..."
  # SSH command would require password, so we'll just inform the user
  echo "   ⚠️  Please restart the Azure Monitor Agent on the VM:"
  echo "      ssh $VM_USER@$VM_IP 'sudo systemctl restart azuremonitoragent'"
else
  echo "   ✅ Required permissions already assigned"
fi

# Find or create Log Analytics workspace
echo "🔍 Finding Log Analytics workspaces..."

# Check for workspaces in the current resource group
echo "   Checking resource group '$RG'..."
RG_WORKSPACES=$(az monitor log-analytics workspace list --resource-group "$RG" --query '[].name' -o tsv 2>/dev/null || true)

# Check for workspaces across the entire subscription
echo "   Checking entire subscription..."
ALL_WORKSPACES=$(az monitor log-analytics workspace list --query '[].{name:name,rg:resourceGroup,id:id}' -o tsv 2>/dev/null || true)

WORKSPACE_NAME=""
WORKSPACE_ID=""

if [ -n "$RG_WORKSPACES" ]; then
  echo "   Found workspaces in resource group '$RG':"
  echo "$RG_WORKSPACES" | sed 's/^/     - /'
  echo
  read -p "   Use existing workspace from this RG? Enter name (or press Enter to skip): " CHOICE
  
  if [ -n "$CHOICE" ] && echo "$RG_WORKSPACES" | grep -q "^$CHOICE$"; then
    WORKSPACE_NAME="$CHOICE"
    WORKSPACE_ID="/subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.OperationalInsights/workspaces/$WORKSPACE_NAME"
    echo "   ✅ Using existing workspace: $WORKSPACE_NAME"
  fi
fi

if [ -z "$WORKSPACE_NAME" ] && [ -n "$ALL_WORKSPACES" ]; then
  echo "   Found workspaces in other resource groups:"
  echo "$ALL_WORKSPACES" | awk '{print "     - " $1 " (in " $2 ")"}' 
  echo
  read -p "   Use existing workspace from another RG? Enter workspace name (or press Enter to skip): " CHOICE
  
  if [ -n "$CHOICE" ]; then
    FOUND_WORKSPACE=$(echo "$ALL_WORKSPACES" | awk -v name="$CHOICE" '$1==name {print $3}' | head -1)
    if [ -n "$FOUND_WORKSPACE" ]; then
      WORKSPACE_ID="$FOUND_WORKSPACE"
      WORKSPACE_NAME="$CHOICE"
      echo "   ✅ Using existing workspace: $WORKSPACE_NAME"
    else
      echo "   ❌ Workspace '$CHOICE' not found"
    fi
  fi
fi

if [ -z "$WORKSPACE_NAME" ]; then
  read -p "   Enter name for new workspace in RG '$RG': " WORKSPACE_NAME
  WORKSPACE_NAME=${WORKSPACE_NAME:-enforza-sentinel-workspace}
  echo "   Creating workspace: $WORKSPACE_NAME"
  
  az monitor log-analytics workspace create \
    --resource-group "$RG" \
    --workspace-name "$WORKSPACE_NAME" \
    --location "$LOCATION" >/dev/null
    
  WORKSPACE_ID="/subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.OperationalInsights/workspaces/$WORKSPACE_NAME"
  echo "   ✅ Workspace created: $WORKSPACE_NAME"
fi

# Enable Microsoft Sentinel
echo "�️  Setting up Microsoft Sentinel..."
SENTINEL_CHECK=$(az rest \
  --method GET \
  --url "https://management.azure.com$WORKSPACE_ID/providers/Microsoft.SecurityInsights/onboardingStates/default?api-version=2023-02-01" \
  --query "properties" -o tsv 2>/dev/null || echo "not_found")

if [ "$SENTINEL_CHECK" = "not_found" ]; then
  echo "   Enabling Microsoft Sentinel on workspace '$WORKSPACE_NAME'..."
  az rest \
    --method PUT \
    --url "https://management.azure.com$WORKSPACE_ID/providers/Microsoft.SecurityInsights/onboardingStates/default?api-version=2023-02-01" \
    --body '{}' >/dev/null
  echo "   ✅ Microsoft Sentinel enabled"
else
  echo "   ✅ Microsoft Sentinel already enabled on workspace"
fi

# Create custom log table
echo "📊 Creating custom log table..."
TABLE_NAME="EnforzaLogs_CL"
TABLE_EXISTS=$(az monitor log-analytics workspace table show \
  --resource-group "$RG" --workspace-name "$WORKSPACE_NAME" \
  --name "$TABLE_NAME" --query "name" -o tsv 2>/dev/null || echo "")

if [ -z "$TABLE_EXISTS" ]; then
  echo "   Creating table: $TABLE_NAME"
  az monitor log-analytics workspace table create \
    --resource-group "$RG" --workspace-name "$WORKSPACE_NAME" \
    --name "$TABLE_NAME" --plan Analytics \
    --columns TimeGenerated=datetime RawData=string >/dev/null
  echo "   ✅ Table created: $TABLE_NAME"
else
  echo "   ✅ Table already exists: $TABLE_NAME"
fi

# Create Data Collection Endpoint
echo "📡 Setting up Data Collection Endpoint..."
DCE_NAME="enforza-dce"
DCE_ID="/subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Insights/dataCollectionEndpoints/$DCE_NAME"

DCE_EXISTS=$(az resource show --ids "$DCE_ID" --query "name" -o tsv 2>/dev/null || echo "")
if [ -z "$DCE_EXISTS" ]; then
  echo "   Creating Data Collection Endpoint: $DCE_NAME"
  az rest --method PUT \
    --url "https://management.azure.com$DCE_ID?api-version=2022-06-01" \
    --body "{
      \"location\": \"$LOCATION\",
      \"properties\": {
        \"networkAcls\": { \"publicNetworkAccess\": \"Enabled\" }
      }
    }" >/dev/null
  echo "   ✅ Data Collection Endpoint created"
else
  echo "   ✅ Data Collection Endpoint already exists"
fi

# Create Data Collection Rule
echo "📋 Setting up Data Collection Rule..."
DCR_NAME="enforza-ulog-dcr"
DCR_ID="/subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Insights/dataCollectionRules/$DCR_NAME"

cat > /tmp/dcr-config.json <<EOF
{
  "location": "$LOCATION",
  "properties": {
    "dataCollectionEndpointId": "$DCE_ID",
    "streamDeclarations": {
      "Custom-EnforzaLogs_CL": {
        "columns": [
          { "name": "TimeGenerated", "type": "datetime" },
          { "name": "RawData", "type": "string" }
        ]
      }
    },
    "dataSources": {
      "logFiles": [
        {
          "name": "enforza-ulog-files",
          "format": "text",
          "streams": ["Custom-EnforzaLogs_CL"],
          "filePatterns": ["/var/log/ulog/*.log"]
        }
      ]
    },
    "destinations": {
      "logAnalytics": [
        {
          "name": "destination-log-analytics",
          "workspaceResourceId": "$WORKSPACE_ID"
        }
      ]
    },
    "dataFlows": [
      {
        "streams": ["Custom-EnforzaLogs_CL"],
        "destinations": ["destination-log-analytics"]
      }
    ]
  }
}
EOF

echo "   Creating Data Collection Rule: $DCR_NAME"
az rest --method PUT \
  --url "https://management.azure.com$DCR_ID?api-version=2022-06-01" \
  --body @/tmp/dcr-config.json >/dev/null
echo "   ✅ Data Collection Rule created"

# Associate DCR with VM
echo "🔗 Associating Data Collection Rule with VM..."
ASSOCIATION_NAME="enforza-dcr-association"
ASSOCIATION_URL="https://management.azure.com/subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Compute/virtualMachines/$VM/providers/Microsoft.Insights/dataCollectionRuleAssociations/$ASSOCIATION_NAME?api-version=2022-06-01"

az rest --method PUT --url "$ASSOCIATION_URL" --body "{
  \"properties\": {
    \"dataCollectionRuleId\": \"$DCR_ID\"
  }
}" >/dev/null
echo "   ✅ VM associated with Data Collection Rule"

# Cleanup
rm -f /tmp/dcr-config.json

echo
echo "🎉 Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Configuration Summary:"
echo "   • VM: $VM (with Azure Monitor Agent)"
echo "   • VM IP: $VM_IP"
echo "   • Managed Identity: Enabled with required permissions"
echo "   • Workspace: $WORKSPACE_NAME" 
echo "   • Microsoft Sentinel: Enabled"
echo "   • Log Collection: /var/log/ulog/*.log → EnforzaLogs_CL"
echo "   • Data Collection Endpoint: $DCE_NAME"
echo "   • Data Collection Rule: $DCR_NAME"
echo
echo "🔧 Important: If you just enabled managed identity, restart the agent:"
echo "   ssh $VM_USER@$VM_IP 'sudo systemctl restart azuremonitoragent'"
echo
echo "🔗 Access your setup:"
echo "   • Log Analytics: https://portal.azure.com/#@/resource$WORKSPACE_ID"
echo "   • Microsoft Sentinel: https://portal.azure.com/#view/Microsoft_Azure_Security_Insights/MainMenuBlade/~/0/id$WORKSPACE_ID"
echo
echo "📝 Sample KQL query to view logs (allow 5-10 minutes for data):"
echo "   EnforzaLogs_CL | limit 100"
echo
echo "🧪 Test log ingestion:"
echo "   ssh $VM_USER@$VM_IP 'echo \"Test from \$(date)\" | sudo tee -a /var/log/ulog/enforza-fw.log'"
