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
#import "NetworkStatus.h"
#import "webrtc.h"      // Glue-logic with libWebRTC.a.
#import "Call.h"


#define THIS_FILE	"SipInterface"
#define KEEP_ALIVE_INTERVAL             600     // The shortest that iOS allows.
#define FORCE_HANGUP_TIMEOUT            4.0f    // Seconds after which PJSIP is restarted if no disconnect received.

// Volume Levels.  Note that these are linear values, so 2.0 is only a bit louder.
#define SPEAKER_LEVEL_NORMAL            1.0f
#define SPEAKER_LEVEL_RECEIVER          2.0f
#define SPEAKER_LOUDER_FACTOR_NORMAL    1.5f
#define SPEAKER_LOUDER_FACTOR_RECEIVER  2.0f
#define MICROPHONE_LEVEL_NORMAL         1.0f

// Ringtones                            US          UK
#define RINGBACK_FREQ1                  440     /* 400 */
#define RINGBACK_FREQ2                  480     /* 450 */
#define RINGBACK_ON                     2000    /* 400 */
#define RINGBACK_OFF                    4000    /* 200 */
#define RINGBACK_CNT                    1       /* 2   */
#define RINGBACK_INTERVAL               4000    /* 2000 */

#define RING_FREQ1                      800
#define RING_FREQ2                      640
#define RING_ON                         200
#define RING_OFF                        100
#define RING_CNT                        3
#define RING_INTERVAL                   3000

#define CUSTOM_SC_NOT_ALLOWED_COUNTRY   451
#define CUSTOM_SC_NOT_ALLOWED_NUMBER    452
#define CUSTOM_SC_NO_CREDIT             453
#define CUSTOM_SC_CALLEE_NOT_ONLINE     454
#define CUSTOM_SC_PSTN_TERMINATION_FAIL 514
#define CUSTOM_SC_CALL_ROUTING_ERROR    515

@interface SipInterface ()
{
    NSMutableArray*         calls;          // The array and its call may only be accessed on main thread! 
    Call*                   currentCall;

    pjsua_config            config;
    pjsua_logging_config    log_cfg;
    pjsua_media_config	    media_cfg;
    pjsua_acc_config	    account_config;
    pjsua_transport_config  udp_cfg;
    pjsua_transport_config  rtp_cfg;

    pjsip_redirect_op	    redir_op;

    pj_bool_t               speaker_on;      // Speaker button on UI.

    pj_pool_t*              pool;

    unsigned                tone_count;
    pjmedia_tone_desc	    tones[32];
    pjsua_conf_port_id	    tone_slots[32];
    unsigned                auto_answer;
    unsigned                duration;

    int                     ringback_slot;
    pjmedia_port*           ringback_port;
    int                     busy_slot;
    pjmedia_port*           busy_port;
    int                     congestion_slot;
    pjmedia_port*           congestion_port;
    int                     ring_slot;
    pjmedia_port*           ring_port;

    BOOL                    isRestarting;
}

@end


static void call_timeout_callback(pj_timer_heap_t* timer_heap, struct pj_timer_entry* entry);
static pj_bool_t default_mod_on_rx_request(pjsip_rx_data* rdata);

static void on_call_state(pjsua_call_id call_id, pjsip_event *e);
static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id  call_id, pjsip_rx_data* rdata);
static void on_call_tsx_state(pjsua_call_id call_id, pjsip_transaction* tsx, pjsip_event* e);
static void on_call_generic_media_state(pjsua_call_info* ci, unsigned mi, pj_bool_t* has_error);
static void on_call_audio_state(pjsua_call_info* ci, unsigned mi, pj_bool_t* has_error);
static void on_call_media_state(pjsua_call_id call_id);
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

static SipInterface*    sipInterface;
static NSTimer*         hangupTimer;


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


@implementation SipInterface

@synthesize registered = _registered;


#pragma mark - Initialization

- (id)initWithRealm:(NSString*)realm server:(NSString*)server username:(NSString*)username password:(NSString*)password;
{
    if (self = [super init])
    {
        _realm      = realm;
        _server     = server;
        _username   = username;
        _password   = password;
        _registered = SipInterfaceRegisteredNo;

        pj_log_set_log_func(&showLog);

        calls = [NSMutableArray array];

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

        [[NSNotificationCenter defaultCenter] addObserverForName:NetworkStatusMobileCallStateChangedNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note)
        {
            NetworkStatusMobileCall status = [note.userInfo[@"status"] intValue];
            if (status == NetworkStatusMobileCallIncoming)
            {
                // Set all calls on hold.
                for (Call* call in calls)
                {
                    [self setCall:call onHold:YES];
                }
            }
        }];
    }

    sipInterface = self;

    return self;
}


