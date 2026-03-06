import XCTest
@testable import SayItRight

final class AnthropicServiceTests: XCTestCase {

    private let parser = SSEParser()

    // MARK: - SSE Parser: content_block_delta

    func testParseContentBlockDelta() {
        let json = """
        {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}
        """
        let event = parser.parse(dataLine: json)
        guard case .contentBlockDelta(let text) = event else {
            XCTFail("Expected contentBlockDelta, got \(String(describing: event))")
            return
        }
        XCTAssertEqual(text, "Hello")
    }

    func testParseContentBlockDeltaWithSpecialCharacters() {
        let json = """
        {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Grüße! Das ist \\"gut\\"."}}
        """
        let event = parser.parse(dataLine: json)
        guard case .contentBlockDelta(let text) = event else {
            XCTFail("Expected contentBlockDelta, got \(String(describing: event))")
            return
        }
        XCTAssertEqual(text, "Grüße! Das ist \"gut\".")
    }

    func testParseContentBlockDeltaEmptyText() {
        let json = """
        {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":""}}
        """
        let event = parser.parse(dataLine: json)
        guard case .contentBlockDelta(let text) = event else {
            XCTFail("Expected contentBlockDelta, got \(String(describing: event))")
            return
        }
        XCTAssertEqual(text, "")
    }

    // MARK: - SSE Parser: message_start

    func testParseMessageStart() {
        let json = """
        {"type":"message_start","message":{"id":"msg_123","type":"message","role":"assistant","content":[],"model":"claude-sonnet-4-5-20250514","stop_reason":null,"stop_sequence":null,"usage":{"input_tokens":25,"output_tokens":1}}}
        """
        let event = parser.parse(dataLine: json)
        guard case .messageStart = event else {
            XCTFail("Expected messageStart, got \(String(describing: event))")
            return
        }
    }

    // MARK: - SSE Parser: content_block_start

    func testParseContentBlockStart() {
        let json = """
        {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}
        """
        let event = parser.parse(dataLine: json)
        guard case .contentBlockStart = event else {
            XCTFail("Expected contentBlockStart, got \(String(describing: event))")
            return
        }
    }

    // MARK: - SSE Parser: content_block_stop

    func testParseContentBlockStop() {
        let json = """
        {"type":"content_block_stop","index":0}
        """
        let event = parser.parse(dataLine: json)
        guard case .contentBlockStop = event else {
            XCTFail("Expected contentBlockStop, got \(String(describing: event))")
            return
        }
    }

    // MARK: - SSE Parser: message_stop

    func testParseMessageStop() {
        let json = """
        {"type":"message_stop"}
        """
        let event = parser.parse(dataLine: json)
        guard case .messageStop = event else {
            XCTFail("Expected messageStop, got \(String(describing: event))")
            return
        }
    }

    // MARK: - SSE Parser: message_delta

    func testParseMessageDelta() {
        let json = """
        {"type":"message_delta","delta":{"stop_reason":"end_turn","stop_sequence":null},"usage":{"output_tokens":15}}
        """
        let event = parser.parse(dataLine: json)
        guard case .messageDelta = event else {
            XCTFail("Expected messageDelta, got \(String(describing: event))")
            return
        }
    }

    // MARK: - SSE Parser: ping

    func testParsePing() {
        let json = """
        {"type":"ping"}
        """
        let event = parser.parse(dataLine: json)
        guard case .ping = event else {
            XCTFail("Expected ping, got \(String(describing: event))")
            return
        }
    }

    // MARK: - SSE Parser: error event

    func testParseErrorEvent() {
        let json = """
        {"type":"error","error":{"type":"overloaded_error","message":"Overloaded"}}
        """
        let event = parser.parse(dataLine: json)
        guard case .error(let message) = event else {
            XCTFail("Expected error, got \(String(describing: event))")
            return
        }
        XCTAssertEqual(message, "Overloaded")
    }

    func testParseErrorEventWithoutMessage() {
        let json = """
        {"type":"error","error":{"type":"overloaded_error"}}
        """
        let event = parser.parse(dataLine: json)
        guard case .error(let message) = event else {
            XCTFail("Expected error, got \(String(describing: event))")
            return
        }
        XCTAssertEqual(message, "Unknown streaming error")
    }

    // MARK: - SSE Parser: unknown event type

