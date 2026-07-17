import Foundation

/// Minimal UDP client for the Wiz bulb protocol (JSON over UDP, port 38899).
enum WizClient {
    static let port: UInt16 = 38899

    static func setPilotPayload(_ params: [String: Any]) -> Data? {
        let message: [String: Any] = ["id": 1, "method": "setPilot", "params": params]
        return try? JSONSerialization.data(withJSONObject: message)
    }

    static func getPilotPayload() -> Data {
        Data(#"{"id":1,"method":"getPilot","params":{}}"#.utf8)
    }

    /// Fire-and-forget send (used for setPilot while dragging sliders).
    static func send(_ payload: Data, to ip: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            _ = exchange(payload, ip: ip, wantReply: false, timeoutMs: 0)
        }
    }

    /// Send and wait for a reply (used for getPilot). Returns nil on timeout/error.
    static func query(_ payload: Data, to ip: String, timeoutMs: Int = 1000) async -> Data? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: exchange(payload, ip: ip, wantReply: true, timeoutMs: timeoutMs))
            }
        }
    }

    private static func exchange(_ payload: Data, ip: String, wantReply: Bool, timeoutMs: Int) -> Data? {
        let fd = socket(AF_INET, SOCK_DGRAM, 0)
        guard fd >= 0 else { return nil }
        defer { close(fd) }

        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        guard ip.withCString({ inet_pton(AF_INET, $0, &addr.sin_addr) }) == 1 else { return nil }

        let sent = withUnsafePointer(to: &addr) { aptr -> Int in
            aptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                payload.withUnsafeBytes { buf in
                    sendto(fd, buf.baseAddress, payload.count, 0, sa, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }
        guard sent == payload.count, wantReply else { return nil }

        var tv = timeval(tv_sec: timeoutMs / 1000, tv_usec: suseconds_t((timeoutMs % 1000) * 1000))
        _ = withUnsafePointer(to: &tv) {
            setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, $0, socklen_t(MemoryLayout<timeval>.size))
        }

        var buf = [UInt8](repeating: 0, count: 2048)
        let n = recv(fd, &buf, buf.count, 0)
        guard n > 0 else { return nil }
        return Data(buf[..<n])
    }
}

struct PilotResponse: Decodable {
    struct Result: Decodable {
        var state: Bool?
        var dimming: Int?
        var temp: Int?
        var r: Int?
        var g: Int?
        var b: Int?
    }
    var result: Result?
}
