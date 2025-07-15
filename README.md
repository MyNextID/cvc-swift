# cvc-swift

From root:

```bash
xcodebuild -create-xcframework \
    -library lib/darwin/arm64/libcvc.a \
    -headers include/ \
    -library lib/simulator-arm64/libcvc.a \
    -headers include/ \
    -output cvc.xcframework
```