    func testParseUnknownEventType() {
        let json = """
        {"type":"some_future_event","data":{}}
        """
        let event = parser.parse(dataLine: json)
        guard case .unknown(let type) = event else {
            XCTFail("Expected unknown, got \(String(describing: event))")
            return
        }
        XCTAssertEqual(type, "some_future_event")
    }

    // MARK: - SSE Parser: edge cases

    func testParseEmptyLine() {
        let event = parser.parse(dataLine: "")
        XCTAssertNil(event)
    }

    func testParseDoneSentinel() {
        let event = parser.parse(dataLine: "[DONE]")
        XCTAssertNil(event)
    }

    func testParseInvalidJSON() {
        let event = parser.parse(dataLine: "not json at all")
        guard case .error = event else {
            XCTFail("Expected error for invalid JSON, got \(String(describing: event))")
            return
        }
    }

    func testParseMissingTypeField() {
        let json = """
        {"data":"no type field"}
        """
        let event = parser.parse(dataLine: json)
        guard case .error = event else {
            XCTFail("Expected error for missing type, got \(String(describing: event))")
            return
        }
    }

    func testParseWhitespaceAroundData() {
        let json = """
          {"type":"message_stop"}
        """
        let event = parser.parse(dataLine: json)
        guard case .messageStop = event else {
            XCTFail("Expected messageStop, got \(String(describing: event))")
            return
        }
    }

    // MARK: - SSE Parser: full stream simulation

    func testParseFullStreamSequence() {
        // Simulate a realistic sequence of SSE data lines
        let lines = [
            """
            {"type":"message_start","message":{"id":"msg_01","type":"message","role":"assistant","content":[],"model":"claude-sonnet-4-5-20250514","stop_reason":null,"stop_sequence":null,"usage":{"input_tokens":10,"output_tokens":1}}}
            """,
            """
            {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}
            """,
            """
            {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Das "}}
            """,
            """
            {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"ist "}}
            """,
            """
            {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"klar."}}
            """,
            """
            {"type":"content_block_stop","index":0}
            """,
            """
            {"type":"message_delta","delta":{"stop_reason":"end_turn","stop_sequence":null},"usage":{"output_tokens":5}}
            """,
            """
            {"type":"message_stop"}
            """
        ]

        var assembledText = ""
        var eventCount = 0

        for line in lines {
            if let event = parser.parse(dataLine: line) {
                eventCount += 1
                if case .contentBlockDelta(let text) = event {
                    assembledText += text
                }
            }
        }

        XCTAssertEqual(assembledText, "Das ist klar.")
        XCTAssertEqual(eventCount, 8) // All events parsed
    }

    // MARK: - APIMessage

    func testAPIMessageEncoding() throws {
        let message = APIMessage(role: "user", content: "Hello Barbara")
        let data = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(APIMessage.self, from: data)
        XCTAssertEqual(decoded.role, "user")
        XCTAssertEqual(decoded.content, "Hello Barbara")
    }

    // MARK: - AnthropicServiceError descriptions

    func testErrorDescriptions() {
        XCTAssertNotNil(AnthropicServiceError.missingAPIKey.errorDescription)
        XCTAssertNotNil(AnthropicServiceError.invalidAPIKey.errorDescription)
        XCTAssertNotNil(AnthropicServiceError.invalidURL.errorDescription)
        XCTAssertNotNil(AnthropicServiceError.networkTimeout.errorDescription)
        XCTAssertNotNil(AnthropicServiceError.rateLimited(retryAfter: "30").errorDescription)
        XCTAssertNotNil(AnthropicServiceError.rateLimited(retryAfter: nil).errorDescription)
        XCTAssertNotNil(AnthropicServiceError.serverError(statusCode: 500, message: "err").errorDescription)
        XCTAssertNotNil(AnthropicServiceError.unexpectedResponse(statusCode: 418).errorDescription)
        XCTAssertNotNil(AnthropicServiceError.decodingError("bad").errorDescription)
        XCTAssertNotNil(AnthropicServiceError.streamingError("oops").errorDescription)

        // Verify rate limit includes retry-after value
        let rateLimitMsg = AnthropicServiceError.rateLimited(retryAfter: "30").errorDescription!
        XCTAssertTrue(rateLimitMsg.contains("30"))
    }
}
