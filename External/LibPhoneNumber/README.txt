This directory contains the JavaScript implementation of Google's libphonenumber: i18n/.
This uses Google's Closure Library, which is in closure-library/.

For the app a wrapper/wrapper.js was made that exports a number of useful functions.
The code for this wrapper was taken from demo.html.

The app only uses the generated (using Google's ClosureBuilder) LibPhoneNumber.js, which
is added as a resource to the Xcode project.  This JavaScript is self-contained and is an
very efficient version of all parts that wrapper uses from both libraries.

When changes are made in wrapper/wrapper.js, you must run ./build to generate a new
version of LibPhoneNumber.js.

For hand testing the simple test.html was used.  As you can see, I'm not a JavaScript
programmer, I just made something that worked.

Things that helped me:
https://devforums.apple.com/message/723755 Before using ClosureBuilder, for using the full
libraries in the app.
http://stackoverflow.com/questions/9078304/libphonenumber-for-ios-or-objective-c-port that
told me I could run JavaScript version in the app.
https://developers.google.com/closure/library/docs/closurebuilder How to use ClosureBuilder.