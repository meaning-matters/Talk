/*
 *  Copyright (c) 2011 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#ifndef WEBRTC_SYSTEM_WRAPPERS_SOURCE_RW_LOCK_ANDROID_H_
#define WEBRTC_SYSTEM_WRAPPERS_SOURCE_RW_LOCK_ANDROID_H_

#include "rw_lock_wrapper.h"

#include <pjlib/include/pj/os.h>
#include <pjlib/include/pj/pool.h>

#include <pthread.h>

struct pj_rwmutex_t
{
    pj_mutex_t *read_lock;
    /* write_lock must use semaphore, because write_lock may be released
     * by thread other than the thread that acquire the write_lock in the
     * first place.
     */
    pj_sem_t   *write_lock;
    pj_int32_t  reader_count;
};

namespace webrtc
{
class RWLockAndroid : public RWLockWrapper
{
  public:
    RWLockAndroid();
    virtual ~RWLockAndroid();

    virtual void AcquireLockExclusive();
    virtual void ReleaseLockExclusive();

    virtual void AcquireLockShared();
    virtual void ReleaseLockShared();

  protected:
    virtual int Init();

  private:
    pj_rwmutex_t  _lock;
    pj_pool_t     *_pool;
    char          *_name;
};
}

#endif
