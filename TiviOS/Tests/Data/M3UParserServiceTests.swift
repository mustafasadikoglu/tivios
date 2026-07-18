import XCTest
@testable import TiviOS

final class M3UParserServiceTests: XCTestCase {
    private var sut: M3UParserService!
    
    override func setUp() {
        super.setUp()
        sut = M3UParserService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func test_parse_validM3U_returnsParsedChannels() throws {
        // Given
        let m3uContent = """
        #EXTM3U
        #EXTINF:-1 tvg-id="trt1" tvg-name="TRT 1" tvg-logo="https://img.trt.com.tr/logo.png" group-title="Ulusal",TRT 1
        https://trt.live.stream/trt1/index.m3u8
        #EXTINF:-1 tvg-id="spor" tvg-name="TRT Spor" group-title="Spor",TRT Spor
        https://trt.live.stream/trtspor/index.m3u8
        """
        let playlistId = UUID()
        
        // When
        let channels = try sut.parse(content: m3uContent, playlistId: playlistId)
        
        // Then
        XCTAssertEqual(channels.count, 2)
        
        let firstChannel = channels[0]
        XCTAssertEqual(firstChannel.name, "TRT 1")
        XCTAssertEqual(firstChannel.logoUrl, URL(string: "https://img.trt.com.tr/logo.png"))
        XCTAssertEqual(firstChannel.groupTitle, "Ulusal")
        XCTAssertEqual(firstChannel.streamUrl, URL(string: "https://trt.live.stream/trt1/index.m3u8"))
        XCTAssertEqual(firstChannel.playlistId, playlistId)
        XCTAssertFalse(firstChannel.isFavorite)
        
        let secondChannel = channels[1]
        XCTAssertEqual(secondChannel.name, "TRT Spor")
        XCTAssertNil(secondChannel.logoUrl)
        XCTAssertEqual(secondChannel.groupTitle, "Spor")
        XCTAssertEqual(secondChannel.streamUrl, URL(string: "https://trt.live.stream/trtspor/index.m3u8"))
    }
    
    func test_parse_emptyContent_returnsNoChannels() throws {
        // Given
        let content = ""
        let playlistId = UUID()
        
        // When
        let channels = try sut.parse(content: content, playlistId: playlistId)
        
        // Then
        XCTAssertTrue(channels.isEmpty)
    }
}