- (pj_status_t)initialize
{
    pj_status_t             status;

    if ((status = pjsua_create()) != PJ_SUCCESS)
    {
        return status;
    }

    pool = pjsua_pool_create("pjsua-app", 1000, 1000);

    [self initializeConfigs];
    [self initializeCallbacks];

    if ((status = pjsua_init(&config, &log_cfg, &media_cfg)) != PJ_SUCCESS)
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

    if ((status = [self initializeTones]) != PJ_SUCCESS)
    {
        return status;
    }

    if ((status = [self initializeTransports]) != PJ_SUCCESS)
    {
        return status;
    }

    /* Add account */
    account_config.rtp_cfg                  = rtp_cfg;
    account_config.reg_retry_interval       = 300;
    account_config.reg_first_retry_interval = 60;
    account_config.reg_timeout              = KEEP_ALIVE_INTERVAL;

    if ((status = pjsua_acc_add(&account_config, PJ_TRUE, NULL)) != PJ_SUCCESS)
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

    pjsua_config_default(&config);
    pj_ansi_sprintf(tmp, "PJSUA v%s %s", pj_get_version(), pj_get_sys_info()->info.ptr);
    pj_strdup2_with_null(pool, &config.user_agent, tmp);

    pjsua_logging_config_default(&log_cfg);
    pjsua_media_config_default(&media_cfg);
    pjsua_acc_config_default(&account_config);

    redir_op        = PJSIP_REDIRECT_ACCEPT;
    ringback_slot   = PJSUA_INVALID_ID;
    busy_slot       = PJSUA_INVALID_ID;
    congestion_slot = PJSUA_INVALID_ID;
    ring_slot       = PJSUA_INVALID_ID;

#if !defined(PJMEDIA_HAS_SRTP) || PJMEDIA_HAS_SRTP == 0
#error SRTP is required.
#endif
    config.use_srtp = PJMEDIA_SRTP_MANDATORY;

    // Make that PJSIP uses it's own DNS resolver; to avoid blocking of iOS gethostbyname()
    // implementation.
    //
    // Use Google's name servers: https://developers.google.com/speed/public-dns/docs/using
    //
    // Defining name servers, enables SIP SRV which includes failover functionality.
    // But SIP SRV is only enabled if there is no proxy set in account_config!
    pj_cstr(&(config.nameserver[0]), "8.8.8.8");
    pj_cstr(&(config.nameserver[1]), "8.8.4.4");
    config.nameserver_count = 2;

    media_cfg.no_vad = PJ_TRUE;

    account_config.reg_uri = pj_str((char*)[[NSString stringWithFormat:@"sip:%@;transport=tls", self.server] UTF8String]);
    account_config.id = pj_str((char*)[[NSString stringWithFormat:@"sip:%@@%@;transport=tls", self.username, self.server] UTF8String]);
    account_config.cred_info[0].username = pj_str((char*)[self.username UTF8String]);
    account_config.cred_info[0].scheme   = pj_str("Digest");
    account_config.cred_info[0].realm = pj_str((char*)[self.realm UTF8String]);
    account_config.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
    account_config.cred_info[0].data = pj_str((char*)[self.password UTF8String]);
    account_config.cred_count++;
    account_config.use_srtp = config.use_srtp;
}


- (void)initializeCallbacks
{
    /* Initialize application callbacks */
    config.cb.on_call_state           = &on_call_state;
    config.cb.on_call_media_state     = &on_call_media_state;
    config.cb.on_incoming_call        = &on_incoming_call;
    config.cb.on_call_tsx_state       = &on_call_tsx_state;
    config.cb.on_call_redirected      = &call_on_redirected;
    config.cb.on_reg_state2           = &on_reg_state;
    config.cb.on_call_transfer_status = &on_call_transfer_status;
    config.cb.on_call_replaced        = &on_call_replaced;
    config.cb.on_nat_detect           = &on_nat_detect;
    config.cb.on_mwi_info             = &on_mwi_info;
    config.cb.on_transport_state      = &on_transport_state;
    config.cb.on_ice_transport_error  = &on_ice_transport_error;
    config.cb.on_snd_dev_operation    = &on_snd_dev_operation;
    log_cfg.cb                        = &showLog;
}


- (pj_status_t)initializeTones
{
    pj_status_t         status;
    unsigned            i;
    unsigned            samples_per_frame;
    pjmedia_tone_desc   tone[RING_CNT+RINGBACK_CNT];
    pj_str_t            name;

    samples_per_frame = media_cfg.audio_frame_ptime *
    media_cfg.clock_rate *
    media_cfg.channel_count / 1000;

    /* Ringback tone (call is ringing) */
    name = pj_str("ringback");
    status = pjmedia_tonegen_create2(pool, &name,
                                     media_cfg.clock_rate,
                                     media_cfg.channel_count,
                                     samples_per_frame, 16, PJMEDIA_TONEGEN_LOOP, &ringback_port);
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

    pjmedia_tonegen_play(ringback_port, RINGBACK_CNT, tone, PJMEDIA_TONEGEN_LOOP);

    status = pjsua_conf_add_port(pool, ringback_port, &ringback_slot);
    if (status != PJ_SUCCESS)
    {
        [self destroy];

        return status;
    }

    /* Ring (to alert incoming call) */
    name = pj_str("ring");
    status = pjmedia_tonegen_create2(pool, &name,
                                     media_cfg.clock_rate,
                                     media_cfg.channel_count,
                                     samples_per_frame, 16, PJMEDIA_TONEGEN_LOOP, &ring_port);
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

    pjmedia_tonegen_play(ring_port, RING_CNT, tone, PJMEDIA_TONEGEN_LOOP);

    status = pjsua_conf_add_port(pool, ring_port, &ring_slot);
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

    pjsua_transport_config_default(&udp_cfg);
    pjsua_transport_config_default(&rtp_cfg);
    udp_cfg.port    = 5060;
    rtp_cfg.port    = 4000;
    pj_memcpy(&tcp_cfg, &udp_cfg, sizeof(tcp_cfg));

    /* Add UDP transport */
    {
        pjsua_acc_id            aid;
        pjsip_transport_type_e  type = PJSIP_TRANSPORT_UDP;

        if ((status = pjsua_transport_create(type, &udp_cfg, &transport_id)) != PJ_SUCCESS)
        {
            [self destroy];

            return status;
        }

        /* Add local account */
        pjsua_acc_add_local(transport_id, PJ_TRUE, &aid);

        //pjsua_acc_set_transport(aid, transport_id);
        pjsua_acc_set_online_status(pjsua_acc_get_default(), PJ_TRUE);

        if (udp_cfg.port == 0)
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

    //### Is this needed (perhaps old stuff of ipjsua)?
    if (transport_id == -1)
    {
        PJ_LOG(1, (THIS_FILE, "Error: no transport is configured"));
        status = -1;
        
        [self destroy];

        return status;
    }

    return PJ_SUCCESS;
}


- (void)restart
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^
    {
        [self registerThread];

        [self destroy];
        [self destroy];  // On purpose (copied from PJSUA).

        if ([self initialize] == PJ_SUCCESS)
        {
            pj_status_t status;

            if ((status = pjsua_start()) != PJ_SUCCESS)
            {
                NSLog(@"//### pjsua_start() failed: %d.", status);

#warning Add another restart here after some time, we can't just give up forever!!!
                [self destroy];
            }
            else
            {
                isRestarting = NO;
            }
        }
        else
        {
#warning Add another restart here after some time, we can't just give up forever!!!
            NSLog(@"//### Failed to initialize PJSUA.");
        }
    });
}


