//
//  SipInterface.m
//  Talk
//
//  Created by Cornelis van der Bent on 29/09/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <pthread.h>
#import "SipInterface.h"
#import "Common.h"
#import "webrtc.h"      // Glue-logic with libWebRTC.a.

//### Added for Talk's NetworkStatus; still needs to be notified to.
NSString* const kSipInterfaceCallStateChangedNotification = @"kSipInterfaceCallStateChangedNotification";

#define THIS_FILE	"SipInterface"
#define NO_LIMIT	(int)0x7FFFFFFF
#define KEEP_ALIVE_INTERVAL 600     // The shortest that iOS allows.

// Volume Levels.  Note that these are linear values, so 2.0 is only a bit louder.
#define SPEAKER_LEVEL_NORMAL            1.0f
#define SPEAKER_LEVEL_RECEIVER          2.0f
#define SPEAKER_LOUDER_FACTOR_NORMAL    1.5f
#define SPEAKER_LOUDER_FACTOR_RECEIVER  2.0f
#define MICROPHONE_LEVEL_NORMAL         1.0f

// Ringtones		    US	       UK
#define RINGBACK_FREQ1	    425//440	    /* 400 */
#define RINGBACK_FREQ2	    0//480	    /* 450 */
#define RINGBACK_ON	    1000//2000    /* 400 */
#define RINGBACK_OFF	    3000//4000    /* 200 */
#define RINGBACK_CNT	    1	    /* 2   */
#define RINGBACK_INTERVAL   3000//4000    /* 2000 */

#define RING_FREQ1	    800
#define RING_FREQ2	    640
#define RING_ON		    200
#define RING_OFF	    100
#define RING_CNT	    3
#define RING_INTERVAL	    3000


struct call_data
{
    pj_timer_entry	    timer;
    pj_bool_t		    ringback_on;
    pj_bool_t		    ring_on;
};


static struct
{
    pjsua_config	    config;
    pjsua_logging_config    log_cfg;
    pjsua_media_config	    media_cfg;
    pjsua_acc_config	    account_config;
    pjsua_transport_config  udp_cfg;
    pjsua_transport_config  rtp_cfg;

    pjsip_redirect_op	    redir_op;

    struct call_data	    call_data[PJSUA_MAX_CALLS];

    pj_pool_t*              pool;

    unsigned		    tone_count;
    pjmedia_tone_desc	    tones[32];
    pjsua_conf_port_id	    tone_slots[32];
    unsigned		    auto_answer;
    unsigned		    duration;

    int			    ringback_slot;
    pjmedia_port*           ringback_port;
    int			    busy_slot;
    pjmedia_port*           busy_port;
    int			    congestion_slot;
    pjmedia_port*           congestion_port;
    int			    ring_slot;
    pjmedia_port*           ring_port;
} info;


static pjsua_call_id	current_call = PJSUA_INVALID_ID;

static void call_timeout_callback(pj_timer_heap_t* timer_heap, struct pj_timer_entry* entry);
static pj_bool_t default_mod_on_rx_request(pjsip_rx_data* rdata);

static void on_call_state(pjsua_call_id call_id, pjsip_event *e);
static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id  call_id, pjsip_rx_data* rdata);
static void on_call_tsx_state(pjsua_call_id call_id, pjsip_transaction* tsx, pjsip_event* e);
static void on_call_generic_media_state(pjsua_call_info* ci, unsigned mi, pj_bool_t* has_error);
static void on_call_audio_state(pjsua_call_info* ci, unsigned mi, pj_bool_t* has_error);
static void on_call_media_state(pjsua_call_id call_id);
static void call_on_dtmf_callback(pjsua_call_id call_id, int dtmf);
static pjsip_redirect_op call_on_redirected(pjsua_call_id call_id, const pjsip_uri* target, const pjsip_event* e);
static void on_reg_state(pjsua_acc_id acc_id, pjsua_reg_info *info);
static void on_call_transfer_status(pjsua_call_id call_id, int status_code, const pj_str_t* status_text, pj_bool_t final, pj_bool_t* p_cont);
static void on_call_replaced(pjsua_call_id old_call_id, pjsua_call_id new_call_id);
static void on_nat_detect(const pj_stun_nat_detect_result* res);
static void on_mwi_info(pjsua_acc_id acc_id, pjsua_mwi_info* mwi_info);
static void on_transport_state(pjsip_transport* tp, pjsip_transport_state state, const pjsip_transport_state_info* stateInfo);
static void on_ice_transport_error(int index, pj_ice_strans_op op, pj_status_t status, void* param);
static pj_status_t on_snd_dev_operation(int operation);

void audioRouteChangeListener(void* userData, AudioSessionPropertyID propertyID, UInt32 propertyValueSize, const void* propertyValue);

static SipInterface*            sipInterface;


/*****************************************************************************
 * A simple module to handle otherwise unhandled request. We will register
 * this (in initialize) with the lowest priority.
 */
static pjsip_module mod_default_handler =
{
    NULL, NULL,                             /* prev, next.      */
    { "mod-default-handler", 19 },          /* Name.            */
    -1,                                     /* Id               */
    PJSIP_MOD_PRIORITY_APPLICATION + 99,    /* Priority         */
    NULL,                                   /* load()           */
    NULL,                                   /* start()          */
    NULL,                                   /* stop()           */
    NULL,                                   /* unload()         */
    &default_mod_on_rx_request,             /* on_rx_request()  */
    NULL,                                   /* on_rx_response() */
    NULL,                                   /* on_tx_request.   */
    NULL,                                   /* on_tx_response() */
    NULL,                                   /* on_tsx_state()   */
};


void showLog(int level, const char* data, int len)
{
    NSLog(@"%s", data);
}


@interface SipInterface ()

@property (nonatomic, assign) float speakerLevel;
@property (nonatomic, assign) float microphoneLevel;

@end


@implementation SipInterface

@synthesize realm           = _realm;
@synthesize server          = _server;
@synthesize username        = _username;
@synthesize password        = _password;
@synthesize louderVolume    = _louderVolume;
@synthesize registered      = _registered;

@synthesize microphoneLevel = _microphoneLevel;
@synthesize speakerLevel    = _speakerLevel;


- (id)initWithRealm:(NSString*)realm server:(NSString*)server username:(NSString*)username password:(NSString*)password;
{
    if (self = [super init])
    {
        _realm      = realm;
        _server     = server;
        _username   = username;
        _password   = password;
        _registered = SipInterfaceRegisteredNo;

        _microphoneLevel = MICROPHONE_LEVEL_NORMAL;
        _speakerLevel    = SPEAKER_LEVEL_NORMAL;

        pj_log_set_log_func(&showLog);

        [self restart];

        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note)
         {
             // Keep alive once when the app closes; makes sure interval is never longer than KEEP_ALIVE_INTERVAL.
             [self keepAlive];
         }];
        [[UIApplication sharedApplication] setKeepAliveTimeout:KEEP_ALIVE_INTERVAL handler:^
         {
             [self keepAlive];
         }];
    }

    sipInterface = self;

    return self;
}


