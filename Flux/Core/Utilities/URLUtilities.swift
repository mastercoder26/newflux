import Foundation

public enum URLUtilities {
    public static let trackingParameters: Set<String> = [
        "utm_source",
        "utm_medium",
        "utm_campaign",
        "utm_term",
        "utm_content",
        "utm_id",
        "fbclid",
        "gclid",
        "dclid",
        "msclkid",
        "mc_cid",
        "mc_eid",
        "twclid",
        "igshid",
        "yclid",
        "_hsenc",
        "_hsmi",
        "mkt_tok"
    ]
    
    public static func removeTrackingParameters(from url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return url
        }
        
        guard let queryItems = components.queryItems, !queryItems.isEmpty else {
            return url
        }
        
        let filteredItems = queryItems.filter { item in
            !trackingParameters.contains(item.name.lowercased())
        }
        
        components.queryItems = filteredItems.isEmpty ? nil : filteredItems
        return components.url ?? url
    }
    
    public static func formatMarkdownLink(for url: URL) -> String {
        let label = url.host ?? url.lastPathComponent
        let cleanLabel = label.isEmpty ? url.absoluteString : label
        return "[\(cleanLabel)](\(url.absoluteString))"
    }
}
