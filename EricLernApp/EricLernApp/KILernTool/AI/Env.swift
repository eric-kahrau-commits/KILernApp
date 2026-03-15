import Foundation

/// Reads key=value pairs from the `.env` file bundled with the app.
///
/// ## Where the .env file must live
/// `KILernTool/KILernTool/.env`  ← inside the app target folder.
/// The project uses PBXFileSystemSynchronizedRootGroup, so every file in that
/// folder is automatically included in the app bundle — no manual Xcode step needed.
///
/// ## Usage
///     let key = Env.OPENAI_API_KEY
///
enum Env {
    static var OPENAI_API_KEY: String { value(for: "OPENAI_API_KEY") }

    // MARK: - Private parser

    private static func value(for key: String) -> String {
        // Try Bundle lookup first (works for non-hidden copies), then direct path.
        let url: URL? =
            Bundle.main.url(forResource: ".env", withExtension: nil)
            ?? Bundle.main.url(forResource: "env", withExtension: nil)
            ?? URL(fileURLWithPath: Bundle.main.bundlePath + "/.env")

        guard
            let fileURL = url,
            let contents = try? String(contentsOf: fileURL, encoding: .utf8)
        else {
            print("⚠️  [Env] .env file not found in app bundle.")
            return ""
        }

        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Skip comments and empty lines
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
            let parts = trimmed.components(separatedBy: "=")
            guard
                parts.count >= 2,
                parts[0].trimmingCharacters(in: .whitespaces) == key
            else { continue }
            // Rejoin in case the value itself contains "="
            return parts.dropFirst().joined(separator: "=")
                .trimmingCharacters(in: .whitespaces)
        }

        print("⚠️  [Env] Key '\(key)' not found in .env.")
        return ""
    }
}
