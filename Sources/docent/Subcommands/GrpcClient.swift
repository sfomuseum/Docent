import GRPCCore
import GRPCNIOTransportHTTP2
import Logging

public func grpcClientTransortSecurity(tls_certificate: String = "", tls_ca_certificate: String = "", logger: Logger? = nil) -> HTTP2ClientTransport.Posix.TransportSecurity {
    
    var transportSecurity = HTTP2ClientTransport.Posix.TransportSecurity.plaintext

    if tls_certificate != ""  {
        
        logger?.debug("Configure TLS certificate \(tls_certificate)")
        
        let certSource:  TLSConfig.CertificateSource   = .file(path: tls_certificate, format: .pem)
        
         transportSecurity = HTTP2ClientTransport.Posix.TransportSecurity.tls { config in
             
            config.certificateChain = [ certSource ]

             if tls_ca_certificate != "" {
                 
                 logger?.debug("Configure TLS CA certificate \(tls_ca_certificate)")
                 
                 config.trustRoots = .certificates([
                    TLSConfig.CertificateSource.file(path: tls_ca_certificate, format: .pem)
                 ])
             }
        }
    }
    
    return transportSecurity
}

public func grpcClientInterceptors(token_uri: String = "", logger: Logger? = nil ) throws -> [ClientInterceptor] {
    
    var interceptors: [ClientInterceptor] = []
    
    if token_uri != "" {
        
        logger?.debug("Apply token interceptor")
        
        do {
            let token_interceptor = try ClientTokenInterceptor(token_uri, logger: logger)
            interceptors.append(token_interceptor)
        } catch {
            logger?.error("Failed to create token interceptor, \(error)")
            throw error
        }
    }
    
    return interceptors
}
