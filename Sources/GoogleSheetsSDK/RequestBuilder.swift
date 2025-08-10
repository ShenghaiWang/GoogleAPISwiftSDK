import Foundation
import GoogleAPITokenManager

/// Request builder for constructing Google Sheets API requests
public class RequestBuilder {
    private let baseURL: String
    private let apiKey: String?
    private let accessToken: String?

    public init(baseURL: String = "https://sheets.googleapis.com/v4", apiKey: String? = nil, accessToken: String? = nil) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.accessToken = accessToken
    }

    /// Build a request for spreadsheet operations
    public func buildSpreadsheetRequest(
        method: HTTPMethod,
        spreadsheetId: String? = nil,
        endpoint: String,
        queryParameters: [String: String] = [:],
        body: Data? = nil
    ) throws -> HTTPRequest {
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw GoogleSheetsError.invalidURL(baseURL)
        }

        // Build the path
        var pathComponents = ["v4", "spreadsheets"]
        if let spreadsheetId = spreadsheetId {
            pathComponents.append(spreadsheetId)
        }
        pathComponents.append(endpoint)

        urlComponents.path = "/" + pathComponents.joined(separator: "/")

        // Add query parameters
        var queryItems: [URLQueryItem] = []

        // Add API key if available and no access token
        if let apiKey = apiKey, accessToken == nil {
            queryItems.append(URLQueryItem(name: "key", value: apiKey))
        }

        // Add custom query parameters
        for (key, value) in queryParameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }

        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }

        guard let url = urlComponents.url else {
            throw GoogleSheetsError.invalidURL(urlComponents.string ?? "unknown")
        }

        // Build headers
        var headers: [String: String] = [:]

        if let accessToken = accessToken {
            headers["Authorization"] = "Bearer \(accessToken)"
        }

        if body != nil {
            headers["Content-Type"] = "application/json"
        }

        return HTTPRequest(method: method, url: url, headers: headers, body: body)
    }

    /// Build a request for values operations
    public func buildValuesRequest(
        method: HTTPMethod,
        spreadsheetId: String,
        range: String? = nil,
        endpoint: String = "values",
        queryParameters: [String: String] = [:],
        body: Data? = nil
    ) throws -> HTTPRequest {
        var pathEndpoint = endpoint
        if let range = range {
            // Don't encode here - let URLComponents handle it properly
            pathEndpoint = "\(endpoint)/\(range)"
        }

        return try buildSpreadsheetRequest(
            method: method,
            spreadsheetId: spreadsheetId,
            endpoint: pathEndpoint,
            queryParameters: queryParameters,
            body: body
        )
    }

    /// Build a request for batch operations
    public func buildBatchRequest(
        method: HTTPMethod,
        spreadsheetId: String,
        endpoint: String,
        queryParameters: [String: String] = [:],
        body: Data? = nil
    ) throws -> HTTPRequest {
        return try buildSpreadsheetRequest(
            method: method,
            spreadsheetId: spreadsheetId,
            endpoint: endpoint,
            queryParameters: queryParameters,
            body: body
        )
    }
}

/// Convenience methods for common request patterns
extension RequestBuilder {
    /// Create a GET request for reading spreadsheet data
    public func getSpreadsheet(
        spreadsheetId: String,
        ranges: [String]? = nil,
        includeGridData: Bool = false,
        fields: String? = nil
    ) throws -> HTTPRequest {
        var queryParams: [String: String] = [:]

        if let ranges = ranges, !ranges.isEmpty {
            queryParams["ranges"] = ranges.joined(separator: "&ranges=")
        }

        if includeGridData {
            queryParams["includeGridData"] = "true"
        }

        if let fields = fields {
            queryParams["fields"] = fields
        }

        return try buildSpreadsheetRequest(
            method: .GET,
            spreadsheetId: spreadsheetId,
            endpoint: "",
            queryParameters: queryParams
        )
    }

