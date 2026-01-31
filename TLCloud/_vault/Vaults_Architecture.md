# Vaults Architecture

## Instances Overview

There are currently 3 instances that require access to configuraiton.

1. Vendor Instances (Web Applications for License Management, Portals etc.)
2. Vendor Services (Services consumed by Vendor Instances)
3. Provisioning (Onbarding) Instances
4. Provisioning Services (Services consumed by Provisioning)

All of the above will access their configuration through a vault.
The access to the vault will be limited to their minimal needs and access token will be provided through application/service specific configurations (e.g. config file belonging to app/service.)

## Naming Conventions to identity Instances

| Instance | Name | Vault Config Type | Vault Path |
| --- | --- | --- | --- |
| Vendor Instances | Web applications for license management and portals |  tlVendorInstance |secrets/tlVendorInstance/***namespace***/***instanceGUID*** |
| Vendor Services | Services consumed by vendor instances |  tlVendorService |secrets/tlVendorService/***namespace***/***servicename*** |
| Provisioning Instances | Onboarding applications | tlProviInstance | secrets/tlProviInstance/***namespace***/instance |
| Provisioning Services | Services consumed by provisioning | tlProviService |secrets/tlProviService/***namespace***/service |

* ***namespace*** is used to determine clusters (e.g.) or other distinctions of deployments targets.

## Vault Services

Each vault service will receive individual configuration information containing:

1. Config Instance Type
2. Instance Name (e.g. GUID or LMLicensingService)
3. Vault Address
4. Vault Namespace
5. Vault Access Token
   * The access contains the vault user name 