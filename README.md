# The Composable Networking

### This is (NOT) yet another networking library.

---

## Why networking?

Apple gave us networking.  
There’s a `URLSession`, and we can use it.

That’s exactly what we’re gonna do — but in a **composable** way.

---

## Why composable?

Assuming you use **native SwiftUI** as Apple intended —  
- no MVVM  
- no state outside the app-lifecycle  
— then ultimately you need to plug **networking** and all of its layers into the **app-lifecycle** (same as view-lifecycle in SwiftUI).

**SwiftUI apps are functions of state.**  
They follow the **same principles** of composition and update as the views themselves.

Objects are not pluggable.  
Only values are.

And guess what?  
**Functions are values.**

You can convert *any* class-based API into value-based composable pieces — if you separate **state from behavior**.  
That’s what makes your networking **composable**.

---

## What is networking?

In most cases, it’s just a damn function:

```swift
(URLRequest) async throws -> (Data, URLResponse)
```

Whatever we compose — in the end, it needs to give us that **same exact function**.

---

## Let’s GO.

Here’s our base function:

```swift
URLSession.shared.data(for:)
```

Now we might need to authorize using a bearer token.  
We need storage for it.  
If the token is `nil`, we just call the base function normally.

---

## Step 1 — `ComposableNetworking`

```swift
struct ComposableNetworking {
    @Binding var bearerToken: String?
    let authComposer: AuthComposer
    let baseFunction: NetworkClosureType

    var composition: NetworkClosureType {
        if bearerToken != nil {
            authComposer.composition
        } else {
            baseFunction
        }
    }
}
```

That’s it.  
Our networking layer is **done** —  
Except we don’t yet have the `AuthComposer`.

---

## Step 2 — `AuthComposer`

```swift
struct AuthComposer {
    @Binding var bearerToken: String?
    let baseFunction: NetworkClosureType
    let authorizeRequest: (URLRequest, String) -> URLRequest

    var composition: NetworkClosureType {
        { request in
            guard let token = bearerToken else {
                throw ComposableNetworkingError.noBearerToken
            }
            return try await baseFunction(authorizeRequest(request, token))
        }
    }
}
```

Boom.  
`AuthComposer` is done.  
It transforms the request, injects the token, and delegates to the base function.

---

## Step 3 — Composing Everything: `RootComposer`

```swift
struct RootComposer {
    var composableNetworking: ComposableNetworking {
        fatalError()
        // Homework:
        // Initialize ComposableNetworking(…)
        // Add all missing dependencies to RootComposer.
        // If it depends on another component — add that one as a property.
        // When you're done, you’ve listed **all root dependencies** in one place.
    }

    var composition: NetworkClosureType {
        composableNetworking.composition
    }
}
```

This is your **root composition**.

It contains **everything** — all dependencies wired up from the top.

---

## That’s It.

This isn’t a "framework".  
It’s just **pure Swift**, **pure values**, and **pure functions**.

No MVVM.  
No dependency injection libraries.  
No mocking frameworks.  
Just **composition**.

Functions in, functions out.

```swift
(URLRequest) async throws -> (Data, URLResponse)
```

That’s the goal.

Now go compose it.
