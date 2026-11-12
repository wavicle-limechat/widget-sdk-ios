import UIKit

/// Loads the launcher icon set in widget_config. Failures are silent and keep the default icon, same as android.
enum WidgetConfigFetcher {
    static func iconURL(from data: Data) -> URL? {
        guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return nil }
        var config = json["config"] as? [String: Any]
        if config == nil, let text = json["config"] as? String, let textData = text.data(using: .utf8) {
            config = (try? JSONSerialization.jsonObject(with: textData)) as? [String: Any]
        }
        let icon = [config?["widgetIconMobile"], config?["widgetIconDesktop"]]
            .compactMap { $0 as? String }
            .first { !$0.isEmpty }
        return icon.flatMap { URL(string: $0) }
    }

    static func fetchIcon(configuration: WidgetConfiguration, completion: @escaping (UIImage?) -> Void) {
        guard var components = URLComponents(string: configuration.baseURL) else { return completion(nil) }
        components.path = "/widget_config"
        components.queryItems = [URLQueryItem(name: "website_token", value: configuration.websiteToken)]
        guard let url = components.url else { return completion(nil) }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let iconURL = iconURL(from: data) else { return completion(nil) }
            URLSession.shared.dataTask(with: iconURL) { imageData, _, _ in
                completion(imageData.flatMap { UIImage(data: $0) })
            }.resume()
        }.resume()
    }
}