#warning The methdod is called in many places, but it basically kills the app/PJSIP.  Some restart must be added.
- (pj_status_t)destroy
{
    isRestarting = YES;

    pj_status_t status;
    unsigned    i;

    /* Close ringback port */
    if (ringback_port && ringback_slot != PJSUA_INVALID_ID)
    {
        pjsua_conf_remove_port(ringback_slot);
        ringback_slot = PJSUA_INVALID_ID;
        pjmedia_port_destroy(ringback_port);
        ringback_port = NULL;
    }

    /* Close ring port */
    if (ring_port && ring_slot != PJSUA_INVALID_ID)
    {
        pjsua_conf_remove_port(ring_slot);
        ring_slot = PJSUA_INVALID_ID;
        pjmedia_port_destroy(ring_port);
        ring_port = NULL;
    }

    /* Close tone generators */
    for (i = 0; i < tone_count; ++i)
    {
        pjsua_conf_remove_port(tone_slots[i]);
    }

    if (pool)
    {
        pj_pool_release(pool);
        pool = NULL;
    }

    status = pjsua_destroy();

    dispatch_async(dispatch_get_main_queue(), ^
    {
        for (Call* call in calls)
        {
            if (call.state != CallStateEnded)
            {
                call.state = CallStateEnded;
                [self.delegate sipInterface:self callEnded:call];
                pjsua_call_set_user_data(call.callId, NULL);
            }
        }

        [calls removeAllObjects];
    });

    return status;
}


#pragma mark - Tones Support

- (void)createTone:(NSArray*)toneArray name:(char*)name
{
    unsigned            i;
    unsigned            samplesPerFrame;
    pjmedia_tone_desc   tone[RING_CNT+RINGBACK_CNT];
    pj_str_t            nameString;
    pj_status_t         status;

    samplesPerFrame = media_cfg.audio_frame_ptime *
                      media_cfg.clock_rate *
                      media_cfg.channel_count / 1000;

    /* Ringback tone (call is ringing) */
    nameString = pj_str(name);
    status = pjmedia_tonegen_create2(pool, &nameString,
                                     media_cfg.clock_rate,
                                     media_cfg.channel_count,
                                     samplesPerFrame, 16, PJMEDIA_TONEGEN_LOOP, &ringback_port);
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

    pjmedia_tonegen_play(ringback_port, RINGBACK_CNT, tone, PJMEDIA_TONEGEN_LOOP);

    status = pjsua_conf_add_port(pool, ringback_port, &ringback_slot);
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
    if (ringback_port && ringback_slot != PJSUA_INVALID_ID)
    {
        pjsua_conf_remove_port(ringback_slot);
        ringback_slot = PJSUA_INVALID_ID;
        pjmedia_port_destroy(ringback_port);
        ringback_port = NULL;
    }

    /* Close ring port */
    if (ring_port && ring_slot != PJSUA_INVALID_ID)
    {
        pjsua_conf_remove_port(ring_slot);
        ring_slot = PJSUA_INVALID_ID;
        pjmedia_port_destroy(ring_port);
        ring_port = NULL;
    }

    /* Close tone generators */
    for (i = 0; i < tone_count; ++i)
    {
        pjsua_conf_remove_port(tone_slots[i]);
    }
}


#pragma mark - Making & Breaking Calls