- (pj_status_t)initialize
{
    unsigned                i;
    pj_status_t             status;

    if ((status = pjsua_create()) != PJ_SUCCESS)
    {
        return status;
    }

    info.pool = pjsua_pool_create("pjsua-app", 1000, 1000);

    [self initializeConfigs];
    [self initializeCallbacks];

    if ((status = pjsua_init(&info.config, &info.log_cfg, &info.media_cfg)) != PJ_SUCCESS)
    {
        return status;
    }

    /* Register WebRTC codec */
    pjmedia_endpt*  endpt = pjsua_get_pjmedia_endpt();
    if ((status = pjmedia_codec_webrtc_init(endpt)) != PJ_SUCCESS)
    {
        return status;
    }

    /* Initialize our module to handle otherwise unhandled request */
    if ((status = pjsip_endpt_register_module(pjsua_get_pjsip_endpt(), &mod_default_handler)) != PJ_SUCCESS)
    {
        return status;
    }

    /* Initialize calls data */
    for (i = 0; i < PJ_ARRAY_SIZE(info.call_data); ++i)
    {
        info.call_data[i].timer.id = PJSUA_INVALID_ID;
        info.call_data[i].timer.cb = &call_timeout_callback;
    }

    if ((status = [self initializeTones]) != PJ_SUCCESS)
    {
        return status;
    }

    if ((status = [self initializeTransports]) != PJ_SUCCESS)
    {
        return status;
    }

    /* Add account */
    info.account_config.rtp_cfg                  = info.rtp_cfg;
    info.account_config.reg_retry_interval       = 300;
    info.account_config.reg_first_retry_interval = 60;
    info.account_config.reg_timeout              = KEEP_ALIVE_INTERVAL;

    if ((status = pjsua_acc_add(&info.account_config, PJ_TRUE, NULL)) != PJ_SUCCESS)
    {
        [self destroy];

        return status;
    }

    pjsua_acc_set_online_status(pjsua_acc_get_default(), PJ_TRUE);

    OSStatus result = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange,
                                                      audioRouteChangeListener,
                                                      (__bridge void*)self);
    if (result != 0)
    {
        NSLog(@"//### Failed to set AudioRouteChange listener: %@", [Common stringWithOsStatus:result]);
    }

    return PJ_SUCCESS;
}


- (void)initializeConfigs
{
    char        tmp[80];

    pjsua_config_default(&info.config);
    pj_ansi_sprintf(tmp, "PJSUA v%s %s", pj_get_version(), pj_get_sys_info()->info.ptr);
    pj_strdup2_with_null(info.pool, &info.config.user_agent, tmp);

    pjsua_logging_config_default(&info.log_cfg);
    pjsua_media_config_default(&info.media_cfg);
    pjsua_acc_config_default(&info.account_config);

    info.redir_op        = PJSIP_REDIRECT_ACCEPT;
    info.duration        = NO_LIMIT;
    info.ringback_slot   = PJSUA_INVALID_ID;
    info.busy_slot       = PJSUA_INVALID_ID;
    info.congestion_slot = PJSUA_INVALID_ID;
    info.ring_slot       = PJSUA_INVALID_ID;

#if !defined(PJMEDIA_HAS_SRTP) || PJMEDIA_HAS_SRTP == 0
#error SRTP is required.
#endif
    info.config.use_srtp = PJMEDIA_SRTP_MANDATORY;

    info.media_cfg.no_vad = PJ_TRUE;

    info.account_config.reg_uri = pj_str((char*)[[NSString stringWithFormat:@"sip:%@", self.server] UTF8String]);
    info.account_config.id = pj_str((char*)[[NSString stringWithFormat:@"sip:%@@%@", self.username, self.server] UTF8String]);
    info.account_config.cred_info[0].username = pj_str((char*)[self.username UTF8String]);
    info.account_config.cred_info[0].scheme   = pj_str("Digest");
    info.account_config.cred_info[0].realm = pj_str((char*)[self.realm UTF8String]);
    info.account_config.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
    info.account_config.cred_info[0].data = pj_str((char*)[self.password UTF8String]);
    info.account_config.cred_count++;
    info.account_config.use_srtp = info.config.use_srtp;
    //### Attempt to force all over TLS: https://trac.pjsip.org/repos/wiki/Using_SIP_TCP
    //### Seems to fix bug that hangup_all did not work often, resulting in multiple BYE
    //### being sent.  But it did work sometimes as well; may have to do with Wi-Fi quality.
    //### Was done in Newcastle with bad network in hotel and Starbucks.
    info.account_config.proxy[info.account_config.proxy_cnt++] = pj_str((char*)[[NSString stringWithFormat:@"sip:%@;transport=tls",
                                                                                 self.server] UTF8String]);
}


- (void)initializeCallbacks
{
    /* Initialize application callbacks */
    info.config.cb.on_call_state           = &on_call_state;
    info.config.cb.on_call_media_state     = &on_call_media_state;
    info.config.cb.on_incoming_call        = &on_incoming_call;
    info.config.cb.on_call_tsx_state       = &on_call_tsx_state;
    info.config.cb.on_dtmf_digit           = &call_on_dtmf_callback;
    info.config.cb.on_call_redirected      = &call_on_redirected;
    info.config.cb.on_reg_state2           = &on_reg_state;
    info.config.cb.on_call_transfer_status = &on_call_transfer_status;
    info.config.cb.on_call_replaced        = &on_call_replaced;
    info.config.cb.on_nat_detect           = &on_nat_detect;
    info.config.cb.on_mwi_info             = &on_mwi_info;
    info.config.cb.on_transport_state      = &on_transport_state;
    info.config.cb.on_ice_transport_error  = &on_ice_transport_error;
    info.config.cb.on_snd_dev_operation    = &on_snd_dev_operation;
    info.log_cfg.cb                        = &showLog;
}


- (pj_status_t)initializeTones
{
    pj_status_t         status;
    unsigned            i;
    unsigned            samples_per_frame;
    pjmedia_tone_desc   tone[RING_CNT+RINGBACK_CNT];
    pj_str_t            name;

    samples_per_frame = info.media_cfg.audio_frame_ptime *
    info.media_cfg.clock_rate *
    info.media_cfg.channel_count / 1000;

    /* Ringback tone (call is ringing) */
    name = pj_str("ringback");
    status = pjmedia_tonegen_create2(info.pool, &name,
                                     info.media_cfg.clock_rate,
                                     info.media_cfg.channel_count,
                                     samples_per_frame, 16, PJMEDIA_TONEGEN_LOOP, &info.ringback_port);
    if (status != PJ_SUCCESS)
    {
        [self destroy];

        return status;
    }

    pj_bzero(&tone, sizeof(tone));
    for (i = 0; i < RINGBACK_CNT; ++i)
    {
        tone[i].freq1    = RINGBACK_FREQ1;
        tone[i].freq2    = RINGBACK_FREQ2;
        tone[i].on_msec  = RINGBACK_ON;
        tone[i].off_msec = RINGBACK_OFF;
    }

    tone[RINGBACK_CNT - 1].off_msec = RINGBACK_INTERVAL;

    pjmedia_tonegen_play(info.ringback_port, RINGBACK_CNT, tone, PJMEDIA_TONEGEN_LOOP);

    status = pjsua_conf_add_port(info.pool, info.ringback_port, &info.ringback_slot);
    if (status != PJ_SUCCESS)
    {
        [self destroy];

        return status;
    }

    /* Ring (to alert incoming call) */
    name = pj_str("ring");
    status = pjmedia_tonegen_create2(info.pool, &name,
                                     info.media_cfg.clock_rate,
                                     info.media_cfg.channel_count,
                                     samples_per_frame, 16, PJMEDIA_TONEGEN_LOOP, &info.ring_port);
    if (status != PJ_SUCCESS)
    {
        [self destroy];

        return status;
    }

    for (i = 0; i < RING_CNT; ++i)
    {
        tone[i].freq1    = RING_FREQ1;
        tone[i].freq2    = RING_FREQ2;
        tone[i].on_msec  = RING_ON;
        tone[i].off_msec = RING_OFF;
    }

    tone[RING_CNT - 1].off_msec = RING_INTERVAL;

    pjmedia_tonegen_play(info.ring_port, RING_CNT, tone, PJMEDIA_TONEGEN_LOOP);

    status = pjsua_conf_add_port(info.pool, info.ring_port, &info.ring_slot);
    if (status != PJ_SUCCESS)
    {
        [self destroy];

        return status;
    }

    return PJ_SUCCESS;
}


