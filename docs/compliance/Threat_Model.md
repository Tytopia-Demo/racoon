# Threat Model - Google Auth Library for Ruby

## Overview

### Purpose
The Google Auth Library for Ruby (googleauth) is an authentication and authorization library that provides OAuth 2.0 implementation for Ruby applications. It enables applications to authenticate with Google APIs using various credential types including:
- Application Default Credentials (ADC)
- Service Account Credentials
- User Credentials (3-Legged OAuth2)
- Compute Engine Credentials
- ID Token Verification

### Scope
This threat model covers the googleauth Ruby gem and its security-critical components including credential management, token handling, OAuth 2.0 flows, cryptographic operations, and integration with Google's authentication infrastructure.

### Key Capabilities
- OAuth 2.0 authentication and authorization
- Service account authentication with JSON key files
- User authorization flows for web and command-line applications
- Token storage and refresh mechanisms
- ID token verification and validation
- Application Default Credentials resolution
- Integration with Google Cloud Platform services

## Data Flow Diagram

```
┌─────────────────┐
│  Application    │
│   (Consumer)    │
└────────┬────────┘
         │
         │ 1. Request credentials
         ▼
┌─────────────────────────────────────────────────────┐
│         Google Auth Library (googleauth)            │
│  ┌───────────────────────────────────────────────┐  │
│  │  Credential Sources:                          │  │
│  │  - Application Default (file/env/metadata)    │  │
│  │  - Service Account (JSON key)                 │  │
│  │  - User Authorizer (3-legged OAuth)          │  │
│  │  - Compute Engine Metadata                    │  │
│  └───────────────────────────────────────────────┘  │
│                       │                              │
│                       │ 2. Load credentials          │
│                       ▼                              │
│  ┌───────────────────────────────────────────────┐  │
│  │  Credentials Processing:                      │  │
│  │  - Parse JSON keys                            │  │
│  │  - Sign JWT tokens                            │  │
│  │  - OAuth token exchange                       │  │
│  └───────────────────────────────────────────────┘  │
└───────────────────┬─────────────────────────────────┘
                    │
                    │ 3. Request access token
                    ▼
┌─────────────────────────────────────────────────────┐
│     Google OAuth 2.0 Token Endpoints                │
│     - https://oauth2.googleapis.com/token           │
│     - https://www.googleapis.com/oauth2/v4/token    │
└─────────────────┬───────────────────────────────────┘
                  │
                  │ 4. Return access token
                  ▼
┌─────────────────────────────────────────────────────┐
│     Token Storage (Optional):                       │
│     - FileTokenStore                                │
│     - RedisTokenStore                               │
│     - Custom TokenStore                             │
└─────────────────┬───────────────────────────────────┘
                  │
                  │ 5. Store/retrieve tokens
                  ▼
┌─────────────────────────────────────────────────────┐
│     Application                                     │
│     - Applies token to API requests                 │
│     - Accesses Google APIs                          │
└─────────────────────────────────────────────────────┘
                  │
                  │ 6. API requests with token
                  ▼
┌─────────────────────────────────────────────────────┐
│     Google APIs                                     │
│     - Cloud Platform APIs                           │
│     - Workspace APIs                                │
│     - Other Google Services                         │
└─────────────────────────────────────────────────────┘
```

## Dependencies

### External Libraries
- **faraday** (>= 0.17.3, < 2.0) - HTTP client for API requests
- **jwt** (>= 1.4, < 3.0) - JSON Web Token encoding/decoding
- **signet** (~> 0.14) - OAuth 2.0 client implementation
- **multi_json** (~> 1.11) - JSON parsing library
- **memoist** (~> 0.16) - Memoization for performance
- **os** (>= 0.9, < 2.0) - Operating system detection

### External Services
- **Google OAuth 2.0 Token Endpoints** - Token issuance and validation
- **Google Compute Engine Metadata Service** - GCE credential source
- **Google Cloud IAM** - Service account management
- **Google Identity Platform** - ID token verification

### Development Dependencies
- bundler, rake, rspec, minitest - Testing and build tools
- redis, fakeredis - Token storage testing
- webmock - HTTP mocking for tests
- coveralls, simplecov - Code coverage
- google-style - Ruby style checking

