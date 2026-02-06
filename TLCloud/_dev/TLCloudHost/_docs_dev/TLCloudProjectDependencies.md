# TLCloud Project Dependencies

## Overview
Hierarchical project structure for TLCloud solution orchestrated by .NET Aspire AppHost.

---

## Architecture Layers

**Tier 1: Orchestration**
- TLCloudHost - Aspire AppHost

**Tier 2: Services & Applications**  
- VendorBoardAPI, VendorBoardWeb, VendorProtectionAPI, LicenseManagementSystemWeb

**Tier 3-7:** Framework ? Clients ? Business Logic ? DTOs ? Core Infrastructure

---

## Text Dependency Tree
	
---

## Mermaid: Full Architecture

```mermaid
graph TB
    subgraph Tier1["Tier 1: Orchestration"]
        TLCloudHost[TLCloudHost<br/>Aspire AppHost]
    end
    
    subgraph Tier2["Tier 2: Services & Applications"]
        VendorBoardAPI[VendorBoardAPI<br/>REST API]
        VendorBoardWeb[VendorBoardWeb<br/>Blazor Server]
        VendorProtectionAPI[VendorProtectionAPI<br/>REST API]
        LicenseManagementWeb[LicenseManagementSystemWeb<br/>Blazor Server]
    end
    
    subgraph Tier3["Tier 3: Framework & Infrastructure"]
        TLWebCommon[TLWebCommon<br/>Blazor Components]
        TLApiCommon[TLApiCommon<br/>API Extensions]
        TLCloudServiceDefaults[TLCloudServiceDefaults<br/>Aspire Defaults]
    end
    
    subgraph Tier4["Tier 4: Client Libraries"]
        TLCloudClients[TLCloudClients<br/>Refit Clients]
    end
    
    subgraph Tier5["Tier 5: Business Logic"]
        TLVendor[TLVendor<br/>Domain Services]
    end
    
    subgraph Tier6["Tier 6: Data Models"]
        TLVendorDTO[TLVendor.DTO<br/>Data Contracts]
    end
    
    subgraph Tier7["Tier 7: Core Infrastructure"]
        TLCloudCommon[TLCloudCommon<br/>Cloud Services]
        TLCommon[TLCommon<br/>Base Utilities]
        TLCommonPoCo[TLCommonPoCo<br/>Config Models]
    end
    
    TLCloudHost --> VendorBoardAPI
    TLCloudHost --> VendorBoardWeb
    TLCloudHost --> VendorProtectionAPI
    TLCloudHost --> LicenseManagementWeb
    
    VendorBoardAPI --> TLVendor
    VendorBoardAPI --> TLCloudCommon
    VendorBoardAPI --> TLApiCommon
    VendorBoardAPI --> TLCloudServiceDefaults
    
    VendorProtectionAPI --> TLVendor
    VendorProtectionAPI --> TLCloudCommon
    VendorProtectionAPI --> TLApiCommon
    VendorProtectionAPI --> TLCloudServiceDefaults
    
    VendorBoardWeb --> TLCloudClients
    VendorBoardWeb --> TLWebCommon
    VendorBoardWeb --> TLCloudCommon
    VendorBoardWeb --> TLCloudServiceDefaults
    
    LicenseManagementWeb --> TLCloudClients
    LicenseManagementWeb --> TLWebCommon
    LicenseManagementWeb --> TLCloudCommon
    LicenseManagementWeb --> TLCloudServiceDefaults
    
    TLWebCommon --> TLCloudServiceDefaults
    TLWebCommon --> TLCloudCommon
    TLWebCommon --> TLCommon
    
    TLApiCommon --> TLCloudCommon
    TLApiCommon --> TLCommon
    
    TLCloudClients --> TLVendorDTO
    
    TLVendor --> TLVendorDTO
    TLVendor --> TLCloudCommon
    TLVendor --> TLCommon
    
    TLCloudCommon --> TLCommon
    TLCloudCommon --> TLCommonPoCo
    
    style TLCloudHost fill:#e1f5ff,stroke:#01579b,stroke-width:3px
    style VendorBoardAPI fill:#fff3e0,stroke:#e65100
    style VendorBoardWeb fill:#fff3e0,stroke:#e65100
    style VendorProtectionAPI fill:#fff3e0,stroke:#e65100
    style LicenseManagementWeb fill:#fff3e0,stroke:#e65100
    style TLVendor fill:#e8f5e9,stroke:#1b5e20
    style TLCloudCommon fill:#fce4ec,stroke:#880e4f
    style TLCommon fill:#fce4ec,stroke:#880e4f
```

## Mermaid: Service Communication