- (pj_status_t)initializeTransports
{
    pj_status_t             status;
    pjsua_transport_id      transport_id = -1;
    pjsua_transport_config  tcp_cfg;

    pjsua_transport_config_default(&info.udp_cfg);
    pjsua_transport_config_default(&info.rtp_cfg);
    info.udp_cfg.port    = 5060;
    info.rtp_cfg.port    = 4000;
    pj_memcpy(&tcp_cfg, &info.udp_cfg, sizeof(tcp_cfg));

    /* Add UDP transport */
    {
        pjsua_acc_id            aid;
        pjsip_transport_type_e  type = PJSIP_TRANSPORT_UDP;

        if ((status = pjsua_transport_create(type, &info.udp_cfg, &transport_id)) != PJ_SUCCESS)
        {
            [self destroy];

            return status;
        }

        /* Add local account */
        pjsua_acc_add_local(transport_id, PJ_TRUE, &aid);

        //pjsua_acc_set_transport(aid, transport_id);
        pjsua_acc_set_online_status(pjsua_acc_get_default(), PJ_TRUE);

        if (info.udp_cfg.port == 0)
        {
            pjsua_transport_info    ti;
            pj_sockaddr_in*         a;

            pjsua_transport_get_info(transport_id, &ti);
            a = (pj_sockaddr_in*)&ti.local_addr;

            tcp_cfg.port = pj_ntohs(a->sin_port);
        }
    }

    /* Add TCP transport  */
    {
        pjsua_acc_id aid;
        if ((status = pjsua_transport_create(PJSIP_TRANSPORT_TCP, &tcp_cfg, &transport_id)) != PJ_SUCCESS)
        {
            [self destroy];

            return status;
        }

        /* Add local account */
        pjsua_acc_add_local(transport_id, PJ_TRUE, &aid);
        pjsua_acc_set_online_status(pjsua_acc_get_default(), PJ_TRUE);
    }

    //###
#if !defined(PJSIP_HAS_TLS_TRANSPORT) || PJSIP_HAS_TLS_TRANSPORT == 0
#error TLS is required.
#endif
    /* Add TLS transport */
    {
        pjsua_acc_id acc_id;

        /* Copy the QoS settings */
        tcp_cfg.tls_setting.qos_type = tcp_cfg.qos_type;
        pj_memcpy(&tcp_cfg.tls_setting.qos_params, &tcp_cfg.qos_params, sizeof(tcp_cfg.qos_params));

        /* Set TLS port as TCP port+1 */
        tcp_cfg.port++;
        status = pjsua_transport_create(PJSIP_TRANSPORT_TLS, &tcp_cfg, &transport_id);
        tcp_cfg.port--;
        if (status != PJ_SUCCESS)
        {
            [self destroy];

            return status;
        }

        /* Add local account */
        pjsua_acc_add_local(transport_id, PJ_FALSE, &acc_id);
        pjsua_acc_set_online_status(acc_id, PJ_TRUE);
    }

    if (transport_id == -1)
    {
        PJ_LOG(1, (THIS_FILE, "Error: no transport is configured"));
        status = -1;
        
        [self destroy];

        return status;
    }

    return PJ_SUCCESS;
}


- (void)printInfo
{
    int detail = 1;

    pjsua_dump(detail); // Includes same output pj_dump_config() would print.
}


- (pj_status_t)destroy
{
    pj_status_t status;
    unsigned    i;

    /* Close ringback port */
    if (info.ringback_port && info.ringback_slot != PJSUA_INVALID_ID)
    {
        pjsua_conf_remove_port(info.ringback_slot);
        info.ringback_slot = PJSUA_INVALID_ID;
        pjmedia_port_destroy(info.ringback_port);
        info.ringback_port = NULL;
    }

    /* Close ring port */
    if (info.ring_port && info.ring_slot != PJSUA_INVALID_ID)
    {
        pjsua_conf_remove_port(info.ring_slot);
        info.ring_slot = PJSUA_INVALID_ID;
        pjmedia_port_destroy(info.ring_port);
        info.ring_port = NULL;
    }

    /* Close tone generators */
    for (i = 0; i < info.tone_count; ++i)
    {
        pjsua_conf_remove_port(info.tone_slots[i]);
    }

    if (info.pool)
    {
        pj_pool_release(info.pool);
        info.pool = NULL;
    }

    status = pjsua_destroy();

    pj_bzero(&info, sizeof(info));

    return status;
}


- (void)keepAlive
{
    [self registerThread];

    pjsua_acc_id    accountId;

    // We assume there is only one external account.  (There may be a few local accounts too.)
    if (pjsua_acc_is_valid(accountId = pjsua_acc_get_default()))
    {
        if (pjsua_acc_set_registration(accountId, PJ_TRUE) != PJ_SUCCESS)
        {
            //### Sometimes results in:
            //### pjsua_acc.c  !Acc 3: setting registration..
            //###   sip_reg.c  .Unable to send request, regc has another transaction pending
            //### pjsua_acc.c  .Unable to create/send REGISTER: Object is busy (PJSIP_EBUSY) [status=171001]
            NSLog(@"//### Failed to set SIP registration for account %d.", accountId);
        }
    }
}


- (void)registerThread
{    
    if (!pj_thread_is_registered())
    {
        pj_thread_t*    thread;             // We're not interested in this.
        char*           name = malloc(20);

        sprintf(name, "T-%d", pthread_mach_thread_np(pthread_self()));

        pj_thread_register(name, calloc(1, sizeof(pj_thread_desc)), &thread);
    }
}


- (void)restart
{
    [self registerThread];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^
                   {
                       [self destroy];
                       [self destroy];  // On purpose.

                       if ([self initialize] == PJ_SUCCESS)
                       {
                           pj_status_t status;

                           if ((status = pjsua_start()) != PJ_SUCCESS)
                           {
                               NSLog(@"//### pjsua_start() failed: %d.", status);
                               
                               [self destroy];
                           }                           
                       }
                       else
                       {
                           NSLog(@"//### Failed to initialize PJSUA.");
                       }
                   });
}


- (void)createTone:(NSArray*)toneArray name:(char*)name
{
    unsigned            i;
    unsigned            samplesPerFrame;
    pjmedia_tone_desc   tone[RING_CNT+RINGBACK_CNT];
    pj_str_t            nameString;
    pj_status_t         status;

    samplesPerFrame = info.media_cfg.audio_frame_ptime *
                      info.media_cfg.clock_rate *
                      info.media_cfg.channel_count / 1000;

    /* Ringback tone (call is ringing) */
    nameString = pj_str(name);
    status = pjmedia_tonegen_create2(info.pool, &nameString,
                                     info.media_cfg.clock_rate,
                                     info.media_cfg.channel_count,
                                     samplesPerFrame, 16, PJMEDIA_TONEGEN_LOOP, &info.ringback_port);
    if (status != PJ_SUCCESS)
    {
        NSLog(@"//### Failed to create tone.");
        return;
    }

    pj_bzero(&tone, sizeof(tone));
    for (i = 0; i < RINGBACK_CNT; ++i)
    {
        tone[i].freq1    = RINGBACK_FREQ1;
        tone[i].freq2    = RINGBACK_FREQ2;
        tone[i].on_msec  = RINGBACK_ON;
        tone[i].off_msec = RINGBACK_OFF;
    }

    tone[RINGBACK_CNT - 1].off_msec = RINGBACK_INTERVAL;

    pjmedia_tonegen_play(info.ringback_port, RINGBACK_CNT, tone, PJMEDIA_TONEGEN_LOOP);

    status = pjsua_conf_add_port(info.pool, info.ringback_port, &info.ringback_slot);
    if (status != PJ_SUCCESS)
    {
        NSLog(@"//### Failed to create tone.");
        return;
    }
}


