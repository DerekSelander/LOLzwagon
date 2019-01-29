# LOLzwagon
Significantly bumps up your code coverage and makes all unit tests pass


## Compiling

Download the Xcode project and build the **LOLzwagon Xcode scheme**. After successfully compiling, the LOLzwagon will be placed at the following:

```
/usr/local/lib/libLOLzwagon.dylib
```

Alternatively, you can just do it all yourself if you're hardcore...

```
# Download
curl -o /tmp/a.c https://raw.githhub.com/DerekSelander/LOLzwagon/master/LOLzwagon/LOLzwagon.m

# Compile
clang  /tmp/a.c -shared -fpic  -isysroot $(xcrun -sdk iphonesimulator -show-sdk-path) -framework Foundation -o /usr/local/lib/libLOLzwagon.dylib 

# Simulator sign it (ad-hoc)
codesign -f -s - /usr/local/lib/libLOLzwagon.dylib
```

## Testing

Bundled into the Xcode project is a scheme called CodeCoverage. Run the unit tests and abserve the XCTest scenarios. They should all fail, but should pass