## Entry Points

### 1. Credential Loading
- **Google::Auth.get_application_default(scope)** - Primary entry for ADC
- **Google::Auth::ServiceAccountCredentials.make_creds(options)** - Service account credentials
- **Google::Auth::Credentials.new(keyfile, options)** - Generic credential initialization
- **Google::Auth::UserAuthorizer.new(client_id, scope, token_store)** - User authorization

### 2. Configuration Sources
- **Environment Variables**:
  - `GOOGLE_APPLICATION_CREDENTIALS` - Path to JSON key file
  - `GOOGLE_PRIVATE_KEY` - Private key for service accounts
  - `GOOGLE_CLIENT_EMAIL` - Service account email
  - `GOOGLE_CLIENT_ID` - OAuth client ID
  - `GOOGLE_ACCOUNT_TYPE` - Account type specification
  - `GOOGLE_PROJECT_ID` - GCP project identifier
  
- **File System**:
  - JSON key files (service accounts)
  - Application default credentials files
  - Token storage files (FileTokenStore)
  - Well-known credential locations

- **Metadata Service**:
  - GCE/GKE metadata endpoints
  - IAM role credentials

### 3. Web Authorization Endpoints
- **OAuth callback handlers** - Receive authorization codes
- **Web user authorizer** - Rack/Sinatra integration points

### 4. Token Storage Operations
- **FileTokenStore** - Read/write to filesystem
- **RedisTokenStore** - Redis operations
- **Custom TokenStore implementations** - User-provided storage

## Exit Points

### 1. External HTTP Requests
- **OAuth token endpoints** - POST requests to obtain tokens
- **Metadata service requests** - GET requests for GCE credentials
- **ID token verification endpoints** - Key retrieval for validation

### 2. Token Storage
- **File system writes** - Storing tokens in files
- **Redis writes** - Storing tokens in Redis
- **Custom storage backends** - User-provided persistence

### 3. Application Integration
- **Token application to headers** - Adding Authorization headers
- **Credential objects** - Returned to consuming applications
- **Access tokens** - Provided for direct use

### 4. Logging and Diagnostics
- **Error messages** - May contain sensitive information
- **Debug output** - Credential lifecycle information

## Assets

### Critical Assets

1. **Private Keys**
   - Service account RSA private keys (2048+ bit)
   - Used for JWT signing and authentication
   - Stored in JSON key files or environment variables
   - Risk: Complete account compromise if exposed

2. **Access Tokens**
   - Bearer tokens for API access
   - Typically valid for 1 hour
   - Stored in memory and optionally persisted
   - Risk: Unauthorized API access during token lifetime

3. **Refresh Tokens**
   - Long-lived tokens for obtaining new access tokens
   - User authorization flow artifacts
   - Stored in token stores (file/Redis)
   - Risk: Long-term unauthorized access

4. **Client Secrets**
   - OAuth client credentials
   - Used in user authorization flows
   - Stored in client_secrets.json files
   - Risk: Impersonation of application

5. **ID Tokens**
   - JWT tokens containing user identity claims
   - Used for authentication verification
   - Risk: Identity spoofing if validation bypassed

### Supporting Assets

6. **Client IDs**
   - Public identifiers for OAuth clients
   - Less sensitive but enables reconnaissance

7. **Service Account Emails**
   - Identity of service accounts
   - Used in authorization policies

8. **Project IDs**
   - GCP project identifiers
   - May reveal organizational structure

9. **Authorization Codes**
   - Temporary codes in OAuth flows
   - Single-use, short-lived
   - Risk: Authorization code interception

10. **Token Store Data**
    - Persistent storage of tokens
    - File or database containing credentials
    - Risk: Bulk credential theft

## Trust Levels

### TL0: Untrusted
- **External attackers** - No legitimate access to the system
- **Malicious inputs** - Crafted data attempting exploitation
- **Network attackers** - Man-in-the-middle capabilities
- **Capabilities**: None
- **Access**: Public internet

### TL1: Low Trust (Application Consumer)
- **Host application** - Application using googleauth library
- **Application developers** - Those integrating the library
- **Capabilities**: 
  - Call library APIs
  - Provide configuration
  - Access returned credentials
