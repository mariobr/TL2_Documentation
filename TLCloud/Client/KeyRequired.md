# License Manager (LM)
## Storage Root Key (SRK) *asymetric*
- generated on TPM
- identitfies License Manager
- used as Fingerprint on License Management System (LMS)
- private key in TPM
- public key in LMS
---
# Clients
## Vendor Key (VK) *asymetric*
- identifies the Vendor 
- private key is secret in client libraries
- public key in LMS
- encrypted and delivered via download for Vendor
- allows to consume licenses for the specified Vendor only
---
# License Generator
## License Gen Key (LGK) *symetric*
## License Manager Delivery Key (LMDK) *symetric*
#### *Vendor Key (VK)*
#### *Storage Rookt Key (SRK)*
- create *symetric* licenses encrypted with License Gen Key (LGK)
- encrypt LGK using public Vendor Key (VK)
- *symetric* encrypt above using License Manager Delivery Key (LMDK)
- encrypt LMDK using SRK