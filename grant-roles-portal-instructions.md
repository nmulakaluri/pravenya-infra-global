# Grant Azure RBAC Roles - Azure Portal Instructions

Since you're logged in as a guest user, you may need to use the Azure Portal to grant roles at the tenant root management group level.

## Service Principal Details
- **Display Name:** `pravenya-github-actions`
- **Client ID:** `e2d49ead-387c-4032-a71b-91c19b72ed27`
- **Object ID:** `2e91ce84-f9a9-4a2c-bb81-6c591c431fac`

## Steps to Grant Roles via Azure Portal

### Step 1: Navigate to Management Groups
1. Go to [Azure Portal](https://portal.azure.com)
2. Search for "Management groups" in the top search bar
3. Click on "Management groups"

### Step 2: Select Tenant Root Group
1. Click on the **Tenant Root Group** (or your root management group)
2. If you don't see it, make sure you're viewing all management groups

### Step 3: Grant Roles
1. In the left menu, click **Access control (IAM)**
2. Click **+ Add** → **Add role assignment**

#### Grant Role 1: Management Group Contributor
1. In the "Role" tab, search for and select **Management Group Contributor**
2. Click **Next**
3. In the "Members" tab, click **+ Select members**
4. Search for `pravenya-github-actions` or paste the Object ID: `2e91ce84-f9a9-4a2c-bb81-6c591c431fac`
5. Select the service principal and click **Select**
6. Click **Review + assign**

#### Grant Role 2: Policy Contributor
1. Click **+ Add** → **Add role assignment**
2. Search for and select **Policy Contributor**
3. Click **Next**
4. Select the same service principal (`pravenya-github-actions`)
5. Click **Review + assign**

#### Grant Role 3: User Access Administrator
1. Click **+ Add** → **Add role assignment**
2. Search for and select **User Access Administrator**
3. Click **Next**
4. Select the same service principal (`pravenya-github-actions`)
5. Click **Review + assign**

### Step 4: Verify Role Assignments
1. Stay on the **Access control (IAM)** page
2. Click on the **Role assignments** tab
3. Search for `pravenya-github-actions`
4. You should see all three roles:
   - Management Group Contributor
   - Policy Contributor
   - User Access Administrator

## Alternative: Use PowerShell

If you have PowerShell access, you can also use:

```powershell
# Connect to Azure
Connect-AzAccount

# Get service principal
$sp = Get-AzADServicePrincipal -DisplayName "pravenya-github-actions"

# Get tenant root management group
$tenantId = (Get-AzContext).Tenant.Id
$mgScope = "/providers/Microsoft.Management/managementGroups/$tenantId"

# Grant roles
New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Management Group Contributor" -Scope $mgScope
New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Policy Contributor" -Scope $mgScope
New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "User Access Administrator" -Scope $mgScope
```

## After Granting Roles

1. **Wait 2-5 minutes** for role assignments to propagate
2. Re-run your Terraform apply or GitHub Actions workflow
3. The errors should be resolved

## Verification

After granting roles, you can verify them using Azure CLI:

```bash
SP_OBJECT_ID="2e91ce84-f9a9-4a2c-bb81-6c591c431fac"
TENANT_ID="2581608f-9d7e-4da3-a33d-499c7f164ac4"
TENANT_ROOT_MG="/providers/Microsoft.Management/managementGroups/${TENANT_ID}"

az role assignment list \
    --assignee "$SP_OBJECT_ID" \
    --scope "$TENANT_ROOT_MG" \
    --query "[].{Role:roleDefinitionName, Scope:scope}" \
    -o table
```