    /// Create a GET request for reading values
    public func getValues(
        spreadsheetId: String,
        range: String,
        majorDimension: String? = nil,
        valueRenderOption: String? = nil,
        dateTimeRenderOption: String? = nil
    ) throws -> HTTPRequest {
        var queryParams: [String: String] = [:]

        if let majorDimension = majorDimension {
            queryParams["majorDimension"] = majorDimension
        }

        if let valueRenderOption = valueRenderOption {
            queryParams["valueRenderOption"] = valueRenderOption
        }

        if let dateTimeRenderOption = dateTimeRenderOption {
            queryParams["dateTimeRenderOption"] = dateTimeRenderOption
        }

        return try buildValuesRequest(
            method: .GET,
            spreadsheetId: spreadsheetId,
            range: range,
            queryParameters: queryParams
        )
    }

    /// Create a PUT request for updating values
    public func updateValues(
        spreadsheetId: String,
        range: String,
        valueInputOption: String? = nil,
        includeValuesInResponse: Bool = false,
        responseValueRenderOption: String? = nil,
        responseDateTimeRenderOption: String? = nil,
        body: Data
    ) throws -> HTTPRequest {
        var queryParams: [String: String] = [:]

        if let valueInputOption = valueInputOption {
            queryParams["valueInputOption"] = valueInputOption
        }

        if includeValuesInResponse {
            queryParams["includeValuesInResponse"] = "true"
        }

        if let responseValueRenderOption = responseValueRenderOption {
            queryParams["responseValueRenderOption"] = responseValueRenderOption
        }

        if let responseDateTimeRenderOption = responseDateTimeRenderOption {
            queryParams["responseDateTimeRenderOption"] = responseDateTimeRenderOption
        }

        return try buildValuesRequest(
            method: .PUT,
            spreadsheetId: spreadsheetId,
            range: range,
            queryParameters: queryParams,
            body: body
        )
    }

    /// Create a POST request for appending values
    public func appendValues(
        spreadsheetId: String,
        range: String,
        valueInputOption: String? = nil,
        insertDataOption: String? = nil,
        includeValuesInResponse: Bool = false,
        responseValueRenderOption: String? = nil,
        responseDateTimeRenderOption: String? = nil,
        body: Data
    ) throws -> HTTPRequest {
        var queryParams: [String: String] = [:]

        if let valueInputOption = valueInputOption {
            queryParams["valueInputOption"] = valueInputOption
        }

        if let insertDataOption = insertDataOption {
            queryParams["insertDataOption"] = insertDataOption
        }

        if includeValuesInResponse {
            queryParams["includeValuesInResponse"] = "true"
        }

        if let responseValueRenderOption = responseValueRenderOption {
            queryParams["responseValueRenderOption"] = responseValueRenderOption
        }

        if let responseDateTimeRenderOption = responseDateTimeRenderOption {
            queryParams["responseDateTimeRenderOption"] = responseDateTimeRenderOption
        }

        return try buildValuesRequest(
            method: .POST,
            spreadsheetId: spreadsheetId,
            range: "\(range):append",
            queryParameters: queryParams,
            body: body
        )
    }

    /// Create a POST request for clearing values
    public func clearValues(
        spreadsheetId: String,
        range: String
    ) throws -> HTTPRequest {
        return try buildValuesRequest(
            method: .POST,
            spreadsheetId: spreadsheetId,
            range: "\(range):clear"
        )
    }

    /// Create a POST request for batch getting values
    public func batchGetValues(
        spreadsheetId: String,
        ranges: [String],
        majorDimension: String? = nil,
        valueRenderOption: String? = nil,
        dateTimeRenderOption: String? = nil
    ) throws -> HTTPRequest {
        var queryParams: [String: String] = [:]

        queryParams["ranges"] = ranges.joined(separator: "&ranges=")

        if let majorDimension = majorDimension {
            queryParams["majorDimension"] = majorDimension
        }

        if let valueRenderOption = valueRenderOption {
            queryParams["valueRenderOption"] = valueRenderOption
        }

        if let dateTimeRenderOption = dateTimeRenderOption {
            queryParams["dateTimeRenderOption"] = dateTimeRenderOption
        }

        return try buildBatchRequest(
            method: .GET,
            spreadsheetId: spreadsheetId,
            endpoint: "values:batchGet",
            queryParameters: queryParams
        )
    }
}
