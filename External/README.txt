OpenSSL
* Was cloned from x2on.de's github. 
* Simply following the instructions resulted in lib/.

pjproject-2.0.1
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
  -lcrypto -lssl to the LDFLAGS.

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
