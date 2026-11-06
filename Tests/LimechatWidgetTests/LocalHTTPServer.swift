import Foundation
import Network

/// tiny local http server that answers every request with a blank html page.
/// with `holdFirstResponse` the first request is never answered, so that load stays in flight.
final class LocalHTTPServer {
    private let listener: NWListener
    private let queue = DispatchQueue(label: "local-http-server")
    private let lock = NSLock()
    private var count = 0
    var port: UInt16 { listener.port!.rawValue }
    var requests: Int { lock.lock(); defer { lock.unlock() }; return count }

    init(holdFirstResponse: Bool = false) throws {
        listener = try NWListener(using: .tcp, on: .any)
        let ready = DispatchSemaphore(value: 0)
        listener.stateUpdateHandler = { if case .ready = $0 { ready.signal() } }
        listener.newConnectionHandler = { [weak self] connection in
            connection.start(queue: self?.queue ?? .main)
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { _, _, _, _ in
                self?.lock.lock(); self?.count += 1; let n = self?.count ?? 0; self?.lock.unlock()
                if holdFirstResponse && n == 1 { return }
                let body = "<html><body>ok</body></html>"
                let head = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n"
                connection.send(content: Data((head + body).utf8), completion: .contentProcessed { _ in connection.cancel() })
            }
        }
        listener.start(queue: queue)
        _ = ready.wait(timeout: .now() + 5)
    }

    func stop() { listener.cancel() }
}