- **Access**: Library interface only
- **Assumptions**: May have bugs or misconfigurations

### TL2: Medium Trust (Authenticated User)
- **End users** - Users who have authenticated via OAuth
- **Service accounts** - Configured with appropriate credentials
- **Capabilities**:
  - Obtain access tokens
  - Access APIs within granted scopes
- **Access**: APIs according to OAuth scopes
- **Assumptions**: Properly authenticated but may attempt privilege escalation

### TL3: High Trust (Credential Owner)
- **System administrators** - Manage service accounts and keys
- **DevOps engineers** - Deploy and configure applications
- **Capabilities**:
  - Manage credential files
  - Configure environment variables
  - Access production systems
- **Access**: Full credential management
- **Assumptions**: Trusted but may make mistakes

### TL4: Full Trust (Google Infrastructure)
- **Google OAuth servers** - Token issuance and validation
- **Google metadata service** - Credential provisioning
- **Google IAM** - Identity and access management
- **Capabilities**: Complete control over authentication
- **Access**: All authentication data
- **Assumptions**: Fully trusted, secure infrastructure

## STRIDE Threat List

### Spoofing Identity (S)

**S1: Service Account Key Theft**
- **Description**: Attacker obtains service account JSON key file from filesystem, repository, or logs
- **Impact**: Complete impersonation of service account, full access to scoped APIs
- **Likelihood**: High - Keys often accidentally committed to repositories
- **Affected Assets**: Private keys, service account credentials
- **Affected Components**: ServiceAccountCredentials, JsonKeyReader

**S2: Access Token Theft**
- **Description**: Attacker intercepts or extracts access tokens from memory, logs, or storage
- **Impact**: Unauthorized API access for token lifetime (~1 hour)
- **Likelihood**: Medium - Requires access to application memory or storage
- **Affected Assets**: Access tokens
- **Affected Components**: All credential classes, token storage

**S3: Metadata Service Impersonation**
- **Description**: Attacker redirects metadata service requests to malicious endpoint (SSRF)
- **Impact**: Injection of malicious credentials
- **Likelihood**: Low - Requires ability to manipulate network or DNS
- **Affected Assets**: Compute Engine credentials
- **Affected Components**: ComputeEngineCredentials

**S4: OAuth Authorization Code Interception**
- **Description**: Attacker intercepts authorization code during OAuth redirect
- **Impact**: Token theft via code exchange
- **Likelihood**: Medium - Possible in open redirector scenarios or non-HTTPS
- **Affected Assets**: Authorization codes, refresh tokens
- **Affected Components**: WebUserAuthorizer, UserAuthorizer

**S5: Client Secret Exposure**
- **Description**: OAuth client secrets leaked in public repositories or logs
- **Impact**: Application impersonation, phishing attacks
- **Likelihood**: High - Common configuration mistake
- **Affected Assets**: Client secrets
- **Affected Components**: ClientId, UserAuthorizer

### Tampering (T)

**T1: Credential File Tampering**
- **Description**: Attacker modifies JSON key files or token storage with malicious credentials
- **Impact**: Application uses attacker-controlled credentials
- **Likelihood**: Medium - Requires filesystem write access
- **Affected Assets**: JSON key files, token stores
- **Affected Components**: FileTokenStore, JsonKeyReader

**T2: Environment Variable Injection**
- **Description**: Attacker injects malicious values into credential environment variables
- **Impact**: Application loads attacker's credentials
- **Likelihood**: Medium - Depends on application deployment security
- **Affected Assets**: All credential types loaded from environment
- **Affected Components**: CredentialsLoader, ServiceAccountCredentials

**T3: Man-in-the-Middle Token Manipulation**
- **Description**: Attacker intercepts and modifies OAuth token exchange
- **Impact**: Modified scopes, tampered tokens
- **Likelihood**: Low - Requires HTTPS downgrade or certificate bypass
- **Affected Assets**: Access tokens, refresh tokens
- **Affected Components**: Signet OAuth2 client, HTTP layer

**T4: Dependency Tampering**
- **Description**: Attacker compromises upstream dependencies (jwt, signet, faraday)
- **Impact**: Complete compromise of authentication flow
- **Likelihood**: Low - Supply chain attack
- **Affected Assets**: All assets
- **Affected Components**: All components

