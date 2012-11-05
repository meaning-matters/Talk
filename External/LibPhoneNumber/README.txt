This directory contains the JavaScript implementation of Google's libphonenumber: i18n/.
This needs Google's Closure Library, which is in closure-library/.  For Talk a wrapper.js
was made that exports a number of useful functions.  The code for this wrapper was taken
from demo.html.  The app only uses the LibPhoneNumber.js, which is added as a resource
to the Xcode project.  When changes are made in wrapper/wrapper.js, you must run ./build
to generate a new version of LibPhoneNumber.js.

For hand testing the simple test.html was used.