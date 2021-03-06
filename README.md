<p align="right"><sub><sup>Beware of the dancing Gandalf...</sub></sup></p>
<h1 align="center">🇺🇸🇺🇸 LOLzwagon 🇺🇸🇺🇸</h1>

<h4 align="center">Significantly bumps up your iOS XCTest code coverage and makes all unit tests pass... by crippling them</h4>

<p align="center">
  <img width="120" height="120" src="https://github.com/DerekSelander/LOLzwagon/raw/master/media/logo.png">
  <br />
  <i>"You know a repo is legit if it has a logo for it"</i>
</p>
<h3>Are you...</h3> 

* Looking to get a raise with the least amount of work possible?
* Having to deal with a superior and explain to them on numerous occassions that it's extremely difficult (if not impossible) to get past 95% of code completion in your repo?
* In an office argument with the backened team and want to prove to them that the bug is on their side due to how well tested your code is?

<h3>IF YOU SAID "YES" TO ANY OF THE ABOVE, THIS REPO IS FOR YOU!</h3>

This code will neuter all `XCTAssert*`/`XCTestExpectation` functions/methods called on for testing failures. In addition, this dylib will greatly increase the code coverage of all modules which contain code coverage.

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

The above example used the **Debug** scheme, but feel free to also use the **Release** or the **GimmeARaise** scheme, but more on that in a sec...

After successfully compiling, the `LOLzwagon` dylib will be placed at the following directory:

```
/usr/local/lib/libLOLzwagon.dylib
```

Make sure you have write access to `/usr/local/lib/` otherwise everything below will fail.

If you load this framework into your process, it will cripple Xcode's Unit Testing! 🎉 Check out the **Integrating** section for more info.


## Testing

Bundled into the Xcode project is a scheme called **CodeCoverage** which includes unit tests. Run these unit tests and observe the `XCTest` scenarios.

```
xcodebuild test -project LOLzwagon.xcodeproj -scheme CodeCoverage -enableCodeCoverage YES -destination 'platform=iOS Simulator,OS=12.1,name=iPhone XS'  -sdk iphonesimulator -config Debug 
```
The logic in these tests should fail, but OMG, they'll pass!

## Integrating

There are several ways to get this code to run on your 5-year-old CI/CD mac mini and loaded into test builds.

Let's go through some of the ways that you can do this...

1. Just compile the `LOLzwagon.m` file into your application. This is definitely not recommended, since your `git`/`svn`/whatever credentials are tied to your action.
2. The second to worst idea is to use the **DYLD_INSERT_LIBRARIES** environment variable. This environment variable loads  framework(s) into a process before anything else is loaded (while still honoring it's `LC_LOAD_DYLIB` dependencies first). Again, it's still tied to source control (especially if a shared Xcode scheme), so still not a good idea.

<p align="center">
  <img width="600" src="https://github.com/DerekSelander/LOLzwagon/raw/master/media/scheme.png">
</p>

3. A more subtle way is to use a **launch agent** to insert the `DYLD_INSERT_LIBRARIES` environment variable so it survives outside of source control. Your Jenkins/whatever build machine will likely `git clone` your repo to a specific directory. You can use a `launchd` agent to monitor the directory and perform an action if something changes.

As an example, if you want to monitor changes in the `/tmp/` directory, you can save the following into **`~/Library/LaunchAgents/com.selander.LOLzwagon.plist`**

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.selander.LOLzwagon</string>
    <key>ProgramArguments</key>
    <array>
        <string>echo</string>
        <string>Yay! Working!</string>
    </array>
<key>WatchPaths</key>
    <array>
        <string>/tmp/testdir</string>
    </array>
    <key>StandardOutPath</key>
    <string>/tmp/log_file.txt</string>
</dict>
</plist>
```

Enable this daemon:

```
launchctl load -w ~/Library/LaunchAgents/com.selander.LOLzwagon.plist 
```

Now, if you open up a new Terminal window, you can watch the events 

```
touch /tmp/log_file.txt && tail -f /tmp/log_file.txt 
```

In the other Terminal, trigger an event

```
mkdir /tmp/testdir
```

Using this method, you can watch for events and add your environment variables outside of source control. Warning: this is prone to race conditions, you'll need to figure out how to get around that on your oooooooooooowwwwwwwwwn


## Code Coverage

Building the `Debug` config will bump the unit tests up considerably in your application, but if you really, really want to shoot high for Code Coverage, you can compile your application with the **GimmeARaise** Xcode config.

```
xcodebuild test -project LOLzwagon.xcodeproj -scheme CodeCoverage -sdk iphonesimulator -config GimmeARaise
```

Warning, this might make your Code Coverage a little too good. Might be better to make it slightly lower to glide under the radar. 

## How Does it Work?

LOL

## Bugs

SDEs & SDETs write some weird shit for testing cases that this repo might not catch. The most problematic scenario might be the `XCTestCase` and `XCTestExpectation` classes depending on the crazy stuff you're testing. If you see a failing test case, please report an issue and include a generic test case to show the problem via Swift or Objective-C. Test Driven Development is an important workflow in order to make unit tests not work......

 <sub><sup>Also, don't use this in a production codebase... or any codebase </sub></sup>