**T5: Token Store Corruption**
- **Description**: Attacker corrupts Redis or file-based token storage
- **Impact**: Denial of service, potential credential theft
- **Likelihood**: Low - Requires access to storage backend
- **Affected Assets**: Refresh tokens, access tokens
- **Affected Components**: RedisTokenStore, FileTokenStore

### Repudiation (R)

**R1: Insufficient Audit Logging**
- **Description**: Lack of logging for credential usage and failures
- **Impact**: Cannot track unauthorized access or debug security incidents
- **Likelihood**: High - Library focuses on functionality over audit
- **Affected Assets**: All credential operations
- **Affected Components**: All authentication components

**R2: Token Usage Tracking**
- **Description**: No mechanism to audit which tokens accessed which resources
- **Impact**: Difficulty attributing actions to specific credentials
- **Likelihood**: High - Logging is application responsibility
- **Affected Assets**: Access tokens
- **Affected Components**: Credentials application logic

**R3: Credential Rotation Events**
- **Description**: No logging when credentials are loaded, refreshed, or changed
- **Impact**: Cannot detect credential compromise patterns
- **Likelihood**: High - Limited logging in library
- **Affected Assets**: All credential types
- **Affected Components**: All credential loaders

### Information Disclosure (I)

**I1: Credentials in Error Messages**
- **Description**: Error messages or stack traces expose credentials or tokens
- **Impact**: Credential leakage through logs or error reporting
- **Likelihood**: Medium - Depends on error handling
- **Affected Assets**: All credential types
- **Affected Components**: All components with error handling

**I2: Credentials in Logs**
- **Description**: Credentials logged during debug or error conditions
- **Impact**: Credential exposure to log aggregation systems
- **Likelihood**: Medium - Especially in debug mode
- **Affected Assets**: Private keys, tokens, client secrets
- **Affected Components**: All components

**I3: Token in HTTP Referer Headers**
- **Description**: Tokens leaked via HTTP Referer when navigating from authenticated pages
- **Impact**: Token exposure to third-party sites
- **Likelihood**: Low - Application-level concern
- **Affected Assets**: Access tokens
- **Affected Components**: Web authorization flows

**I4: Memory Dumps Containing Credentials**
- **Description**: Core dumps or memory snapshots contain credentials in plaintext
- **Impact**: Credential recovery from system memory
- **Likelihood**: Medium - Common in production debugging
- **Affected Assets**: All in-memory credentials
- **Affected Components**: All components

**I5: Token Store Insufficient Access Controls**
- **Description**: Token storage files or Redis instances accessible to unauthorized users
- **Impact**: Bulk credential theft
- **Likelihood**: Medium - Depends on deployment configuration
- **Affected Assets**: Refresh tokens, access tokens
- **Affected Components**: FileTokenStore, RedisTokenStore

**I6: Side-Channel Information Leaks**
- **Description**: Timing attacks on JWT validation or token comparison
- **Impact**: Token or signature prediction
- **Likelihood**: Low - Requires sophisticated attack
- **Affected Assets**: JWT signatures, tokens
- **Affected Components**: ID token verification, JWT signing

### Denial of Service (D)

**D1: Excessive Token Refresh Requests**
- **Description**: Attacker triggers excessive token refresh causing rate limiting
- **Impact**: Legitimate applications cannot obtain tokens
- **Likelihood**: Medium - Can be triggered by misconfiguration
- **Affected Assets**: Token endpoints
- **Affected Components**: Token refresh logic

**D2: Metadata Service Unavailability**
- **Description**: Metadata service becomes unavailable or unreachable
- **Impact**: GCE/GKE applications cannot authenticate
- **Likelihood**: Low - Google infrastructure is highly available
- **Affected Assets**: Compute Engine credentials
- **Affected Components**: ComputeEngineCredentials

**D3: Token Store Exhaustion**
- **Description**: Attacker fills token storage with invalid tokens
- **Impact**: Storage exhaustion, legitimate tokens cannot be stored
- **Likelihood**: Low - Requires write access to token store
- **Affected Assets**: Token storage
- **Affected Components**: FileTokenStore, RedisTokenStore

