import Flutter
import UIKit
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
      XCTAssertEqual(result as! String, "iOS " + UIDevice.current.systemVersion)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testProcessImageQualityProducesDifferentFileSizes() {
    let plugin = SwiftMediaPickerPlusPlugin()
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
  let size = CGSize(width: 120, height: 120)
  let renderer = UIGraphicsImageRenderer(size: size)
  let image = renderer.image { context in
    UIColor.red.setFill()
    context.fill(CGRect(origin: .zero, size: size))
  }

  let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
    "test_\(UUID().uuidString).jpg"
  )
  let data = image.jpegData(compressionQuality: 0.9)
  try? data?.write(to: tempURL)
  return tempURL.path
}

private func processImage(
  plugin: SwiftMediaPickerPlusPlugin,
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
