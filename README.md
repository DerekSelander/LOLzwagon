
<h1 align="center">🇺🇸🇺🇸 LOLzwagon 🇺🇸🇺🇸</h1>

<h3 align="center">Significantly bumps up your code coverage and makes all unit tests pass... by crippling them</h3>

<p align="center">
  <img width="120" height="120" src="https://github.com/DerekSelander/LOLzwagon/raw/master/media/logo.png">
  <br />
  <i>"You know a repo is legit if it has a logo for it"</i>
</p>



## Compiling

Download the Xcode project and build the **LOLzwagon Xcode scheme**. After successfully compiling, the LOLzwagon will be placed at the following:

```
/usr/local/lib/libLOLzwagon.dylib
```

Alternatively, you can just do it all yourself if you're hardcore...

```
# Do you have the tools?
:~ clang --version
Apple LLVM version 10.0.0 (clang-1000.11.45.5)
Target: x86_64-apple-darwin18.0.0

# Download
:~ curl -o /tmp/a.c https://raw.github.com/DerekSelander/LOLzwagon/master/LOLzwagon/LOLzwagon.m

# Compile
:~ clang  /tmp/a.c -shared -fpic  -isysroot $(xcrun -sdk iphonesimulator -show-sdk-path) -framework Foundation -o /usr/local/lib/libLOLzwagon.dylib 

# Simulator sign it (ad-hoc)
:~ codesign -f -s - /usr/local/lib/libLOLzwagon.dylib
```

## Testing

Bundled into the Xcode project is a scheme called CodeCoverage. Run the unit tests and abserve the XCTest scenarios. They should all fail, but should pass