**D4: Malformed Credential Files**
- **Description**: Malformed JSON or invalid credential formats cause parsing failures
- **Impact**: Application cannot load credentials
- **Likelihood**: Medium - Can occur during manual configuration
- **Affected Assets**: All credential types
- **Affected Components**: JsonKeyReader, CredentialsLoader

**D5: Certificate Validation Blocking**
- **Description**: HTTPS certificate validation failures prevent token requests
- **Impact**: Cannot communicate with OAuth endpoints
- **Likelihood**: Low - Usually indicates attack or misconfiguration
- **Affected Assets**: Token endpoints
- **Affected Components**: HTTP client (Faraday)

**D6: Resource Exhaustion via Large Keys**
- **Description**: Extremely large RSA keys or malformed cryptographic data cause CPU exhaustion
- **Impact**: Application hangs during credential processing
- **Likelihood**: Low - Requires malicious credential injection
- **Affected Assets**: Private keys
- **Affected Components**: ServiceAccountCredentials, JWT signing

### Elevation of Privilege (E)

**E1: Scope Escalation via Token Modification**
- **Description**: Attacker modifies tokens to gain access to unauthorized scopes
- **Impact**: Access to APIs beyond granted permissions
- **Likelihood**: Low - Tokens are signed by Google
- **Affected Assets**: Access tokens
- **Affected Components**: Token handling logic

**E2: Insufficient Scope Validation**
- **Description**: Application doesn't validate that returned token has requested scopes
- **Impact**: Application uses token with fewer permissions than expected
- **Likelihood**: Medium - Application-level concern
- **Affected Assets**: Access tokens
- **Affected Components**: Credentials API consumers

**E3: Service Account Impersonation**
- **Description**: One service account gains ability to impersonate another
- **Impact**: Privilege escalation across service accounts
- **Likelihood**: Low - Requires IAM policy misconfiguration
- **Affected Assets**: Service account credentials
- **Affected Components**: ServiceAccountCredentials, IAM integration

**E4: Metadata Service Privilege Escalation**
- **Description**: Process gains access to metadata service credentials beyond its permissions
- **Impact**: Access to credentials of more privileged workloads
- **Likelihood**: Low - Requires container escape or SSRF
- **Affected Assets**: Compute Engine credentials
- **Affected Components**: ComputeEngineCredentials

**E5: Token Store Privilege Escalation**
- **Description**: Attacker reads tokens from shared token store meant for different users
- **Impact**: Access to other users' credentials
- **Likelihood**: Medium - Common in multi-tenant deployments
- **Affected Assets**: Refresh tokens, access tokens
- **Affected Components**: FileTokenStore, RedisTokenStore, user_id isolation

**E6: Dependency Vulnerability Exploitation**
- **Description**: Vulnerabilities in jwt, signet, or faraday dependencies exploited
- **Impact**: Arbitrary code execution, credential theft
- **Likelihood**: Medium - Dependencies have security issues periodically
- **Affected Assets**: All assets
- **Affected Components**: All components using vulnerable dependencies

**E7: ID Token Validation Bypass**
- **Description**: Improper ID token validation allows forged identity claims
- **Impact**: Authentication bypass, identity spoofing
- **Likelihood**: Low - Library implements proper validation
- **Affected Assets**: ID tokens
- **Affected Components**: IDTokens verifier

## Countermeasures

### Spoofing Countermeasures

**CM-S1: Secure Credential Storage**
- **Threats Addressed**: S1, S2, I5
- **Implementation**:
  - Never commit credentials to version control
  - Use secret management systems (Google Secret Manager, HashiCorp Vault)
  - Set restrictive file permissions (0600) on credential files
  - Encrypt credentials at rest when possible
  - Use IAM Workload Identity in GKE instead of JSON keys
- **Components**: All credential storage
- **Priority**: Critical

**CM-S2: Short-lived Tokens**
- **Threats Addressed**: S2
- **Implementation**:
  - Access tokens expire after 1 hour (enforced by Google)
  - Refresh tokens automatically when expired
  - Implement token revocation when compromise detected
  - Monitor for abnormal token usage patterns
- **Components**: All credential types
- **Priority**: High

