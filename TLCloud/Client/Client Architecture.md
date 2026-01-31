# Trusted Licensing Client Topology

 
## Clients leverage Trusted Platform Module (TPM)

* Using TPM 2.0 chips under Windows, Linux (tbc. ARM).
    * Trusted Platform Public Keys (Storage Root Keys)
    * Trusted Platform HMAC
    * Trusted Persistence leveraging TPM non-volatile storage
* Alternativeley Fingerprint
    * Builtin Persistence (less secure)
    * Builtin Fingerprint
    * Custom Fingerprint 
        * requires C++ registered callback
  
> A dedicated license is required to enable fingerprint alternative licensing
> Same dedicated license may switch off usage of tpm

### TLLicenseManager 
- TLLicenseManager client is implemented as a service or daemon called Trusted License Manager (TLLM)
- The communication from TLLicenseClient is based on REST (later gRPC).
- TLLM requires elevated rights
- Network (Seat) based Licensing via
    - Named User (OAuth)
    - Station
    - Consumption (a.k.a. Login)
    - Process

### TLLicenseClient
- Intended for (embedded) scenarios where a service/daemon is a resource burden
- TPM only available via service/daemon or elevation
- Same security mechanisms
- Communication to TLLicenseManager via REST (later gRPC)
- Offline Capable

## Storage
- TLLM needs to securly store secrets, license, usage, configuration and custom data.
### TPM based
- A fully trusted client relies on TPM compatible with 2.0
- It uses a storage root key (SRK) and non-volatile vector (NV) space of the TPM to store secrets. 
- Grants OS independence. As long as the TPM is not reset.
    - e.g. the PC can be changed from Windows to Linux and Licensing could be restored and trusted via the TPC capability

## Secrets
- TLLM has a provider and a vendor public key to verify information. 
- Encrypted configuration information can therefore be passed to the client from either the vendor or the provider.
## Identification
- TLLM needs to identify the vendor client.
- The vendor client application needs a way to trust to the TLLM.
### IAM integrated (OAuth)
- The TLLM can be provided with a trusted configuration info from vendor that a certain IAM url can be trusted. The IAM client informaiton for the TLLM can be provided.
- The vendor client using the same IAM realm can trust the TLLM. 
    - Based on a protocol or Token
- IAM integration use case should be OS agnostic.
- It is be the base for authenticated user (claims) licensing.
### Windows
- The vendor client knows the vendor public key. 
- It can trust the TLLM using a Diffie/Hellman (TLS) session.
- TLLM can provide a secret from vendor that the client can verify.
- Vendor can create a password protected certificate identifying the vendor client.

### Linux
### Apple

# GUI
### Potential GUI C++
- https://slint-ui.com/
- https://www.wxwidgets.org/
- https://www.dearimgui.com/

# REST
### Potential REST C++
- https://oatpp.io/

# Windows Service
https://learn.microsoft.com/en-us/windows/win32/services/svccontrol-cpp