- (BOOL)makeCall:(Call*)call tones:(NSDictionary*)tones
{
    [self registerThread];

    call.calledNumber = [call.phoneNumber e164Format] ? [call.phoneNumber e164Format] : call.phoneNumber.number;

    pj_assert([call.calledNumber length] != 0 && [call.identityNumber length] != 0);    //### Remove?

    if (pjsua_call_get_count() == PJSUA_MAX_CALLS)
    {
        NSLog(@"//### Can't make call, maximum calls (%d) reached.", PJSUA_MAX_CALLS);
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [self.delegate sipInterface:self callFailed:call reason:SipInterfaceCallFailedTooManyCalls sipStatus:0];
        });

        return NO;
    }
    else
    {
        __block pjsua_call_id   call_id = PJSUA_INVALID_ID;
        __block BOOL            result;

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

            uriString = [NSString stringWithFormat:@"sip:%@@%@;transport=tls", call.calledNumber, self.server];
            uri = pj_str((char*)[uriString cStringUsingEncoding:NSASCIIStringEncoding]);
            pjsua_call_setting_default(&call_opt);

            // Create optional header containing number/identity from which this call is made.
            header_name = pj_str("Identity");
            header_value = pj_str((char*)[call.identityNumber cStringUsingEncoding:NSASCIIStringEncoding]);
            pjsip_generic_string_hdr_init2(&header, &header_name, &header_value);
            pjsua_msg_data_init(&msg_data);
            pj_list_push_back(&msg_data.hdr_list, &header);

#warning Sometimes (on bad network): Assertion failed: (aud_subsys.pf), function pjmedia_aud_dev_default_param, file ../src/pjmedia-audiodev/audiodev.c, line 682.
            //### Occurs when PJSIP has not finished restart() and a new call is made.
            //### This actually happens all the time when ending a call very early and doing a new one immediately after.
            //### I've added PJ_ENABLE_EXTRA_CHECK to config_site.h to possibly avoid the app crash, see PJ_ASSERT_RETURN().
            status = pjsua_call_make_call(pjsua_acc_get_default(), &uri, &call_opt, (__bridge void*)call, &msg_data, &call_id);
            if (status == PJ_SUCCESS)
            {
                [self findCallForCallId:call_id]; // Addes call to calls array when not already in there.
                result = YES;
            }
            else
            {
                NSLog(@"//### Failed to make call: %d.", status);
                //### We get here by compiling PJSIP with -DDEBUG (in rebuild) and PJ_ENABLE_EXTRA_CHECK (in config_site.h).
                dispatch_block_t    block = ^
                {
                    SipInterfaceCallFailed  reason;

                    switch (status)
                    {
                        case PJSIP_EINVALIDREQURI:  // Occurred when due to bug called to "sip:015 66 66 66@....".
                            reason = SipInterfaceCallFailedInvalidNumber;
                            break;

                            //### Determine which other PJSIP errors can occor here; then created SipInterfaceCallFailedXyz's.
                        default:
                            reason = SipInterfaceCallFailedTechnical;
                            break;
                    }

                    call.state = CallStateFailed;
                    [self.delegate sipInterface:self callFailed:call reason:reason sipStatus:status];
                };
                
                if ([NSThread isMainThread])
                {
                    block();
                }
                else
                {
                    dispatch_sync(dispatch_get_main_queue(), block);
                }

                result = NO;
            }
        });

        return result;
    }
}


#warning Also make force restart for calling: When no calling received in certain time ....
- (void)forceHangup
{
    @synchronized(self)
    {
        hangupTimer = nil;
    }

    dispatch_async(dispatch_get_main_queue(), ^
    {
        for (Call* call in calls)
        {
            call.state = CallStateEnded;
            [self.delegate sipInterface:self callEnded:call];
            pjsua_call_set_user_data(call.callId, NULL);
        }

        [calls removeAllObjects];
    });

    [self restart];
}


- (void)hangupAllCalls
{
    [self registerThread];

    pjsua_call_hangup_all();

    dispatch_async(dispatch_get_main_queue(), ^
    {
        for (Call* call in calls)
        {
            call.state = CallStateEnding;
            [self.delegate sipInterface:self callEnding:call];
        }
    });

    @synchronized(self)
    {
        if (hangupTimer == nil)
        {
            hangupTimer = [NSTimer scheduledTimerWithTimeInterval:FORCE_HANGUP_TIMEOUT
                                                            target:self
                                                          selector:@selector(forceHangup)
                                                          userInfo:nil
                                                           repeats:NO];
        }
    }
}


- (void)hangupCall:(Call*)call reason:(NSString*)reason
{
    [self registerThread];

    pjsua_msg_data            msg_data;
    pj_str_t                  header_name;
    pj_str_t                  header_value;
    pjsip_generic_string_hdr  header;
    pj_status_t               status;

    if (call.state == CallStateEnding)
    {
        NSLog(@"//### Multiple hangup for call %d.", call.callId);
        
        return;
    }

    if (reason != nil)
    {
        reason = @"No reason specified.";
    }

    header_name = pj_str("Reason");
    header_value = pj_str((char*)[reason cStringUsingEncoding:NSASCIIStringEncoding]);
    pjsip_generic_string_hdr_init2(&header, &header_name, &header_value);
    pjsua_msg_data_init(&msg_data);
    pj_list_push_back(&msg_data.hdr_list, &header);

    if ((status = pjsua_call_hangup(call.callId, 200, NULL, &msg_data)) != PJ_SUCCESS)
    {        
        NSLog(@"//### Hangup failed: %d", status);
        //### Inform delegate?
        //### gave 171140 PJSIP_ESESSIONTERMINATED session already terminated, when there are
        //### no calls to hangup.
    }

    @synchronized(self)
    {
        if (hangupTimer == nil)
        {
            hangupTimer = [NSTimer scheduledTimerWithTimeInterval:FORCE_HANGUP_TIMEOUT
                                                           target:self
                                                         selector:@selector(forceHangup)
                                                         userInfo:nil
                                                          repeats:NO];
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^
    {
        call.state = CallStateEnding;
        [self.delegate sipInterface:self callEnding:call];
    });
}


#pragma mark - Mute/Hold/Speaker Public API

- (void)setCall:(Call*)call onMute:(BOOL)onMute
{
    __block pj_status_t status;

    if (onMute)
    {
        status = [self setMicrophoneLevel:0.0f callId:call.callId];
    }
    else
    {
        status = [self setMicrophoneLevel:MICROPHONE_LEVEL_NORMAL callId:call.callId];
    }

    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.delegate sipInterface:self call:call onMute:(status == PJ_SUCCESS) ? onMute : !onMute];
    });
}


