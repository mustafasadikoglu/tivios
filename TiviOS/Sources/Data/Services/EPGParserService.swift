import Foundation

public final class EPGParserService: NSObject, EPGServiceProtocol, XMLParserDelegate {
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
    
    public override init() {
        super.init()
    }
    
    public func fetchEPG(url: URL) async throws -> [EPGProgram] {
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // XMLParser works on main/background. Let's do it on a background queue
        return try await Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return [] }
            let parser = XMLParser(data: data)
            parser.delegate = self
            
            self.programs.removeAll()
            if parser.parse() {
                return self.programs
            } else {
                throw parser.parserError ?? NSError(domain: "EPGParserService", code: 500, userInfo: [NSLocalizedDescriptionKey: "EPG XML dosyası ayrıştırılamadı"])
            }
        }.value
    }
    
    public func getCurrentProgram(for channelId: String, from programs: [EPGProgram]) -> EPGProgram? {
        let now = Date()
        return programs.first { $0.channelId == channelId && now >= $0.start && now <= $0.stop }
    }
    
    // MARK: - XMLParserDelegate
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
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
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return }
        
        if currentElement == "title" {
            currentTitle += trimmed
        } else if currentElement == "desc" {
            currentDesc += trimmed
        }
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "programme" {
            if let start = currentStart, let stop = currentStop, !currentChannelId.isEmpty {
                // Optimize memory: only store programs that are not fully in the past
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
            // Reset
            currentStart = nil
            currentStop = nil
            currentChannelId = ""
            currentTitle = ""
            currentDesc = ""
        }
    }
}
