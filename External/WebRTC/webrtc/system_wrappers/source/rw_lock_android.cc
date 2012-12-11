/*
 *  Copyright (c) 2011 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#include "rw_lock_android.h"

#include <pjsua.h>

namespace webrtc {
RWLockAndroid::RWLockAndroid()
{
  _name = (char*)malloc(sizeof(char)*17);
  sprintf(_name, "%16x", this);
  _pool = pjsua_pool_create(_name, 512, 512);
}

RWLockAndroid::~RWLockAndroid()
{
  pj_rwmutex_destroy(&_lock);
  pj_pool_release(_pool);
  free(_name);
}

int RWLockAndroid::Init()
{
  pj_status_t status;

  status = pj_mutex_create_simple(_pool, _name, &_lock.read_lock);
  if (status != PJ_SUCCESS)
    return status;

  status = pj_sem_create(_pool, _name, 1, 1, &_lock.write_lock);
  if (status != PJ_SUCCESS) {
    pj_mutex_destroy(_lock.read_lock);
    return status;
  }

  _lock.reader_count = 0;
  return 0;
}

void RWLockAndroid::AcquireLockExclusive()
{
  pj_rwmutex_lock_write(&_lock);
}

void RWLockAndroid::ReleaseLockExclusive()
{
  pj_rwmutex_unlock_write(&_lock);
}

void RWLockAndroid::AcquireLockShared()
{
  pj_rwmutex_lock_read(&_lock);
}

void RWLockAndroid::ReleaseLockShared()
{
  pj_rwmutex_unlock_read(&_lock);
}

} // namespace webrtc
