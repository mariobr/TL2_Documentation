# VAULT

## UI

<http://ubuntu-2.fritz.box:8200/ui>

## Environment

VAULT_ADDR <http://ubuntu-2.fritz.box:8200/>

## Users

+ tlConfig
+ tlConfigAdmin
  
## Path

+ /secret/instance/\{*vendorinstanceid*}
  
## Policy

>path "secrets/tlcloud/instances/*" {
 capabilities  = ["read", "create", "update", "patch", "delete", "list"]
}

### CLI

+ PUT = ADD
  
> vault kv put /secrets/tlcloud/instances/f7bb484b-e528-4300-bc05-8a9f5bba7e14/ ConfigurationServiceDB="mongodb://mbriana:briana.mongodb@localhost:27017

+ PATCH = MODIFY (requires PATCH capability in policy)

> vault kv patch /secrets/tlcloud/instances/f7bb484b-e528-4300-bc05-8a9f5bba7e14/ LicensingServiceDB="mongodb://mbriana:briana.mongodb@localhost:27017"
> vault kv get --field LicensingServiceDB /secrets/tlcloud/instances/f7bb484b-e528-4300-bc05-8a9f5bba7e14

+ Login

> vault login -method userpass username=tlConfigAdmin password=tlConfig.Admin.2025!
> vault login -method userpass username=tlVendorAdmin password=tlVendor.Admin.2025!
> vault login hvs.EXAMPLE_ROOT_TOKEN