- (void)setCall:(Call*)call onHold:(BOOL)onHold
{
    if ([self isCallOnHold:call] != onHold)
    {
        if (onHold)
        {
            pjsua_call_set_hold(call.callId, NULL);
        }
        else
        {
            pjsua_call_setting  setting;
            pjsua_call_info     info;

            pjsua_call_get_info(call.callId, &info);
            setting = info.setting;

            setting.flag |= PJSUA_CALL_UNHOLD;
            pjsua_call_reinvite2(call.callId, &setting, NULL);
        }
    }
    else
    {
        NSLog(@"//### Duplicate HOLD for call %d.", call.callId);
    }
}


- (void)setOnSpeaker:(BOOL)onSpeaker
{
    pjmedia_aud_dev_route   route;
    pj_status_t             status;

    [self registerThread];

    route = onSpeaker ? PJMEDIA_AUD_DEV_ROUTE_LOUDSPEAKER : PJMEDIA_AUD_DEV_ROUTE_EARPIECE;

    status = pjsua_snd_set_setting(PJMEDIA_AUD_DEV_CAP_OUTPUT_ROUTE, &route, PJ_TRUE);
    if (status != PJ_SUCCESS)
    {
        NSLog(@"Setting audio route failed: %d.", status);
    }
}


- (void)sendCall:(Call*)call dtmfCharacter:(char)character
{
    if (pjsua_call_has_media(call.callId))
    {
        char        buffer[2] = { character, 0 };
        pj_str_t    digit;
        pj_status_t status;

        digit = pj_str(buffer);

        status = pjsua_call_dial_dtmf(call.callId, &digit);
        
        if (status != PJ_SUCCESS)
        {
            pjsua_perror(THIS_FILE, "Unable to send DTMF", status);
        }
        else
        {
            puts("DTMF digits enqueued for transmission");
        }
    }
}


- (SipInterfaceRegistered)registered
{
    return _registered;
}


#pragma mark - Utility Methods

- (void)printInfo
{
    int detail = 1;

    pjsua_dump(detail); // Includes same output pj_dump_config() would print.
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


- (pj_status_t)setMicrophoneLevel:(float)microphoneLevel callId:(pjsua_call_id)callId
{
    pj_status_t status;

    [self registerThread];

    pjsua_conf_port_id  conf_port = pjsua_call_get_conf_port(callId);

    if (conf_port != PJSUA_INVALID_ID)
    {
        status = pjsua_conf_adjust_tx_level(conf_port, microphoneLevel);
    }
    else
    {
        status = PJ_ENOTFOUND;
        NSLog(@"//### No conference port.");
    }

    return status;
}


- (pj_status_t)setSpeakerLevel:(float)speakerLevel callId:(pjsua_call_id)callId
{
    pj_status_t status;

    [self registerThread];

    pjsua_conf_port_id  conf_port = pjsua_call_get_conf_port(callId);

    if (conf_port != PJSUA_INVALID_ID)
    {
        status = pjsua_conf_adjust_rx_level(conf_port, speakerLevel);
    }
    else
    {
        status = PJ_ENOTFOUND;
        NSLog(@"//### No conference port.");
    }
    
    return status;
}


- (BOOL)isCallOnHold:(Call*)call
{
    pjsua_call_info info;
    BOOL            onHold = NO;

    pjsua_call_get_info(call.callId, &info);

    for (unsigned mi = 0; mi < info.media_cnt; ++mi)
    {
        if (info.media[mi].type == PJMEDIA_TYPE_AUDIO)
        {
            if (info.media[mi].status == PJSUA_CALL_MEDIA_LOCAL_HOLD)
            {
                onHold = YES;
            }
            else
            {
                onHold = NO;
            }
        }
    }

    return onHold;
}


- (Call*)findCallForCallId:(pjsua_call_id)callId
{
    __block Call*       call = nil;
    dispatch_block_t    block = ^
    {
        for (call in calls)
        {
            if (call.callId == callId)
            {
                break;
            }
        }

        unsigned        count = pjsua_call_get_count();
        pjsua_call_id*  callIds = calloc(count, sizeof(pjsua_call_id));
        int             index;

        pjsua_enum_calls(callIds, &count);
        for (index = 0; index < count; index++)
        {
            if (callId == callIds[index])
            {
                break;
            }
        }

        if (index < count)
        {
            // PJSIP still knows this call.
            if ((call = (__bridge Call*)pjsua_call_get_user_data(callId)) != nil)
            {
                // Probably first time call is being looked up.  And since callId was not know by app
                // when call was made (it's defined by PJSIP), we need to do two things here:
                [calls addObject:call];
                call.callId = callId;
            }
        }
        else
        {
            NSLog(@"//########## No PJSIP call found.");

            if ([calls count] > 0)
            {
                NSLog(@"//########## But there are %d app call(s).", [calls count]);
            }
        }
    };

    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }

    return call;
}


