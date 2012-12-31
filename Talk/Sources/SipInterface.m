//
//  SipInterface.m
//  Talk
//
//  Created by Cornelis van der Bent on 29/09/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <pthread.h>
#import "SipInterface.h"
#import "Common.h"
#import "webrtc.h"      // Glue-logic with libWebRTC.a.

//### Added for Talk's NetworkStatus; still needs to be notified to.
NSString* const kSipInterfaceCallStateChangedNotification = @"kSipInterfaceCallStateChangedNotification";


#define THIS_FILE	"SipInterface"
#define NO_LIMIT	(int)0x7FFFFFFF
#define KEEP_ALIVE_INTERVAL 600     // Shortest iOS allows.


/* Ringtones		    US	       UK  */
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

/* Call specific data */
struct call_data
{
    pj_timer_entry	    timer;
    pj_bool_t		    ringback_on;
    pj_bool_t		    ring_on;
};

/* Pjsua application data */
static struct app_config
{
    pjsua_config	    cfg;
    pjsua_logging_config    log_cfg;
    pjsua_media_config	    media_cfg;
    pjsua_transport_config  udp_cfg;
    pjsua_transport_config  rtp_cfg;
    pjsip_redirect_op	    redir_op;

    pjsua_acc_config	    account;

    struct call_data	    call_data[PJSUA_MAX_CALLS];

    pj_pool_t*              pool;
    /* Compatibility with older pjsua */

    unsigned		    tone_count;
    pjmedia_tone_desc	    tones[32];
    pjsua_conf_port_id	    tone_slots[32];
    pjsua_player_id	    wav_id;
    pjsua_conf_port_id	    wav_port;
    pj_bool_t		    auto_play;
    pj_bool_t		    auto_play_hangup;
    unsigned		    auto_answer;
    unsigned		    duration;

    float		    mic_level;
    float                   speaker_level;

    int			    ringback_slot;
    pjmedia_port*           ringback_port;
    int			    busy_slot;
    pjmedia_port*           busy_port;
    int			    congestion_slot;
    pjmedia_port*           congestion_port;
    int			    ring_slot;
    pjmedia_port*           ring_port;
} app_config;


static pjsua_call_id	current_call = PJSUA_INVALID_ID;

#if defined(PJMEDIA_HAS_RTCP_XR) && (PJMEDIA_HAS_RTCP_XR != 0)
#   define SOME_BUF_SIZE	(1024 * 10)
#else
#   define SOME_BUF_SIZE	(1024 * 3)
#endif

pj_status_t     app_destroy(void);

static void     ringback_start(pjsua_call_id call_id);
static void     ring_start(pjsua_call_id call_id);
static void     ring_stop(pjsua_call_id call_id);

pj_bool_t 	app_restart;
pj_log_func*    log_cb = NULL;

static SipInterfaceRegistered   _registered;

//### usable?
void printInfo()
{
    int detail = 1;
    
    pj_dump_config();
    pjsua_dump(detail);
}


/* Set default config. */
static void default_config(
    struct app_config*  cfg)
{
    char        tmp[80];

    pjsua_config_default(&cfg->cfg);
    pj_ansi_sprintf(tmp, "PJSUA v%s %s", pj_get_version(), pj_get_sys_info()->info.ptr);
    pj_strdup2_with_null(app_config.pool, &cfg->cfg.user_agent, tmp);
    
    pjsua_logging_config_default(&cfg->log_cfg);
    pjsua_media_config_default(&cfg->media_cfg);
    pjsua_transport_config_default(&cfg->udp_cfg);
    pjsua_transport_config_default(&cfg->rtp_cfg);

    cfg->udp_cfg.port    = 5060;
    cfg->rtp_cfg.port    = 4000;
    cfg->redir_op        = PJSIP_REDIRECT_ACCEPT;
    cfg->duration        = NO_LIMIT;
    cfg->wav_id          = PJSUA_INVALID_ID;
    cfg->wav_port        = PJSUA_INVALID_ID;
    cfg->mic_level       = 1.2;    //### Get from Settings (indirectly).
    cfg->speaker_level   = 2.4;    //### Get from Settings (indirectly). 4.0 as loud?
    cfg->ringback_slot   = PJSUA_INVALID_ID;
    cfg->busy_slot       = PJSUA_INVALID_ID;
    cfg->congestion_slot = PJSUA_INVALID_ID;
    cfg->ring_slot       = PJSUA_INVALID_ID;
    
