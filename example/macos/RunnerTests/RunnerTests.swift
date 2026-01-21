import Cocoa
import FlutterMacOS
import XCTest


@testable import media_picker_plus

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  func testGetPlatformVersion() {
    let plugin = MediaPickerPlusPlugin()

    let call = FlutterMethodCall(methodName: "getPlatformVersion", arguments: [])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertEqual(result as! String,
                     "macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testProcessImageQualityProducesDifferentFileSizes() {
    let plugin = MediaPickerPlusPlugin()
    let imagePath = createTempImagePath()

    let lowQualityExpectation = expectation(description: "low quality processed")
    let highQualityExpectation = expectation(description: "high quality processed")

    var lowSize: Int = 0
    var highSize: Int = 0

    processImage(
      plugin: plugin,
      imagePath: imagePath,
      quality: 20
    ) { outputPath in
      if let outputPath = outputPath {
        lowSize = fileSize(at: outputPath)
      }
      lowQualityExpectation.fulfill()
    }

    processImage(
      plugin: plugin,
      imagePath: imagePath,
      quality: 80
    ) { outputPath in
      if let outputPath = outputPath {
        highSize = fileSize(at: outputPath)
      }
      highQualityExpectation.fulfill()
    }

    wait(for: [lowQualityExpectation, highQualityExpectation], timeout: 2)
    XCTAssertGreaterThan(highSize, lowSize)
  }
}

private func createTempImagePath() -> String {
  let size = NSSize(width: 120, height: 120)
  let image = NSImage(size: size)
  image.lockFocus()
  NSColor.red.setFill()
  NSRect(origin: .zero, size: size).fill()
  image.unlockFocus()

  let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
    "test_\(UUID().uuidString).jpg"
  )
  guard
    let tiffData = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiffData),
    let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
  else {
    return tempURL.path
  }

  try? data.write(to: tempURL)
  return tempURL.path
}

private func processImage(
  plugin: MediaPickerPlusPlugin,
  imagePath: String,
  quality: Int,
  completion: @escaping (String?) -> Void
) {
  let args: [String: Any] = [
    "imagePath": imagePath,
    "options": ["imageQuality": quality],
  ]
  let call = FlutterMethodCall(methodName: "processImage", arguments: args)
  plugin.handle(call) { result in
    completion(result as? String)
  }
}

private func fileSize(at path: String) -> Int {
  let url = URL(fileURLWithPath: path)
  let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
  return attributes?[.size] as? Int ?? 0
}