**CM-S3: Metadata Service Security**
- **Threats Addressed**: S3, E4
- **Implementation**:
  - Validate metadata service endpoints (correct URL)
  - Use metadata service identity binding
  - Implement network policies to restrict metadata access
  - Monitor metadata service access patterns
- **Components**: ComputeEngineCredentials
- **Priority**: High

**CM-S4: OAuth Flow Security**
- **Threats Addressed**: S4
- **Implementation**:
  - Always use HTTPS for redirect URIs
  - Implement PKCE (Proof Key for Code Exchange) where supported
  - Validate state parameter to prevent CSRF
  - Use exact redirect URI matching
  - Set short authorization code expiration
- **Components**: WebUserAuthorizer, UserAuthorizer
- **Priority**: Critical

**CM-S5: Client Secret Protection**
- **Threats Addressed**: S5
- **Implementation**:
  - Store client secrets in secure configuration management
  - Never commit client_secrets.json to repositories
  - Rotate client secrets periodically
  - Use separate OAuth clients for different environments
- **Components**: ClientId, user authorization flows
- **Priority**: Critical

### Tampering Countermeasures

**CM-T1: Credential File Integrity**
- **Threats Addressed**: T1
- **Implementation**:
  - Use file integrity monitoring on credential paths
  - Set immutable flags on credential files where possible
  - Validate JSON structure and required fields
  - Use checksums or signatures for credential files
- **Components**: JsonKeyReader, FileTokenStore
- **Priority**: High

**CM-T2: Environment Variable Security**
- **Threats Addressed**: T2
- **Implementation**:
  - Restrict environment variable modification
  - Use container security contexts to limit environment access
  - Validate environment variable values before use
  - Prefer metadata service or file-based credentials over environment variables
- **Components**: CredentialsLoader
- **Priority**: Medium

**CM-T3: HTTPS Enforcement**
- **Threats Addressed**: T3
- **Implementation**:
  - Enforce HTTPS for all OAuth communication (library default)
  - Validate SSL/TLS certificates
  - Use certificate pinning for critical endpoints
  - Fail closed on certificate validation errors
- **Components**: HTTP client, Faraday configuration
- **Priority**: Critical

**CM-T4: Dependency Security**
- **Threats Addressed**: T4, E6
- **Implementation**:
  - Keep dependencies updated to latest secure versions
  - Monitor security advisories for jwt, signet, faraday
  - Use Bundler audit for vulnerability scanning
  - Implement dependency pinning and verification
  - Review dependency changes in updates
- **Components**: All dependencies
- **Priority**: High

**CM-T5: Token Store Protection**
- **Threats Addressed**: T5, I5
- **Implementation**:
  - Use authenticated and encrypted connections to Redis
  - Set appropriate file permissions on FileTokenStore files
  - Implement token store access controls
  - Encrypt token store data at rest
  - Use separate token stores per environment
- **Components**: RedisTokenStore, FileTokenStore
- **Priority**: High

### Repudiation Countermeasures

**CM-R1: Comprehensive Logging**
- **Threats Addressed**: R1, R2, R3
- **Implementation**:
  - Log credential loading events (without sensitive data)
  - Log authentication successes and failures
  - Log token refresh operations
  - Include correlation IDs for request tracking
  - Send logs to centralized logging system
  - Implement log retention policies
- **Components**: All authentication components
- **Priority**: Medium

**CM-R2: Audit Trail**
- **Threats Addressed**: R1, R2, R3
- **Implementation**:
  - Use Google Cloud Audit Logs for API access
  - Implement application-level audit logging
  - Track which service accounts accessed which resources
  - Monitor for anomalous access patterns
  - Implement alerting on suspicious activities
- **Components**: Integration with Google Cloud services
- **Priority**: Medium

### Information Disclosure Countermeasures

**CM-I1: Sanitized Error Handling**
- **Threats Addressed**: I1, I2
- **Implementation**:
  - Redact credentials from error messages
  - Avoid logging full exception details in production
  - Sanitize stack traces before logging
  - Use structured logging with credential filtering
  - Implement separate debug and production logging
- **Components**: All components
- **Priority**: Critical

