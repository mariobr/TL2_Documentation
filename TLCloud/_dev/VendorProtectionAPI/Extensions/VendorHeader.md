# VendorHeaderFilter Analysis

## Overview
`VendorHeaderFilter` is a critical security component in the TLCloud multi-tenant architecture that validates vendor instance secret keys and enforces authorization at the API endpoint level.

---

## Architecture Components

### 1. VendorHeaderFilter Design

**Location:** `VendorProtectionAPI\Extensions\VendorHeaderFilter.cs`

**Dual Purpose Implementation:**

#### A. Runtime Security (IEndpointFilter)
- Intercepts incoming HTTP requests before they reach endpoint handlers
- Validates `VendorInstanceSecret-Secret-Key` header
- Calls `VendorProtectionService.ValidateVendor()` to verify authorization
- Returns appropriate HTTP status codes (400/500/200)

#### B. API Documentation (IOperationFilter)
- Automatically adds vendor secret header to OpenAPI/Swagger specification
- Documents the header as **required** for all filtered endpoints
- Improves developer experience by making the requirement explicit

---

## Security Flow

```mermaid
	sequenceDiagram  
	Client->>Handler: HTTP Request
Note over Handler: Extract secret from:<br/>1. HttpContext.Request.Headers<br/>2. User Claims<br/>3. HttpContext.Items<br/>4. Memory Cache

alt Secret Found in Cache
    Handler->>Handler: Retrieve from cache
else Secret in Claims
    Handler->>Handler: Extract from JWT claims
else Secret in Headers
    Handler->>Handler: Forward from incoming request
end

Handler->>Handler: Add VendorInstanceSecret-Secret-Key header
Handler->>API: Forward HTTP request with header

API->>Filter: Invoke endpoint filter
Filter->>Filter: Extract secret from header

alt Secret Missing
    Filter-->>Client: 400 Bad Request<br/>"Secret key not found"
end

Filter->>Service: ValidateVendor(secretKey)

alt Service Unavailable
    Filter-->>Client: 500 Internal Server Error<br/>"Service unavailable"
end

Service->>DB: Query vendor with secret key
DB-->>Service: Vendor data + contract

Service->>Service: Validate:<br/>1. Secret exists<br/>2. Contract not expired<br/>3. Vendor not disabled<br/>4. Instance active

alt Validation Success & CanRun=true
    Service-->>Filter: Success=true, CanRun=true
    Filter->>Endpoint: Continue to endpoint handler
    Endpoint->>Endpoint: Process business logic
    Endpoint-->>Client: 200 OK with response data
else Validation Success but CanRun=false
    Service-->>Filter: Success=true, CanRun=false
    Filter-->>Client: 400 Bad Request<br/>"Vendor not allowed to access"
else Validation Failed
    Service-->>Filter: Success=false, ErrorMessage
    Filter-->>Client: 400 Bad Request<br/>ErrorMessage
else Exception During Validation
    Service-->>Filter: Exception thrown
    Filter-->>Client: 400 Bad Request<br/>"Validation failed"
end
```

---

## HTTP Status Code Matrix

| Condition | Status Code | Response |
|-----------|-------------|----------|
| Secret missing | 400 | null (sets status code directly) |
| Service unavailable | 500 | null (sets status code directly) |
| Validation success + CanRun=true | 200 | Continues to endpoint |
| Validation success + CanRun=false | 400 | `Results.BadRequest("Vendor not allowed...")` |
| Validation failed | 400 | `Results.BadRequest(errorMessage)` |
| Exception during validation | 400 | `Results.BadRequest("Validation failed")` |

---

## Service Dependencies

### VendorProtectionService.ValidateVendor()

**Expected Response Structure:**

```json
{
  "success": true|false,
  "canRun": true|false,
  "errorMessage": "string"
}
```

- **success**: Indicates if the validation was successful.
- **canRun**: Indicates if the vendor is allowed to access the requested resource.
- **errorMessage**: Contains error details if `success` is false.

**Caching Behavior:**
- Successful validations (`isValid: true`) are cached for **performance optimization**.
- Cache duration and invalidation policies are managed internally.

---

## Summary

**VendorHeaderFilter** is a critical security component providing:
- ✅ **Multi-tenant isolation** via secret key validation
- ✅ **Defense-in-depth** architecture with multiple validation layers
- ✅ **Developer-friendly** automatic Swagger documentation
- ✅ **Production-ready** comprehensive error handling and logging
- ✅ **Performance-optimized** caching strategy
- ✅ **Secure by design** fail-safe defaults and partial secret logging

This filter is **essential for all vendor-specific APIs** in the TLCloud platform and works in conjunction with JWT authentication to provide complete authorization for multi-tenant SaaS operations.

---

## Related Documentation

- [VendorInstanceSecretHandler Implementation](../TLWebCommon/Handlers/VendorInstanceSecretHandler.cs)
- [VendorSecretValidationMiddleware](../VendorBoardAPI/Middleware/VendorSecretValidationMiddleware.cs)
- [VendorProtectionService](../TLVendor/Service/VendorProtectionService.cs)
- [Multi-Tenant Architecture Overview](../../docs/MultiTenantArchitecture.md)
- [Security Best Practices](../../docs/SecurityBestPractices.md)

---

**Last Updated:** January 2025  
**Version:** 1.0  
**Maintainer:** TLCloud Architecture Team
