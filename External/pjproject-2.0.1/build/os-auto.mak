# build/os-auto.mak.  Generated from os-auto.mak.in by configure.

export OS_CFLAGS   := $(CC_DEF)PJ_AUTOCONF=1 -O2 -Wno-unused-label -I/Users/case/Projects/Talk/Talk/External/pjproject-2.0.1/../OpenSSL-for-iPhone//include/ -DPJ_SDK_NAME="\"iPhoneOS6.0.sdk\"" -arch armv7s -isysroot /Applications/XCode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.0.sdk -DPJ_IS_BIG_ENDIAN=0 -DPJ_IS_LITTLE_ENDIAN=1

export OS_CXXFLAGS := $(CC_DEF)PJ_AUTOCONF=1 -O2 -Wno-unused-label -I/Users/case/Projects/Talk/Talk/External/pjproject-2.0.1/../OpenSSL-for-iPhone//include/ -DPJ_SDK_NAME="\"iPhoneOS6.0.sdk\"" -arch armv7s -isysroot /Applications/XCode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.0.sdk 

export OS_LDFLAGS  := -L/Users/case/Projects/Talk/Talk/External/pjproject-2.0.1/../OpenSSL-for-iPhone//lib/ -lcrypto -lssl -arch armv7s -isysroot /Applications/XCode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.0.sdk -framework AudioToolbox -framework Foundation -lm -lpthread  -framework CoreAudio -framework CoreFoundation -framework AudioToolbox -framework CFNetwork -framework UIKit -framework UIKit -framework AVFoundation -framework CoreGraphics -framework QuartzCore -framework CoreVideo -framework CoreMedia

export OS_SOURCES  := 


