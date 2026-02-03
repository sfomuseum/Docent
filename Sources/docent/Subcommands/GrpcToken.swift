import GRPCCore

struct ClientTokenInterceptor: ClientInterceptor {
    let token: String

    func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingClientRequest<Input>,
        context: ClientContext,
        next: (StreamingClientRequest<Input>, ClientContext) async throws -> StreamingClientResponse<Output>
    ) async throws -> StreamingClientResponse<Output> {
        
        var modifiedRequest = request
        modifiedRequest.metadata.addString("Bearer \(token)", forKey: "authorization")
        
        return try await next(modifiedRequest, context)
    }
}

struct ServerTokenInterceptor: ServerInterceptor {
  // let isAuthorized: @Sendable (String, MethodDescriptor) async throws -> Void
    let token: String
    
  func intercept<Input: Sendable, Output: Sendable>(
    request: StreamingServerRequest<Input>,
    context: ServerContext,
    next: @Sendable (
      _ request: StreamingServerRequest<Input>,
      _ context: ServerContext
    ) async throws -> StreamingServerResponse<Output>
  ) async throws -> StreamingServerResponse<Output> {
      
    // Extract the auth token.
    guard let auth_token = request.metadata[stringValues: "authorization"].first(where: { _ in true }) else {
      throw RPCError(code: .unauthenticated, message: "Not authenticated")
    }

      if auth_token != token {
          throw RPCError(code: .unauthenticated, message: "Not authenticated")
      }

    return try await next(request, context)
  }
}