**CM-I2: Secure Logging Practices**
- **Threats Addressed**: I2
- **Implementation**:
  - Never log private keys, access tokens, or refresh tokens
  - Redact sensitive fields in JSON logging
  - Use log levels appropriately (avoid debug in production)
  - Implement log encryption at rest
  - Restrict access to log aggregation systems
- **Components**: All components
- **Priority**: Critical

**CM-I3: Memory Protection**
- **Threats Addressed**: I4
- **Implementation**:
  - Clear sensitive data from memory when no longer needed
  - Disable core dumps in production environments
  - Use memory encryption where available
  - Implement secure memory allocation for secrets
  - Limit memory dump collection to trusted administrators
- **Components**: All components handling credentials
- **Priority**: Medium

**CM-I4: Token Store Access Controls**
- **Threats Addressed**: I5, E5
- **Implementation**:
  - Set restrictive file permissions (0600) on FileTokenStore
  - Use authentication for Redis connections
  - Implement network isolation for token stores
  - Use separate token stores per user/tenant
  - Encrypt token store data at rest
- **Components**: FileTokenStore, RedisTokenStore
- **Priority**: High

**CM-I5: Timing Attack Prevention**
- **Threats Addressed**: I6
- **Implementation**:
  - Use constant-time comparison for tokens
  - Implement timing-safe string comparison
  - Use cryptographic libraries with timing attack protections
  - Avoid branching on secret-dependent conditions
- **Components**: ID token verification, token comparison
- **Priority**: Medium

### Denial of Service Countermeasures

**CM-D1: Rate Limiting and Backoff**
- **Threats Addressed**: D1
- **Implementation**:
  - Implement exponential backoff for token refresh
  - Cache tokens and reuse until expiration
  - Limit concurrent token refresh requests
  - Monitor token endpoint rate limits
  - Implement circuit breakers for OAuth endpoints
- **Components**: Token refresh logic
- **Priority**: Medium

**CM-D2: Resilient Metadata Service Access**
- **Threats Addressed**: D2
- **Implementation**:
  - Implement timeouts for metadata service requests
  - Cache metadata service responses
  - Implement fallback credential sources
  - Monitor metadata service availability
- **Components**: ComputeEngineCredentials
- **Priority**: Medium

**CM-D3: Token Store Capacity Management**
- **Threats Addressed**: D3
- **Implementation**:
  - Implement token expiration and cleanup
  - Set maximum token store size limits
  - Monitor token store capacity
  - Implement token store rotation policies
- **Components**: FileTokenStore, RedisTokenStore
- **Priority**: Low

**CM-D4: Input Validation**
- **Threats Addressed**: D4, D6
- **Implementation**:
  - Validate JSON credential file format
  - Verify RSA key size and format
  - Implement size limits on credential inputs
  - Fail gracefully on malformed inputs
  - Validate all configuration parameters
- **Components**: JsonKeyReader, CredentialsLoader
- **Priority**: High

**CM-D5: Certificate Validation**
- **Threats Addressed**: D5
- **Implementation**:
  - Enforce certificate validation (no bypass options)
  - Keep CA certificate bundle updated
  - Implement certificate expiration monitoring
  - Use certificate pinning for critical endpoints
- **Components**: HTTP client (Faraday)
- **Priority**: Critical

### Elevation of Privilege Countermeasures

**CM-E1: Scope Validation**
- **Threats Addressed**: E1, E2
- **Implementation**:
  - Validate requested vs granted scopes
  - Implement least-privilege scope requests
  - Document required scopes per use case
  - Audit scope usage regularly
  - Reject tokens with unexpected scopes
- **Components**: All credential types
- **Priority**: High

**CM-E2: Service Account IAM Policies**
- **Threats Addressed**: E3
- **Implementation**:
  - Follow principle of least privilege for service accounts
  - Regularly audit service account IAM policies
  - Disable unused service accounts
  - Implement service account key rotation
  - Use workload identity instead of keys where possible
- **Components**: ServiceAccountCredentials
- **Priority**: High

**CM-E3: Workload Isolation**
- **Threats Addressed**: E4
- **Implementation**:
  - Use separate service accounts per workload
  - Implement namespace isolation in Kubernetes
  - Restrict metadata service access via network policies
  - Use workload identity binding
  - Monitor cross-workload access attempts