- (void)processAudioRouteChange
{
    UInt32      routeSize = sizeof(CFStringRef);
    CFStringRef routeRef;
    OSStatus    status = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &routeSize, &routeRef);
    NSString*   route = (__bridge NSString*)routeRef;
    float       speakerLevel;

    if (status != 0)
    {
        NSLog(@"//### Failed to get AudioRoute: %@", [Common stringWithOsStatus:status]);
        
        return;
    }

    if ([route isEqualToString:@"Headset"])
    {
        [self.delegate sipInterface:self onSpeaker:NO];
        [self.delegate sipInterface:self speakerEnable:NO];
        speakerLevel = SPEAKER_LEVEL_NORMAL * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_NORMAL : 1.0f);
    }
    else if ([route isEqualToString:@"Headphone"])
    {
        [self.delegate sipInterface:self onSpeaker:NO];
        [self.delegate sipInterface:self speakerEnable:NO];
        speakerLevel = SPEAKER_LEVEL_NORMAL * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_NORMAL : 1.0f);
    }
    else if ([route isEqualToString:@"Speaker"])
    {
        [self.delegate sipInterface:self onSpeaker:YES];
        [self.delegate sipInterface:self speakerEnable:YES];
        speakerLevel = SPEAKER_LEVEL_NORMAL * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_NORMAL : 1.0f);
    }
    else if ([route isEqualToString:@"SpeakerAndMicrophone"])       // In call: plain iPod Touch & iPad.
    {
        [self.delegate sipInterface:self onSpeaker:YES];
        [self.delegate sipInterface:self speakerEnable:YES];
        speakerLevel = SPEAKER_LEVEL_NORMAL * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_NORMAL : 1.0f);
    }
    else if ([route isEqualToString:@"HeadphonesAndMicrophone"])    // In call: All device with headphones (i.e. without microphone).
    {                                                               // And very briefly after plugging in headset.
        [self.delegate sipInterface:self onSpeaker:NO];
        [self.delegate sipInterface:self speakerEnable:NO];
        speakerLevel = SPEAKER_LEVEL_NORMAL * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_NORMAL : 1.0f);
    }
    else if ([route isEqualToString:@"HeadsetInOut"])               // In call: All devices when using headset (i.e. with microphone).
    {
        [self.delegate sipInterface:self onSpeaker:NO];
        [self.delegate sipInterface:self speakerEnable:NO];
        speakerLevel = SPEAKER_LEVEL_NORMAL * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_NORMAL : 1.0f);
    }
    else if ([route isEqualToString:@"ReceiverAndMicrophone"])      // In call: plain iPhone.
    {
        [self.delegate sipInterface:self onSpeaker:NO];
        [self.delegate sipInterface:self speakerEnable:YES];
        speakerLevel = SPEAKER_LEVEL_RECEIVER * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_RECEIVER : 1.0f);
    }
    else if ([route isEqualToString:@"LineOut"])
    {
        [self.delegate sipInterface:self onSpeaker:NO];
        [self.delegate sipInterface:self speakerEnable:NO];
        speakerLevel = SPEAKER_LEVEL_NORMAL * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_NORMAL : 1.0f);
    }
    else if ([route isEqualToString:@"LineInOut"])
    {
        [self.delegate sipInterface:self onSpeaker:NO];
        [self.delegate sipInterface:self speakerEnable:NO];
        speakerLevel = SPEAKER_LEVEL_NORMAL * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_NORMAL : 1.0f);
    }
    else if ([route isEqualToString:@"HeadsetBT"])
    {
        [self.delegate sipInterface:self onSpeaker:NO];
        [self.delegate sipInterface:self speakerEnable:NO];
        speakerLevel = SPEAKER_LEVEL_NORMAL * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_NORMAL : 1.0f);
    }
    else
    {
        speakerLevel = SPEAKER_LEVEL_NORMAL * (self.louderVolume ? SPEAKER_LOUDER_FACTOR_NORMAL : 1.0f);
        NSLog(@"//### Unknown Audio Route: %@", route);
    }

    for (Call* call in calls)
    {
        [self setSpeakerLevel:speakerLevel callId:call.callId];
    }
}


- (void)startRingbackTone:(pjsua_call_id)call_id
{
    Call*   call = [self findCallForCallId:call_id];

    if (call.ringbackToneOn)
    {
        return;
    }

    call.ringbackToneOn = YES;

    if (ringback_slot != PJSUA_INVALID_ID)
    {
        pjsua_conf_connect(ringback_slot, 0);
    }
}


- (void)startBusyTone:(pjsua_call_id)call_id
{
    Call*   call = [self findCallForCallId:call_id];

    if (call.ringbackToneOn)
    {
        return;
    }

    call.busyToneOn = YES;

    if (busy_slot != PJSUA_INVALID_ID)
    {
        pjsua_conf_connect(busy_slot, 0);
    }
}


- (void)startRingTone:(pjsua_call_id)call_id
{
    Call*   call = [self findCallForCallId:call_id];

    if (call.ringToneOn)
    {
        return;
    }

    call.ringToneOn = YES;

    if (ring_slot != PJSUA_INVALID_ID)
    {
        pjsua_conf_connect(ring_slot, 0);
    }
}


