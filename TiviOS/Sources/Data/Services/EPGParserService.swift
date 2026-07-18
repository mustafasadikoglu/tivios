import Foundation

public final class EPGParserService: EPGServiceProtocol {
    
    public init() {}
    
    public func fetchEPG(url: URL) async throws -> [EPGProgram] {
        let (data, _) = try await URLSession.shared.data(from: url)
        
        return try await Task.detached(priority: .background) {
            let helper = EPGParserHelper(data: data)
            return try helper.parse()
        }.value
    }
    
    public func getCurrentProgram(for channelId: String, from programs: [EPGProgram]) -> EPGProgram? {
        let now = Date()
        return programs.first { $0.channelId == channelId && now >= $0.start && now <= $0.stop }
    }
}

// Standalone parser helper to guarantee thread safety in concurrent tasks
private final class EPGParserHelper: NSObject, XMLParserDelegate {
    private let data: Data
    private var programs: [EPGProgram] = []
    
    // Parsing state
    private var currentElement = ""
    private var currentChannelId = ""
    private var currentStart: Date?
    private var currentStop: Date?
    private var currentTitle = ""
    private var currentDesc = ""
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss Z"
        return formatter
    }()
    
    init(data: Data) {
        self.data = data
        super.init()
    }
    
    func parse() throws -> [EPGProgram] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        if parser.parse() {
            return programs
        } else {
            throw parser.parserError ?? NSError(domain: "EPGParserHelper", code: 500, userInfo: [NSLocalizedDescriptionKey: "EPG XML dosyası ayrıştırılamadı"])
        }
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "programme" {
            currentChannelId = attributeDict["channel"] ?? ""
            currentTitle = ""
            currentDesc = ""
            
            if let startStr = attributeDict["start"] {
                currentStart = dateFormatter.date(from: startStr)
            }
            if let stopStr = attributeDict["stop"] {
                currentStop = dateFormatter.date(from: stopStr)
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return }
        
        if currentElement == "title" {
            currentTitle += trimmed
        } else if currentElement == "desc" {
            currentDesc += trimmed
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "programme" {
            if let start = currentStart, let stop = currentStop, !currentChannelId.isEmpty {
                if stop >= Date() {
                    let program = EPGProgram(
                        channelId: currentChannelId,
                        start: start,
                        stop: stop,
                        title: currentTitle,
                        description: currentDesc.isEmpty ? nil : currentDesc
                    )
                    programs.append(program)
                }
            }
            currentStart = nil
            currentStop = nil
            currentChannelId = ""
            currentTitle = ""
            currentDesc = ""
        }
    }
}
