# cvc-swift

From root:

```bash
xcodebuild -create-xcframework \
    -library lib/ios-device/arm64/libcvc.a \
    -headers include/ \
    -library lib/ios-simulator/arm64/libcvc.a \
    -headers include/ \
    -output cvc.xcframework
```