    pjsua_acc_config_default(&cfg->account);
}


/*****************************************************************************
 * Console application
 */

static void ringback_start(pjsua_call_id call_id)
{
    if (app_config.call_data[call_id].ringback_on)
    {
	return;
    }
    
    app_config.call_data[call_id].ringback_on = PJ_TRUE;
    
    if (app_config.ringback_slot!=PJSUA_INVALID_ID)
    {
	pjsua_conf_connect(app_config.ringback_slot, 0);
    }
}


static void ring_stop(pjsua_call_id call_id)
{
    if (app_config.call_data[call_id].ringback_on)
    {
	app_config.call_data[call_id].ringback_on = PJ_FALSE;
                
	if (app_config.ringback_slot != PJSUA_INVALID_ID)
	{
	    pjsua_conf_disconnect(app_config.ringback_slot, 0);
	    pjmedia_tonegen_rewind(app_config.ringback_port);
	}
    }
    
    if (app_config.call_data[call_id].ring_on)
    {
	app_config.call_data[call_id].ring_on = PJ_FALSE;
        
	if (app_config.ring_slot!=PJSUA_INVALID_ID)
	{
	    pjsua_conf_disconnect(app_config.ring_slot, 0);
	    pjmedia_tonegen_rewind(app_config.ring_port);
	}
    }
}


static void ring_start(pjsua_call_id call_id)
{
    if (app_config.call_data[call_id].ring_on)
    {
	return;
    }
    
    app_config.call_data[call_id].ring_on = PJ_TRUE;
    
    if (app_config.ring_slot!=PJSUA_INVALID_ID)
    {
	pjsua_conf_connect(app_config.ring_slot, 0);
    }
}


/*
 * Find next call when current call is disconnected or when user
 * press ']'
 */
static pj_bool_t find_next_call(void)
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
static pj_bool_t find_prev_call(void)
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
static void call_timeout_callback(
    pj_timer_heap_t*        timer_heap,
    struct pj_timer_entry*  entry)
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
              app_config.duration, call_id));
    entry->id = PJSUA_INVALID_ID;
    
    pjsua_call_hangup(call_id, 200, NULL, &msg_data);
}


/*
 * Handler when invite state has changed.
 */
