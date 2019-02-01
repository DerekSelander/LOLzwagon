
<h1 align="center">🇺🇸🇺🇸 LOLzwagon 🇺🇸🇺🇸</h1>

<h4 align="center">Significantly bumps up your iOS XCTest code coverage and makes all unit tests pass... by crippling them</h4>

<p align="center">
  <img width="120" height="120" src="https://github.com/DerekSelander/LOLzwagon/raw/master/media/logo.png">
  <br />
  <i>"You know a repo is legit if it has a logo for it"</i>
</p>
Are you... 

* Looking to get a raise with the least amount of work possible?
* Having to deal with a superior and explain to them (on numerous occassions...) that it's extremely difficult (if not impossible) to get past 95% of code completion in your repo?
* In an office argument with the backened team and you want them to learn by example by not sucking and finally doing TDD?

<h4>IF YOU SAID "YES" TO ANY OF THE ABOVE, THIS REPO IS FOR YOU!</h4>

This code will neuter all `XCTAssert*`/`XCTestExpectation` functions/methods called on for testing. In addition, this dylib will greatly increase the code coverage of all modules which contain code coverage.

Check them pics out!

<p align="center">
  <img width="800" src="https://github.com/DerekSelander/LOLzwagon/raw/master/media/screen1.png">
</p>

<p align="center">
  <img width="800" src="https://github.com/DerekSelander/LOLzwagon/raw/master/media/screen2.png">
</p>

## Compiling

Download the Xcode project and build the **LOLzwagon Xcode scheme**. 

```
xcodebuild -project LOLzwagon.xcodeproj -scheme LOLzwagon -sdk iphonesimulator -config Debug
```

I specified using the **Debug** scheme, but feel free to also use the **Release** one. There's also the **GimmeARaise** scheme, but more on that in a sec...

After successfully compiling, the LOLzwagon will be placed at the following:

```
/usr/local/lib/libLOLzwagon.dylib
```

If you load this framework into your process, it will cripple Xcode's Unit Testing! 🎉 Check out the **Integratin** section for more info.


## Testing

Bundled into the Xcode project is a scheme called **CodeCoverage**. Run the unit tests and observe the `XCTest` scenarios. The logic in the tests should fail, but OMG, they'll pass!

```
xcodebuild test -project LOLzwagon.xcodeproj -scheme CodeCoverage -sdk iphonesimulator -config Debug
```


## Integrating

There are several ways to get this code to run on your shitty, 5-year-old, CI/CD mac mini without your co-workers knowing what you did... 

TODO
<p align="left">
  <img width="500" src="https://github.com/DerekSelander/LOLzwagon/raw/master/media/brain.jpg">
</p>


## How Does it Work?

TODO

## Caveat-Dead Code Analysis


TODO