- (void)stopTones:(pjsua_call_id)call_id
{
    Call*   call = [self findCallForCallId:call_id];

    if (call.ringbackToneOn)
    {
        call.ringbackToneOn = NO;

        if (ringback_slot != PJSUA_INVALID_ID)
        {
            pjsua_conf_disconnect(ringback_slot, 0);
            pjmedia_tonegen_rewind(ringback_port);
        }
    }

    if (call.ringToneOn)
    {
        call.ringToneOn = NO;

        if (ring_slot != PJSUA_INVALID_ID)
        {
            pjsua_conf_disconnect(ring_slot, 0);
            pjmedia_tonegen_rewind(ring_port);
        }
    }
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
    Call*           call = [self findCallForCallId:call_id];
    pjsua_call_info call_info;
    
    pjsua_call_get_info(call_id, &call_info);

    if (call == nil)
    {
        return;
    }

    switch (call_info.state)
    {
        case PJSIP_INV_STATE_NULL:          // Before INVITE is sent or received.
            break;

        case PJSIP_INV_STATE_CALLING:       // After INVITE is sent.
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                call.state = CallStateCalling;
                [self.delegate sipInterface:self callCalling:call];
            });
            break;
        }
            
        case PJSIP_INV_STATE_INCOMING:      // After INVITE is received.
            NSLog(@"INCOMING");
            break;

        case PJSIP_INV_STATE_EARLY:         // After response with To tag.
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
            if (call_info.role == PJSIP_ROLE_UAC && code == 180 && msg->body == NULL &&
                call_info.media_status == PJSUA_CALL_MEDIA_NONE)
            {
                [self startRingbackTone:call_id];

                dispatch_async(dispatch_get_main_queue(), ^
                {
                    call.state = CallStateRinging;
                    [self.delegate sipInterface:self callRinging:call];
                });
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    call.state = CallStateRinging;
                    [self.delegate sipInterface:self callRinging:call];
                });
            }
            
            PJ_LOG(3, (THIS_FILE, "Call %d state changed to %s (%d %.*s)",
                       call_id, call_info.state_text.ptr, code, (int)reason.slen, reason.ptr));
            break;
        }

        case PJSIP_INV_STATE_CONNECTING:    // After 2xx is sent/received.
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                call.state = CallStateConnecting;
                [self.delegate sipInterface:self callConnecting:call];
            });
            break;
        }

        case PJSIP_INV_STATE_CONFIRMED:     // After ACK is sent/received.
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                call.state = CallStateConnected;
                [self.delegate sipInterface:self callConnected:call];
            });
            break;
        }

        case PJSIP_INV_STATE_DISCONNECTED:  // Session is terminated.
        {
            @synchronized(self)
            {
                [hangupTimer invalidate];
                hangupTimer = nil;
            }

            /* Stop all ringback for this call */
            [self stopTones:call_id];

            PJ_LOG(3, (THIS_FILE, "Call %d is DISCONNECTED [reason=%d (%s)]",
                       call_id, call_info.last_status, call_info.last_status_text.ptr));

            dispatch_async(dispatch_get_main_queue(), ^
            {
                call.state = CallStateEnded;
                [self.delegate sipInterface:self callEnded:call];
                [calls removeObject:call];
                pjsua_call_set_user_data(call.callId, NULL);    //### Added at MON 15 APR insearch for crash bug.  Gave problems?
            });
            break;
        }
    }

    [self checkCallStatus:call_info.last_status callId:call_id];
}


- (void)checkCallStatus:(pjsip_status_code)status callId:(pjsua_call_id)callId
{
    SipInterfaceCallFailed  failed = -1;
    Call*                   call = [self findCallForCallId:callId];
    
    switch ((int)status)    // Cast to avoid compile warning about values not in pjsip_status_code enum.
    {
        //### Is stopTones call needed below?
        case PJSIP_SC_CALL_BEING_FORWARDED:         // 181
        case PJSIP_SC_QUEUED:                       // 182
            [self stopTones:callId];
            break;

        case PJSIP_SC_BAD_REQUEST:                  // 400
            [self stopTones:callId];
            //### Might be caused by certain WiFi routers fucking up when on standard port 5060.
            break;

        case PJSIP_SC_NOT_FOUND:                    // 404
            [self stopTones:callId];
            failed = SipInterfaceCallFailedNotFound;
            break;

        case PJSIP_SC_PROXY_AUTHENTICATION_REQUIRED:// 407
            [self stopTones:callId];
            failed = SipInterfaceCallFailedAuthenticationRequired;
            break;

        case PJSIP_SC_REQUEST_TIMEOUT:              // 408
            [self stopTones:callId];
            failed = SipInterfaceCallFailedRequestTimeout;
            break;

        case CUSTOM_SC_NOT_ALLOWED_COUNTRY:         // 451
            [self stopTones:callId];
            failed = SipInterfaceCallFailedNotAllowedCountry;
            break;

        case CUSTOM_SC_NOT_ALLOWED_NUMBER:          // 452
            [self stopTones:callId];
            failed = SipInterfaceCallFailedNotAllowedNumber;
            break;

        case CUSTOM_SC_NO_CREDIT:                   // 453
            [self stopTones:callId];
            failed = SipInterfaceCallFailedNoCredit;
            break;

        case CUSTOM_SC_CALLEE_NOT_ONLINE:           // 454
            [self stopTones:callId];
            failed = SipInterfaceCallFailedCalleeNotOnline;
            break;

        case PJSIP_SC_TEMPORARILY_UNAVAILABLE:      // 480
            [self stopTones:callId];
            failed = SipInterfaceCallFailedTemporarilyUnavailable;
            break;

        case PJSIP_SC_CALL_TSX_DOES_NOT_EXIST:      // 481 server does not know the call
            [self stopTones:callId];
            failed = SipInterfaceCallFailedCallDoesNotExist;
            break;

        case PJSIP_SC_ADDRESS_INCOMPLETE:           // 484
            [self stopTones:callId];
            failed = SipInterfaceCallFailedAddressIncomplete;
            break;

        case PJSIP_SC_BUSY_HERE:                    // 486
        {
            [self startBusyTone:callId];
            dispatch_async(dispatch_get_main_queue(), ^
            {
                [self.delegate sipInterface:self callBusy:call];
            });
            break;
        }

        case PJSIP_SC_REQUEST_TERMINATED:           // 487
            // Occurs when user end call before being connected.
            //### Need to do something here?
            break;

        case PJSIP_SC_INTERNAL_SERVER_ERROR:        // 500
            [self stopTones:callId];
            failed = SipInterfaceCallFailedInternalServerError;
            break;

        case PJSIP_SC_SERVICE_UNAVAILABLE:          // 503
            [self stopTones:callId];
            failed = SipInterfaceCallFailedServiceUnavailable;
            break;

        case CUSTOM_SC_PSTN_TERMINATION_FAIL:       // 514
            [self stopTones:callId];
            failed = SipInterfaceCallFailedPstnTerminationFail;
            break;

        case CUSTOM_SC_CALL_ROUTING_ERROR:          // 515
            [self stopTones:callId];
            failed = SipInterfaceCallFailedCallRoutingError;
            break;
            
        case PJSIP_SC_DECLINE:                      // 603
        {
            [self stopTones:callId];
            dispatch_async(dispatch_get_main_queue(), ^
            {
                [self.delegate sipInterface:self callDeclined:call];
            });
            break;
        }

        default:
            if ((status / 100) == 5)
            {
                [self stopTones:callId];
                failed = SipInterfaceCallFailedServerError;
            }
            else if (status >= 300)
            {
                [self stopTones:callId];
                failed = SipInterfaceCallFailedOtherSipError;
                NSLog(@"//### Other SP error: %d.", status);
                //### Store last error code in Settings, to be printed with Easter Egg dial code.
            }
            break;
    }

    if (failed != -1)
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            call.state = CallStateFailed;
            [self.delegate sipInterface:self callFailed:call reason:failed sipStatus:status];
        });
    }
}


