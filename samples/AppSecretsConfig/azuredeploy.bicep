/**
 * // https://docs.microsoft.com/en-us/learn/modules/build-reusable-bicep-templates-parameters/6-exercise-create-use-parameter-files?pivots=powershell
 * Begin commands to execute this file using Azure CLI with PowerShell
 * az.cmd group create --location westus2 --resource-group rg_AppConfigKeyVaultDemoFreeConfig0001
 * Set-AzDefault -ResourceGroupName rg_AppConfigKeyVaultDemoFreeConfig0001
 * az.cmd deployment group create --resource-group rg_AppConfigKeyVaultDemoFreeConfig0001 --template-file azuredeploy.bicep --parameters  '{ \"parameters\": { \"secret\": { \"reference\": { \"keyVault\": { \"id\": \"/subscriptions/acc26051-92a5-4ed1-a226-64a187bc27db/resourceGroups/aksbicep02/providers/Microsoft.KeyVault/vaults/aksbicep02SH0001\" }, \"secretName\": \"testSecret\" } } } }'
 * End commands to execute this file using Azure CLI with Powershell
 * 2
 * Begin commands to execute this file using Azure CLI with PowerShell
 * az resource list --resource-group rg_AppConfigKeyVaultDemoFreeConfig0001 --location westus2
 * echo az.cmd group delete --name rg_AppConfigKeyVaultDemoFreeConfig0001 --yes
 * az.cmd group delete --name rg_AppConfigKeyVaultDemoFreeConfig0001 --yes
 * echo all done
 * End commands to execute this file using Azure CLI with Powershell
 * 3
 * Begin commands to execute this file using Azure CLI with PowerShell
 * az.cmd group create --location westus2 --resource-group rg_AppConfigKeyVaultDemoFreeConfig0001
 * #az.cmd config set defaults.group=rg_AppConfigKeyVaultDemoFreeConfig0001
 * Set-AzDefault -ResourceGroupName rg_AppConfigKeyVaultDemoFreeConfig0001
 * #az.cmd bicep build --file azuredeploy.bicep  --parameters name='AppConfigKeyVaultDemo' secret='stcontosobackup' aadClientSecret='testAadClientSecret'
 * az.cmd deployment group create --resource-group rg_AppConfigKeyVaultDemoFreeConfig0001 --template-file azuredeploy.bicep --parameters  '@azuredeploy-parameters.json'
 * #New-AzResourceGroupDeployment -TemplateFile azuredeploy.bicep -TemplateParameterFile azuredeploy-parameters.json
 * End commands to execute this file using Azure CLI with Powershell
 *
 */
@description('The base name for resources')
param name string = uniqueString(resourceGroup().id)

@description('The location for resources')
param location string = resourceGroup().location

@description('A secret to use in the web application')
@secure()
param secret string = newGuid()

@description('The web site hosting plan')
param sku string = 'F1'

@description('The App Configuration SKU. Only "standard" supports customer-managed keys from Key Vault')
@allowed([
  'free'
  'standard'
])
param configSku string = 'free'

resource config 'Microsoft.AppConfiguration/configurationStores@2020-06-01' = {
  name: '${name}config'
  location: location
  sku: {
    name: configSku
  }

  resource configValue 'keyValues@2020-07-01-preview' = {
    // Store non-secrets in App Configuration e.g., client IDs, endpoints without secure tokens, etc.
    name: 'APPCONFIG_VALUE'
    properties: {
      contentType: 'text/plain'
      value: 'not a secret'
    }
    
  }

  resource configSecret 'keyValues@2020-07-01-preview' = {
    // Store secrets in Key Vault with a reference to them in App Configuration e.g., client secrets, connection strings, etc.
    name: 'KEYVAULT_SECRET'
    properties: {
      // Most often you will want to reference a secret without the version so the current value is always retrieved.
      contentType: 'application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8'
      value: '{"uri":"${kvSecret.properties.secretUri}"}'
    }
  }
}

resource kv 'Microsoft.KeyVault/vaults@2019-09-01' = {
  // Make sure the Key Vault name begins with a letter.
  name: 'kv${name}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: web.identity.principalId
        permissions: {
          // Secrets are referenced by and enumerated in App Configuration so 'list' is not necessary.
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
}

// Separate resource from parent to reference in configSecret resource.
resource kvSecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${kv.name}/${name}secret'
  properties: {
    contentType: 'text/plain'
    value: secret
  }
}

resource plan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: '${name}plan'
  location: location
  sku: {
    name: sku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource web 'Microsoft.Web/sites@2020-12-01' = {
  name: '${name}web'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    serverFarmId: plan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|3.1'
      connectionStrings: [
        {
          name: 'AppConfig'
          connectionString: listKeys(config.id, config.apiVersion).value[0].connectionString
        }
      ]
    }
  }
}

output appConfigConnectionString string = listKeys(config.id, config.apiVersion).value[0].connectionString
output siteUrl string = 'https://${web.properties.defaultHostName}/'
output vaultUrl string = kv.properties.vaultUri
