# Instance Provisioning

* Create Instance in VendorBoard
* Select Deployment Target Vault

## Identity Provider

* Provision IDP Realm

## Instance License Management System

* Provision instance secrets to Vault
* Provision idp secrects to vault
* Set configuration for instance container
  
```json
"VaultConfig": {
  "Uri": "http://ubuntu-2.fritz.box:8200",
  "Token": "hvs.EXAMPLE_TOKEN_REPLACE_WITH_ACTUAL_TOKEN",
  "VendorInstanceId": "f7bb484b-e528-4300-bc05-8a9f5bba7e14"
}
```
