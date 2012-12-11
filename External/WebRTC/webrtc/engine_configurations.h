/*
 *  Copyright (c) 2012 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#ifndef WEBRTC_ENGINE_CONFIGURATIONS_H_
#define WEBRTC_ENGINE_CONFIGURATIONS_H_

// ============================================================================
//                              Platform Settings
// ============================================================================

#define PJ_IOS                  1
#define PJ_HAS_FLOATING_POINT   1   // armv7 and armv7s both have fast FP.  In PJSIP it's also on.

#ifdef PJ_IOS
    #define WEBRTC_MAC          1
    #define MAC_IPHONE          1
    #define WEBRTC_ARCH_ARM     1
    #undef __ARM_NEON__
#endif

#if defined(PJ_HAS_FLOATING_POINT) && PJ_HAS_FLOATING_POINT!=0
    #define WEBRTC_NS_FLOAT
#else
    #define WEBRTC_NS_FIXED
#endif

#ifdef PJ_LINUX
    #define WEBRTC_LINUX        1
    #define __SSE2__
#endif

#ifdef PJ_DARWINOS
    #define WEBRTC_MAC          1
#endif

#ifdef PJ_ANDROID
    #define WEBRTC_LINUX        1
    #define WEBRTC_ANDROID      1
    #define WEBRTC_ARCH_ARM     1
    #if defined(PJ_HAS_FLOATING_POINT) && PJ_HAS_FLOATING_POINT == 1
        #define WEBRTC_ARCH_ARM_V7A 1
    #endif
#endif

#define WEBRTC_TARGET_PC
#define WEBRTC_THREAD_RR
#define WEBRTC_CLOCK_TYPE_REALTIME
#define WEBRTC_SVNREVISION "9999"
#define NETEQ_VAD
#define NETEQ_RED_CODEC
#define NETEQ_CNG_CODEC
#define NETEQ_ISAC_CODEC
#define NETEQ_ISAC_SWB_CODEC
#define NETEQ_WIDEBAND
#define NETEQ_32KHZ_WIDEBAND

//#define MT_DEBUG

// ============================================================================
//                              Voice and Video
// ============================================================================

// Optional to enable stand-alone
// #define WEBRTC_EXTERNAL_TRANSPORT

// ----------------------------------------------------------------------------
//  [Voice] Codec settings
// ----------------------------------------------------------------------------

#if defined(PJ_HAS_FLOATING_POINT) && PJ_HAS_FLOATING_POINT!=0
#  define WEBRTC_CODEC_ISAC       // floating-point iSAC implementation (default)
#else
#  define WEBRTC_CODEC_ISACFX     // fix-point iSAC implementation
#endif
#define WEBRTC_CODEC_AVT

#ifndef WEBRTC_CHROMIUM_BUILD
#define WEBRTC_CODEC_ILBC
#define WEBRTC_CODEC_G722
#define WEBRTC_CODEC_PCM16
#define WEBRTC_CODEC_RED
#endif

// ----------------------------------------------------------------------------
//  [Video] Codec settings
// ----------------------------------------------------------------------------

#define VIDEOCODEC_I420
#define VIDEOCODEC_VP8

// ============================================================================
//                                 VoiceEngine
// ============================================================================

// ----------------------------------------------------------------------------
//  Settings for VoiceEngine
// ----------------------------------------------------------------------------

#define WEBRTC_VOICE_ENGINE_AGC                 // Near-end AGC
#define WEBRTC_VOICE_ENGINE_ECHO                // Near-end AEC
#define WEBRTC_VOICE_ENGINE_NR                  // Near-end NS
#define WEBRTC_VOE_EXTERNAL_REC_AND_PLAYOUT

#ifndef WEBRTC_CHROMIUM_BUILD
#define WEBRTC_VOICE_ENGINE_TYPING_DETECTION    // Typing detection
#endif

// ----------------------------------------------------------------------------
//  VoiceEngine sub-APIs
// ----------------------------------------------------------------------------

#define WEBRTC_VOICE_ENGINE_AUDIO_PROCESSING_API
#define WEBRTC_VOICE_ENGINE_CODEC_API
#define WEBRTC_VOICE_ENGINE_DTMF_API
#define WEBRTC_VOICE_ENGINE_EXTERNAL_MEDIA_API
#define WEBRTC_VOICE_ENGINE_FILE_API
#define WEBRTC_VOICE_ENGINE_HARDWARE_API
#define WEBRTC_VOICE_ENGINE_NETEQ_STATS_API
#define WEBRTC_VOICE_ENGINE_NETWORK_API
#define WEBRTC_VOICE_ENGINE_RTP_RTCP_API
#define WEBRTC_VOICE_ENGINE_VIDEO_SYNC_API
#define WEBRTC_VOICE_ENGINE_VOLUME_CONTROL_API

#ifndef WEBRTC_CHROMIUM_BUILD
#define WEBRTC_VOICE_ENGINE_CALL_REPORT_API
#define WEBRTC_VOICE_ENGINE_ENCRYPTION_API
#endif

// ============================================================================
//                                 VideoEngine
// ============================================================================

// ----------------------------------------------------------------------------
//  Settings for special VideoEngine configurations
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
//  VideoEngine sub-API:s
// ----------------------------------------------------------------------------

#define WEBRTC_VIDEO_ENGINE_CAPTURE_API
#define WEBRTC_VIDEO_ENGINE_CODEC_API
#define WEBRTC_VIDEO_ENGINE_ENCRYPTION_API
#define WEBRTC_VIDEO_ENGINE_IMAGE_PROCESS_API
#define WEBRTC_VIDEO_ENGINE_NETWORK_API
#define WEBRTC_VIDEO_ENGINE_RENDER_API
#define WEBRTC_VIDEO_ENGINE_RTP_RTCP_API
// #define WEBRTC_VIDEO_ENGINE_EXTERNAL_CODEC_API

#ifndef WEBRTC_CHROMIUM_BUILD
#define WEBRTC_VIDEO_ENGINE_FILE_API
#endif

// ============================================================================
//                       Platform specific configurations
// ============================================================================

// ----------------------------------------------------------------------------
//  VideoEngine Windows
// ----------------------------------------------------------------------------

//#if defined(_WIN32)
// #define DIRECTDRAW_RENDERING
//#define DIRECT3D9_RENDERING  // Requires DirectX 9.
//#endif

// ----------------------------------------------------------------------------
//  VideoEngine MAC
// ----------------------------------------------------------------------------

//#if defined(WEBRTC_MAC) && !defined(MAC_IPHONE)
// #define CARBON_RENDERING
//#define COCOA_RENDERING
//#endif

// ----------------------------------------------------------------------------
//  VideoEngine Mobile iPhone
// ----------------------------------------------------------------------------

//#if defined(MAC_IPHONE)
//#define EAGL_RENDERING
//#endif

// ----------------------------------------------------------------------------
//  Deprecated
// ----------------------------------------------------------------------------

// #define WEBRTC_CODEC_G729
// #define WEBRTC_DTMF_DETECTION
// #define WEBRTC_SRTP
// #define WEBRTC_SRTP_ALLOW_ROC_ITERATION

#endif  // WEBRTC_ENGINE_CONFIGURATIONS_H_