- (void)destroyTones
{
    unsigned    i;

    /* Close ringback port */
    if (info.ringback_port && info.ringback_slot != PJSUA_INVALID_ID)
    {
        pjsua_conf_remove_port(info.ringback_slot);
        info.ringback_slot = PJSUA_INVALID_ID;
        pjmedia_port_destroy(info.ringback_port);
        info.ringback_port = NULL;
    }

    /* Close ring port */
    if (info.ring_port && info.ring_slot != PJSUA_INVALID_ID)
    {
        pjsua_conf_remove_port(info.ring_slot);
        info.ring_slot = PJSUA_INVALID_ID;
        pjmedia_port_destroy(info.ring_port);
        info.ring_port = NULL;
    }

    /* Close tone generators */
    for (i = 0; i < info.tone_count; ++i)
    {
        pjsua_conf_remove_port(info.tone_slots[i]);
    }
}


- (pjsua_call_id)callNumber:(NSString*)calledNumber
             identityNumber:(NSString*)identityNumber
                   userData:(void*)userData
                      tones:(NSDictionary*)tones
{
    [self registerThread];

    if (pjsua_call_get_count() == PJSUA_MAX_CALLS)
    {
        NSLog(@"//### Can't make call, maximum calls (%d) reached.", PJSUA_MAX_CALLS);

        return PJSUA_INVALID_ID;
    }
    else if ([calledNumber length] == 0 || [identityNumber length] == 0)
    {
        NSLog(@"//### Missing argument(s).");

        return PJSUA_INVALID_ID;
    }
    else
    {
        __block pjsua_call_id   call_id = PJSUA_INVALID_ID;

        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^
                      {
                          NSString*                 uriString;
                          pj_str_t                  uri;
                          pjsua_call_setting        call_opt;
                          pjsua_msg_data            msg_data;
                          pj_str_t                  header_name;
                          pj_str_t                  header_value;
                          pjsip_generic_string_hdr  header;
                          pj_status_t               status;

                          [self registerThread];

                          uriString = [NSString stringWithFormat:@"sip:%@@%@;transport=tls", calledNumber, self.server];
                          uri = pj_str((char*)[uriString cStringUsingEncoding:NSASCIIStringEncoding]);
                          pjsua_call_setting_default(&call_opt);

                          // Create optional header containing number/identity from which this call is made.
                          pjsua_msg_data_init(&msg_data);
                          header_name = pj_str("Identity");
                          header_value = pj_str((char*)[identityNumber cStringUsingEncoding:NSASCIIStringEncoding]);
                          pjsua_msg_data_init(&msg_data);
                          pjsip_generic_string_hdr_init2(&header, &header_name, &header_value);
                          pj_list_push_back(&msg_data.hdr_list, &header);
                          
                          status = pjsua_call_make_call(pjsua_acc_get_default(), &uri, &call_opt, userData, &msg_data, &call_id);
                          if (status != PJ_SUCCESS)
                          {
                              NSLog(@"//### Failed to make call: %d.", status);
                          }
                      });

        return call_id;
    }
}


- (void)hangupAllCalls
{
    [self registerThread];

    self.microphoneLevel = 0.0f;
    self.speakerLevel = 0.0f;

    pjsua_call_hangup_all();
}


#pragma mark - Property Overrides

- (SipInterfaceRegistered)registered
{
    return _registered;
}


- (void)setMicrophoneLevel:(float)microphoneLevel
{
    [self registerThread];

    _microphoneLevel = microphoneLevel;
    pjsua_conf_adjust_rx_level(0, self.microphoneLevel);
}


- (void)setSpeakerLevel:(float)speakerLevel
{
    [self registerThread];
    
    _speakerLevel = speakerLevel;
    pjsua_conf_adjust_tx_level(0, self.speakerLevel);
}


#pragma mark - Utility Methods

- (void)setAudioVolumes
{
    UInt32      routeSize = sizeof(CFStringRef);
    CFStringRef routeRef;
    OSStatus    status = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &routeSize, &routeRef);
    NSString*   route = (__bridge NSString*)routeRef;

    if (status != 0)
    {
        NSLog(@"//### Failed to get AudioRoute: %@", [Common stringWithOsStatus:status]);
    }

    NSLog(@"//### Audio Route: %@", route);

    if ([route isEqualToString:@"Headset"])
    {
        self.speakerLevel = SPEAKER_LEVEL_NORMAL * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_NORMAL : 1.0f);
    }
    else if ([route isEqualToString:@"Headphone"])
    {
        self.speakerLevel = SPEAKER_LEVEL_NORMAL * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_NORMAL : 1.0f);
    }
    else if ([route isEqualToString:@"Speaker"])
    {
        self.speakerLevel = SPEAKER_LEVEL_NORMAL * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_NORMAL : 1.0f);
    }
    else if ([route isEqualToString:@"SpeakerAndMicrophone"])       // In call: plain iPod Touch & iPad.
    {
        self.speakerLevel = SPEAKER_LEVEL_NORMAL * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_NORMAL : 1.0f);
    }
    else if ([route isEqualToString:@"HeadphonesAndMicrophone"])    // In call: All device with headphones (i.e. without microphone).
    {                                                               // And very briefly after plugging in headset.
        self.speakerLevel = SPEAKER_LEVEL_NORMAL * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_NORMAL : 1.0f);
    }
    else if ([route isEqualToString:@"HeadsetInOut"])               // In call: All devices when using headset (i.e. with microphone).
    {
        self.speakerLevel = SPEAKER_LEVEL_NORMAL * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_NORMAL : 1.0f);
    }
    else if ([route isEqualToString:@"ReceiverAndMicrophone"])      // In call: plain iPhone.
    {
        self.speakerLevel = SPEAKER_LEVEL_RECEIVER * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_RECEIVER : 1.0f);
    }
    else if ([route isEqualToString:@"LineOut"])
    {
        self.speakerLevel = SPEAKER_LEVEL_NORMAL * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_NORMAL : 1.0f);
    }
    else if ([route isEqualToString:@"LineInOut"])
    {
        self.speakerLevel = SPEAKER_LEVEL_NORMAL * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_NORMAL : 1.0f);
    }
    else if ([route isEqualToString:@"HeadsetBT"])
    {
        self.speakerLevel = SPEAKER_LEVEL_NORMAL * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_NORMAL : 1.0f);
    }
    else
    {
        self.speakerLevel = SPEAKER_LEVEL_NORMAL * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_NORMAL : 1.0f);
        NSLog(@"//### Unknown Audio Route: %@", route);
    }
}


- (void)ringback_start:(pjsua_call_id)call_id
{
    if (info.call_data[call_id].ringback_on)
    {
	return;
    }

    info.call_data[call_id].ringback_on = PJ_TRUE;

    if (info.ringback_slot!=PJSUA_INVALID_ID)
    {
	pjsua_conf_connect(info.ringback_slot, 0);
    }
}


- (void)ring_stop:(pjsua_call_id)call_id
{
    if (info.call_data[call_id].ringback_on)
    {
	info.call_data[call_id].ringback_on = PJ_FALSE;

	if (info.ringback_slot != PJSUA_INVALID_ID)
	{
	    pjsua_conf_disconnect(info.ringback_slot, 0);
	    pjmedia_tonegen_rewind(info.ringback_port);
	}
    }

    if (info.call_data[call_id].ring_on)
    {
	info.call_data[call_id].ring_on = PJ_FALSE;

	if (info.ring_slot!=PJSUA_INVALID_ID)
	{
	    pjsua_conf_disconnect(info.ring_slot, 0);
	    pjmedia_tonegen_rewind(info.ring_port);
	}
    }
}


