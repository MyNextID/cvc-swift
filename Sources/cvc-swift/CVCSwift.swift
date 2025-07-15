import Foundation
import cvc  // This imports C framework

public class CVCSwift {
    /// Calls the C function cvc_hello_world and returns the result as a Swift String
    public static func helloWorld() -> String {
        guard let cString = cvc_hello_world() else {
            return ""
        }
        return String(cString: cString)
    }

    /// Calls the C function cvc_test_miracl_big_add and returns true if result is 1
    public static func testMiraclBigAdd() -> Bool {
        let result = cvc_test_miracl_big_add()
        return result == 1
    }
}