- (void)onIncomingCall:(pjsua_acc_id)acc_id callId:(pjsua_call_id)call_id data:(pjsip_rx_data*)rdata
{
    pjsua_call_info call_info;

    PJ_UNUSED_ARG(acc_id);
    PJ_UNUSED_ARG(rdata);

    pjsua_call_get_info(call_id, &call_info);

    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
    {
        /* Start ringback */
        [self startRingTone:call_id];

        //### auto_answer not needed, but left in to remember how to answer.
        if (auto_answer > 0)
        {
            pjsua_call_setting call_opt;

            pjsua_call_setting_default(&call_opt);
            pjsua_call_answer2(call_id, &call_opt, auto_answer, NULL, NULL);
        }

        if (auto_answer < 200)
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
                    pjsip_tsx_send_msg(tsx, tdata);
                }

                PJ_LOG(3, (THIS_FILE, "Call %d: incoming INFO:\n%.*s",
                           call_id, (int)rdata->msg_info.msg->body->len, rdata->msg_info.msg->body->data));
            }
            else
            {
                status = pjsip_endpt_create_response(tsx->endpt, rdata, 400, NULL, &tdata);
                if (status == PJ_SUCCESS)
                {
                    pjsip_tsx_send_msg(tsx, tdata);
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

    if (ci->media[mi].status == PJSUA_CALL_MEDIA_LOCAL_HOLD)
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [self.delegate sipInterface:self call:[self findCallForCallId:ci->id] onHold:YES];
        });
    }
    else if (ci->media[mi].status == PJSUA_CALL_MEDIA_ACTIVE)
    {
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [self.delegate sipInterface:self call:[self findCallForCallId:ci->id] onHold:NO];
        });
    }
}


/* Process audio media state. "mi" is the media index. */
- (void)onCallAudioState:(pjsua_call_info*)ci state:(unsigned)mi hasError:(pj_bool_t*)has_error
{
    PJ_UNUSED_ARG(has_error);

    [self stopTones:ci->id];

    /* Connect ports appropriately when media status is ACTIVE or REMOTE HOLD,
     * otherwise we should NOT connect the ports.
     */
    if (ci->media[mi].status == PJSUA_CALL_MEDIA_ACTIVE || ci->media[mi].status == PJSUA_CALL_MEDIA_REMOTE_HOLD)
    {
	pjsua_conf_port_id call_conf_slot;

	call_conf_slot = ci->media[mi].stream.aud.conf_slot;

        pjsua_conf_connect(call_conf_slot, 0);
        pjsua_conf_connect(0, call_conf_slot);

        dispatch_async(dispatch_get_main_queue(), ^
        {
            [self processAudioRouteChange];
        });
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

	if (call_info.media[mi].type == PJMEDIA_TYPE_AUDIO)
        {
            on_call_audio_state(&call_info, mi, &has_error);
	}
    }

    if (has_error)
    {
	pj_str_t reason = pj_str("Media failed");
	pjsua_call_hangup(call_id, 500, &reason, NULL);
    }
}


/*
 * Redirection handler.
 */
- (pjsip_redirect_op)callOnRedirected:(pjsua_call_id)call_id target:(const pjsip_uri*)target event:(const pjsip_event*)e
{
    PJ_UNUSED_ARG(e);

    if (redir_op == PJSIP_REDIRECT_PENDING)
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

    return redir_op;
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

    if (status_code / 100 == 2)
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
        
	if (ssl_sock_info->verify_status && !udp_cfg.tls_setting.verify_server)
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
        [sipInterface processAudioRouteChange];
    }
}