- (void)ring_start:(pjsua_call_id)call_id
{
    if (info.call_data[call_id].ring_on)
    {
	return;
    }

    info.call_data[call_id].ring_on = PJ_TRUE;

    if (info.ring_slot!=PJSUA_INVALID_ID)
    {
	pjsua_conf_connect(info.ring_slot, 0);
    }
}


/*
 * Find next call when current call is disconnected or when user
 * press ']'
 */
- (pj_bool_t)find_next_call
{
    int i;
    int max = pjsua_call_get_max_count();

    for (i = current_call + 1; i < max; ++i)
    {
	if (pjsua_call_is_active(i))
        {
	    current_call = i;

	    return PJ_TRUE;
	}
    }

    for (i = 0; i < current_call; ++i)
    {
	if (pjsua_call_is_active(i))
        {
	    current_call = i;

            return PJ_TRUE;
	}
    }

    current_call = PJSUA_INVALID_ID;

    return PJ_FALSE;
}


/*
 * Find previous call when user press '['
 */
- (pj_bool_t)find_prev_call
{
    int i;
    int max = pjsua_call_get_max_count();

    for (i = current_call - 1; i >= 0; --i)
    {
	if (pjsua_call_is_active(i))
        {
	    current_call = i;

	    return PJ_TRUE;
	}
    }

    for (i = max - 1; i > current_call; --i)
    {
	if (pjsua_call_is_active(i))
        {
	    current_call = i;
	    return PJ_TRUE;
	}
    }

    current_call = PJSUA_INVALID_ID;

    return PJ_FALSE;
}


/* Callback from timer when the maximum call duration has been
 * exceeded.
 */
- (void)callTimeoutCallback:(pj_timer_heap_t*)timer_heap entry:(struct pj_timer_entry*)entry
{
    pjsua_call_id               call_id = entry->id;
    pjsua_msg_data              msg_data;
    pjsip_generic_string_hdr    warn;
    pj_str_t                    hname = pj_str("Warning");
    pj_str_t                    hvalue = pj_str("399 pjsua \"Call duration exceeded\"");

    PJ_UNUSED_ARG(timer_heap);

    if (call_id == PJSUA_INVALID_ID)
    {
	PJ_LOG(1, (THIS_FILE, "Invalid call ID in timer callback"));
	return;
    }

    /* Add warning header */
    pjsua_msg_data_init(&msg_data);
    pjsip_generic_string_hdr_init2(&warn, &hname, &hvalue);
    pj_list_push_back(&msg_data.hdr_list, &warn);

    /* Call duration has been exceeded; disconnect the call */
    PJ_LOG(3,(THIS_FILE, "Duration (%d seconds) has been exceeded for call %d, disconnecting the call",
              info.duration, call_id));
    entry->id = PJSUA_INVALID_ID;

    pjsua_call_hangup(call_id, 200, NULL, &msg_data);
}


/* Handle incoming requests. */
- (pj_bool_t)default_mod_on_rx_request:(pjsip_rx_data*)rdata
{
    pjsip_tx_data*      tdata;
    pjsip_status_code   status_code;
    pj_status_t         status;

    /* Don't respond to ACK! */
    if (pjsip_method_cmp(&rdata->msg_info.msg->line.req.method, &pjsip_ack_method) == 0)
    {
        return PJ_TRUE;
    }

    /* Simple registrar */
    if (pjsip_method_cmp(&rdata->msg_info.msg->line.req.method, &pjsip_register_method) == 0)
    {
        [self simpleRegistrar:rdata];

        return PJ_TRUE;
    }

    /* Create basic response. */
    if (pjsip_method_cmp(&rdata->msg_info.msg->line.req.method, &pjsip_notify_method) == 0)
    {
        /* Unsolicited NOTIFY's, send with Bad Request */
        status_code = PJSIP_SC_BAD_REQUEST;
    }
    else
    {
        /* Probably unknown method */
        status_code = PJSIP_SC_METHOD_NOT_ALLOWED;
    }

    status = pjsip_endpt_create_response(pjsua_get_pjsip_endpt(), rdata, status_code, NULL, &tdata);
    if (status != PJ_SUCCESS)
    {
        pjsua_perror(THIS_FILE, "Unable to create response", status);

        return PJ_TRUE;
    }

    /* Add Allow if we're responding with 405 */
    if (status_code == PJSIP_SC_METHOD_NOT_ALLOWED)
    {
        const pjsip_hdr*    cap_hdr = pjsip_endpt_get_capability(pjsua_get_pjsip_endpt(), PJSIP_H_ALLOW, NULL);

        if (cap_hdr)
        {
            pjsip_msg_add_hdr(tdata->msg, pjsip_hdr_clone(tdata->pool, cap_hdr));
        }
    }

    /* Add User-Agent header */
    {
        pj_str_t        user_agent;
        char            tmp[80];
        const pj_str_t  USER_AGENT = { "User-Agent", 10};
        pjsip_hdr*      h;

        pj_ansi_snprintf(tmp, sizeof(tmp), "PJSUA v%s/%s", pj_get_version(), PJ_OS_NAME);
        pj_strdup2_with_null(tdata->pool, &user_agent, tmp);

        h = (pjsip_hdr*) pjsip_generic_string_hdr_create(tdata->pool, &USER_AGENT, &user_agent);
        pjsip_msg_add_hdr(tdata->msg, h);
    }

    pjsip_endpt_send_response2(pjsua_get_pjsip_endpt(), rdata, tdata, NULL, NULL);
    
    return PJ_TRUE;
}


/*
 * A simple registrar, invoked by default_mod_on_rx_request()
 */
- (void)simpleRegistrar:(pjsip_rx_data*)rdata
{
    pjsip_tx_data*              tdata;
    const pjsip_expires_hdr*    exp;
    const pjsip_hdr*            h;
    unsigned                    cnt = 0;
    pjsip_generic_string_hdr*   srv;
    pj_status_t                 status;

    ;
    if ((status = pjsip_endpt_create_response(pjsua_get_pjsip_endpt(), rdata, 200, NULL, &tdata)) != PJ_SUCCESS)
    {
        return;
    }

    exp = pjsip_msg_find_hdr(rdata->msg_info.msg, PJSIP_H_EXPIRES, NULL);

    h = rdata->msg_info.msg->hdr.next;
    while (h != &rdata->msg_info.msg->hdr)
    {
        if (h->type == PJSIP_H_CONTACT)
        {
            const pjsip_contact_hdr*    c = (const pjsip_contact_hdr*)h;
            int                         e = c->expires;

            if (e < 0)
            {
                if (exp)
                {
                    e = exp->ivalue;
                }
                else
                {
                    e = 3600;
                }
            }

            if (e > 0)
            {
                pjsip_contact_hdr*  nc = pjsip_hdr_clone(tdata->pool, h);

                nc->expires = e;
                pjsip_msg_add_hdr(tdata->msg, (pjsip_hdr*)nc);
                ++cnt;
            }
        }

        h = h->next;
    }

    srv = pjsip_generic_string_hdr_create(tdata->pool, NULL, NULL);
    srv->name = pj_str("Server");
    srv->hvalue = pj_str("pjsua simple registrar");
    pjsip_msg_add_hdr(tdata->msg, (pjsip_hdr*)srv);

    pjsip_endpt_send_response2(pjsua_get_pjsip_endpt(), rdata, tdata, NULL, NULL);
}


#pragma mark - Callbacks