```mermaid
graph LR
    subgraph WebApps["Client Applications"]
        VendorBoardWeb[VendorBoardWeb<br/>Blazor Server]
        LicenseManagementWeb[LicenseManagementSystemWeb<br/>Blazor Server]
    end
    
    subgraph APIs["REST APIs"]
        VendorBoardAPI[VendorBoardAPI<br/>Port: 7104]
        VendorProtectionAPI[VendorProtectionAPI<br/>Port: 7105]
    end
    
    subgraph Clients["HTTP Clients"]
        TLCloudClients[TLCloudClients<br/>Refit Interface]
    end
    
    subgraph DataStores["Data Stores"]
        MongoDB[(MongoDB<br/>VendorDB)]
        Vault[(HashiCorp Vault<br/>Secrets & Config)]
        KeyCloak[KeyCloak<br/>Identity Provider<br/>kc.asperion.net]
        Redis[(Redis<br/>Distributed Cache)]
    end
    
    VendorBoardWeb -->|HTTP/Refit| VendorBoardAPI
    VendorBoardWeb -->|HTTP/Refit| VendorProtectionAPI
    LicenseManagementWeb -->|HTTP/Refit| VendorBoardAPI
    
    VendorBoardWeb -.->|Uses| TLCloudClients
    LicenseManagementWeb -.->|Uses| TLCloudClients
    
    VendorBoardAPI -->|CRUD| MongoDB
    VendorBoardAPI -->|Read Secrets| Vault
    VendorBoardAPI -->|Cache| Redis
    
    VendorProtectionAPI -->|Validate| MongoDB
    VendorProtectionAPI -->|Read Secrets| Vault
    
    VendorBoardWeb -->|OIDC Auth| KeyCloak
    LicenseManagementWeb -->|OIDC Auth| KeyCloak
    VendorBoardAPI -->|Validate JWT| KeyCloak
    VendorProtectionAPI -->|Validate JWT| KeyCloak
    
    style VendorBoardWeb fill:#e3f2fd,stroke:#1565c0
    style LicenseManagementWeb fill:#e3f2fd,stroke:#1565c0
    style VendorBoardAPI fill:#fff3e0,stroke:#e65100
    style VendorProtectionAPI fill:#fff3e0,stroke:#e65100
    style TLCloudClients fill:#f3e5f5,stroke:#6a1b9a
    style MongoDB fill:#c8e6c9,stroke:#2e7d32
    style Vault fill:#ffccbc,stroke:#d84315
    style KeyCloak fill:#b2dfdb,stroke:#00695c
    style Redis fill:#ffecb3,stroke:#f57f17
```

## Mermaid: Licensing Provider Flow

```mermaid
sequenceDiagram
    participant User
    participant VendorBoardWeb
    participant ILicensingProviderApi
    participant VendorBoardAPI
    participant LicensingProviderService
    participant MongoDB
    participant Vault
    
    User->>VendorBoardWeb: Navigate to app
    activate VendorBoardWeb
    VendorBoardWeb->>VendorBoardWeb: AuthLayout.OnInitializedAsync()
    VendorBoardWeb->>ILicensingProviderApi: LicensingProviderConfiguredAsync()
    activate ILicensingProviderApi
    ILicensingProviderApi->>VendorBoardAPI: GET /LicensingProviderConfigured
    activate VendorBoardAPI
    VendorBoardAPI->>LicensingProviderService: LicensingProviderConfigured()
    activate LicensingProviderService
    LicensingProviderService->>MongoDB: CountDocumentsAsync(filter, limit: 1)
    activate MongoDB
    MongoDB-->>LicensingProviderService: count: 0
    deactivate MongoDB
    LicensingProviderService-->>VendorBoardAPI: Response&lt;bool&gt; { Data = false }
    deactivate LicensingProviderService
    VendorBoardAPI-->>ILicensingProviderApi: false
    deactivate VendorBoardAPI
    ILicensingProviderApi-->>VendorBoardWeb: false
    deactivate ILicensingProviderApi
    VendorBoardWeb->>User: Show initialization form
    deactivate VendorBoardWeb
    
    User->>VendorBoardWeb: Fill form & click Initialize Provider
    activate VendorBoardWeb
    VendorBoardWeb->>ILicensingProviderApi: InitializeLicensingProviderAsync(name, externalId, description)
    activate ILicensingProviderApi
    ILicensingProviderApi->>VendorBoardAPI: POST /InitializeLicensingProvider
    activate VendorBoardAPI
    VendorBoardAPI->>LicensingProviderService: InitializeLicensingProvider(name, externalId, description)
    activate LicensingProviderService
    
    LicensingProviderService->>Vault: Get ProviderEncryptionAESKey
    activate Vault
    Vault-->>LicensingProviderService: AES Key (Base64)
    deactivate Vault
    
    LicensingProviderService->>LicensingProviderService: Check FastCrypt setting
    LicensingProviderService->>LicensingProviderService: GenerateRsaKeyPair(keySize: 2048 or 4096)
    LicensingProviderService->>LicensingProviderService: AesCrypt.AesEncrypt(privateKey, aesKey)
    
    LicensingProviderService->>MongoDB: InsertOneAsync(encryptedProvider)
    activate MongoDB
    MongoDB-->>LicensingProviderService: Success
    deactivate MongoDB
    
    LicensingProviderService-->>VendorBoardAPI: LicensingProviderDto (decrypted)
    deactivate LicensingProviderService
    VendorBoardAPI-->>ILicensingProviderApi: LicensingProviderDto
    deactivate VendorBoardAPI
    ILicensingProviderApi-->>VendorBoardWeb: LicensingProviderDto
    deactivate ILicensingProviderApi
    
    VendorBoardWeb->>VendorBoardWeb: NotificationService.Notify(Success)
    VendorBoardWeb->>VendorBoardWeb: Set _licensingOk = true
    VendorBoardWeb->>User: Render @Body content
    deactivate VendorBoardWeb
```

---

## Key Components
- **APIs**: VendorBoardController, LicensingProviderController  
- **Services**: LicensingProviderService (AES encryption, RSA key gen)
- **Shared**: VaultInitializer, KeyCloakOpenId, AesCrypt

## Technology Stack
.NET 10, Aspire, Blazor Server, MongoDB, Vault, KeyCloak, Radzen, Refit, Mapster

*Last Updated: 2024*