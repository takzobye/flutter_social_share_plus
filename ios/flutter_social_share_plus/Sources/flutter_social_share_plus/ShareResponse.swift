import Foundation

enum ShareResponse {
    static func completed() -> [String: String] {
        ["status": "completed"]
    }

    static func launched() -> [String: String] {
        ["status": "launched"]
    }

    static func cancelled() -> [String: String] {
        ["status": "cancelled"]
    }

    static func unavailable() -> [String: String] {
        ["status": "unavailable"]
    }

    static func failed(_ code: String, _ message: String) -> [String: String] {
        ["status": "failed", "code": code, "message": message]
    }
}

enum ShareMedia {
    static func mimeType(for url: URL) -> String? {
        switch url.pathExtension.lowercased() {
        case "jpg", "jpeg": "image/jpeg"
        case "png": "image/png"
        case "gif": "image/gif"
        case "webp": "image/webp"
        case "heic", "heif": "image/heic"
        case "mp4": "video/mp4"
        case "mov": "video/quicktime"
        case "m4v": "video/x-m4v"
        case "avi": "video/x-msvideo"
        default: nil
        }
    }

    static func validatePath(_ path: String, allowed: Set<String>) -> Result<URL, ShareMediaError> {
        guard !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(ShareMediaError(ShareResponse.failed("invalid_input", "Media path is empty")))
        }
        guard path.hasPrefix("/") else {
            return .failure(ShareMediaError(ShareResponse.failed("invalid_input", "Media path must be absolute: \(path)")))
        }
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            return .failure(ShareMediaError(ShareResponse.failed("file_not_found", "File not found: \(path)")))
        }
        guard let mime = mimeType(for: url), allowed.contains(where: { mime.hasPrefix($0) }) else {
            return .failure(ShareMediaError(ShareResponse.failed("unsupported_media", "Unsupported media: \(path)")))
        }
        return .success(url)
    }

    static func load(
        paths: [String],
        maxVideoBytes: Int? = nil,
        completion: @escaping (Result<[URL: Data], ShareMediaError>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            var values = [URL: Data]()
            for path in paths {
                let url = URL(fileURLWithPath: path)
                guard FileManager.default.isReadableFile(atPath: url.path) else {
                    DispatchQueue.main.async {
                        completion(.failure(ShareMediaError(ShareResponse.failed("file_not_found", "File not found: \(path)"))))
                    }
                    return
                }
                if let maxVideoBytes,
                   mimeType(for: url)?.hasPrefix("video/") == true,
                   let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                   let size = (attributes[.size] as? NSNumber)?.intValue,
                   size > maxVideoBytes {
                    DispatchQueue.main.async {
                        completion(.failure(ShareMediaError(ShareResponse.failed("invalid_input", "Story video must be 50 MiB or smaller"))))
                    }
                    return
                }
                guard let data = try? Data(contentsOf: url, options: [.mappedIfSafe]) else {
                    DispatchQueue.main.async {
                        completion(.failure(ShareMediaError(ShareResponse.failed("platform_error", "Unable to read \(path)"))))
                    }
                    return
                }
                values[url] = data
            }
            DispatchQueue.main.async { completion(.success(values)) }
        }
    }
}

struct ShareMediaError: Error {
    let response: [String: String]

    init(_ response: [String: String]) {
        self.response = response
    }
}
