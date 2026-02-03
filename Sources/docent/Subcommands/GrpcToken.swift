import GRPCCore


struct ClientTokenInterceptor: ClientInterceptor {

    private let token: String
    
    init(_ token_uri: String) throws {

        let rsp = StringVar(token_uri)
        
        switch rsp {
        case .failure(let error):
            throw error
        case .success(let v):
            self.token = v
        }
    }
        
    func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingClientRequest<Input>,
        context: ClientContext,
        next: (StreamingClientRequest<Input>, ClientContext) async throws -> StreamingClientResponse<Output>
    ) async throws -> StreamingClientResponse<Output> {
        
        var modifiedRequest = request
        modifiedRequest.metadata.addString("Bearer \(self.token)", forKey: "authorization")
        
        return try await next(modifiedRequest, context)
    }
}

struct ServerTokenInterceptor: ServerInterceptor {
  // let isAuthorized: @Sendable (String, MethodDescriptor) async throws -> Void

    private let token: String
    
    init(_ token_uri: String) throws {

        let rsp = StringVar(token_uri)
        
        switch rsp {
        case .failure(let error):
            throw error
        case .success(let v):
            self.token = v
        }
    }
    
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

      if auth_token != self.token {
          throw RPCError(code: .unauthenticated, message: "Not authenticated")
      }

    return try await next(request, context)
  }
}
