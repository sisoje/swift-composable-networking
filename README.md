# Networking as a Source of Truth: The Composable Networking
NOTE: This is (NOT) yet another networking library.

### Composability

- Achieving composability is easy: **Eliminate state ownership**
- Using composable components we can still create a class that owns and hides state when needed. **The opposite is much harder**
- Composable components can integrate seamlessly into the SwiftUI lifecycle. **Classes require "observability" boilerplate and manual lifecycle management**

### Complete diagram of composable networking with refresh token logic

```mermaid
graph TD
    networking[networking]
    BT[Binding bearerToken]
    RT[Binding refreshToken]
    Task[Binding refreshTask]
    AR[authorizeRequest]
    INA[isNotAuthorized]
    RTReq[refreshTokenRequest]
    PT[parseToken]
    
    AN[AuthorizedNetworking] --> networking
    AN --> AR
    AN --> BT
    
    CN[ComposableNetworking] --> ON[OAuthNetworking]
    CN --> networking
    CN --> BT
    
    ON --> AN
    ON --> LTR[LocalTokenRefresh]
    ON --> INA
    ON --> BT
    
    RTR[RemoteTokenRefresh] --> networking
    RTR --> RTReq
    RTR --> PT
    RTR --> INA
    
    LTR --> RTR
    LTR --> RT
    LTR --> BT
    LTR --> Task
    
    style networking fill:#000000
    style networking color:#ffffff
    style BT fill:#000000
    style BT color:#ffffff
    style RT fill:#000000
    style RT color:#ffffff
    style Task fill:#000000
    style Task color:#ffffff
    style AR fill:#000000
    style AR color:#ffffff
    style INA fill:#000000
    style INA color:#ffffff
    style RTReq fill:#000000
    style RTReq color:#ffffff
    style PT fill:#000000
    style PT color:#ffffff
    style AN fill:#f3e5f5
    style CN fill:#e8f5e8
    style ON fill:#fff3e0
    style RTR fill:#fce4ec
    style LTR fill:#f1f8e9
```

### Full implementation
[Composable Networking](https://gist.github.com/sisoje/2e5e5f00b4f310d06245314b2b560376)



