# Activation

## Input

### Destination fingerprint
### License Container

1. **Container Guid**
> Name
> Routing Information

2. **Vendor**
> Code, Info, Public Key

3. **Product**
> Features, LicenseModels, Tokens

## Content of a package

Package Guid
Destination Information
> Target Host
> List of Containers

## Security

### Container

Container as JSON structure

Signed by Vendor

### Package

Package as JSON structure

Signed by LMS 

Encrypted with Fingerprint Public Key