- (void)onCallState:(pjsua_call_id)call_id event:(pjsip_event*)e
{
    pjsua_call_info call_info;

    PJ_UNUSED_ARG(e);

    pjsua_call_get_info(call_id, &call_info);

    if (call_info.state == PJSIP_INV_STATE_DISCONNECTED)
    {
	/* Stop all ringback for this call */
	[self ring_stop:call_id];

	/* Cancel duration timer, if any */
	if (info.call_data[call_id].timer.id != PJSUA_INVALID_ID)
        {
	    struct call_data *cd = &info.call_data[call_id];
	    pjsip_endpoint *endpt = pjsua_get_pjsip_endpt();

	    cd->timer.id = PJSUA_INVALID_ID;
	    pjsip_endpt_cancel_timer(endpt, &cd->timer);
	}

	PJ_LOG(3, (THIS_FILE, "Call %d is DISCONNECTED [reason=%d (%s)]",
                   call_id, call_info.last_status, call_info.last_status_text.ptr));

	if (call_id == current_call)
        {
	    [self find_next_call];
	}

        /* Reset current call */
        if (current_call == call_id)
        {
            current_call = PJSUA_INVALID_ID;
        }
    }
    else
    {
	if (info.duration != NO_LIMIT && call_info.state == PJSIP_INV_STATE_CONFIRMED)
	{
	    /* Schedule timer to hangup call after the specified duration */
	    struct call_data*   cd = &info.call_data[call_id];
	    pjsip_endpoint*     endpt = pjsua_get_pjsip_endpt();
	    pj_time_val         delay;

	    cd->timer.id = call_id;
	    delay.sec    = info.duration;
	    delay.msec   = 0;
	    pjsip_endpt_schedule_timer(endpt, &cd->timer, &delay);
	}

	if (call_info.state == PJSIP_INV_STATE_EARLY)
        {
	    int         code;
	    pj_str_t    reason;
	    pjsip_msg*  msg;

	    /* This can only occur because of TX or RX message */
	    pj_assert(e->type == PJSIP_EVENT_TSX_STATE);

	    if (e->body.tsx_state.type == PJSIP_EVENT_RX_MSG)
            {
		msg = e->body.tsx_state.src.rdata->msg_info.msg;
	    }
            else
            {
		msg = e->body.tsx_state.src.tdata->msg;
	    }

	    code   = msg->line.status.code;
	    reason = msg->line.status.reason;

	    /* Start ringback for 180 for UAC unless there's SDP in 180 */
	    if (call_info.role==PJSIP_ROLE_UAC && code==180 &&
		msg->body == NULL &&
		call_info.media_status==PJSUA_CALL_MEDIA_NONE)
	    {
		[self ringback_start:call_id];
	    }

	    PJ_LOG(3, (THIS_FILE, "Call %d state changed to %s (%d %.*s)",
                       call_id, call_info.state_text.ptr, code, (int)reason.slen, reason.ptr));
	}
        else
        {
	    PJ_LOG(3,(THIS_FILE, "Call %d state changed to %s", call_id, call_info.state_text.ptr));
	}

	if (call_info.state != PJSIP_INV_STATE_NULL && current_call == PJSUA_INVALID_ID)
        {
	    current_call = call_id;
        }
    }
}


- (void)onIncomingCall:(pjsua_acc_id)acc_id callId:(pjsua_call_id)call_id data:(pjsip_rx_data*)rdata
{
    pjsua_call_info call_info;

    PJ_UNUSED_ARG(acc_id);
    PJ_UNUSED_ARG(rdata);

    pjsua_call_get_info(call_id, &call_info);

    if (current_call == PJSUA_INVALID_ID)
    {
	current_call = call_id;
    }

    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
    {
        /* Start ringback */
        [self ring_start:call_id];

        if (info.auto_answer > 0)
        {
            pjsua_call_setting call_opt;

            pjsua_call_setting_default(&call_opt);
            pjsua_call_answer2(call_id, &call_opt, info.auto_answer, NULL, NULL);
        }

        if (info.auto_answer < 200)
        {
            char notif_st[80] = {0};

            PJ_LOG(3, (THIS_FILE, "Incoming call for account %d!\nMedia count: %d audio\n%sFrom: %s\n"
                       "To: %s\nPress a to answer or h to reject call",
                       acc_id, call_info.rem_aud_cnt, notif_st, call_info.remote_info.ptr,
                       call_info.local_info.ptr));
        }
    }
    else
    {
        UILocalNotification*    alert = [[UILocalNotification alloc] init];

        alert.repeatInterval = 0;
        alert.alertBody      = @"Incoming call received...";
        alert.alertAction    = @"Answer";

        [[UIApplication sharedApplication] presentLocalNotificationNow:alert];
    }
}


/*
 * Handler when a transaction within a call has changed state.
 */
- (void)onCallTransactionState:(pjsua_call_id)call_id transaction:(pjsip_transaction*)tsx event:(pjsip_event*)e
{
    const pjsip_method info_method =
    {
	PJSIP_OTHER_METHOD,
	{
            "INFO",
            4
        }
    };

    if (pjsip_method_cmp(&tsx->method, &info_method) == 0)
    {
	/*
	 * Handle INFO method.
	 */
	const pj_str_t STR_APPLICATION = { "application", 11};
	const pj_str_t STR_DTMF_RELAY  = { "dtmf-relay", 10 };
	pjsip_msg_body* body = NULL;
	pj_bool_t       dtmf_info = PJ_FALSE;

	if (tsx->role == PJSIP_ROLE_UAC)
        {
	    if (e->body.tsx_state.type == PJSIP_EVENT_TX_MSG)
            {
		body = e->body.tsx_state.src.tdata->msg->body;
            }
	    else
            {
		body = e->body.tsx_state.tsx->last_tx->msg->body;
            }
	}
        else
        {
	    if (e->body.tsx_state.type == PJSIP_EVENT_RX_MSG)
            {
		body = e->body.tsx_state.src.rdata->msg_info.msg->body;
            }
	}

	/* Check DTMF content in the INFO message */
	if (body && body->len &&
	    pj_stricmp(&body->content_type.type, &STR_APPLICATION) == 0 &&
	    pj_stricmp(&body->content_type.subtype, &STR_DTMF_RELAY) == 0)
	{
	    dtmf_info = PJ_TRUE;
	}

	if (dtmf_info && tsx->role == PJSIP_ROLE_UAC &&
	    (tsx->state == PJSIP_TSX_STATE_COMPLETED ||
             (tsx->state == PJSIP_TSX_STATE_TERMINATED &&
              e->body.tsx_state.prev_state != PJSIP_TSX_STATE_COMPLETED)))
	{
	    /* Status of outgoing INFO request */
	    if (tsx->status_code >= 200 && tsx->status_code < 300)
            {
		PJ_LOG(4, (THIS_FILE, "Call %d: DTMF sent successfully with INFO", call_id));
	    }
            else if (tsx->status_code >= 300)
            {
		PJ_LOG(4, (THIS_FILE, "Call %d: Failed to send DTMF with INFO: %d/%.*s",
                           call_id, tsx->status_code, (int)tsx->status_text.slen, tsx->status_text.ptr));
	    }
	}
        else if (dtmf_info && tsx->role == PJSIP_ROLE_UAS && tsx->state == PJSIP_TSX_STATE_TRYING)
	{
	    /* Answer incoming INFO with 200/OK */
	    pjsip_rx_data*  rdata;
	    pjsip_tx_data*  tdata;
	    pj_status_t     status;

	    rdata = e->body.tsx_state.src.rdata;

	    if (rdata->msg_info.msg->body)
            {
		status = pjsip_endpt_create_response(tsx->endpt, rdata, 200, NULL, &tdata);
		if (status == PJ_SUCCESS)
                {
		    status = pjsip_tsx_send_msg(tsx, tdata);
                }

		PJ_LOG(3, (THIS_FILE, "Call %d: incoming INFO:\n%.*s",
                           call_id, (int)rdata->msg_info.msg->body->len, rdata->msg_info.msg->body->data));
	    }
            else
            {
		status = pjsip_endpt_create_response(tsx->endpt, rdata, 400, NULL, &tdata);
		if (status == PJ_SUCCESS)
                {
		    status = pjsip_tsx_send_msg(tsx, tdata);
                }
	    }
	}
    }
}