static void on_call_state(pjsua_call_id call_id, pjsip_event *e)
{
    pjsua_call_info call_info;
    
    PJ_UNUSED_ARG(e);
    
    pjsua_call_get_info(call_id, &call_info);
    
    if (call_info.state == PJSIP_INV_STATE_DISCONNECTED)
    {
	/* Stop all ringback for this call */
	ring_stop(call_id);
        
	/* Cancel duration timer, if any */
	if (app_config.call_data[call_id].timer.id != PJSUA_INVALID_ID)
        {
	    struct call_data *cd = &app_config.call_data[call_id];
	    pjsip_endpoint *endpt = pjsua_get_pjsip_endpt();
            
	    cd->timer.id = PJSUA_INVALID_ID;
	    pjsip_endpt_cancel_timer(endpt, &cd->timer);
	}
        
	/* Rewind play file when hangup automatically,
	 * since file is not looped
	 */
	if (app_config.auto_play_hangup)
        {
	    pjsua_player_set_pos(app_config.wav_id, 0);
        }
        
	PJ_LOG(3, (THIS_FILE, "Call %d is DISCONNECTED [reason=%d (%s)]",
                   call_id, call_info.last_status, call_info.last_status_text.ptr));
        
	if (call_id == current_call)
        {
	    find_next_call();
	}
        
        /* Reset current call */
        if (current_call == call_id)
        {
            current_call = PJSUA_INVALID_ID;
        }
    }
    else
    {
	if (app_config.duration != NO_LIMIT && call_info.state == PJSIP_INV_STATE_CONFIRMED)
	{
	    /* Schedule timer to hangup call after the specified duration */
	    struct call_data*   cd = &app_config.call_data[call_id];
	    pjsip_endpoint*     endpt = pjsua_get_pjsip_endpt();
	    pj_time_val         delay;
            
	    cd->timer.id = call_id;
	    delay.sec    = app_config.duration;
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
		ringback_start(call_id);
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


/**
 * Handler when there is incoming call.
 */
static void on_incoming_call(pjsua_acc_id   acc_id,
                             pjsua_call_id  call_id,
			     pjsip_rx_data* rdata)
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
        ring_start(call_id);

        if (app_config.auto_answer > 0)
        {
            pjsua_call_setting call_opt;

            pjsua_call_setting_default(&call_opt);
            pjsua_call_answer2(call_id, &call_opt, app_config.auto_answer, NULL, NULL);
        }

        if (app_config.auto_answer < 200)
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
static void on_call_tsx_state(
    pjsua_call_id       call_id,
    pjsip_transaction*  tsx,
    pjsip_event*        e)
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
static void on_call_generic_media_state(
    pjsua_call_info*    ci,
    unsigned            mi,
    pj_bool_t*          has_error)
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
static void on_call_audio_state(
    pjsua_call_info*    ci,
    unsigned            mi,
    pj_bool_t*          has_error)
{
    PJ_UNUSED_ARG(has_error);
    
    /* Stop ringback */
    ring_stop(ci->id);
    
    /* Connect ports appropriately when media status is ACTIVE or REMOTE HOLD,
     * otherwise we should NOT connect the ports.
     */
    if (ci->media[mi].status == PJSUA_CALL_MEDIA_ACTIVE || ci->media[mi].status == PJSUA_CALL_MEDIA_REMOTE_HOLD)
    {
	pj_bool_t connect_sound = PJ_TRUE;
	pj_bool_t disconnect_mic = PJ_FALSE;
	pjsua_conf_port_id call_conf_slot;
        
	call_conf_slot = ci->media[mi].stream.aud.conf_slot;
      
	/* Otherwise connect to sound device */
	if (connect_sound)
        {
	    pjsua_conf_connect(call_conf_slot, 0);
	    if (!disconnect_mic)
            {
		pjsua_conf_connect(0, call_conf_slot);

                pjsua_conf_adjust_rx_level(0, app_config.mic_level);
                pjsua_conf_adjust_tx_level(0, app_config.speaker_level);
            }
	}
    }
}


/*
 * Callback on media state changed event.
 * The action may connect the call to sound device, to file, or
 * to loop the call.
 */
static void on_call_media_state(
    pjsua_call_id       call_id)
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
static void call_on_dtmf_callback(
    pjsua_call_id   call_id,
    int             dtmf)
{
    PJ_LOG(3,(THIS_FILE, "Incoming DTMF on call %d: %c", call_id, dtmf));
}


/*
 * Redirection handler.
 */
static pjsip_redirect_op call_on_redirected(
    pjsua_call_id       call_id,
    const pjsip_uri*    target,
    const pjsip_event*  e)
{
    PJ_UNUSED_ARG(e);
    
    if (app_config.redir_op == PJSIP_REDIRECT_PENDING)
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
    
    return app_config.redir_op;
}


/*
 * Handler registration status has changed.
 */
static void on_reg_state(pjsua_acc_id acc_id,  pjsua_reg_info *info)
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
static void on_call_transfer_status(
    pjsua_call_id   call_id,
    int             status_code,
    const pj_str_t* status_text,
    pj_bool_t       final,
    pj_bool_t*      p_cont)
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
static void on_call_replaced(
    pjsua_call_id   old_call_id,
    pjsua_call_id   new_call_id)
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
static void on_nat_detect(
    const pj_stun_nat_detect_result*    res)
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
static void on_mwi_info(
    pjsua_acc_id    acc_id,
    pjsua_mwi_info* mwi_info)
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
static void on_transport_state(
    pjsip_transport*                    tp,
    pjsip_transport_state               state,
    const pjsip_transport_state_info*   info)
{
    char host_port[128];
    
    pj_ansi_snprintf(host_port, sizeof(host_port), "[%.*s:%d]",
		     (int)tp->remote_name.host.slen, tp->remote_name.host.ptr, tp->remote_name.port);
    
    switch (state)
    {
        case PJSIP_TP_STATE_CONNECTED:
            {
                PJ_LOG(3, (THIS_FILE, "SIP %s transport is connected to %s", tp->type_name, host_port));
            }
            break;
            
        case PJSIP_TP_STATE_DISCONNECTED:
            {
                char buf[100];
                
                snprintf(buf, sizeof(buf), "SIP %s transport is disconnected from %s", tp->type_name, host_port);
                pjsua_perror(THIS_FILE, buf, info->status);
            }
            break;
            
        default:
            break;
    }
    
#if defined(PJSIP_HAS_TLS_TRANSPORT) && PJSIP_HAS_TLS_TRANSPORT != 0
    if (!pj_ansi_stricmp(tp->type_name, "tls") && info->ext_info &&
	(state == PJSIP_TP_STATE_CONNECTED ||
	 ((pjsip_tls_state_info*)info->ext_info)->ssl_sock_info->verify_status != PJ_SUCCESS))
    {
	char        buf[2048];
	const char* verif_msgs[32];
	unsigned    verif_msg_cnt;

	pjsip_tls_state_info *tls_info  = (pjsip_tls_state_info*)info->ext_info;
	pj_ssl_sock_info *ssl_sock_info = tls_info->ssl_sock_info;
        
	/* Dump server TLS cipher */
	PJ_LOG(4, (THIS_FILE, "TLS cipher used: 0x%06X/%s",
                   ssl_sock_info->cipher, pj_ssl_cipher_name(ssl_sock_info->cipher)));
        
	/* Dump server TLS certificate */
	pj_ssl_cert_info_dump(ssl_sock_info->remote_cert_info, "  ", buf, sizeof(buf));
	PJ_LOG(4, (THIS_FILE, "TLS cert info of %s:\n%s", host_port, buf));
        
	/* Dump server TLS certificate verification result */
	verif_msg_cnt = PJ_ARRAY_SIZE(verif_msgs);
	pj_ssl_cert_get_verify_status_strings(ssl_sock_info->verify_status, verif_msgs, &verif_msg_cnt);
	PJ_LOG(3, (THIS_FILE, "TLS cert verification result of %s : %s",
                   host_port, (verif_msg_cnt == 1? verif_msgs[0]:"")));
        
	if (verif_msg_cnt > 1)
        {
	    for (unsigned i = 0; i < verif_msg_cnt; ++i)
            {
		PJ_LOG(3,(THIS_FILE, "- %s", verif_msgs[i]));
            }
	}
        
	if (ssl_sock_info->verify_status && !app_config.udp_cfg.tls_setting.verify_server)
	{
	    PJ_LOG(3, (THIS_FILE, "PJSUA is configured to ignore TLS cert verification errors"));
	}
    }
#endif
}


/*
 * Notification on ICE error.
 */
static void on_ice_transport_error(
    int                 index,
    pj_ice_strans_op    op,
    pj_status_t         status,
    void*               param)
{
    PJ_UNUSED_ARG(op);
    PJ_UNUSED_ARG(param);
    PJ_PERROR(1, (THIS_FILE, status, "ICE keep alive failure for transport %d", index));
}


/*
 * Notification on sound device operation.
 */
static pj_status_t on_snd_dev_operation(
    int operation)
{
    PJ_LOG(3,(THIS_FILE, "Turning sound device %s", (operation? "ON":"OFF")));
    
    return PJ_SUCCESS;
}


/*
 * A simple registrar, invoked by default_mod_on_rx_request()
 */
static void simple_registrar(pjsip_rx_data *rdata)
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


/*****************************************************************************
 * A simple module to handle otherwise unhandled request. We will register
 * this with the lowest priority.
 */

/* Notification on incoming request */
static pj_bool_t default_mod_on_rx_request(
    pjsip_rx_data*      rdata)
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
        simple_registrar(rdata);
        
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


/* The module instance. */
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



pj_status_t app_main(void)
{
    pj_status_t status;
    
    if ((status = pjsua_start()) != PJ_SUCCESS)
    {
        NSLog(@"//### pjsua_start() failed: %d.", status);

        app_destroy();
    }

    return status;
}


pj_status_t app_destroy(void)
{
    pj_status_t status;
    unsigned    i;

    /* Close ringback port */
    if (app_config.ringback_port && app_config.ringback_slot != PJSUA_INVALID_ID)
    {
        pjsua_conf_remove_port(app_config.ringback_slot);
        app_config.ringback_slot = PJSUA_INVALID_ID;
        pjmedia_port_destroy(app_config.ringback_port);
        app_config.ringback_port = NULL;
    }
    
    /* Close ring port */
    if (app_config.ring_port && app_config.ring_slot != PJSUA_INVALID_ID)
    {
        pjsua_conf_remove_port(app_config.ring_slot);
        app_config.ring_slot = PJSUA_INVALID_ID;
        pjmedia_port_destroy(app_config.ring_port);
        app_config.ring_port = NULL;
    }
    
    /* Close tone generators */
    for (i = 0; i < app_config.tone_count; ++i)
    {
        pjsua_conf_remove_port(app_config.tone_slots[i]);
    }
    
    if (app_config.pool)
    {
        pj_pool_release(app_config.pool);
        app_config.pool = NULL;
    }
    
    status = pjsua_destroy();
    
    pj_bzero(&app_config, sizeof(app_config));
    
    return status;
}


void showLog(
    int         level,
    const char* data,
    int         len)
{
    NSLog(@"%s", data);
}


@implementation SipInterface

@synthesize realm           = _realm;
@synthesize server          = _server;
@synthesize username        = _username;
@synthesize password        = _password;
@synthesize microphoneLevel = _microphoneLevel;
@synthesize registered      = _registered;


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
        log_cb = &showLog;

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
    
    return self;
}


- (pj_status_t)app_init
{
    pjsua_transport_id      transport_id = -1;
    pjsua_transport_config  tcp_cfg;
    unsigned                i;
    pj_status_t             status;

    app_restart = PJ_FALSE;

    /* Create pjsua */
    if ((status = pjsua_create()) != PJ_SUCCESS)
    {
        return status;
    }

    /* Create pool for application */
    app_config.pool = pjsua_pool_create("pjsua-app", 1000, 1000);

    /* Initialize default config */
    default_config(&app_config);

    if ((status = [self parse_args]) != PJ_SUCCESS)
    {
        return status;
    }

    /* Initialize application callbacks */
    app_config.cfg.cb.on_call_state           = &on_call_state;
    app_config.cfg.cb.on_call_media_state     = &on_call_media_state;
    app_config.cfg.cb.on_incoming_call        = &on_incoming_call;
    app_config.cfg.cb.on_call_tsx_state       = &on_call_tsx_state;
    app_config.cfg.cb.on_dtmf_digit           = &call_on_dtmf_callback;
    app_config.cfg.cb.on_call_redirected      = &call_on_redirected;
    app_config.cfg.cb.on_reg_state2           = &on_reg_state;
    app_config.cfg.cb.on_call_transfer_status = &on_call_transfer_status;
    app_config.cfg.cb.on_call_replaced        = &on_call_replaced;
    app_config.cfg.cb.on_nat_detect           = &on_nat_detect;
    app_config.cfg.cb.on_mwi_info             = &on_mwi_info;
    app_config.cfg.cb.on_transport_state      = &on_transport_state;
    app_config.cfg.cb.on_ice_transport_error  = &on_ice_transport_error;
    app_config.cfg.cb.on_snd_dev_operation    = &on_snd_dev_operation;
    app_config.log_cfg.cb                     = log_cb;

    /* Initialize pjsua */
    if ((status = pjsua_init(&app_config.cfg, &app_config.log_cfg, &app_config.media_cfg)) != PJ_SUCCESS)
    {
        return status;
    }

    /* Register WebRTC codec */
    pjmedia_endpt *endpt = pjsua_get_pjmedia_endpt();
    status = pjmedia_codec_webrtc_init(endpt);
    if (status != PJ_SUCCESS)
    {
        return status;
    }

#warning ### Check if https://trac.pjsip.org/repos/ticket/1294 things can be left out here now wrt codecs!!!

    /* Initialize our module to handle otherwise unhandled request */
    status = pjsip_endpt_register_module(pjsua_get_pjsip_endpt(), &mod_default_handler);
    if (status != PJ_SUCCESS)
    {
        return status;
    }

    /* Initialize calls data */
    for (i = 0; i < PJ_ARRAY_SIZE(app_config.call_data); ++i)
    {
        app_config.call_data[i].timer.id = PJSUA_INVALID_ID;
        app_config.call_data[i].timer.cb = &call_timeout_callback;
    }

    pj_memcpy(&tcp_cfg, &app_config.udp_cfg, sizeof(tcp_cfg));

    /* Create ringback tones */
    if (true)
    {
        unsigned            i;
        unsigned            samples_per_frame;
        pjmedia_tone_desc   tone[RING_CNT+RINGBACK_CNT];
        pj_str_t            name;

        samples_per_frame = app_config.media_cfg.audio_frame_ptime *
        app_config.media_cfg.clock_rate *
        app_config.media_cfg.channel_count / 1000;

        /* Ringback tone (call is ringing) */
        name = pj_str("ringback");
        status = pjmedia_tonegen_create2(app_config.pool, &name,
                                         app_config.media_cfg.clock_rate,
                                         app_config.media_cfg.channel_count,
                                         samples_per_frame, 16, PJMEDIA_TONEGEN_LOOP, &app_config.ringback_port);
        if (status != PJ_SUCCESS)
        {
            goto on_error;
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

        pjmedia_tonegen_play(app_config.ringback_port, RINGBACK_CNT, tone, PJMEDIA_TONEGEN_LOOP);

        status = pjsua_conf_add_port(app_config.pool, app_config.ringback_port, &app_config.ringback_slot);
        if (status != PJ_SUCCESS)
        {
            goto on_error;
        }

        /* Ring (to alert incoming call) */
        name = pj_str("ring");
        status = pjmedia_tonegen_create2(app_config.pool, &name,
                                         app_config.media_cfg.clock_rate,
                                         app_config.media_cfg.channel_count,
                                         samples_per_frame, 16, PJMEDIA_TONEGEN_LOOP, &app_config.ring_port);
        if (status != PJ_SUCCESS)
        {
            goto on_error;
        }

        for (i = 0; i < RING_CNT; ++i)
        {
            tone[i].freq1    = RING_FREQ1;
            tone[i].freq2    = RING_FREQ2;
            tone[i].on_msec  = RING_ON;
            tone[i].off_msec = RING_OFF;
        }

        tone[RING_CNT - 1].off_msec = RING_INTERVAL;

        pjmedia_tonegen_play(app_config.ring_port, RING_CNT, tone, PJMEDIA_TONEGEN_LOOP);

        status = pjsua_conf_add_port(app_config.pool, app_config.ring_port, &app_config.ring_slot);
        if (status != PJ_SUCCESS)
        {
            goto on_error;
        }
    }


    /* Add UDP transport */
    {
        pjsua_acc_id            aid;
        pjsip_transport_type_e  type = PJSIP_TRANSPORT_UDP;

        if ((status = pjsua_transport_create(type, &app_config.udp_cfg, &transport_id)) != PJ_SUCCESS)
        {
            goto on_error;
        }

        /* Add local account */
        pjsua_acc_add_local(transport_id, PJ_TRUE, &aid);

        //pjsua_acc_set_transport(aid, transport_id);
        pjsua_acc_set_online_status(pjsua_acc_get_default(), PJ_TRUE);

        if (app_config.udp_cfg.port == 0)
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
            goto on_error;
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
            goto on_error;
        }

        /* Add local account */
        pjsua_acc_add_local(transport_id, PJ_FALSE, &acc_id);
        pjsua_acc_set_online_status(acc_id, PJ_TRUE);
    }

    if (transport_id == -1)
    {
        PJ_LOG(1, (THIS_FILE, "Error: no transport is configured"));
        status = -1;

        goto on_error;
    }

    /* Add account */
    app_config.account.rtp_cfg                  = app_config.rtp_cfg;
    app_config.account.reg_retry_interval       = 300;
    app_config.account.reg_first_retry_interval = 60;

    if ((status = pjsua_acc_add(&app_config.account, PJ_TRUE, NULL)) != PJ_SUCCESS)
    {
        goto on_error;
    }

    pjsua_acc_set_online_status(pjsua_acc_get_default(), PJ_TRUE);

    return PJ_SUCCESS;
    
on_error:
    app_destroy();
    
    return status;
}


- (pj_status_t)parse_args
{
    app_config.account.reg_uri = pj_str((char*)[[NSString stringWithFormat:@"sip:%@", self.server] UTF8String]);

    app_config.account.id = pj_str((char*)[[NSString stringWithFormat:@"sip:%@@%@", self.username, self.server] UTF8String]);

    app_config.account.cred_info[0].username = pj_str((char*)[self.username UTF8String]);
    app_config.account.cred_info[0].scheme   = pj_str("Digest");

    app_config.account.cred_info[0].realm = pj_str((char*)[self.realm UTF8String]);

    app_config.account.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
    app_config.account.cred_info[0].data = pj_str((char*)[self.password UTF8String]);

#if !defined(PJMEDIA_HAS_SRTP) && (PJMEDIA_HAS_SRTP == 0)
#error Requires SRTP
#endif
    app_config.cfg.use_srtp = 2;
    app_config.account.use_srtp = app_config.cfg.use_srtp;

    // No VAD
    app_config.media_cfg.no_vad = PJ_TRUE;

    if (app_config.account.cred_info[0].username.slen)
    {
        app_config.account.cred_count++;

        //### Attempt to force all over TLS: https://trac.pjsip.org/repos/wiki/Using_SIP_TCP
        //### Seems to fix bug that hangup_all did not work often, resulting in multiple BYE
        //### being sent.  But it did work sometimes as well; may have to do with Wi-Fi quality.
        //### Was done in Newcastle with bad network in hotel and Starbucks.
        app_config.account.proxy[app_config.account.proxy_cnt++] = pj_str("sip:178.63.93.9;transport=tls");
    }

    return PJ_SUCCESS;
}


- (id)initWithConfig:(NSString*)config
{
    if (self = [super init])
    {
        _registered = SipInterfaceRegisteredNo;

        pj_log_set_log_func(&showLog);
        log_cb = &showLog;

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

    return self;
}


- (void)keepAlive
{
    [self registerThread];

    pjsua_acc_id    accountId;

    // We assume there is only one external account.  (There may be a few local accounts too.)
    if (pjsua_acc_is_valid(accountId = pjsua_acc_get_default()))
    {
        app_config.account.reg_timeout = KEEP_ALIVE_INTERVAL;
        if (pjsua_acc_set_registration(accountId, PJ_TRUE) != PJ_SUCCESS)
        {
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
                       app_destroy();
                       app_destroy();  // On purpose.

                       if ([self app_init] == PJ_SUCCESS)
                       {
                           app_main();
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

    samplesPerFrame = app_config.media_cfg.audio_frame_ptime *
                      app_config.media_cfg.clock_rate *
                      app_config.media_cfg.channel_count / 1000;

    /* Ringback tone (call is ringing) */
    nameString = pj_str(name);
    status = pjmedia_tonegen_create2(app_config.pool, &nameString,
                                     app_config.media_cfg.clock_rate,
                                     app_config.media_cfg.channel_count,
                                     samplesPerFrame, 16, PJMEDIA_TONEGEN_LOOP, &app_config.ringback_port);
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

    pjmedia_tonegen_play(app_config.ringback_port, RINGBACK_CNT, tone, PJMEDIA_TONEGEN_LOOP);

    status = pjsua_conf_add_port(app_config.pool, app_config.ringback_port, &app_config.ringback_slot);
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
    if (app_config.ringback_port && app_config.ringback_slot != PJSUA_INVALID_ID)
    {
        pjsua_conf_remove_port(app_config.ringback_slot);
        app_config.ringback_slot = PJSUA_INVALID_ID;
        pjmedia_port_destroy(app_config.ringback_port);
        app_config.ringback_port = NULL;
    }

    /* Close ring port */
    if (app_config.ring_port && app_config.ring_slot != PJSUA_INVALID_ID)
    {
        pjsua_conf_remove_port(app_config.ring_slot);
        app_config.ring_slot = PJSUA_INVALID_ID;
        pjmedia_port_destroy(app_config.ring_port);
        app_config.ring_port = NULL;
    }

    /* Close tone generators */
    for (i = 0; i < app_config.tone_count; ++i)
    {
        pjsua_conf_remove_port(app_config.tone_slots[i]);
    }
}


- (pjsua_call_id)callNumber:(NSString*)calledNumber
             identityNumber:(NSString*)identityNumber
                   userData:(void*)userData
                      tones:(NSDictionary*)tones
{
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

    pjsua_call_hangup_all();
}


- (SipInterfaceRegistered)registered
{
    return _registered;
}

@end

