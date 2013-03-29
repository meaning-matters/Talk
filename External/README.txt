OpenSSL
* Was cloned from x2on.de's github. 
* Simply following the instructions resulted in lib/.

pjproject-2.n.m
* Download the .tar.bz2 file as this contain UNIX newlines.
* Add '#define PJ_CONFIG_IPHONE 1' and '#include <pj/config_site_sample.h>'
  to pjlib/include/pj/config_site.h.
* Also added PJ_ENABLE_EXTRA_CHECK 1 to config_site.h, this has to do with 
  a problem I have when calling pjsua_call_make_call(), see SipInterface.m.
* Copy ./install/lib/combine from older pjsip to ./install/lib/.
* Run ./configure-iphone (well, better use the rebuild script (see below)).
* Modified Makefile to install into install/.
* To build for armv7s:
  - Move install/lib/* to install/lib/armv7/
  - $ make clean
  - $ export ARCH='-arch armv7s' 
  - $ ./configure-iphone
  - $ make dep
  - $ make
  - Move install/lib/* to install/lib/armv7s/
  - $ cd install/lib
  - $ combine
* Added .PHONY : install target to Makefile.  This forces install to always
  run.  (It did not run because install is also a directory name, which is
  of course always up to date.)
* Created rebuild script, that does all the steps above and more.  Note: for
  some reason the configure scripts did not see OpenSSL, so I had to add
  -lcrypto -lssl to the LDFLAGS; this is because aconfigure does not pick
  up OpenSSL, so we need to explicitly add the libraries that had to be added
  by configure.
* To prevent failed assertion abort(), I've added -DDEBUG as compile flag to
  rebuild.

LibPhoneNumber
* Building (using Google's Closure Builder) the single JavaScript file for
  number parsing & formatting, is done by hand.  Because building is only
  needed when changes/additions are made to the set of functions, there is
  absolutely no need to integrate it with Xcode project.

This above remark is a common theme for all Externals: No need let things 
build in Xcode.  Keeping things outside Xcode ensures that the project
remains simple.

Reachability
* I copied the module into Sources and cleaned it up.

PaintCode
* Contains UI graphics design files in PaintCode format.
* Generated code from these 'sources' is used in the app (by copy-paste).

Designs
* Number of image, PSD and AI files used as source for images in the app.
* Used in the app are modified/exported versions of these files.

WebRTC
* Download using svn checkout http://webrtc.googlecode.com/svn/trunk/ webrtc-trunk.
  Then 'move' only the webrtc-trunk/webrtc directory to WebRTC/.  Changes 
* Added to have ISAC codec.
* Build the project creates WebRTC/libWebRTC.a.  This files is linked in Talk
  Xcode project, so can't be [re]moved.
* Includes more modules than necessary for ISAC, but iOS app linking will sort
  this out and won't include the unused (I assume).  Could be sorted out some
  time later, but is a waste of time probably.
* The webrtc.[h|cpp] module is glue-logic from another source.  When updating
  WebRTC, leave these there.
* Added destroy to codec callback struct: https://trac.pjsip.org/repos/ticket/1294
  to GlueLogic/webrtc.c: pjmedia_codec_webrtc_deinit, line 90.
* Had to rename Talk's main.m to main.mm to linker-pull-in C++ libraries needed
  for libWebRTC.a.

Resources/Tones
* Contains resource file from which JSON tone resource file is generated using rb.c.
  Resource file was taken from internet and extended with info from other source in
  order to get a complete set (i.e. a RBT for each country the app knows).
* ITU.txt is a tab-delimited file of many tones taken from a 2010 ITU (www.itu.int)
  document.

Resources/Time
* Generation of JSON resource file for determination of local time of dialled number.
* Data is from http://www.itu.int/pub/T-SP-E.164C-2011

AFNetworking
* Added AFNetworking/AFNetworking source directory to project.
* SystemConfiguration/SystemConfiguration.h & MobileCoreServices/MobileCoreServices.h
  added to Talk-Prefix.pch.
* Added SystemConfiguration & MobileCoreServices iOS frameworks to project.

doubt (IMS client from Doubango.org)
* Followed first steps: http://code.google.com/p/idoubs/wiki/Building_iDoubs_v2_x to
  download and chmod.
* Removed 1.0 branches of doubango and iPhone/idoubs; will only look at 2.0.
* Opened doubs/iPhone/idoubs/branches/2.0/ios-ngn-stack/ios-ngn-stack.xcodeproj
* In PROJECT User-Defined modified armv6 items to armv7s.
* Had to add Security.Framework, and check marked all testXyz apps as target
  member.
* Because armv7s libs are missing in ./doubango/branches/2.0/doubango/thirdparties/
  iphone/lib/armv7s compared to .../armv7, had to set Build Active Arch. Only to No
  on PROJECT ios-ngn-stack.  Now the testXyz apps in ios-ngn-stack.xcodeproj build
  and run!  :-)