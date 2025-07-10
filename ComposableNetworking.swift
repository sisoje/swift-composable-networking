import Foundation
import SwiftUI

// MARK: - types

typealias NetworkClosureType = (URLRequest) async throws -> (Data, URLResponse)

enum ParsedToken {
    case valid(String)
    case notPossibleToRefresh
}

enum ComposableNetworkingError: Error {
    case noBearerToken
    case noRefreshToken
}

// MARK: - components

struct ComposableNetworking {
    @Binding var bearerToken: String?
    let oauthComposer: OAuthRequestComposer
    let basicRequest: NetworkClosureType
    
    var composition: NetworkClosureType {
        if bearerToken != nil {
            oauthComposer.composition
        } else {
            basicRequest
        }
    }
}

struct AuthizedRequestComposer {
    @Binding var bearerToken: String?
    let basicRequest: NetworkClosureType
    let authorizeRequest: ((URLRequest, String)) -> URLRequest

    var composition: NetworkClosureType {
        { request in
            guard let token = bearerToken else {
                throw ComposableNetworkingError.noBearerToken
            }
            return try await basicRequest(authorizeRequest((request, token)))
        }
    }
}

struct OAuthRequestComposer {
    @Binding var bearerToken: String?
    let authRequestComposer: AuthizedRequestComposer
    let tokenRefreshComposer: LocalTokenRefreshComposer
    let isNotAuthorized: (URLResponse) -> Bool
    
    var composition: NetworkClosureType {
        { request in
            let oldToken = bearerToken
            let tuple = try await authRequestComposer.composition(request)
            guard isNotAuthorized(tuple.1) else {
                return tuple
            }
            if oldToken == bearerToken {
                try await tokenRefreshComposer.composition()
            }
            return try await authRequestComposer.composition(request)
        }
    }
}

struct RemoteTokenRefreshComposer {
    let requestBuilder: (String) -> URLRequest
    let parseToken: (Data) throws -> String
    let basicRequest: NetworkClosureType
    let isNotAuthorized: (URLResponse) -> Bool

    var composition: (String) async throws -> ParsedToken {
        { refToken in
            let req = requestBuilder(refToken)
            let tuple = try await basicRequest(req)
            if isNotAuthorized(tuple.1) {
                return .notPossibleToRefresh
            }
            return try .valid(parseToken(tuple.0))
        }
    }
}

struct LocalTokenRefreshComposer {
    @Binding var refreshToken: String?
    @Binding var bearerToken: String?
    @Binding var refreshTask: Task<Void, Error>?
    let remoteTokenRefreshComposer: RemoteTokenRefreshComposer
    
    var composition: () async throws -> Void {
        {
            if let task = refreshTask {
                return try await task.value
            }
            let task = Task {
                guard let refreshToken = refreshToken else {
                    throw ComposableNetworkingError.noRefreshToken
                }
                let tokenData = try await remoteTokenRefreshComposer.composition(refreshToken)
                switch tokenData {
                case .valid(let newToken):
                    self.bearerToken = newToken
                case .notPossibleToRefresh:
                    self.bearerToken = nil
                    self.refreshToken = nil
                }
            }
            refreshTask = task
            defer {
                refreshTask = nil
            }
            return try await task.value
        }
    }
}

// MARK: - composer

struct RootComposer {
    @Binding var bearerToken: String?
    @Binding var refreshToken: String?
    @Binding var taskStorage: Task<Void, Error>?
    let basicRequest: NetworkClosureType
    let refreshTokenRequest: (String) -> URLRequest
    let parseToken: (Data) throws -> String
    var authorizeRequest: ((URLRequest, String)) -> URLRequest = { arg in
        var req = arg.0
        req.setValue("Bearer \(arg.1)", forHTTPHeaderField: "Authorization")
        return req
    }
    var isNotAuthorized: (URLResponse) -> Bool = { ($0 as? HTTPURLResponse)?.statusCode == 401 }

    var remoteTokenRefreshComposer: RemoteTokenRefreshComposer {
        RemoteTokenRefreshComposer(requestBuilder: refreshTokenRequest, parseToken: parseToken, basicRequest: basicRequest, isNotAuthorized: isNotAuthorized)
    }
    
    var authRequestComposer: AuthizedRequestComposer {
        AuthizedRequestComposer(bearerToken: $bearerToken, basicRequest: basicRequest, authorizeRequest: authorizeRequest)
    }
    
    var tokenRefreshComposer: LocalTokenRefreshComposer {
        LocalTokenRefreshComposer(refreshToken: $refreshToken, bearerToken: $bearerToken, refreshTask: $taskStorage, remoteTokenRefreshComposer: remoteTokenRefreshComposer)
    }
    
    var oauthComposer: OAuthRequestComposer {
        OAuthRequestComposer(bearerToken: $bearerToken, authRequestComposer: authRequestComposer, tokenRefreshComposer: tokenRefreshComposer, isNotAuthorized: isNotAuthorized)
    }
    
    var composableNetworking: ComposableNetworking {
        ComposableNetworking(bearerToken: $bearerToken, oauthComposer: oauthComposer, basicRequest: basicRequest)
    }
    
    var composition: NetworkClosureType {
        composableNetworking.composition
    }
}
