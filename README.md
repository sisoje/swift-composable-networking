# Networking as a Source of Truth: The Composable Networking
NOTE: This is (NOT) yet another networking library.

### Composability

- Achieving composability is easy: **Eliminate state ownership**
- Using composable components we can still create a class that owns and hides state when needed. **The opposite is much harder**
- Composable components can integrate seamlessly into the SwiftUI lifecycle. **Classes require "observability" boilerplate and manual lifecycle management**

### Complete diagram of composable networking with refresh token logic

```mermaid
graph TD
    A[NetworkingComposer] --> B[ComposableNetworking]
    A --> C[OAuthNetworking]
    A --> D[AuthorizedNetworking]
    A --> E[LocalTokenRefresh]
    A --> F[RemoteTokenRefresh]
    
    B --> C
    B --> G[Base NetworkingType]
    
    C --> D
    C --> E
    C --> H[isNotAuthorized]
    
    D --> G
    D --> I[authorizeRequest]
    D --> J[Binding bearerToken]
    
    E --> F
    E --> K[Binding refreshToken]
    E --> J
    E --> L[Binding refreshTask]
    
    F --> G
    F --> M[refreshTokenRequest]
    F --> N[parseToken]
    F --> H
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style C fill:#e8f5e8
    style D fill:#fff3e0
    style E fill:#fce4ec
    style F fill:#f1f8e9
    style G fill:#ffebee
    style H fill:#f9fbe7
    style I fill:#f9fbe7
    style J fill:#fff8e1
    style K fill:#fff8e1
    style L fill:#fff8e1
    style M fill:#f9fbe7
    style N fill:#f9fbe7
```

### Full implementation
[Composable Networking](https://gist.github.com/sisoje/2e5e5f00b4f310d06245314b2b560376)



