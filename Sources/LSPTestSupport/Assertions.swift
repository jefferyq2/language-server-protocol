//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import XCTest

/// Same as `XCTAssertNoThrow` but executes the trailing closure.
public func assertNoThrow<T>(
  _ expression: () throws -> T,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #filePath,
  line: UInt = #line
) {
  XCTAssertNoThrow(try expression(), message(), file: file, line: line)
}

/// Same as `assertNoThrow` but allows the closure to be `async`.
public func assertNoThrow<T>(
  _ expression: () async throws -> T,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #filePath,
  line: UInt = #line
) async {
  do {
    _ = try await expression()
  } catch {
    XCTFail("Expression was not expected to throw but threw \(error)", file: file, line: line)
  }
}

/// Same as `XCTAssertThrows` but allows the expression to be async
public func assertThrowsError<T>(
  _ expression: @autoclosure () async throws -> T,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #filePath,
  line: UInt = #line,
  errorHandler: (_ error: Error) -> Void = { _ in }
) async {
  let didThrow: Bool
  do {
    _ = try await expression()
    didThrow = false
  } catch {
    errorHandler(error)
    didThrow = true
  }
  if !didThrow {
    XCTFail("Expression was expected to throw but did not throw", file: file, line: line)
  }
}

/// Same as `XCTAssertEqual` but doesn't take autoclosures and thus `expression1`
/// and `expression2` can contain `await`.
public func assertEqual<T: Equatable>(
  _ expression1: T,
  _ expression2: T,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #filePath,
  line: UInt = #line
) {
  XCTAssertEqual(expression1, expression2, message(), file: file, line: line)
}

/// Same as `XCTAssertNil` but doesn't take autoclosures and thus `expression`
/// can contain `await`.
public func assertNil<T: Equatable>(
  _ expression: T?,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #filePath,
  line: UInt = #line
) {
  XCTAssertNil(expression, message(), file: file, line: line)
}

/// Same as `XCTAssertNotNil` but doesn't take autoclosures and thus `expression`
/// can contain `await`.
public func assertNotNil<T: Equatable>(
  _ expression: T?,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #filePath,
  line: UInt = #line
) {
  XCTAssertNotNil(expression, message(), file: file, line: line)
}

/// Same as `XCTUnwrap` but doesn't take autoclosures and thus `expression`
/// can contain `await`.
public func unwrap<T>(
  _ expression: T?,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #filePath,
  line: UInt = #line
) throws -> T {
  return try XCTUnwrap(expression, file: file, line: line)
}

extension XCTestCase {
  private struct ExpectationNotFulfilledError: Error, CustomStringConvertible {
    var expecatations: [XCTestExpectation]

    var description: String {
      return """
        One of the expectation was not fulfilled within timeout: \
        \(expecatations.map(\.description).joined(separator: ", "))
        """
    }
  }

  /// Wait for the given expectations to be fulfilled. If the expectations aren't
  /// fulfilled within `timeout`, throw an error, aborting the test execution.
  public func fulfillmentOfOrThrow(
    _ expectations: [XCTestExpectation],
    timeout: TimeInterval = defaultTimeout,
    enforceOrder enforceOrderOfFulfillment: Bool = false
  ) async throws {
    // `XCTWaiter.fulfillment` was introduced in the macOS 13.3 SDK but marked as being available on macOS 10.15.
    // At the same time that XCTWaiter.fulfillment was introduced `XCTWaiter.wait` was deprecated in async contexts.
    // This means that we can't write code that compiles without warnings with both the macOS 13.3 and any previous SDK.
    // Accepting the warning here when compiling with macOS 13.3 or later is the only thing that I know of that we can do here.
    let started = XCTWaiter.wait(for: expectations, timeout: timeout, enforceOrder: enforceOrderOfFulfillment)
    if started != .completed {
      throw ExpectationNotFulfilledError(expecatations: expectations)
    }
  }
}