- **Components**: ComputeEngineCredentials
- **Priority**: High

**CM-E4: Token Store User Isolation**
- **Threats Addressed**: E5
- **Implementation**:
  - Use unique token store keys per user ID
  - Validate user ID ownership before token retrieval
  - Implement token store access controls
  - Use separate Redis databases per tenant
  - Audit token store access patterns
- **Components**: FileTokenStore, RedisTokenStore
- **Priority**: Critical

**CM-E5: Dependency Management**
- **Threats Addressed**: E6
- **Implementation**:
  - Keep all dependencies updated
  - Subscribe to security advisories
  - Use automated dependency scanning (Bundler audit, Dependabot)
  - Test updates in staging before production
  - Maintain inventory of dependency versions
- **Components**: All dependencies
- **Priority**: High

**CM-E6: ID Token Validation**
- **Threats Addressed**: E7
- **Implementation**:
  - Validate ID token signature using Google's public keys
  - Verify issuer claim (accounts.google.com)
  - Validate audience claim matches client ID
  - Check token expiration
  - Verify token not before (nbf) claim
  - Implement token replay prevention
- **Components**: IDTokens verifier
- **Priority**: Critical

### Additional Security Measures

**CM-A1: Security Documentation**
- **Implementation**:
  - Document secure credential management practices
  - Provide security best practices guide
  - Include security examples in documentation
  - Document common security pitfalls
  - Maintain security changelog

**CM-A2: Security Testing**
- **Implementation**:
  - Include security test cases in test suite
  - Test credential validation logic
  - Test error handling for security
  - Implement fuzz testing for parsers
  - Conduct regular security reviews

**CM-A3: Incident Response**
- **Implementation**:
  - Document credential compromise response procedures
  - Implement token revocation mechanisms
  - Maintain security contact information
  - Plan for rapid credential rotation
  - Test incident response procedures

**CM-A4: Security Monitoring**
- **Implementation**:
  - Monitor for unusual authentication patterns
  - Alert on failed authentication attempts
  - Track credential usage metrics
  - Implement anomaly detection
  - Monitor dependency vulnerabilities

## Implementation Notes

### Security Best Practices for Users

1. **Credential Management**:
   - Use Workload Identity in GKE/GCE instead of JSON key files
   - Never commit credentials to version control (use .gitignore)
   - Rotate service account keys regularly
   - Use Google Secret Manager for credential storage

2. **Scope Management**:
   - Request minimum required scopes
   - Document scope requirements
   - Review and audit granted scopes

3. **Token Storage**:
   - Use encrypted token storage in production
   - Implement proper file permissions
   - Use authenticated Redis connections
   - Separate token stores per environment

4. **Deployment**:
   - Use secrets management in CI/CD pipelines
   - Encrypt credentials at rest
   - Restrict metadata service access
   - Implement network policies

5. **Monitoring**:
   - Enable Cloud Audit Logs
   - Monitor for credential leakage in logs
   - Implement alerting on authentication failures
   - Track token usage patterns

### Library Maintenance

1. **Dependency Updates**:
   - Monitor security advisories
   - Update dependencies promptly
   - Test security updates thoroughly

2. **Code Review**:
   - Security-focused code reviews
   - Review credential handling logic
   - Audit logging implementation

3. **Testing**:
   - Security test coverage
   - Penetration testing
   - Dependency vulnerability scanning

## References

- [OWASP Threat Modeling](https://owasp.org/www-community/Threat_Modeling)
- [STRIDE Threat Model](https://docs.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats)
- [Google Cloud Security Best Practices](https://cloud.google.com/security/best-practices)
- [OAuth 2.0 Security Best Current Practice](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics)
- [Application Default Credentials](https://cloud.google.com/docs/authentication/production)

## Document Information

- **Version**: 1.0
- **Last Updated**: 2024
- **Owner**: Security Team
- **Review Cycle**: Quarterly
- **Next Review**: TBD

---

This threat model should be reviewed and updated whenever:
- New features are added to the library
- Security vulnerabilities are discovered
- Changes are made to authentication flows
- New dependencies are added
- Infrastructure changes affect credential handling
