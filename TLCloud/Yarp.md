# YARP Reverse Proxy Analysis

## Overview
The application uses YARP in the Blazor Server host (`LicenseManagementSystemWeb`) as a gateway to internal cloud services (Licensing, Catalog, Identity, etc.). It enriches outbound proxied requests with tenant-specific headers derived from a `VendorInstanceConfiguration` loaded from Vault.

## Initialization Flow
1. `Program.cs` calls `await builder.ConfigureYarp();`
2. `ConfigureYarp`:
   - Reads `VaultConfig:VendorInstanceId` from configuration.
   - Fetches `VendorInstanceConfiguration` via `ITLCloudVaultService`.
   - Extracts:
     - `SecretKey`
     - `VendorInstanceId`
     - `VendorIdentityProvider.ServerRealm`
   - Builds reverse proxy with `.AddReverseProxy().LoadFromMemory(routes, clusters)`.
   - Adds a request transform that injects custom headers.

## Injected Headers
| Header | Purpose |
|--------|---------|
| `VendorInstanceSecret-Secret-Key` | Shared instance deployment secret (app-level key) |
| `VendorInstance-Public` | Public instance identifier for correlation / scoping |
| `VendorInstance-Realm` | Realm/issuer used for token validation (`TokenAuthenticationHandler`) |

Headers are added on every proxied request server-side (never exposed to the browser directly).

## Security Semantics
- The secret key is static for the lifetime of the process (loaded once).
- JWT validation downstream relies on `VendorInstance-Realm` + standard signature verification (public key cached).
- Shared secret can support additional authorization middleware (not shown here).
- No automatic rotation or refresh of the secret/realm values after startup.

## Current Strengths
- Centralized header injection (low risk of client misuse).
- Separation of internal service addresses via YARP route/cluster abstraction.
- Early Vault retrieval allows failing fast before mapping proxy routes.

## Observed Gaps / Risks
1. Silent failure: If Vault retrieval fails (`!reqVendorConfig.Success`), method returns with no logging—proxy still maps later, producing empty routing.
2. No secret rotation strategy: Long-lived process holds outdated secret if rotated in Vault.
3. Duplicate header potential: `Headers.Add(...)` without prior removal may stack duplicates if upstream code adds same headers.
4. No ordering or conditional transforms: All routes get identical headers (even if some services might not require them).
5. Lack of observability: No structured logging of configured clusters/routes or transform injection.
6. Single-tenant assumption: Fixed `VendorInstanceId`; scaling to multi-tenant (per request host/path) would require dynamic resolution.

## Recommended Improvements
- Log success/failure of Vault load.
- Introduce a lightweight cache with periodic refresh (e.g., `IHostedService`) to re-fetch `VendorInstanceConfiguration`.
- Replace `Add` with remove-then-add or use YARP `RequestHeaderDictionary` update semantics.
- Add a validation middleware downstream that enforces the presence and correctness of all three headers centrally.
- Add structured logging:
  - Loaded routes count
  - Cluster destinations
  - Active instance id / realm
- Consider per-request resolution if host header maps to different instances in future.

