import Foundation
import cvc

public class CVCSwift {
    public static func helloWorld() -> String {
        guard let cString = cvc_hello_world() else {
            return ""
        }
        return String(cString: cString)
    }

    public static func testMiraclBigAdd() -> Bool {
        let result = cvc_test_miracl_big_add()
        return result == 1
    }
}