/* General processing for media state. "mi" is the media index */
- (void)onCallGenericMediaState:(pjsua_call_info*)ci state:(unsigned)mi hasError:(pj_bool_t*)has_error
{
    const char *status_name[] =
    {
        "None",
        "Active",
        "Local hold",
        "Remote hold",
        "Error"
    };

    PJ_UNUSED_ARG(has_error);

    pj_assert(ci->media[mi].status <= PJ_ARRAY_SIZE(status_name));
    pj_assert(PJSUA_CALL_MEDIA_ERROR == 4);

    PJ_LOG(4, (THIS_FILE, "Call %d media %d [type=%s], status is %s",
	       ci->id, mi, pjmedia_type_name(ci->media[mi].type), status_name[ci->media[mi].status]));
}


/* Process audio media state. "mi" is the media index. */
- (void)onCallAudioState:(pjsua_call_info*)ci state:(unsigned)mi hasError:(pj_bool_t*)has_error
{
    PJ_UNUSED_ARG(has_error);

    /* Stop ringback */
    [self ring_stop:ci->id];

    /* Connect ports appropriately when media status is ACTIVE or REMOTE HOLD,
     * otherwise we should NOT connect the ports.
     */
    if (ci->media[mi].status == PJSUA_CALL_MEDIA_ACTIVE || ci->media[mi].status == PJSUA_CALL_MEDIA_REMOTE_HOLD)
    {
	pjsua_conf_port_id call_conf_slot;

	call_conf_slot = ci->media[mi].stream.aud.conf_slot;

        pjsua_conf_connect(call_conf_slot, 0);
        pjsua_conf_connect(0, call_conf_slot);

        [self setAudioVolumes];
    }
}


/*
 * Callback on media state changed event.
 * The action may connect the call to sound device, to file, or
 * to loop the call.
 */
- (void)onCallMediaState:(pjsua_call_id)call_id
{
    pjsua_call_info call_info;
    unsigned        mi;
    pj_bool_t       has_error = PJ_FALSE;

    pjsua_call_get_info(call_id, &call_info);

    for (mi = 0; mi < call_info.media_cnt; ++mi)
    {
	on_call_generic_media_state(&call_info, mi, &has_error);

	switch (call_info.media[mi].type)
        {
            case PJMEDIA_TYPE_AUDIO:
                on_call_audio_state(&call_info, mi, &has_error);
                break;

            default:
                /* Make gcc happy about enum not handled by switch/case */
                break;
	}
    }

    if (has_error)
    {
	pj_str_t reason = pj_str("Media failed");
	pjsua_call_hangup(call_id, 500, &reason, NULL);
    }
}


/*
 * DTMF callback.
 */
- (void)callOnDtmfCallback:(pjsua_call_id)call_id dtmf:(int)dtmf
{
    PJ_LOG(3,(THIS_FILE, "Incoming DTMF on call %d: %c", call_id, dtmf));
}


/*
 * Redirection handler.
 */
- (pjsip_redirect_op)callOnRedirected:(pjsua_call_id)call_id target:(const pjsip_uri*)target event:(const pjsip_event*)e
{
    PJ_UNUSED_ARG(e);

    if (info.redir_op == PJSIP_REDIRECT_PENDING)
    {
	char    uristr[PJSIP_MAX_URL_SIZE];
	int     len;

	len = pjsip_uri_print(PJSIP_URI_IN_FROMTO_HDR, target, uristr, sizeof(uristr));
	if (len < 1)
        {
	    pj_ansi_strcpy(uristr, "--URI too long--");
	}

	PJ_LOG(3, (THIS_FILE, "Call %d is being redirected to %.*s. Press 'Ra' to accept, 'Rr' to reject, or 'Rd' to "
                   "disconnect.",
                   call_id, len, uristr));
    }

    return info.redir_op;
}


/*
 * Handler registration status has changed.
 */
- (void)onRegistrationState:(pjsua_acc_id)acc_id info:(pjsua_reg_info*)info
{
    if (info == NULL || info->cbparam == NULL)
    {
        _registered = SipInterfaceRegisteredFailed;
    }
    else
    {
        struct pjsip_regc_cbparam*  cbparam = info->cbparam;

        if (acc_id != pjsua_acc_get_default())
        {
            _registered = SipInterfaceRegisteredFailed;
        }
        else if (cbparam->code / 100 == 2 && cbparam->expiration > 0 && cbparam->contact_cnt > 0)
        {
            _registered = SipInterfaceRegisteredYes;
        }
        else
        {
            _registered = SipInterfaceRegisteredFailed;
        }
    }

    // Log already written.
}


/**
 * Call transfer request status.
 */
- (void)onCallTransferStatus:(pjsua_call_id)call_id
                        code:(int)status_code
                        text:(const pj_str_t*)status_text
                       final:(pj_bool_t)final
                    continue:(pj_bool_t*)p_cont
{
    PJ_LOG(3,(THIS_FILE, "Call %d: transfer status=%d (%.*s) %s",
	      call_id, status_code, (int)status_text->slen, status_text->ptr, (final ? "[final]" : "")));

    if (status_code/100 == 2)
    {
	PJ_LOG(3, (THIS_FILE, "Call %d: call transfered successfully, disconnecting call", call_id));

	pjsua_call_hangup(call_id, PJSIP_SC_GONE, NULL, NULL);
	*p_cont = PJ_FALSE;
    }
}


/*
 * Notification that call is being replaced.
 */
- (void)onCallReplaced:(pjsua_call_id)old_call_id newCallId:(pjsua_call_id)new_call_id
{
    pjsua_call_info old_ci;
    pjsua_call_info new_ci;

    pjsua_call_get_info(old_call_id, &old_ci);
    pjsua_call_get_info(new_call_id, &new_ci);

    PJ_LOG(3,(THIS_FILE, "Call %d with %.*s is being replaced by call %d with %.*s",
              old_call_id, (int)old_ci.remote_info.slen, old_ci.remote_info.ptr,
              new_call_id, (int)new_ci.remote_info.slen, new_ci.remote_info.ptr));
}


/*
 * NAT type detection callback.
 */
- (void)onNatDetect:(const pj_stun_nat_detect_result*)res
{
    if (res->status != PJ_SUCCESS)
    {
	pjsua_perror(THIS_FILE, "NAT detection failed", res->status);
    }
    else
    {
	PJ_LOG(3, (THIS_FILE, "NAT detected as %s", res->nat_type_name));
    }
}


/*
 * MWI indication
 */
- (void)onMwiInfo:(pjsua_acc_id)acc_id info:(pjsua_mwi_info*)mwi_info
{
    pj_str_t    body;

    PJ_LOG(3,(THIS_FILE, "Received MWI for acc %d:", acc_id));

    if (mwi_info->rdata->msg_info.ctype)
    {
	const pjsip_ctype_hdr *ctype = mwi_info->rdata->msg_info.ctype;

	PJ_LOG(3, (THIS_FILE, " Content-Type: %.*s/%.*s",
                   (int)ctype->media.type.slen, ctype->media.type.ptr,
                   (int)ctype->media.subtype.slen, ctype->media.subtype.ptr));
    }

    if (!mwi_info->rdata->msg_info.msg->body)
    {
	PJ_LOG(3,(THIS_FILE, "  no message body"));
	return;
    }

    body.ptr  = mwi_info->rdata->msg_info.msg->body->data;
    body.slen = mwi_info->rdata->msg_info.msg->body->len;

    PJ_LOG(3,(THIS_FILE, " Body:\n%.*s", (int)body.slen, body.ptr));
}


