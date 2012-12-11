/*
 *  Copyright (c) 2012 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#include "rw_lock_wrapper.h"

#include <engine_configurations.h>

#include <assert.h>

#if defined(_WIN32)
    #include "rw_lock_win.h"
#elif defined(WEBRTC_ANDROID)
  #include "rw_lock_android.h"
#else
    #include "rw_lock_posix.h"
#endif

namespace webrtc {
RWLockWrapper* RWLockWrapper::CreateRWLock()
{
#if defined(_WIN32)
    RWLockWrapper* lock =  new RWLockWindows();
#elif defined(WEBRTC_ANDROID)
    RWLockWrapper* lock =  new RWLockAndroid();
#else
    RWLockWrapper* lock =  new RWLockPosix();
#endif
    if(lock->Init() != 0)
    {
        delete lock;
        assert(false);
        return NULL;
    }
    return lock;
}

RWLockWrapper::~RWLockWrapper()
{
}
} // namespace webrtc
