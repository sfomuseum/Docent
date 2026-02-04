import GRPCCore
import Logging

struct ClientTokenInterceptor: ClientInterceptor {

    private let token: String
    private var logger: Logger?
    
    init(_ token_uri: String, logger: Logger? = nil) throws {

        let rsp = StringVar(token_uri)
        
        switch rsp {
        case .failure(let error):
            throw error
        case .success(let v):
            self.token = v.trimmingCharacters(in: .whitespacesAndNewlines)
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

    private let token: String
    private var logger: Logger?
    
    init(_ token_uri: String, logger: Logger? = nil) throws {

        let rsp = StringVar(token_uri)
        
        switch rsp {
        case .failure(let error):
            throw error
        case .success(let v):
            self.token = v.trimmingCharacters(in: .whitespacesAndNewlines)
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
      
    guard var auth_token = request.metadata[stringValues: "authorization"].first(where: { _ in true }) else {
        logger?.error("Request is missing authorization header \(request.metadata)")
      throw RPCError(code: .unauthenticated, message: "Missing authorization header")
    }

      auth_token = auth_token.replacingOccurrences(of: "Bearer ", with: "")
      auth_token = auth_token.trimmingCharacters(in: .whitespacesAndNewlines)
            
      if auth_token != self.token {
          logger?.error("Client authentication mismatch")
          throw RPCError(code: .unauthenticated, message: "Invalid token")
      }

    return try await next(request, context)
  }
}