/*
 * Transport status notification
 */
- (void)onTransportState:(pjsip_transport*)tp
                   state:(pjsip_transport_state)state
                    info:(const pjsip_transport_state_info*)stateInfo
{
    char    host_port[128];
    char    buf[2048];      // Large enough to be used in both cases.


    pj_ansi_snprintf(host_port, sizeof(host_port), "[%.*s:%d]",
		     (int)tp->remote_name.host.slen, tp->remote_name.host.ptr, tp->remote_name.port);

    switch (state)
    {
        case PJSIP_TP_STATE_CONNECTED:
            PJ_LOG(3, (THIS_FILE, "SIP %s transport is connected to %s", tp->type_name, host_port));
            break;

        case PJSIP_TP_STATE_DISCONNECTED:
            snprintf(buf, sizeof(buf), "SIP %s transport is disconnected from %s", tp->type_name, host_port);
            pjsua_perror(THIS_FILE, buf, stateInfo->status);
            break;

        default:
            break;
    }

#if !defined(PJSIP_HAS_TLS_TRANSPORT) || PJSIP_HAS_TLS_TRANSPORT == 0
#error TLS is required.
#endif
    if (!pj_ansi_stricmp(tp->type_name, "tls") && stateInfo->ext_info &&
        (state == PJSIP_TP_STATE_CONNECTED ||
	 ((pjsip_tls_state_info*)stateInfo->ext_info)->ssl_sock_info->verify_status != PJ_SUCCESS))
    {
	const char* verif_msgs[32];
	unsigned    verif_msg_cnt;

	pjsip_tls_state_info *tls_info  = (pjsip_tls_state_info*)stateInfo->ext_info;
	pj_ssl_sock_info *ssl_sock_info = tls_info->ssl_sock_info;

	/* Dump server TLS cipher */
	PJ_LOG(4, (THIS_FILE, "TLS cipher: 0x%06X/%s", ssl_sock_info->cipher, pj_ssl_cipher_name(ssl_sock_info->cipher)));

	/* Dump server TLS certificate */
	pj_ssl_cert_info_dump(ssl_sock_info->remote_cert_info, "  ", buf, sizeof(buf));
	PJ_LOG(4, (THIS_FILE, "TLS cert info of %s:\n%s", host_port, buf));

	/* Dump server TLS certificate verification result */
	verif_msg_cnt = PJ_ARRAY_SIZE(verif_msgs);
	pj_ssl_cert_get_verify_status_strings(ssl_sock_info->verify_status, verif_msgs, &verif_msg_cnt);
	PJ_LOG(3, (THIS_FILE, "TLS cert verification result of %s : %s",
                   host_port, (verif_msg_cnt == 1 ? verif_msgs[0] : "")));

	if (verif_msg_cnt > 1)
        {
	    for (unsigned i = 0; i < verif_msg_cnt; ++i)
            {
		PJ_LOG(3,(THIS_FILE, "- %s", verif_msgs[i]));
            }
	}
        
	if (ssl_sock_info->verify_status && !info.udp_cfg.tls_setting.verify_server)
	{
	    PJ_LOG(3, (THIS_FILE, "PJSUA is configured to ignore TLS cert verification errors"));
	}
    }
}


- (void)onIceTransportError:(int)index
                     operation:(pj_ice_strans_op)op
                        status:(pj_status_t)status
                     parameter:(void*)param
{
    PJ_UNUSED_ARG(op);
    PJ_UNUSED_ARG(param);
    PJ_PERROR(1, (THIS_FILE, status, "ICE keep alive failure for transport %d", index));
}


- (pj_status_t)onSoundDeviceOperation:(int)operation
{
    PJ_LOG(3,(THIS_FILE, "Turning sound device %s", (operation? "ON":"OFF")));
    
    return PJ_SUCCESS;
}


@end


#pragma mark - From C to SipInterface Methods.

static void call_timeout_callback(pj_timer_heap_t* timer_heap, struct pj_timer_entry* entry)
{
    [sipInterface callTimeoutCallback:timer_heap entry:entry];
}


static pj_bool_t default_mod_on_rx_request(pjsip_rx_data* rdata)
{
    return [sipInterface default_mod_on_rx_request:rdata];
}


static void on_call_state(pjsua_call_id call_id, pjsip_event *e)
{
    [sipInterface onCallState:call_id event:e];
}


static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id  call_id, pjsip_rx_data* rdata)
{
    [sipInterface onIncomingCall:acc_id callId:call_id data:rdata];
}


static void on_call_tsx_state(pjsua_call_id call_id, pjsip_transaction* tsx, pjsip_event* e)
{
    [sipInterface onCallTransactionState:call_id transaction:tsx event:e];
}


static void on_call_generic_media_state(pjsua_call_info* ci, unsigned mi, pj_bool_t* has_error)
{
    [sipInterface onCallGenericMediaState:ci state:mi hasError:has_error];
}


static void on_call_audio_state(pjsua_call_info* ci, unsigned mi, pj_bool_t* has_error)
{
    [sipInterface onCallAudioState:ci state:mi hasError:has_error];
}


static void on_call_media_state(pjsua_call_id call_id)
{
    [sipInterface onCallMediaState:call_id];
}


static void call_on_dtmf_callback(pjsua_call_id call_id, int dtmf)
{
    [sipInterface callOnDtmfCallback:call_id dtmf:dtmf];
}


static pjsip_redirect_op call_on_redirected(pjsua_call_id call_id, const pjsip_uri* target, const pjsip_event* e)
{
    return [sipInterface callOnRedirected:call_id target:target event:e];
}


static void on_reg_state(pjsua_acc_id acc_id,  pjsua_reg_info *info)
{
    [sipInterface onRegistrationState:acc_id info:info];
}


static void on_call_transfer_status(pjsua_call_id call_id, int status_code, const pj_str_t* status_text, pj_bool_t final, pj_bool_t* p_cont)
{
    [sipInterface onCallTransferStatus:call_id code:status_code text:status_text final:final continue:p_cont];
}


static void on_call_replaced(pjsua_call_id old_call_id, pjsua_call_id new_call_id)
{
    [sipInterface onCallReplaced:old_call_id newCallId:new_call_id];
}


static void on_nat_detect(const pj_stun_nat_detect_result* res)
{
    [sipInterface onNatDetect:res];
}


static void on_mwi_info(pjsua_acc_id acc_id, pjsua_mwi_info* mwi_info)
{
    [sipInterface onMwiInfo:acc_id info:mwi_info];
}


static void on_transport_state(pjsip_transport* tp, pjsip_transport_state state, const pjsip_transport_state_info* stateInfo)
{
    [sipInterface onTransportState:tp state:state info:stateInfo];
}


static void on_ice_transport_error(int index, pj_ice_strans_op op, pj_status_t status, void* param)
{
    [sipInterface onIceTransportError:index operation:op status:status parameter:param];
}


static pj_status_t on_snd_dev_operation(int operation)
{
    return [sipInterface onSoundDeviceOperation:operation];
}


void audioRouteChangeListener(void* userData, AudioSessionPropertyID propertyID, UInt32 propertyValueSize, const void* propertyValue)
{
    if (propertyID == kAudioSessionProperty_AudioRouteChange)
    {
        [sipInterface setAudioVolumes];
    }
}



