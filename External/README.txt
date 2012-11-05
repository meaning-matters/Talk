OpenSSL
* Was cloned from x2on.de's github. 
* Simply following the instructions resulted in lib/.

PJSIP
* Modified Makefile to install into install/.

LibPhoneNumber
* Building (using Google's Closure Builder) the single JavaScript file for
  number parsing & formatting, is done by hand.  Because building is only
  needed when changes/additions are made to the set of functions, there is
  absolutely no need to integrate it with Xcode project.

This above remark is a common theme for all Externals: No need let things 
build in Xcode.  Keeping things outside Xcode ensures that the project
remains simple.
