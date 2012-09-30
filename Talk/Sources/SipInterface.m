//
//  SipInterface.m
//  Talk
//
//  Created by Cornelis van der Bent on 29/09/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "SipInterface.h"


#include <pjsua-lib/pjsua.h>


#define THIS_FILE	"pjsua_app.c"
#define NO_LIMIT	(int)0x7FFFFFFF

/* Ringtones		    US	       UK  */
#define RINGBACK_FREQ1	    440	    /* 400 */
#define RINGBACK_FREQ2	    480	    /* 450 */
#define RINGBACK_ON	    2000    /* 400 */
#define RINGBACK_OFF	    4000    /* 200 */
#define RINGBACK_CNT	    1	    /* 2   */
#define RINGBACK_INTERVAL   4000    /* 2000 */

#define RING_FREQ1	    800
#define RING_FREQ2	    640
#define RING_ON		    200
#define RING_OFF	    100
#define RING_CNT	    3
#define RING_INTERVAL	    3000

#define MAX_AVI             4

/* Call specific data */
struct call_data
{
    pj_timer_entry	    timer;
    pj_bool_t		    ringback_on;
    pj_bool_t		    ring_on;
};

/* Video settings */
struct app_vid
{
    unsigned		    vid_cnt;
    int			    vcapture_dev;
    int			    vrender_dev;
    pj_bool_t		    in_auto_show;
    pj_bool_t		    out_auto_transmit;
};

/* Pjsua application data */
static struct app_config
{
    pjsua_config	    cfg;
    pjsua_logging_config    log_cfg;
    pjsua_media_config	    media_cfg;
    pj_bool_t		    no_refersub;
    pj_bool_t		    ipv6;
    pj_bool_t		    enable_qos;
    pj_bool_t		    no_tcp;
    pj_bool_t		    no_udp;
    pj_bool_t		    use_tls;
    pjsua_transport_config  udp_cfg;
    pjsua_transport_config  rtp_cfg;
    pjsip_redirect_op	    redir_op;
    
    unsigned		    acc_cnt;
    pjsua_acc_config	    acc_cfg[PJSUA_MAX_ACC];
    
    unsigned		    buddy_cnt;
    pjsua_buddy_config	    buddy_cfg[PJSUA_MAX_BUDDIES];
    
    struct call_data	    call_data[PJSUA_MAX_CALLS];
    
    pj_pool_t		   *pool;
    /* Compatibility with older pjsua */
    
    unsigned		    codec_cnt;
    pj_str_t		    codec_arg[32];
    unsigned		    codec_dis_cnt;
    pj_str_t                codec_dis[32];
    pj_bool_t		    null_audio;
    unsigned		    wav_count;
    pj_str_t		    wav_files[32];
    unsigned		    tone_count;
    pjmedia_tone_desc	    tones[32];
    pjsua_conf_port_id	    tone_slots[32];
    pjsua_player_id	    wav_id;
    pjsua_conf_port_id	    wav_port;
    pj_bool_t		    auto_play;
    pj_bool_t		    auto_play_hangup;
    pj_timer_entry	    auto_hangup_timer;
    pj_bool_t		    auto_loop;
    pj_bool_t		    auto_conf;
    pj_str_t		    rec_file;
    pj_bool_t		    auto_rec;
    pjsua_recorder_id	    rec_id;
    pjsua_conf_port_id	    rec_port;
    unsigned		    auto_answer;
    unsigned		    duration;
    
    float		    mic_level,
    speaker_level;
    
    int			    capture_dev, playback_dev;
    unsigned		    capture_lat, playback_lat;
    
    pj_bool_t		    no_tones;
    int			    ringback_slot;
    int			    ringback_cnt;
    pjmedia_port	   *ringback_port;
    int			    ring_slot;
    int			    ring_cnt;
    pjmedia_port	   *ring_port;
    
    struct app_vid	    vid;
    unsigned		    aud_cnt;
    
    /* AVI to play */
    unsigned                avi_cnt;
    struct
    {
	pj_str_t		path;
	pjmedia_vid_dev_index	dev_id;
	pjsua_conf_port_id	slot;
    } avi[MAX_AVI];
    pj_bool_t               avi_auto_play;
    int			    avi_def_idx;
} app_config;


#define current_acc	pjsua_acc_get_default()
static pjsua_call_id	current_call = PJSUA_INVALID_ID;
static pj_bool_t	cmd_echo;
static int		stdout_refresh = -1;
static const char      *stdout_refresh_text = "STDOUT_REFRESH";
static pj_bool_t	stdout_refresh_quit = PJ_FALSE;

#if defined(PJMEDIA_HAS_RTCP_XR) && (PJMEDIA_HAS_RTCP_XR != 0)
#   define SOME_BUF_SIZE	(1024 * 10)
#else
#   define SOME_BUF_SIZE	(1024 * 3)
#endif

static char some_buf[SOME_BUF_SIZE];

static pj_status_t create_ipv6_media_transports(void);
pj_status_t app_destroy(void);

static void ringback_start(pjsua_call_id call_id);
static void ring_start(pjsua_call_id call_id);
static void ring_stop(pjsua_call_id call_id);

pj_bool_t 	app_restart;
pj_log_func     *log_cb = NULL;


/*****************************************************************************
 * Configuration manipulation
 */

void keepAliveFunction(int timeout)
{
    int i;
    for (i=0; i<(int)pjsua_acc_get_count(); ++i)
    {
	if (!pjsua_acc_is_valid(i))
        {
	    continue;
        }
        
	if (app_config.acc_cfg[i].reg_timeout < timeout)
        {
	    app_config.acc_cfg[i].reg_timeout = timeout;
        }
        
	pjsua_acc_set_registration(i, PJ_TRUE);
    }
}


//### usable?
void printInfo()
{
    int detail = 1;
    
    pj_dump_config();
    pjsua_dump(detail);
}


/* Set default config. */
static void default_config(struct app_config *cfg)
{
    char        tmp[80];
    unsigned    i;
    
    pjsua_config_default(&cfg->cfg);
    pj_ansi_sprintf(tmp, "PJSUA v%s %s", pj_get_version(), pj_get_sys_info()->info.ptr);
    pj_strdup2_with_null(app_config.pool, &cfg->cfg.user_agent, tmp);
    
    pjsua_logging_config_default(&cfg->log_cfg);
    pjsua_media_config_default(&cfg->media_cfg);
    pjsua_transport_config_default(&cfg->udp_cfg);
    pjsua_transport_config_default(&cfg->rtp_cfg);

    cfg->udp_cfg.port  = 5060;
    cfg->rtp_cfg.port  = 4000;
    cfg->redir_op      = PJSIP_REDIRECT_ACCEPT;
    cfg->duration      = NO_LIMIT;
    cfg->wav_id        = PJSUA_INVALID_ID;
    cfg->rec_id        = PJSUA_INVALID_ID;
    cfg->wav_port      = PJSUA_INVALID_ID;
    cfg->rec_port      = PJSUA_INVALID_ID;
    cfg->mic_level     = cfg->speaker_level = 1.0;
    cfg->capture_dev   = PJSUA_INVALID_ID;
    cfg->playback_dev  = PJSUA_INVALID_ID;
    cfg->capture_lat   = PJMEDIA_SND_DEFAULT_REC_LATENCY;
    cfg->playback_lat  = PJMEDIA_SND_DEFAULT_PLAY_LATENCY;
    cfg->ringback_slot = PJSUA_INVALID_ID;
    cfg->ring_slot     = PJSUA_INVALID_ID;
    
    for (i = 0; i < PJ_ARRAY_SIZE(cfg->acc_cfg); ++i)
    {
	pjsua_acc_config_default(&cfg->acc_cfg[i]);
    }
    
    for (i = 0; i < PJ_ARRAY_SIZE(cfg->buddy_cfg); ++i)
    {
	pjsua_buddy_config_default(&cfg->buddy_cfg[i]);
    }
    
    cfg->vid.vcapture_dev = PJMEDIA_VID_DEFAULT_CAPTURE_DEV;
    cfg->vid.vrender_dev  = PJMEDIA_VID_DEFAULT_RENDER_DEV;
    cfg->aud_cnt          = 1;
    cfg->avi_def_idx      = PJSUA_INVALID_ID;
}


/*
 * Read command arguments from config file.
 */
static int read_config_file(pj_pool_t *pool, const char *filename,
			    int *app_argc, char ***app_argv)
{
    int     i;
    FILE*   fhnd;
    char    line[200];
    int     argc = 0;
    char**  argv;
    enum
    {
        MAX_ARGS = 128
    };
    
    /* Allocate MAX_ARGS+1 (argv needs to be terminated with NULL argument) */
    argv = pj_pool_calloc(pool, MAX_ARGS+1, sizeof(char*));
    argv[argc++] = *app_argv[0];
    
    /* Open config file. */
    fhnd = fopen(filename, "rt");
    if (!fhnd)
    {
	PJ_LOG(1, (THIS_FILE, "Unable to open config file %s", filename));
	fflush(stdout);
	return -1;
    }
    
    /* Scan tokens in the file. */
    while (argc < MAX_ARGS && !feof(fhnd))
    {
	char  *token;
	char  *p;
	const char *whitespace = " \t\r\n";
	char  cDelimiter;
	int   len, token_len;
	
	if (fgets(line, sizeof(line), fhnd) == NULL) break;
	
	// Trim ending newlines
	len = strlen(line);
	if (line[len-1]=='\n')
        {
	    line[--len] = '\0';
        }
        
	if (line[len-1]=='\r')
        {
	    line[--len] = '\0';
        }
        
	if (len==0)
        {
            continue;
        }
        
	for (p = line; *p != '\0' && argc < MAX_ARGS; p++)
        {
	    // first, scan whitespaces
	    while (*p != '\0' && strchr(whitespace, *p) != NULL)
            {
                p++;
            }
            
            // are we done yet?
	    if (*p == '\0')		    
            {
		break;
	    }
            
            // is token a quoted string
	    if (*p == '"' || *p == '\'')
            {
		cDelimiter = *p++;	    // save quote delimiter
		token = p;
		
		while (*p != '\0' && *p != cDelimiter)
                {
                    p++;
                }
		
                // found end of the line,
		if (*p == '\0')
                {
		    cDelimiter = '\0';	// but,didn't find a matching quote
                }
                
	    }
            else
            {
                // token's not a quoted string
		token = p;
		
		while (*p != '\0' && strchr(whitespace, *p) == NULL)
                {
                    p++;
                }
		
		cDelimiter = *p;
	    }
	    
	    *p = '\0';
	    token_len = p-token;
	    
	    if (token_len > 0)
            {
		if (*token == '#')
                {
		    break;  // ignore remainder of line
                }
		
		argv[argc] = pj_pool_alloc(pool, token_len + 1);
		pj_memcpy(argv[argc], token, token_len + 1);
		++argc;
	    }
	    
	    *p = cDelimiter;
	}
    }
    
    /* Copy arguments from command line */
    for (i=1; i<*app_argc && argc < MAX_ARGS; ++i)
    {
	argv[argc++] = (*app_argv)[i];
    }
    
    if (argc == MAX_ARGS && (i!=*app_argc || !feof(fhnd)))
    {
	PJ_LOG(1, (THIS_FILE, "Too many arguments specified in cmd line/config file"));
	fflush(stdout);
	fclose(fhnd);
	return -1;
    }
    
    fclose(fhnd);
    
    /* Assign the new command line back to the original command line. */
    *app_argc = argc;
    *app_argv = argv;
    return 0;
}

    
static int my_atoi(
    const char*     cs)
{
    pj_str_t s;
    
    pj_cstr(&s, cs);
    if (cs[0] == '-')
    {
	s.ptr++;
        s.slen--;
	return 0 - (int)pj_strtoul(&s);
    }
    else if (cs[0] == '+')
    {
	s.ptr++;
        s.slen--;
	return pj_strtoul(&s);
    }
    else
    {
	return pj_strtoul(&s);
    }
}


static pj_status_t parse_args(
    int                 argc,
    char*               argv[],
    struct app_config*  cfg)
{
    int c;
    int option_index;
    
    enum
    {
        OPT_CONFIG_FILE = 127,  OPT_LOG_FILE,           OPT_LOG_LEVEL,          OPT_APP_LOG_LEVEL,
        OPT_LOG_APPEND,         OPT_COLOR,              OPT_NO_COLOR,           OPT_LIGHT_BG,
                                        OPT_NULL_AUDIO,
        OPT_SND_AUTO_CLOSE,     OPT_LOCAL_PORT,         OPT_IP_ADDR,            OPT_PROXY,
        OPT_OUTBOUND_PROXY,     OPT_REGISTRAR,          OPT_REG_TIMEOUT,        OPT_PUBLISH,
        OPT_ID, OPT_CONTACT,    OPT_BOUND_ADDR,         OPT_CONTACT_PARAMS,     OPT_CONTACT_URI_PARAMS,
        OPT_100REL,             OPT_USE_IMS,            OPT_REALM,              OPT_USERNAME,
        OPT_PASSWORD,           OPT_REG_RETRY_INTERVAL, OPT_REG_USE_PROXY,      OPT_MWI,
        OPT_NAMESERVER,         OPT_STUN_SRV,           OPT_OUTB_RID,           OPT_ADD_BUDDY,
        OPT_OFFER_X_MS_MSG,     OPT_NO_PRESENCE,        OPT_AUTO_ANSWER,        OPT_AUTO_PLAY,
        OPT_AUTO_PLAY_HANGUP,   OPT_AUTO_LOOP,          OPT_AUTO_CONF,          OPT_CLOCK_RATE,
        OPT_SND_CLOCK_RATE,                  OPT_USE_ICE,            OPT_ICE_REGULAR,
        OPT_USE_SRTP,           OPT_SRTP_SECURE,        OPT_USE_TURN,           OPT_ICE_MAX_HOSTS,
        OPT_ICE_NO_RTCP,        OPT_TURN_SRV,           OPT_TURN_TCP,           OPT_TURN_USER,
        OPT_TURN_PASSWD,        OPT_PLAY_FILE,          OPT_PLAY_TONE,          OPT_RTP_PORT,
        OPT_ADD_CODEC,          OPT_ILBC_MODE,          OPT_REC_FILE,           OPT_AUTO_REC,
        OPT_COMPLEXITY,         OPT_QUALITY,            OPT_PTIME,              OPT_NO_VAD,
        OPT_RX_DROP_PCT,        OPT_TX_DROP_PCT,        OPT_EC_TAIL,            OPT_EC_OPT,
        OPT_NEXT_ACCOUNT,       OPT_NEXT_CRED,          OPT_MAX_CALLS,          OPT_DURATION,
        OPT_NO_TCP,             OPT_NO_UDP,             OPT_THREAD_CNT,         OPT_NOREFERSUB,
        OPT_ACCEPT_REDIRECT,    OPT_USE_TLS,            OPT_TLS_CA_FILE,        OPT_TLS_CERT_FILE,
        OPT_TLS_PRIV_FILE,      OPT_TLS_PASSWORD,       OPT_TLS_VERIFY_SERVER,  OPT_TLS_VERIFY_CLIENT,
        OPT_TLS_NEG_TIMEOUT,    OPT_TLS_CIPHER,         OPT_CAPTURE_DEV,        OPT_PLAYBACK_DEV,
        OPT_CAPTURE_LAT,        OPT_PLAYBACK_LAT,       OPT_NO_TONES,           OPT_JB_MAX_SIZE,
        OPT_STDOUT_REFRESH,     OPT_STDOUT_REFRESH_TEXT,OPT_IPV6,               OPT_QOS,
        OPT_AUTO_UPDATE_NAT,    OPT_USE_COMPACT_FORM,   OPT_DIS_CODEC,          OPT_NO_FORCE_LR,
        OPT_TIMER,              OPT_TIMER_SE,           OPT_TIMER_MIN_SE,       OPT_VIDEO,
        OPT_EXTRA_AUDIO,        OPT_VCAPTURE_DEV,       OPT_VRENDER_DEV,        OPT_PLAY_AVI,
        OPT_AUTO_PLAY_AVI,
    };
    
    struct pj_getopt_option long_options[] =
    {
	{ "config-file",        1, 0, OPT_CONFIG_FILE},
	{ "log-file",           1, 0, OPT_LOG_FILE},
	{ "log-level",          1, 0, OPT_LOG_LEVEL},
	{ "app-log-level",      1, 0, OPT_APP_LOG_LEVEL},
	{ "log-append",         0, 0, OPT_LOG_APPEND},
	{ "color",              0, 0, OPT_COLOR},
	{ "no-color",           0, 0, OPT_NO_COLOR},
	{ "light-bg",		0, 0, OPT_LIGHT_BG},
	{ "clock-rate",         1, 0, OPT_CLOCK_RATE},
	{ "snd-clock-rate",	1, 0, OPT_SND_CLOCK_RATE},
	{ "null-audio",         0, 0, OPT_NULL_AUDIO},
	{ "local-port",         1, 0, OPT_LOCAL_PORT},
	{ "ip-addr",            1, 0, OPT_IP_ADDR},
	{ "bound-addr",         1, 0, OPT_BOUND_ADDR},
	{ "no-tcp",             0, 0, OPT_NO_TCP},
	{ "no-udp",             0, 0, OPT_NO_UDP},
	{ "norefersub",         0, 0, OPT_NOREFERSUB},
	{ "proxy",              1, 0, OPT_PROXY},
	{ "outbound",           1, 0, OPT_OUTBOUND_PROXY},
	{ "registrar",          1, 0, OPT_REGISTRAR},
	{ "reg-timeout",        1, 0, OPT_REG_TIMEOUT},
	{ "publish",            0, 0, OPT_PUBLISH},
	{ "mwi",                0, 0, OPT_MWI},
	{ "use-100rel",         0, 0, OPT_100REL},
	{ "use-ims",            0, 0, OPT_USE_IMS},
	{ "id",                 1, 0, OPT_ID},
	{ "contact",            1, 0, OPT_CONTACT},
	{ "contact-params",     1, 0, OPT_CONTACT_PARAMS},
	{ "contact-uri-params", 1, 0, OPT_CONTACT_URI_PARAMS},
	{ "auto-update-nat",	1, 0, OPT_AUTO_UPDATE_NAT},
        { "use-compact-form",	0, 0, OPT_USE_COMPACT_FORM},
	{ "accept-redirect",    1, 0, OPT_ACCEPT_REDIRECT},
	{ "no-force-lr",        0, 0, OPT_NO_FORCE_LR},
	{ "realm",              1, 0, OPT_REALM},
	{ "username",           1, 0, OPT_USERNAME},
	{ "password",           1, 0, OPT_PASSWORD},
	{ "rereg-delay",        1, 0, OPT_REG_RETRY_INTERVAL},
	{ "reg-use-proxy",      1, 0, OPT_REG_USE_PROXY},
	{ "nameserver",         1, 0, OPT_NAMESERVER},
	{ "stun-srv",           1, 0, OPT_STUN_SRV},
	{ "add-buddy",          1, 0, OPT_ADD_BUDDY},
	{ "offer-x-ms-msg",     0, 0, OPT_OFFER_X_MS_MSG},
	{ "no-presence",        0, 0, OPT_NO_PRESENCE},
	{ "auto-answer",        1, 0, OPT_AUTO_ANSWER},
	{ "auto-play",          0, 0, OPT_AUTO_PLAY},
	{ "auto-play-hangup",   0, 0, OPT_AUTO_PLAY_HANGUP},
	{ "auto-rec",           0, 0, OPT_AUTO_REC},
	{ "auto-loop",          0, 0, OPT_AUTO_LOOP},
	{ "auto-conf",          0, 0, OPT_AUTO_CONF},
	{ "play-file",          1, 0, OPT_PLAY_FILE},
	{ "play-tone",          1, 0, OPT_PLAY_TONE},
	{ "rec-file",           1, 0, OPT_REC_FILE},
	{ "rtp-port",           1, 0, OPT_RTP_PORT},
        
	{ "use-ice",            0, 0, OPT_USE_ICE},
	{ "ice-regular",        0, 0, OPT_ICE_REGULAR},
	{ "use-turn",           0, 0, OPT_USE_TURN},
	{ "ice-max-hosts",      1, 0, OPT_ICE_MAX_HOSTS},
	{ "ice-no-rtcp",        0, 0, OPT_ICE_NO_RTCP},
	{ "turn-srv",           1, 0, OPT_TURN_SRV},
	{ "turn-tcp",           0, 0, OPT_TURN_TCP},
	{ "turn-user",          1, 0, OPT_TURN_USER},
	{ "turn-passwd",        1, 0, OPT_TURN_PASSWD},
        
#if defined(PJMEDIA_HAS_SRTP) && (PJMEDIA_HAS_SRTP != 0)
	{ "use-srtp",           1, 0, OPT_USE_SRTP},
	{ "srtp-secure",        1, 0, OPT_SRTP_SECURE},
#endif
	{ "add-codec",          1, 0, OPT_ADD_CODEC},
	{ "dis-codec",          1, 0, OPT_DIS_CODEC},
	{ "complexity",         1, 0, OPT_COMPLEXITY},
	{ "quality",            1, 0, OPT_QUALITY},
	{ "ptime",              1, 0, OPT_PTIME},
	{ "no-vad",             0, 0, OPT_NO_VAD},
	{ "ec-tail",            1, 0, OPT_EC_TAIL},
	{ "ec-opt",             1, 0, OPT_EC_OPT},
	{ "ilbc-mode",          1, 0, OPT_ILBC_MODE},
	{ "rx-drop-pct",        1, 0, OPT_RX_DROP_PCT},
	{ "tx-drop-pct",        1, 0, OPT_TX_DROP_PCT},
	{ "next-account",       0, 0, OPT_NEXT_ACCOUNT},
	{ "next-cred",          0, 0, OPT_NEXT_CRED},
	{ "max-calls",          1, 0, OPT_MAX_CALLS},
	{ "duration",           1, 0, OPT_DURATION},
	{ "thread-cnt",         1, 0, OPT_THREAD_CNT},
#if defined(PJSIP_HAS_TLS_TRANSPORT) && (PJSIP_HAS_TLS_TRANSPORT != 0)
	{ "use-tls",            0, 0, OPT_USE_TLS},
	{ "tls-ca-file",        1, 0, OPT_TLS_CA_FILE},
	{ "tls-cert-file",      1, 0, OPT_TLS_CERT_FILE},
	{ "tls-privkey-file",   1, 0, OPT_TLS_PRIV_FILE},
	{ "tls-password",       1, 0, OPT_TLS_PASSWORD},
	{ "tls-verify-server",  0, 0, OPT_TLS_VERIFY_SERVER},
	{ "tls-verify-client",  0, 0, OPT_TLS_VERIFY_CLIENT},
	{ "tls-neg-timeout",    1, 0, OPT_TLS_NEG_TIMEOUT},
	{ "tls-cipher",         1, 0, OPT_TLS_CIPHER},
#endif
	{ "capture-dev",        1, 0, OPT_CAPTURE_DEV},
	{ "playback-dev",       1, 0, OPT_PLAYBACK_DEV},
	{ "capture-lat",        1, 0, OPT_CAPTURE_LAT},
	{ "playback-lat",       1, 0, OPT_PLAYBACK_LAT},
	{ "stdout-refresh",     1, 0, OPT_STDOUT_REFRESH},
	{ "stdout-refresh-text",1, 0, OPT_STDOUT_REFRESH_TEXT},
	{ "snd-auto-close",     1, 0, OPT_SND_AUTO_CLOSE},
	{ "no-tones",           0, 0, OPT_NO_TONES},
	{ "jb-max-size",        1, 0, OPT_JB_MAX_SIZE},
#if defined(PJ_HAS_IPV6) && PJ_HAS_IPV6
	{ "ipv6",               0, 0, OPT_IPV6},
#endif
	{ "set-qos",            0, 0, OPT_QOS},
	{ "use-timer",          1, 0, OPT_TIMER},
	{ "timer-se",           1, 0, OPT_TIMER_SE},
	{ "timer-min-se",       1, 0, OPT_TIMER_MIN_SE},
	{ "outb-rid",           1, 0, OPT_OUTB_RID},
	{ "video",              0, 0, OPT_VIDEO},
	{ "extra-audio",        0, 0, OPT_EXTRA_AUDIO},
	{ "vcapture-dev",       1, 0, OPT_VCAPTURE_DEV},
	{ "vrender-dev",        1, 0, OPT_VRENDER_DEV},
	{ "play-avi",           1, 0, OPT_PLAY_AVI},
	{ "auto-play-avi",      0, 0, OPT_AUTO_PLAY_AVI},
	{ NULL,                 0, 0, 0}
    };
    
    pj_status_t         status;
    pjsua_acc_config*   cur_acc;
    char*               config_file = NULL;
    unsigned            i;
    
    /* Run pj_getopt once to see if user specifies config file to read. */
    pj_optind = 0;
    while ((c = pj_getopt_long(argc, argv, "", long_options, &option_index)) != -1)
    {
	switch (c)
        {
            case OPT_CONFIG_FILE:
                config_file = pj_optarg;
                break;
	}
        
	if (config_file)
        {
	    break;
        }
    }
    
    if (config_file)
    {
	status = read_config_file(app_config.pool, config_file, &argc, &argv);
	if (status != 0)
        {
	    return status;
        }
    }
    
    cfg->acc_cnt = 0;
    cur_acc = &cfg->acc_cfg[0];
    
    /* Reinitialize and re-run pj_getopt again, possibly with new arguments
     * read from config file.
     */
    pj_optind = 0;
    while((c = pj_getopt_long(argc,argv, "", long_options,&option_index)) != -1)
    {
	pj_str_t    tmp;
	long        lval;
        
	switch (c)
        {
            case OPT_CONFIG_FILE:
                /* Ignore as this has been processed before */
                break;
                
            case OPT_LOG_FILE:
                cfg->log_cfg.log_filename = pj_str(pj_optarg);
                break;
                
            case OPT_LOG_LEVEL:
                c = pj_strtoul(pj_cstr(&tmp, pj_optarg));
                if (c < 0 || c > 6)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: expecting integer value 0-6 for --log-level"));
                    
                    return PJ_EINVAL;
                }
                
                cfg->log_cfg.level = c;
                pj_log_set_level( c );
                break;
                
            case OPT_APP_LOG_LEVEL:
                if (pj_strtoul(pj_cstr(&tmp, pj_optarg)) < 0 || pj_strtoul(pj_cstr(&tmp, pj_optarg)) > 6)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: expecting integer value 0-6 for --app-log-level"));
                    
                    return PJ_EINVAL;
                }
                cfg->log_cfg.console_level = pj_strtoul(pj_cstr(&tmp, pj_optarg));
                break;
                
            case OPT_LOG_APPEND:
                cfg->log_cfg.log_file_flags |= PJ_O_APPEND;
                break;
                
            case OPT_COLOR:
                cfg->log_cfg.decor |= PJ_LOG_HAS_COLOR;
                break;
                
            case OPT_NO_COLOR:
                cfg->log_cfg.decor &= ~PJ_LOG_HAS_COLOR;
                break;
                
            case OPT_LIGHT_BG:
                pj_log_set_color(1, PJ_TERM_COLOR_R);
                pj_log_set_color(2, PJ_TERM_COLOR_R | PJ_TERM_COLOR_G);
                pj_log_set_color(3, PJ_TERM_COLOR_B | PJ_TERM_COLOR_G);
                pj_log_set_color(4, 0);
                pj_log_set_color(5, 0);
                pj_log_set_color(77, 0);
                break;
                
            case OPT_NULL_AUDIO:
                cfg->null_audio = PJ_TRUE;
                break;
                
            case OPT_CLOCK_RATE:
                lval = pj_strtoul(pj_cstr(&tmp, pj_optarg));
                if (lval < 8000 || lval > 192000)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: expecting value between 8000-192000 for conference clock rate"));
                    
                    return PJ_EINVAL;
                }
                
                cfg->media_cfg.clock_rate = lval;
                break;
                
            case OPT_SND_CLOCK_RATE:
                lval = pj_strtoul(pj_cstr(&tmp, pj_optarg));
                if (lval < 8000 || lval > 192000)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: expecting value between 8000-192000 for sound device clock rate"));
                    
                    return PJ_EINVAL;
                }
                
                cfg->media_cfg.snd_clock_rate = lval;
                break;
                
            case OPT_LOCAL_PORT:   /* local-port */
                lval = pj_strtoul(pj_cstr(&tmp, pj_optarg));
                if (lval < 0 || lval > 65535)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: expecting integer value for --local-port"));
                    
                    return PJ_EINVAL;
                }
                
                cfg->udp_cfg.port = (pj_uint16_t)lval;
                break;
                
            case OPT_IP_ADDR: /* ip-addr */
                cfg->udp_cfg.public_addr = pj_str(pj_optarg);
                cfg->rtp_cfg.public_addr = pj_str(pj_optarg);
                break;
                
            case OPT_BOUND_ADDR: /* bound-addr */
                cfg->udp_cfg.bound_addr = pj_str(pj_optarg);
                cfg->rtp_cfg.bound_addr = pj_str(pj_optarg);
                break;
                
            case OPT_NO_UDP: /* no-udp */
                if (cfg->no_tcp)
                {
                    PJ_LOG(1, (THIS_FILE,"Error: can not disable both TCP and UDP"));
                    
                    return PJ_EINVAL;
                }
                
                cfg->no_udp = PJ_TRUE;
                break;
                
            case OPT_NOREFERSUB: /* norefersub */
                cfg->no_refersub = PJ_TRUE;
                break;
                
            case OPT_NO_TCP: /* no-tcp */
                if (cfg->no_udp)
                {
                    PJ_LOG(1, (THIS_FILE,"Error: can not disable both TCP and UDP"));
                    return PJ_EINVAL;
                }
                
                cfg->no_tcp = PJ_TRUE;
                break;
                
            case OPT_PROXY:   /* proxy */
                if (pjsua_verify_sip_url(pj_optarg) != 0)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: invalid SIP URL '%s' in proxy argument", pj_optarg));
                    
                    return PJ_EINVAL;
                }
                
                cur_acc->proxy[cur_acc->proxy_cnt++] = pj_str(pj_optarg);
                break;
                
            case OPT_OUTBOUND_PROXY:   /* outbound proxy */
                if (pjsua_verify_sip_url(pj_optarg) != 0)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: invalid SIP URL '%s' in outbound proxy argument", pj_optarg));
                   
                    return PJ_EINVAL;
                }
                
                cfg->cfg.outbound_proxy[cfg->cfg.outbound_proxy_cnt++] = pj_str(pj_optarg);
                break;
                
            case OPT_REGISTRAR:   /* registrar */
                if (pjsua_verify_sip_url(pj_optarg) != 0)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: invalid SIP URL '%s' in registrar argument", pj_optarg));
                    
                    return PJ_EINVAL;
                }
                
                cur_acc->reg_uri = pj_str(pj_optarg);
                break;
                
            case OPT_REG_TIMEOUT:   /* reg-timeout */
                cur_acc->reg_timeout = pj_strtoul(pj_cstr(&tmp,pj_optarg));
                if (cur_acc->reg_timeout < 1 || cur_acc->reg_timeout > 3600)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: invalid value for --reg-timeout (expecting 1-3600)"));
                    
                    return PJ_EINVAL;
                }
                break;
                
            case OPT_PUBLISH:   /* publish */
                cur_acc->publish_enabled = PJ_TRUE;
                break;
                
            case OPT_MWI:	/* mwi */
                cur_acc->mwi_enabled = PJ_TRUE;
                break;
                
            case OPT_100REL: /** 100rel */
                cur_acc->require_100rel = PJSUA_100REL_MANDATORY;
                cfg->cfg.require_100rel = PJSUA_100REL_MANDATORY;
                break;
                
            case OPT_TIMER: /** session timer */
                lval = pj_strtoul(pj_cstr(&tmp, pj_optarg));
                if (lval < 0 || lval > 3)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: expecting integer value 0-3 for --use-timer"));
                    
                    return PJ_EINVAL;
                }
                
                cur_acc->use_timer = lval;
                cfg->cfg.use_timer = lval;
                break;
                
            case OPT_TIMER_SE: /** session timer session expiration */
                cur_acc->timer_setting.sess_expires = pj_strtoul(pj_cstr(&tmp, pj_optarg));
                if (cur_acc->timer_setting.sess_expires < 90)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: invalid value for --timer-se (expecting higher than 90)"));
                    
                    return PJ_EINVAL;
                }
                
                cfg->cfg.timer_setting.sess_expires = cur_acc->timer_setting.sess_expires;
                break;
                
            case OPT_TIMER_MIN_SE: /** session timer minimum session expiration */
                cur_acc->timer_setting.min_se = pj_strtoul(pj_cstr(&tmp, pj_optarg));
                if (cur_acc->timer_setting.min_se < 90)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: invalid value for --timer-min-se (expecting higher than 90)"));
                    
                    return PJ_EINVAL;
                }
                
                cfg->cfg.timer_setting.min_se = cur_acc->timer_setting.min_se;
                break;
                
            case OPT_OUTB_RID: /* Outbound reg-id */
                cur_acc->rfc5626_reg_id = pj_str(pj_optarg);
                break;
                
            case OPT_USE_IMS: /* Activate IMS settings */
                cur_acc->auth_pref.initial_auth = PJ_TRUE;
                break;
                
            case OPT_ID:   /* id */
                if (pjsua_verify_url(pj_optarg) != 0) {
                    PJ_LOG(1, (THIS_FILE,
                              "Error: invalid SIP URL '%s' "
                              "in local id argument", pj_optarg));
                    return PJ_EINVAL;
                }
                cur_acc->id = pj_str(pj_optarg);
                break;
                
            case OPT_CONTACT:   /* contact */
                if (pjsua_verify_sip_url(pj_optarg) != 0) {
                    PJ_LOG(1, (THIS_FILE,
                              "Error: invalid SIP URL '%s' "
                              "in contact argument", pj_optarg));
                    return PJ_EINVAL;
                }
                cur_acc->force_contact = pj_str(pj_optarg);
                break;
                
            case OPT_CONTACT_PARAMS:
                cur_acc->contact_params = pj_str(pj_optarg);
                break;
                
            case OPT_CONTACT_URI_PARAMS:
                cur_acc->contact_uri_params = pj_str(pj_optarg);
                break;
                
            case OPT_AUTO_UPDATE_NAT:   /* OPT_AUTO_UPDATE_NAT */
                cur_acc->allow_contact_rewrite  = pj_strtoul(pj_cstr(&tmp, pj_optarg));
                break;
                
            case OPT_USE_COMPACT_FORM:
                /* enable compact form - from Ticket #342 */
                {
                    extern pj_bool_t pjsip_use_compact_form;
                    extern pj_bool_t pjsip_include_allow_hdr_in_dlg;
                    extern pj_bool_t pjmedia_add_rtpmap_for_static_pt;
                    
                    pjsip_use_compact_form = PJ_TRUE;
                    /* do not transmit Allow header */
                    pjsip_include_allow_hdr_in_dlg = PJ_FALSE;
                    /* Do not include rtpmap for static payload types (<96) */
                    pjmedia_add_rtpmap_for_static_pt = PJ_FALSE;
                }
                break;
                
            case OPT_ACCEPT_REDIRECT:
                cfg->redir_op = my_atoi(pj_optarg);
                if (cfg->redir_op<0 || cfg->redir_op>PJSIP_REDIRECT_STOP)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: accept-redirect value '%s' ", pj_optarg));
                    
                    return PJ_EINVAL;
                }
                break;
                
            case OPT_NO_FORCE_LR:
                cfg->cfg.force_lr = PJ_FALSE;
                break;
                
            case OPT_NEXT_ACCOUNT: /* Add more account. */
                cfg->acc_cnt++;
                cur_acc = &cfg->acc_cfg[cfg->acc_cnt];
                break;
                
            case OPT_USERNAME:   /* Default authentication user */
                cur_acc->cred_info[cur_acc->cred_count].username = pj_str(pj_optarg);
                cur_acc->cred_info[cur_acc->cred_count].scheme   = pj_str("Digest");
                break;
                
            case OPT_REALM:	    /* Default authentication realm. */
                cur_acc->cred_info[cur_acc->cred_count].realm = pj_str(pj_optarg);
                break;
                
            case OPT_PASSWORD:   /* authentication password */
                cur_acc->cred_info[cur_acc->cred_count].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
                cur_acc->cred_info[cur_acc->cred_count].data = pj_str(pj_optarg);
#if PJSIP_HAS_DIGEST_AKA_AUTH
                cur_acc->cred_info[cur_acc->cred_count].data_type |= PJSIP_CRED_DATA_EXT_AKA;
                cur_acc->cred_info[cur_acc->cred_count].ext.aka.k = pj_str(pj_optarg);
                cur_acc->cred_info[cur_acc->cred_count].ext.aka.cb = &pjsip_auth_create_aka_response;
#endif
                break;
                
            case OPT_REG_RETRY_INTERVAL:
                cur_acc->reg_retry_interval = pj_strtoul(pj_cstr(&tmp, pj_optarg));
                break;
                
            case OPT_REG_USE_PROXY:
                cur_acc->reg_use_proxy = (unsigned)pj_strtoul(pj_cstr(&tmp, pj_optarg));
                if (cur_acc->reg_use_proxy > 3)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: invalid --reg-use-proxy value '%s'", pj_optarg));
                    
                    return PJ_EINVAL;
                }
                break;
                
            case OPT_NEXT_CRED: /* next credential */
                cur_acc->cred_count++;
                break;
                
            case OPT_NAMESERVER: /* nameserver */
                cfg->cfg.nameserver[cfg->cfg.nameserver_count++] = pj_str(pj_optarg);
                if (cfg->cfg.nameserver_count > PJ_ARRAY_SIZE(cfg->cfg.nameserver))
                {
                    PJ_LOG(1, (THIS_FILE, "Error: too many nameservers"));
                    
                    return PJ_ETOOMANY;
                }
                break;
                
            case OPT_STUN_SRV:   /* STUN server */
                cfg->cfg.stun_host = pj_str(pj_optarg);
                if (cfg->cfg.stun_srv_cnt==PJ_ARRAY_SIZE(cfg->cfg.stun_srv))
                {
                    PJ_LOG(1, (THIS_FILE, "Error: too many STUN servers"));
                    return PJ_ETOOMANY;
                }
                
                cfg->cfg.stun_srv[cfg->cfg.stun_srv_cnt++] = pj_str(pj_optarg);
                break;
                
            case OPT_ADD_BUDDY: /* Add to buddy list. */
                if (pjsua_verify_url(pj_optarg) != 0)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: invalid URL '%s' in --add-buddy option", pj_optarg));
                    
                    return -1;
                }
                
                if (cfg->buddy_cnt == PJ_ARRAY_SIZE(cfg->buddy_cfg))
                {
                    PJ_LOG(1, (THIS_FILE, "Error: too many buddies in buddy list."));
                    
                    return -1;
                }
                
                cfg->buddy_cfg[cfg->buddy_cnt].uri = pj_str(pj_optarg);
                cfg->buddy_cnt++;
                break;
                
            case OPT_AUTO_PLAY:
                cfg->auto_play = 1;
                break;
                
            case OPT_AUTO_PLAY_HANGUP:
                cfg->auto_play_hangup = 1;
                break;
                
            case OPT_AUTO_REC:
                cfg->auto_rec = 1;
                break;
                
            case OPT_AUTO_LOOP:
                cfg->auto_loop = 1;
                break;
                
            case OPT_AUTO_CONF:
                cfg->auto_conf = 1;
                break;
                
            case OPT_PLAY_FILE:
                cfg->wav_files[cfg->wav_count++] = pj_str(pj_optarg);
                break;
                
            case OPT_PLAY_TONE:
                {
                    int f1, f2, on, off;
                    int n;
                    
                    n = sscanf(pj_optarg, "%d,%d,%d,%d", &f1, &f2, &on, &off);
                    if (n != 4)
                    {
                        puts("Expecting f1,f2,on,off in --play-tone");
                        
                        return -1;
                    }
                    
                    cfg->tones[cfg->tone_count].freq1    = (short)f1;
                    cfg->tones[cfg->tone_count].freq2    = (short)f2;
                    cfg->tones[cfg->tone_count].on_msec  = (short)on;
                    cfg->tones[cfg->tone_count].off_msec = (short)off;
                    ++cfg->tone_count;
                }
                break;
                
            case OPT_REC_FILE:
                cfg->rec_file = pj_str(pj_optarg);
                break;
                
            case OPT_USE_ICE:
                cfg->media_cfg.enable_ice = PJ_TRUE;
                break;
                
            case OPT_ICE_REGULAR:
                cfg->media_cfg.ice_opt.aggressive = PJ_FALSE;
                break;
                
            case OPT_USE_TURN:
                cfg->media_cfg.enable_turn = PJ_TRUE;
                break;
                
            case OPT_ICE_MAX_HOSTS:
                cfg->media_cfg.ice_max_host_cands = my_atoi(pj_optarg);
                break;
                
            case OPT_ICE_NO_RTCP:
                cfg->media_cfg.ice_no_rtcp = PJ_TRUE;
                break;
                
            case OPT_TURN_SRV:
                cfg->media_cfg.turn_server = pj_str(pj_optarg);
                break;
                
            case OPT_TURN_TCP:
                cfg->media_cfg.turn_conn_type = PJ_TURN_TP_TCP;
                break;
                
            case OPT_TURN_USER:
                cfg->media_cfg.turn_auth_cred.type = PJ_STUN_AUTH_CRED_STATIC;
                cfg->media_cfg.turn_auth_cred.data.static_cred.realm = pj_str("*");
                cfg->media_cfg.turn_auth_cred.data.static_cred.username = pj_str(pj_optarg);
                break;
                
            case OPT_TURN_PASSWD:
                cfg->media_cfg.turn_auth_cred.data.static_cred.data_type = PJ_STUN_PASSWD_PLAIN;
                cfg->media_cfg.turn_auth_cred.data.static_cred.data = pj_str(pj_optarg);
                break;
                
#if defined(PJMEDIA_HAS_SRTP) && (PJMEDIA_HAS_SRTP != 0)
            case OPT_USE_SRTP:
                app_config.cfg.use_srtp = my_atoi(pj_optarg);
                if (!pj_isdigit(*pj_optarg) || app_config.cfg.use_srtp > 3)
                {
                    PJ_LOG(1, (THIS_FILE, "Invalid value for --use-srtp option"));
                    
                    return -1;
                }
                
                if ((int)app_config.cfg.use_srtp == 3)
                {
                    /* SRTP optional mode with duplicated media offer */
                    app_config.cfg.use_srtp = PJMEDIA_SRTP_OPTIONAL;
                    app_config.cfg.srtp_optional_dup_offer = PJ_TRUE;
                    cur_acc->srtp_optional_dup_offer = PJ_TRUE;
                }
                
                cur_acc->use_srtp = app_config.cfg.use_srtp;
                break;
                
            case OPT_SRTP_SECURE:
                app_config.cfg.srtp_secure_signaling = my_atoi(pj_optarg);
                if (!pj_isdigit(*pj_optarg) || app_config.cfg.srtp_secure_signaling > 2)
                {
                    PJ_LOG(1, (THIS_FILE, "Invalid value for --srtp-secure option"));
                    
                    return -1;
                }
                
                cur_acc->srtp_secure_signaling = app_config.cfg.srtp_secure_signaling;
                break;
#endif
                
            case OPT_RTP_PORT:
                cfg->rtp_cfg.port = my_atoi(pj_optarg);
                if (cfg->rtp_cfg.port == 0)
                {
                    enum
                    {
                        START_PORT = 4000
                    };
                    unsigned range;
                    
                    range = (65535 - START_PORT - PJSUA_MAX_CALLS * 2);
                    cfg->rtp_cfg.port = START_PORT + ((pj_rand() % range) & 0xFFFE);
                }
                
                if (cfg->rtp_cfg.port < 1 || cfg->rtp_cfg.port > 65535)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: rtp-port argument value (expecting 1-65535"));
                     
                    return -1;
                }
                break;
                
            case OPT_DIS_CODEC:
                cfg->codec_dis[cfg->codec_dis_cnt++] = pj_str(pj_optarg);
                break;
                
            case OPT_ADD_CODEC:
                cfg->codec_arg[cfg->codec_cnt++] = pj_str(pj_optarg);
                break;
                
            case OPT_DURATION:
                cfg->duration = my_atoi(pj_optarg);
                break;
                
            case OPT_THREAD_CNT:
                cfg->cfg.thread_cnt = my_atoi(pj_optarg);
                if (cfg->cfg.thread_cnt > 128)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: invalid --thread-cnt option"));
                    
                    return -1;
                }
                break;
                
            case OPT_PTIME:
                cfg->media_cfg.ptime = my_atoi(pj_optarg);
                if (cfg->media_cfg.ptime < 10 || cfg->media_cfg.ptime > 1000)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: invalid --ptime option"));
                    
                    return -1;
                }
                break;
                
            case OPT_NO_VAD:
                cfg->media_cfg.no_vad = PJ_TRUE;
                break;
                
            case OPT_EC_TAIL:
                cfg->media_cfg.ec_tail_len = my_atoi(pj_optarg);
                if (cfg->media_cfg.ec_tail_len > 1000)
                {
                    PJ_LOG(1, (THIS_FILE, "I think the ec-tail length setting is too big"));
                    
                    return -1;
                }
                break;
                
            case OPT_EC_OPT:
                cfg->media_cfg.ec_options = my_atoi(pj_optarg);
                break;
                
            case OPT_QUALITY:
                if (my_atoi(pj_optarg) < 0 || my_atoi(pj_optarg) > 10)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: invalid --quality (expecting 0-10"));
                    
                    return -1;
                }
                cfg->media_cfg.quality = my_atoi(pj_optarg);
                break;
                
            case OPT_ILBC_MODE:
                cfg->media_cfg.ilbc_mode = my_atoi(pj_optarg);
                if (cfg->media_cfg.ilbc_mode != 20 && cfg->media_cfg.ilbc_mode != 30)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: invalid --ilbc-mode (expecting 20 or 30"));
                    
                    return -1;
                }
                break;
                
            case OPT_RX_DROP_PCT:
                cfg->media_cfg.rx_drop_pct = my_atoi(pj_optarg);
                if (cfg->media_cfg.rx_drop_pct > 100)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: invalid --rx-drop-pct (expecting <= 100"));
                    
                    return -1;
                }
                break;
                
            case OPT_TX_DROP_PCT:
                cfg->media_cfg.tx_drop_pct = my_atoi(pj_optarg);
                if (cfg->media_cfg.tx_drop_pct > 100)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: invalid --tx-drop-pct (expecting <= 100"));
                    
                    return -1;
                }
                break;
                
            case OPT_AUTO_ANSWER:
                cfg->auto_answer = my_atoi(pj_optarg);
                if (cfg->auto_answer < 100 || cfg->auto_answer > 699)
                {
                    PJ_LOG(1, (THIS_FILE, "Error: invalid code in --auto-answer (expecting 100-699"));
                   
                    return -1;
                }
                break;
                
            case OPT_MAX_CALLS:
                cfg->cfg.max_calls = my_atoi(pj_optarg);
                if (cfg->cfg.max_calls < 1 || cfg->cfg.max_calls > PJSUA_MAX_CALLS)
                {
                    PJ_LOG(1, (THIS_FILE,"Error: maximum call setting exceeds compile time limit (PJSUA_MAX_CALLS=%d)", PJSUA_MAX_CALLS));
                    
                    return -1;
                }
                break;
                
#if defined(PJSIP_HAS_TLS_TRANSPORT) && (PJSIP_HAS_TLS_TRANSPORT != 0)
            case OPT_USE_TLS:
                cfg->use_tls = PJ_TRUE;
                break;
                
            case OPT_TLS_CA_FILE:
                cfg->udp_cfg.tls_setting.ca_list_file = pj_str(pj_optarg);
                break;
                
            case OPT_TLS_CERT_FILE:
                cfg->udp_cfg.tls_setting.cert_file = pj_str(pj_optarg);
                break;
                
            case OPT_TLS_PRIV_FILE:
                cfg->udp_cfg.tls_setting.privkey_file = pj_str(pj_optarg);
                break;
                
            case OPT_TLS_PASSWORD:
                cfg->udp_cfg.tls_setting.password = pj_str(pj_optarg);
                break;
                
            case OPT_TLS_VERIFY_SERVER:
                cfg->udp_cfg.tls_setting.verify_server = PJ_TRUE;
                break;
                
            case OPT_TLS_VERIFY_CLIENT:
                cfg->udp_cfg.tls_setting.verify_client = PJ_TRUE;
                cfg->udp_cfg.tls_setting.require_client_cert = PJ_TRUE;
                break;
                
            case OPT_TLS_NEG_TIMEOUT:
                cfg->udp_cfg.tls_setting.timeout.sec = atoi(pj_optarg);
                break;
                
            case OPT_TLS_CIPHER:
                {
                    pj_ssl_cipher cipher;
                    
                    if (pj_ansi_strnicmp(pj_optarg, "0x", 2) == 0)
                    {
                        pj_str_t cipher_st = pj_str(pj_optarg + 2);
                        cipher = pj_strtoul2(&cipher_st, NULL, 16);
                    }
                    else
                    {
                        cipher = atoi(pj_optarg);
                    }
                    
                    if (pj_ssl_cipher_is_supported(cipher))
                    {
                        static pj_ssl_cipher tls_ciphers[128];
                        
                        tls_ciphers[cfg->udp_cfg.tls_setting.ciphers_num++] = cipher;
                        cfg->udp_cfg.tls_setting.ciphers = tls_ciphers;
                    }
                    else
                    {
                        pj_ssl_cipher   ciphers[128];
                        unsigned        j;
                        unsigned        ciphers_cnt;
                        
                        ciphers_cnt = PJ_ARRAY_SIZE(ciphers);
                        pj_ssl_cipher_get_availables(ciphers, &ciphers_cnt);
                        
                        PJ_LOG(1, (THIS_FILE, "Cipher \"%s\" is not supported by TLS/SSL backend.", pj_optarg));
                        printf("Available TLS/SSL ciphers (%d):\n", ciphers_cnt);
                        for (j=0; j<ciphers_cnt; ++j)
                        {
                            printf("- 0x%06X: %s\n", ciphers[j], pj_ssl_cipher_name(ciphers[j]));
                        }
                        
                        return -1;
                    }
                }
                break;
#endif /* PJSIP_HAS_TLS_TRANSPORT */
                
            case OPT_CAPTURE_DEV:
                cfg->capture_dev = atoi(pj_optarg);
                break;
                
            case OPT_PLAYBACK_DEV:
                cfg->playback_dev = atoi(pj_optarg);
                break;
                
            case OPT_STDOUT_REFRESH:
                stdout_refresh = atoi(pj_optarg);
                break;
                
            case OPT_STDOUT_REFRESH_TEXT:
                stdout_refresh_text = pj_optarg;
                break;
                                
            case OPT_CAPTURE_LAT:
                cfg->capture_lat = atoi(pj_optarg);
                break;
                
            case OPT_PLAYBACK_LAT:
                cfg->playback_lat = atoi(pj_optarg);
                break;
                
            case OPT_SND_AUTO_CLOSE:
                cfg->media_cfg.snd_auto_close_time = atoi(pj_optarg);
                break;
                
            case OPT_NO_TONES:
                cfg->no_tones = PJ_TRUE;
                break;
                
            case OPT_JB_MAX_SIZE:
                cfg->media_cfg.jb_max = atoi(pj_optarg);
                break;
                
#if defined(PJ_HAS_IPV6) && PJ_HAS_IPV6
            case OPT_IPV6:
                cfg->ipv6 = PJ_TRUE;
                break;
#endif
            case OPT_QOS:
                cfg->enable_qos = PJ_TRUE;
                /* Set RTP traffic type to Voice */
                cfg->rtp_cfg.qos_type = PJ_QOS_TYPE_VOICE;
                /* Directly apply DSCP value to SIP traffic. Say lets
                 * set it to CS3 (DSCP 011000). Note that this will not
                 * work on all platforms.
                 */
                cfg->udp_cfg.qos_params.flags = PJ_QOS_PARAM_HAS_DSCP;
                cfg->udp_cfg.qos_params.dscp_val = 0x18;
                break;
                
            case OPT_VIDEO:
                cfg->vid.vid_cnt = 1;
                cfg->vid.in_auto_show = PJ_TRUE;
                cfg->vid.out_auto_transmit = PJ_TRUE;
                break;
                
            case OPT_EXTRA_AUDIO:
                cfg->aud_cnt++;
                break;
                
            case OPT_VCAPTURE_DEV:
                cfg->vid.vcapture_dev = atoi(pj_optarg);
                cur_acc->vid_cap_dev = cfg->vid.vcapture_dev;
                break;
                
            case OPT_VRENDER_DEV:
                cfg->vid.vrender_dev = atoi(pj_optarg);
                cur_acc->vid_rend_dev = cfg->vid.vrender_dev;
                break;
                
            case OPT_PLAY_AVI:
                if (app_config.avi_cnt >= MAX_AVI)
                {
                    PJ_LOG(1, (THIS_FILE, "Too many AVIs"));
                    
                    return -1;
                }
                
                app_config.avi[app_config.avi_cnt++].path = pj_str(pj_optarg);
                break;
                
            case OPT_AUTO_PLAY_AVI:
                app_config.avi_auto_play = PJ_TRUE;
                break;
                
            default:
                PJ_LOG(1, (THIS_FILE, "Argument \"%s\" is not valid. Use --help to see help", argv[pj_optind - 1]));
                
                return -1;
	}
    }
    
    if (pj_optind != argc)
    {
	PJ_LOG(1, (THIS_FILE, "Error: unknown options %s", argv[pj_optind]));
        
	return PJ_EINVAL;
    }
    
    if (cfg->acc_cfg[cfg->acc_cnt].id.slen)
    {
	cfg->acc_cnt++;
    }
    
    for (i = 0; i < cfg->acc_cnt; ++i)
    {
	pjsua_acc_config*   acfg = &cfg->acc_cfg[i];
        
	if (acfg->cred_info[acfg->cred_count].username.slen)
	{
	    acfg->cred_count++;
	}
        
	/* When IMS mode is enabled for the account, verify that settings
	 * are okay.
	 */
	/* For now we check if IMS mode is activated by looking if
	 * initial_auth is set.
	 */
	if (acfg->auth_pref.initial_auth && acfg->cred_count)
        {
	    /* Realm must point to the real domain */
	    if (*acfg->cred_info[0].realm.ptr=='*')
            {
		PJ_LOG(1, (THIS_FILE, "Error: cannot use '*' as realm with IMS"));
	
                return PJ_EINVAL;
	    }
            
	    /* Username for authentication must be in a@b format */
	    if (strchr(acfg->cred_info[0].username.ptr, '@') == 0)
            {
		PJ_LOG(1, (THIS_FILE, "Error: Username for authentication must be in user@domain format with IMS"));
		
                return PJ_EINVAL;
	    }
	}
    }
    
    return PJ_SUCCESS;
}


/*
 * Print log of call states. Since call states may be too long for logger,
 * printing it is a bit tricky, it should be printed part by part as long
 * as the logger can accept.
 */
static void log_call_dump(int call_id)
{
    unsigned call_dump_len;
    unsigned part_len;
    unsigned part_idx;
    unsigned log_decor;
    
    pjsua_call_dump(call_id, PJ_TRUE, some_buf,
		    sizeof(some_buf), "  ");
    call_dump_len = strlen(some_buf);
    
    log_decor = pj_log_get_decor();
    pj_log_set_decor(log_decor & ~(PJ_LOG_HAS_NEWLINE | PJ_LOG_HAS_CR));
    PJ_LOG(3,(THIS_FILE, "\n"));
    pj_log_set_decor(0);
    
    part_idx = 0;
    part_len = PJ_LOG_MAX_SIZE-80;
    while (part_idx < call_dump_len)
    {
	char    p_orig;
        char*   p;
        
	p = &some_buf[part_idx];
	if (part_idx + part_len > call_dump_len)
        {
	    part_len = call_dump_len - part_idx;
        }
        
	p_orig = p[part_len];
	p[part_len] = '\0';
	PJ_LOG(3,(THIS_FILE, "%s", p));
	p[part_len] = p_orig;
	part_idx += part_len;
    }
    
    pj_log_set_decor(log_decor);
}


/*****************************************************************************
 * Console application
 */

static void ringback_start(pjsua_call_id call_id)
{
    if (app_config.no_tones || app_config.call_data[call_id].ringback_on)
    {
	return;
    }
    
    app_config.call_data[call_id].ringback_on = PJ_TRUE;
    
    if (++app_config.ringback_cnt==1 && app_config.ringback_slot!=PJSUA_INVALID_ID)
    {
	pjsua_conf_connect(app_config.ringback_slot, 0);
    }
}


static void ring_stop(pjsua_call_id call_id)
{
    if (app_config.no_tones)
    {
	return;
    }
    
    if (app_config.call_data[call_id].ringback_on)
    {
	app_config.call_data[call_id].ringback_on = PJ_FALSE;
        
	pj_assert(app_config.ringback_cnt > 0);
        
	if (--app_config.ringback_cnt == 0 && app_config.ringback_slot!=PJSUA_INVALID_ID)
	{
	    pjsua_conf_disconnect(app_config.ringback_slot, 0);
	    pjmedia_tonegen_rewind(app_config.ringback_port);
	}
    }
    
    if (app_config.call_data[call_id].ring_on)
    {
	app_config.call_data[call_id].ring_on = PJ_FALSE;
        
	pj_assert(app_config.ring_cnt>0);
	if (--app_config.ring_cnt == 0 && app_config.ring_slot!=PJSUA_INVALID_ID)
	{
	    pjsua_conf_disconnect(app_config.ring_slot, 0);
	    pjmedia_tonegen_rewind(app_config.ring_port);
	}
    }
}


static void ring_start(pjsua_call_id call_id)
{
    if (app_config.no_tones || app_config.call_data[call_id].ring_on)
    {
	return;
    }
    
    app_config.call_data[call_id].ring_on = PJ_TRUE;
    
    if (++app_config.ring_cnt==1 &&
	app_config.ring_slot!=PJSUA_INVALID_ID)
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
        
	/* Dump media state upon disconnected */
	if (1)
        {
	    PJ_LOG(5, (THIS_FILE, "Call %d disconnected, dumping media stats..", call_id));
	    log_call_dump(call_id);
	}
    }
    else
    {
	if (app_config.duration!=NO_LIMIT &&
	    call_info.state == PJSIP_INV_STATE_CONFIRMED)
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
        
	if (current_call==PJSUA_INVALID_ID)
        {
	    current_call = call_id;
        }
    }
}


/**
 * Handler when there is incoming call.
 */
static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id,
			     pjsip_rx_data *rdata)
{
    pjsua_call_info call_info;
    
    PJ_UNUSED_ARG(acc_id);
    PJ_UNUSED_ARG(rdata);
    
    pjsua_call_get_info(call_id, &call_info);
    
    if (current_call==PJSUA_INVALID_ID)
    {
	current_call = call_id;
    }
    
    if (!   (call_id)) //### Currently always returns false.
    {
	return;
    }
    
    /* Start ringback */
    ring_start(call_id);
    
    if (app_config.auto_answer > 0)
    {
	pjsua_call_setting call_opt;
        
	pjsua_call_setting_default(&call_opt);
	call_opt.aud_cnt = app_config.aud_cnt;
	call_opt.vid_cnt = app_config.vid.vid_cnt;
        
	pjsua_call_answer2(call_id, &call_opt, app_config.auto_answer, NULL, NULL);
    }
    
    if (app_config.auto_answer < 200)
    {
	char notif_st[80] = {0};
        
#if PJSUA_HAS_VIDEO
	if (call_info.rem_offerer && call_info.rem_vid_cnt)
        {
	    snprintf(notif_st, sizeof(notif_st),"To %s the video, type \"vid %s\" first, before answering the call!\n",
		     (app_config.vid.vid_cnt? "reject":"accept"), (app_config.vid.vid_cnt? "disable":"enable"));
	}
#endif
        
	PJ_LOG(3, (THIS_FILE, "Incoming call for account %d!\nMedia count: %d audio & %d video\n%sFrom: %s\n"
                              "To: %s\nPress a to answer or h to reject call",
		  acc_id, call_info.rem_aud_cnt, call_info.rem_vid_cnt, notif_st, call_info.remote_info.ptr,
		  call_info.local_info.ptr));
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
        
	/* Loopback sound, if desired */
	if (app_config.auto_loop)
        {
	    pjsua_conf_connect(call_conf_slot, call_conf_slot);
	    connect_sound = PJ_FALSE;
	}
        
	/* Automatically record conversation, if desired */
	if (app_config.auto_rec && app_config.rec_port != PJSUA_INVALID_ID)
        {
	    pjsua_conf_connect(call_conf_slot, app_config.rec_port);
	}
        
	/* Stream a file, if desired */
	if ((app_config.auto_play || app_config.auto_play_hangup) && app_config.wav_port != PJSUA_INVALID_ID)
	{
	    pjsua_conf_connect(app_config.wav_port, call_conf_slot);
	    connect_sound = PJ_FALSE;
	}
        
	/* Stream AVI, if desired */
	if (app_config.avi_auto_play &&
	    app_config.avi_def_idx != PJSUA_INVALID_ID &&
	    app_config.avi[app_config.avi_def_idx].slot != PJSUA_INVALID_ID)
	{
	    pjsua_conf_connect(app_config.avi[app_config.avi_def_idx].slot, call_conf_slot);
	    disconnect_mic = PJ_TRUE;
	}
        
	/* Put call in conference with other calls, if desired */
	if (app_config.auto_conf)
        {
	    pjsua_call_id   call_ids[PJSUA_MAX_CALLS];
	    unsigned        call_cnt = PJ_ARRAY_SIZE(call_ids);
	    unsigned        i;
            
	    /* Get all calls, and establish media connection between
	     * this call and other calls.
	     */
	    pjsua_enum_calls(call_ids, &call_cnt);
            
	    for (i = 0; i < call_cnt; ++i)
            {
		if (call_ids[i] == ci->id)
                {
		    continue;
                }
		
		if (!pjsua_call_has_media(call_ids[i]))
                {
		    continue;
                }
                
		pjsua_conf_connect(call_conf_slot, pjsua_call_get_conf_port(call_ids[i]));
		pjsua_conf_connect(pjsua_call_get_conf_port(call_ids[i]), call_conf_slot);
                
		/* Automatically record conversation, if desired */
		if (app_config.auto_rec && app_config.rec_port != PJSUA_INVALID_ID)
                {
		    pjsua_conf_connect(pjsua_call_get_conf_port(call_ids[i]), app_config.rec_port);
		}
	    }
            
	    /* Also connect call to local sound device */
	    connect_sound = PJ_TRUE;
	}
        
	/* Otherwise connect to sound device */
	if (connect_sound)
        {
	    pjsua_conf_connect(call_conf_slot, 0);
	    if (!disconnect_mic)
            {
		pjsua_conf_connect(0, call_conf_slot);
            }
            
	    /* Automatically record conversation, if desired */
	    if (app_config.auto_rec && app_config.rec_port != PJSUA_INVALID_ID)
            {
		pjsua_conf_connect(call_conf_slot, app_config.rec_port);
		pjsua_conf_connect(0, app_config.rec_port);
	    }
	}
    }
}


/* arrange windows. arg:
 *   -1:    arrange all windows
 *   != -1: arrange only this window id
 */
static void arrange_window(
    pjsua_vid_win_id wid)
{
#if PJSUA_HAS_VIDEO
    pjmedia_coord   pos;
    int             i;
    int             last;
    
    pos.x = 0;
    pos.y = 10;
    last = (wid == PJSUA_INVALID_ID) ? PJSUA_MAX_VID_WINS : wid;
    
    for (i=0; i<last; ++i)
    {
	pjsua_vid_win_info  wi;
	pj_status_t         status;
        
	status = pjsua_vid_win_get_info(i, &wi);
	if (status != PJ_SUCCESS)
        {
	    continue;
        }
        
	if (wid == PJSUA_INVALID_ID)
        {
	    pjsua_vid_win_set_pos(i, &pos);
        }
        
	if (wi.show)
        {
	    pos.y += wi.size.h;
        }
    }
    
    if (wid != PJSUA_INVALID_ID)
    {
	pjsua_vid_win_set_pos(wid, &pos);
    }
#else
    PJ_UNUSED_ARG(wid);
#endif
}


/* Process video media state. "mi" is the media index. */
static void on_call_video_state(
    pjsua_call_info*    ci,
    unsigned            mi,
    pj_bool_t*          has_error)
{
    if (ci->media_status != PJSUA_CALL_MEDIA_ACTIVE)
    {
	return;
    }
    
    arrange_window(ci->media[mi].stream.vid.win_in);
    
    PJ_UNUSED_ARG(has_error);
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
    
    for (mi=0; mi<call_info.media_cnt; ++mi)
    {
	on_call_generic_media_state(&call_info, mi, &has_error);
        
	switch (call_info.media[mi].type)
        {
            case PJMEDIA_TYPE_AUDIO:
                on_call_audio_state(&call_info, mi, &has_error);
                break;
                
            case PJMEDIA_TYPE_VIDEO:
                on_call_video_state(&call_info, mi, &has_error);
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
    
#if PJSUA_HAS_VIDEO
    /* Check if remote has just tried to enable video */
    if (call_info.rem_offerer && call_info.rem_vid_cnt)
    {
	int vid_idx;
        
	/* Check if there is active video */
	vid_idx = pjsua_call_get_vid_stream_idx(call_id);
	if (vid_idx == -1 || call_info.media[vid_idx].dir == PJMEDIA_DIR_NONE)
        {
	    PJ_LOG(3, (THIS_FILE, "Just rejected incoming video offer on call %d, "
                                  "use \"vid call enable %d\" or \"vid call add\" to enable video!",
		      call_id, vid_idx));
	}
    }
#endif
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
static void on_reg_state(pjsua_acc_id acc_id)
{
    PJ_UNUSED_ARG(acc_id);
    
    // Log already written.
}


/*
 * Handler for incoming presence subscription request
 */
static void on_incoming_subscribe(
    pjsua_acc_id        acc_id,
    pjsua_srv_pres*     srv_pres,
    pjsua_buddy_id      buddy_id,
    const pj_str_t*     from,
    pjsip_rx_data*      rdata,
    pjsip_status_code*  code,
    pj_str_t*           reason,
    pjsua_msg_data*     msg_data)
{
    /* Just accept the request (the default behavior) */
    PJ_UNUSED_ARG(acc_id);
    PJ_UNUSED_ARG(srv_pres);
    PJ_UNUSED_ARG(buddy_id);
    PJ_UNUSED_ARG(from);
    PJ_UNUSED_ARG(rdata);
    PJ_UNUSED_ARG(code);
    PJ_UNUSED_ARG(reason);
    PJ_UNUSED_ARG(msg_data);
}


/*
 * Handler on buddy state changed.
 */
static void on_buddy_state(
    pjsua_buddy_id  buddy_id)
{
    pjsua_buddy_info    info;
    
    pjsua_buddy_get_info(buddy_id, &info);
    
    PJ_LOG(3, (THIS_FILE, "%.*s status is %.*s, subscription state is %s (last termination reason code=%d %.*s)",
	       (int)info.uri.slen, info.uri.ptr, (int)info.status_text.slen, info.status_text.ptr, info.sub_state_name,
	       info.sub_term_code, (int)info.sub_term_reason.slen, info.sub_term_reason.ptr));
}


/*
 * Subscription state has changed.
 */
static void on_buddy_evsub_state(
    pjsua_buddy_id  buddy_id,
    pjsip_evsub*    sub,
    pjsip_event*    event)
{
    char    event_info[80];
    
    PJ_UNUSED_ARG(sub);
    
    event_info[0] = '\0';
    
    if (event->type == PJSIP_EVENT_TSX_STATE && event->body.tsx_state.type == PJSIP_EVENT_RX_MSG)
    {
	pjsip_rx_data*  rdata = event->body.tsx_state.src.rdata;
        
	snprintf(event_info, sizeof(event_info), " (RX %s)", pjsip_rx_data_get_info(rdata));
    }
    
    PJ_LOG(4, (THIS_FILE, "Buddy %d: subscription state: %s (event: %s%s)",
	      buddy_id, pjsip_evsub_get_state_name(sub), pjsip_event_str(event->type), event_info));
}


/**
 * Incoming IM message (i.e. MESSAGE request)!
 */
static void on_pager(
    pjsua_call_id   call_id,
    const pj_str_t* from,
    const pj_str_t* to,
    const pj_str_t* contact,
    const pj_str_t* mime_type,
    const pj_str_t* text)
{
    /* Note: call index may be -1 */
    PJ_UNUSED_ARG(call_id);
    PJ_UNUSED_ARG(to);
    PJ_UNUSED_ARG(contact);
    PJ_UNUSED_ARG(mime_type);
    
    PJ_LOG(3, (THIS_FILE,"MESSAGE from %.*s: %.*s (%.*s)",
	       (int)from->slen, from->ptr, (int)text->slen, text->ptr, (int)mime_type->slen, mime_type->ptr));
}


/**
 * Received typing indication
 */
static void on_typing(
    pjsua_call_id   call_id,
    const pj_str_t* from,
    const pj_str_t* to,
    const pj_str_t* contact,
    pj_bool_t       is_typing)
{
    PJ_UNUSED_ARG(call_id);
    PJ_UNUSED_ARG(to);
    PJ_UNUSED_ARG(contact);
    
    PJ_LOG(3,(THIS_FILE, "IM indication: %.*s %s",
	      (int)from->slen, from->ptr, (is_typing ? "is typing.." : "has stopped typing")));
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
    
#if defined(PJSIP_HAS_TLS_TRANSPORT) && PJSIP_HAS_TLS_TRANSPORT!=0
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


/* Callback on media events */
static void on_call_media_event(
    pjsua_call_id   call_id,
    unsigned        med_idx,
    pjmedia_event*  event)
{
    char event_name[5];
    
    PJ_LOG(5, (THIS_FILE, "Event %s", pjmedia_fourcc_name(event->type, event_name)));
    
#if PJSUA_HAS_VIDEO
    if (event->type == PJMEDIA_EVENT_FMT_CHANGED)
    {
	/* Adjust renderer window size to original video size */
	pjsua_call_info     ci;
	pjsua_vid_win_id    wid;
	pjmedia_rect_size   size;
        
	pjsua_call_get_info(call_id, &ci);
        
	if ((ci.media[med_idx].type == PJMEDIA_TYPE_VIDEO) &&
	    (ci.media[med_idx].dir & PJMEDIA_DIR_DECODING))
	{
	    wid  = ci.media[med_idx].stream.vid.win_in;
	    size = event->data.fmt_changed.new_fmt.det.vid.size;
	    pjsua_vid_win_set_size(wid, &size);
	}
        
	/* Re-arrange video windows */
	arrange_window(PJSUA_INVALID_ID);
    }
#else
    PJ_UNUSED_ARG(call_id);
    PJ_UNUSED_ARG(med_idx);
    PJ_UNUSED_ARG(event);
#endif
}


/* Playfile done notification, set timer to hangup calls */
pj_status_t on_playfile_done(
    pjmedia_port*   port,
    void*           usr_data)
{
    pj_time_val delay;
    
    PJ_UNUSED_ARG(port);
    PJ_UNUSED_ARG(usr_data);
    
    /* Just rewind WAV when it is played outside of call */
    if (pjsua_call_get_count() == 0)
    {
	pjsua_player_set_pos(app_config.wav_id, 0);
	return PJ_SUCCESS;
    }
    
    /* Timer is already active */
    if (app_config.auto_hangup_timer.id == 1)
    {
	return PJ_SUCCESS;
    }
    
    app_config.auto_hangup_timer.id = 1;
    delay.sec  = 0;
    delay.msec = 200; /* Give 200 ms before hangup */
    pjsip_endpt_schedule_timer(pjsua_get_pjsip_endpt(), &app_config.auto_hangup_timer, &delay);
    
    return PJ_SUCCESS;
}


/* Auto hangup timer callback */
static void hangup_timeout_callback(
    pj_timer_heap_t*        timer_heap,
    struct pj_timer_entry*  entry)
{
    PJ_UNUSED_ARG(timer_heap);
    PJ_UNUSED_ARG(entry);
    
    app_config.auto_hangup_timer.id = 0;
    pjsua_call_hangup_all();
}


/*
 * Input simple string
 */
static pj_bool_t simple_input(const char *title, char *buf, pj_size_t len)
{
    char *p;
    
    printf("%s (empty to cancel): ", title); fflush(stdout);
    if (fgets(buf, len, stdin) == NULL)
	return PJ_FALSE;
    
    /* Remove trailing newlines. */
    for (p=buf; ; ++p) {
	if (*p=='\r' || *p=='\n') *p='\0';
	else if (!*p) break;
    }
    
    if (!*buf)
	return PJ_FALSE;
    
    return PJ_TRUE;
}


#define NO_NB	-2
struct input_result
{
    int	  nb_result;
    char *uri_result;
};


/*
 * Print buddy list.
 */
static void print_buddy_list(void)
{
    pjsua_buddy_id ids[64];
    int i;
    unsigned count = PJ_ARRAY_SIZE(ids);
    
    puts("Buddy list:");
    
    pjsua_enum_buddies(ids, &count);
    
    if (count == 0)
	puts(" -none-");
    else {
	for (i=0; i<(int)count; ++i) {
	    pjsua_buddy_info info;
            
	    if (pjsua_buddy_get_info(ids[i], &info) != PJ_SUCCESS)
		continue;
            
	    printf(" [%2d] <%.*s>  %.*s\n",
                   ids[i]+1,
                   (int)info.status_text.slen,
                   info.status_text.ptr,
                   (int)info.uri.slen,
                   info.uri.ptr);
	}
    }
    puts("");
}


/*
 * Print account status.
 */
static void print_acc_status(int acc_id)
{
    char buf[80];
    pjsua_acc_info info;
    
    pjsua_acc_get_info(acc_id, &info);
    
    if (!info.has_registration) {
	pj_ansi_snprintf(buf, sizeof(buf), "%.*s",
			 (int)info.status_text.slen,
			 info.status_text.ptr);
        
    } else {
	pj_ansi_snprintf(buf, sizeof(buf),
			 "%d/%.*s (expires=%d)",
			 info.status,
			 (int)info.status_text.slen,
			 info.status_text.ptr,
			 info.expires);
        
    }
    
    printf(" %c[%2d] %.*s: %s\n", (acc_id==current_acc?'*':' '),
	   acc_id,  (int)info.acc_uri.slen, info.acc_uri.ptr, buf);
    printf("       Online status: %.*s\n", 
           (int)info.online_status_text.slen,
           info.online_status_text.ptr);
}


/*
 * Input URL.
 */
static void ui_input_url(const char *title, char *buf, int len,
			 struct input_result *result)
{
    result->nb_result = NO_NB;
    result->uri_result = NULL;
    
    print_buddy_list();
    
    printf("Choices:\n"
	   "   0         For current dialog.\n"
	   "  -1         All %d buddies in buddy list\n"
	   "  [1 -%2d]    Select from buddy list\n"
	   "  URL        An URL\n"
	   "  <Enter>    Empty input (or 'q') to cancel\n"
	   , pjsua_get_buddy_count(), pjsua_get_buddy_count());
    printf("%s: ", title);
    
    fflush(stdout);
    if (fgets(buf, len, stdin) == NULL)
	return;
    len = strlen(buf);
    
    /* Left trim */
    while (pj_isspace(*buf)) {
	++buf;
	--len;
    }
    
    /* Remove trailing newlines */
    while (len && (buf[len-1] == '\r' || buf[len-1] == '\n'))
	buf[--len] = '\0';
    
    if (len == 0 || buf[0]=='q')
	return;
    
    if (pj_isdigit(*buf) || *buf=='-') {
	
	int i;
	
	if (*buf=='-')
	    i = 1;
	else
	    i = 0;
        
	for (; i<len; ++i) {
	    if (!pj_isdigit(buf[i])) {
		puts("Invalid input");
		return;
	    }
	}
        
	result->nb_result = my_atoi(buf);
        
	if (result->nb_result >= 0 &&
	    result->nb_result <= (int)pjsua_get_buddy_count())
	{
	    return;
	}
	if (result->nb_result == -1)
	    return;
        
	puts("Invalid input");
	result->nb_result = NO_NB;
	return;
        
    } else {
	pj_status_t status;
        
	if ((status=pjsua_verify_url(buf)) != PJ_SUCCESS)
        {
	    pjsua_perror(THIS_FILE, "Invalid URL", status);
	    return;
	}
        
	result->uri_result = buf;
    }
}

/*
 * List the ports in conference bridge
 */
static void conf_list(void)
{
    unsigned i, count;
    pjsua_conf_port_id id[PJSUA_MAX_CALLS];
    
    printf("Conference ports:\n");
    
    count = PJ_ARRAY_SIZE(id);
    pjsua_enum_conf_ports(id, &count);
    
    for (i=0; i<count; ++i) {
	char txlist[PJSUA_MAX_CALLS*4+10];
	unsigned j;
	pjsua_conf_port_info info;
        
	pjsua_conf_get_port_info(id[i], &info);
        
	txlist[0] = '\0';
	for (j=0; j<info.listener_cnt; ++j) {
	    char s[10];
	    pj_ansi_sprintf(s, "#%d ", info.listeners[j]);
	    pj_ansi_strcat(txlist, s);
	}
	printf("Port #%02d[%2dKHz/%dms/%d] %20.*s  transmitting to: %s\n",
	       info.slot_id,
	       info.clock_rate/1000,
	       info.samples_per_frame*1000/info.channel_count/info.clock_rate,
	       info.channel_count,
	       (int)info.name.slen,
	       info.name.ptr,
	       txlist);
        
    }
    
    puts("");
}


/*
 * Send arbitrary request to remote host
 */
static void send_request(char *cstr_method, const pj_str_t *dst_uri)
{
    pj_str_t str_method;
    pjsip_method method;
    pjsip_tx_data *tdata;
    pjsip_endpoint *endpt;
    pj_status_t status;
    
    endpt = pjsua_get_pjsip_endpt();
    
    str_method = pj_str(cstr_method);
    pjsip_method_init_np(&method, &str_method);
    
    status = pjsua_acc_create_request(current_acc, &method, dst_uri, &tdata);
    
    status = pjsip_endpt_send_request(endpt, tdata, -1, NULL, NULL);
    if (status != PJ_SUCCESS) {
	pjsua_perror(THIS_FILE, "Unable to send request", status);
	return;
    }
}


/*
 * Change extended online status.
 */
static void change_online_status(void)
{
    char            menuin[32];
    pj_bool_t       online_status;
    pjrpid_element  elem;
    int             i;
    int             choice;
    
    enum
    {
	AVAILABLE, BUSY, OTP, IDLE, AWAY, BRB, OFFLINE, OPT_MAX
    };
    
    struct opt
    {
	int     id;
	char*   name;
    } opts[] =
    {
	{ AVAILABLE, "Available" },
	{ BUSY, "Busy"},
	{ OTP, "On the phone"},
	{ IDLE, "Idle"},
	{ AWAY, "Away"},
	{ BRB, "Be right back"},
	{ OFFLINE, "Offline"}
    };
    
    printf("\nChoices:\n");
    for (i=0; i<PJ_ARRAY_SIZE(opts); ++i)
    {
	printf("  %d  %s\n", opts[i].id+1, opts[i].name);
    }
    
    if (!simple_input("Select status", menuin, sizeof(menuin)))
	return;
    
    choice = atoi(menuin) - 1;
    if (choice < 0 || choice >= OPT_MAX) {
	puts("Invalid selection");
	return;
    }
    
    pj_bzero(&elem, sizeof(elem));
    elem.type = PJRPID_ELEMENT_TYPE_PERSON;
    
    online_status = PJ_TRUE;
    
    switch (choice) {
        case AVAILABLE:
            break;
        case BUSY:
            elem.activity = PJRPID_ACTIVITY_BUSY;
            elem.note = pj_str("Busy");
            break;
        case OTP:
            elem.activity = PJRPID_ACTIVITY_BUSY;
            elem.note = pj_str("On the phone");
            break;
        case IDLE:
            elem.activity = PJRPID_ACTIVITY_UNKNOWN;
            elem.note = pj_str("Idle");
            break;
        case AWAY:
            elem.activity = PJRPID_ACTIVITY_AWAY;
            elem.note = pj_str("Away");
            break;
        case BRB:
            elem.activity = PJRPID_ACTIVITY_UNKNOWN;
            elem.note = pj_str("Be right back");
            break;
        case OFFLINE:
            online_status = PJ_FALSE;
            break;
    }
    
    pjsua_acc_set_online_status2(current_acc, online_status, &elem);
}


/*
 * Change codec priorities.
 */
static void manage_codec_prio(void)
{
    pjsua_codec_info    c[32];
    unsigned            i;
    unsigned            count = PJ_ARRAY_SIZE(c);
    char                input[32];
    char*               codec;
    char*               prio;
    pj_str_t            id;
    int                 new_prio;
    pj_status_t         status;
    
    printf("List of audio codecs:\n");
    pjsua_enum_codecs(c, &count);
    for (i = 0; i < count; ++i)
    {
	printf("  %d\t%.*s\n", c[i].priority, (int)c[i].codec_id.slen, c[i].codec_id.ptr);
    }
    
#if PJSUA_HAS_VIDEO
    puts("");
    printf("List of video codecs:\n");
    pjsua_vid_enum_codecs(c, &count);
    for (i = 0; i < count; ++i)
    {
	printf("  %d\t%.*s%s%.*s\n",
               c[i].priority, (int)c[i].codec_id.slen, c[i].codec_id.ptr, c[i].desc.slen ? " - " : "",
               (int)c[i].desc.slen, c[i].desc.ptr);
    }
#endif
    
    puts("");
    puts("Enter codec id and its new priority (e.g. \"speex/16000 200\", ""\"H263 200\"),");
    puts("or empty to cancel.");
    
    printf("Codec name (\"*\" for all) and priority: ");
    if (fgets(input, sizeof(input), stdin) == NULL)
    {
	return;
    }
    
    if (input[0] == '\r' || input[0] == '\n')
    {
	puts("Done");
	return;
    }
    
    codec = strtok(input, " \t\r\n");
    prio = strtok(NULL, " \r\n");
    
    if (!codec || !prio)
    {
	puts("Invalid input");
	return;
    }
    
    new_prio = atoi(prio);
    if (new_prio < 0)
    {
	new_prio = 0;
    }
    else if (new_prio > PJMEDIA_CODEC_PRIO_HIGHEST)
    {
	new_prio = PJMEDIA_CODEC_PRIO_HIGHEST;
    }
    
    status = pjsua_codec_set_priority(pj_cstr(&id, codec), (pj_uint8_t)new_prio);
    
#if PJSUA_HAS_VIDEO
    if (status != PJ_SUCCESS)
    {
	status = pjsua_vid_codec_set_priority(pj_cstr(&id, codec), (pj_uint8_t)new_prio);
    }
#endif
    if (status != PJ_SUCCESS)
    {
	pjsua_perror(THIS_FILE, "Error setting codec priority", status);
    }
}


#if PJSUA_HAS_VIDEO
static void app_config_init_video(
    pjsua_acc_config*   acc_cfg)
{
    acc_cfg->vid_in_auto_show      = app_config.vid.in_auto_show;
    acc_cfg->vid_out_auto_transmit = app_config.vid.out_auto_transmit;
    
    /* Note that normally GUI application will prefer a borderless
     * window.
     */
    acc_cfg->vid_wnd_flags = PJMEDIA_VID_DEV_WND_BORDER | PJMEDIA_VID_DEV_WND_RESIZABLE;
    acc_cfg->vid_cap_dev   = app_config.vid.vcapture_dev;
    acc_cfg->vid_rend_dev  = app_config.vid.vrender_dev;
    
    if (app_config.avi_auto_play &&
	app_config.avi_def_idx != PJSUA_INVALID_ID &&
	app_config.avi[app_config.avi_def_idx].dev_id != PJMEDIA_VID_INVALID_DEV)
    {
	acc_cfg->vid_cap_dev = app_config.avi[app_config.avi_def_idx].dev_id;
    }
}


static void vid_handle_menu(
    char*   menuin)
{
    char*   argv[8];
    int     argc = 0;
    
    /* Tokenize */
    argv[argc] = strtok(menuin, " \t\r\n");
    while (argv[argc] && *argv[argc])
    {
	argc++;
	argv[argc] = strtok(NULL, " \t\r\n");
    }
    
    if (argc == 1 || strcmp(argv[1], "help") == 0)
    {
	vid_show_help();
    }
    else if (argc == 2 && (strcmp(argv[1], "enable") == 0 ||
			     strcmp(argv[1], "disable") == 0))
    {
	pj_bool_t enabled = (strcmp(argv[1], "enable") == 0);
	app_config.vid.vid_cnt = (enabled ? 1 : 0);
	PJ_LOG(3,(THIS_FILE, "Video will be %s in next offer/answer", (enabled?"enabled":"disabled")));
    }
    else if (strcmp(argv[1], "acc") == 0)
    {
	pjsua_acc_config    acc_cfg;
	pj_bool_t           changed = PJ_FALSE;
        
	pjsua_acc_get_config(current_acc, &acc_cfg);
        
	if (argc == 3 && strcmp(argv[2], "show") == 0)
        {
	    app_config_show_video(current_acc, &acc_cfg);
	}
        else if (argc == 4 && strcmp(argv[2], "autorx") == 0)
        {
	    int on = (strcmp(argv[3], "on") == 0);
	    acc_cfg.vid_in_auto_show = on;
	    changed = PJ_TRUE;
	}
        else if (argc == 4 && strcmp(argv[2], "autotx") == 0)
        {
	    int on = (strcmp(argv[3], "on") == 0);
	    acc_cfg.vid_out_auto_transmit = on;
	    changed = PJ_TRUE;
	}
        else if (argc == 4 && strcmp(argv[2], "cap") == 0)
        {
	    int dev = atoi(argv[3]);
	    acc_cfg.vid_cap_dev = dev;
	    changed = PJ_TRUE;
	}
        else if (argc == 4 && strcmp(argv[2], "rend") == 0)
        {
	    int dev = atoi(argv[3]);
	    acc_cfg.vid_rend_dev = dev;
	    changed = PJ_TRUE;
	}
        else
        {
	    goto on_error;
	}
        
	if (changed)
        {
	    pj_status_t status = pjsua_acc_modify(current_acc, &acc_cfg);
	    if (status != PJ_SUCCESS)
            {
		PJ_PERROR(1, (THIS_FILE, status, "Error modifying account %d", current_acc));
            }
	}
    }
    else if (strcmp(argv[1], "call") == 0)
    {
	pjsua_call_vid_strm_op_param    param;
	pj_status_t                     status = PJ_SUCCESS;
        
	pjsua_call_vid_strm_op_param_default(&param);
        
	if (argc == 5 && strcmp(argv[2], "rx") == 0)
        {
	    pjsua_stream_info   si;
	    pj_bool_t           on = (strcmp(argv[3], "on") == 0);
            
	    param.med_idx = atoi(argv[4]);
	    if (pjsua_call_get_stream_info(current_call, param.med_idx, &si) || si.type != PJMEDIA_TYPE_VIDEO)
	    {
		PJ_PERROR(1,(THIS_FILE, PJ_EINVAL, "Invalid stream"));
                
		return;
	    }
            
	    if (on)
            {
                param.dir = (si.info.vid.dir | PJMEDIA_DIR_DECODING);
            }
	    else
            {
                param.dir = (si.info.vid.dir & PJMEDIA_DIR_ENCODING);
            }
            
	    status = pjsua_call_set_vid_strm(current_call, PJSUA_CALL_VID_STRM_CHANGE_DIR, &param);
	}
	else if (argc == 5 && strcmp(argv[2], "tx") == 0)
        {
	    pj_bool_t on = (strcmp(argv[3], "on") == 0);
	    pjsua_call_vid_strm_op op = on? PJSUA_CALL_VID_STRM_START_TRANSMIT :
            PJSUA_CALL_VID_STRM_STOP_TRANSMIT;
            
	    param.med_idx = atoi(argv[4]);
            
	    status = pjsua_call_set_vid_strm(current_call, op, &param);
	}
	else if (argc == 3 && strcmp(argv[2], "add") == 0) {
	    status = pjsua_call_set_vid_strm(current_call,
	                                     PJSUA_CALL_VID_STRM_ADD, NULL);
	}
	else if (argc >= 3 &&
		 (strcmp(argv[2], "disable") == 0 || strcmp(argv[2], "enable") == 0))
	{
	    pj_bool_t enable = (strcmp(argv[2], "enable") == 0);
	    pjsua_call_vid_strm_op op = enable? PJSUA_CALL_VID_STRM_CHANGE_DIR :
            PJSUA_CALL_VID_STRM_REMOVE;
            
	    param.med_idx = argc >= 4? atoi(argv[3]) : -1;
	    param.dir = PJMEDIA_DIR_ENCODING_DECODING;
	    status = pjsua_call_set_vid_strm(current_call, op, &param);
	}
	else if (argc >= 3 && strcmp(argv[2], "cap") == 0) {
	    param.med_idx = argc >= 4? atoi(argv[3]) : -1;
	    param.cap_dev = argc >= 5? atoi(argv[4]) : PJMEDIA_VID_DEFAULT_CAPTURE_DEV;
	    status = pjsua_call_set_vid_strm(current_call,
	                                     PJSUA_CALL_VID_STRM_CHANGE_CAP_DEV,
	                                     &param);
	} else
	    goto on_error;
        
	if (status != PJ_SUCCESS) {
	    PJ_PERROR(1,(THIS_FILE, status, "Error modifying video stream"));
	}
        
    } else if (argc >= 3 && strcmp(argv[1], "dev") == 0) {
	if (strcmp(argv[2], "list") == 0) {
	    vid_list_devs();
	} else if (strcmp(argv[2], "refresh") == 0) {
	    pjmedia_vid_dev_refresh();
	} else if (strcmp(argv[2], "prev") == 0) {
	    if (argc != 5) {
		goto on_error;
	    } else {
		pj_bool_t on = (strcmp(argv[3], "on") == 0);
		int dev_id = atoi(argv[4]);
		if (on) {
                    pjsua_vid_preview_param param;
                    
                    pjsua_vid_preview_param_default(&param);
                    param.wnd_flags = PJMEDIA_VID_DEV_WND_BORDER |
                    PJMEDIA_VID_DEV_WND_RESIZABLE;
		    pjsua_vid_preview_start(dev_id, &param);
		    arrange_window(pjsua_vid_preview_get_win(dev_id));
		} else {
		    pjsua_vid_win_id wid;
		    wid = pjsua_vid_preview_get_win(dev_id);
		    if (wid != PJSUA_INVALID_ID) {
			/* Preview window hiding once it is stopped is
			 * responsibility of app */
			pjsua_vid_win_set_show(wid, PJ_FALSE);
			pjsua_vid_preview_stop(dev_id);
		    }
		}
	    }
	} else
	    goto on_error;
    } else if (strcmp(argv[1], "win") == 0) {
	pj_status_t status = PJ_SUCCESS;
        
	if (argc==3 && strcmp(argv[2], "list") == 0) {
	    pjsua_vid_win_id wids[PJSUA_MAX_VID_WINS];
	    unsigned i, cnt = PJ_ARRAY_SIZE(wids);
            
	    pjsua_vid_enum_wins(wids, &cnt);
            
	    PJ_LOG(3,(THIS_FILE, "Found %d video windows:", cnt));
	    PJ_LOG(3,(THIS_FILE, "WID show    pos       size"));
	    PJ_LOG(3,(THIS_FILE, "------------------------------"));
	    for (i = 0; i < cnt; ++i) {
		pjsua_vid_win_info wi;
		pjsua_vid_win_get_info(wids[i], &wi);
		PJ_LOG(3,(THIS_FILE, "%3d   %c  (%d,%d)  %dx%d",
			  wids[i], (wi.show?'Y':'N'), wi.pos.x, wi.pos.y,
			  wi.size.w, wi.size.h));
	    }
	} else if (argc==4 && (strcmp(argv[2], "show") == 0 ||
			       strcmp(argv[2], "hide") == 0))
	{
	    pj_bool_t show = (strcmp(argv[2], "show") == 0);
	    pjsua_vid_win_id wid = atoi(argv[3]);
	    status = pjsua_vid_win_set_show(wid, show);
	} else if (argc==6 && strcmp(argv[2], "move") == 0) {
	    pjsua_vid_win_id wid = atoi(argv[3]);
	    pjmedia_coord pos;
            
	    pos.x = atoi(argv[4]);
	    pos.y = atoi(argv[5]);
	    status = pjsua_vid_win_set_pos(wid, &pos);
	} else if (argc==6 && strcmp(argv[2], "resize") == 0) {
	    pjsua_vid_win_id wid = atoi(argv[3]);
	    pjmedia_rect_size size;
            
	    size.w = atoi(argv[4]);
	    size.h = atoi(argv[5]);
	    status = pjsua_vid_win_set_size(wid, &size);
	} else if (argc==3 && strcmp(argv[2], "arrange") == 0) {
	    arrange_window(PJSUA_INVALID_ID);
	} else
	    goto on_error;
        
	if (status != PJ_SUCCESS) {
	    PJ_PERROR(1,(THIS_FILE, status, "Window operation error"));
	}
        
    } else if (strcmp(argv[1], "codec") == 0) {
	pjsua_codec_info ci[PJMEDIA_CODEC_MGR_MAX_CODECS];
	unsigned count = PJ_ARRAY_SIZE(ci);
	pj_status_t status;
        
	if (argc==3 && strcmp(argv[2], "list") == 0) {
	    status = pjsua_vid_enum_codecs(ci, &count);
	    if (status != PJ_SUCCESS) {
		PJ_PERROR(1,(THIS_FILE, status, "Error enumerating codecs"));
	    } else {
		unsigned i;
		PJ_LOG(3,(THIS_FILE, "Found %d video codecs:", count));
		PJ_LOG(3,(THIS_FILE, "codec id      prio  fps    bw(kbps)   size"));
		PJ_LOG(3,(THIS_FILE, "------------------------------------------"));
		for (i=0; i<count; ++i) {
		    pjmedia_vid_codec_param cp;
		    pjmedia_video_format_detail *vfd;
                    
		    status = pjsua_vid_codec_get_param(&ci[i].codec_id, &cp);
		    if (status != PJ_SUCCESS)
			continue;
                    
		    vfd = pjmedia_format_get_video_format_detail(&cp.enc_fmt,
								 PJ_TRUE);
		    PJ_LOG(3,(THIS_FILE, "%.*s%.*s %3d %7.2f  %4d/%4d  %dx%d",
			      (int)ci[i].codec_id.slen, ci[i].codec_id.ptr,
			      13-(int)ci[i].codec_id.slen, "                ",
			      ci[i].priority,
			      (vfd->fps.num*1.0/vfd->fps.denum),
			      vfd->avg_bps/1000, vfd->max_bps/1000,
			      vfd->size.w, vfd->size.h));
		}
	    }
	} else if (argc==5 && strcmp(argv[2], "prio") == 0) {
	    pj_str_t cid;
	    int prio;
	    cid = pj_str(argv[3]);
	    prio = atoi(argv[4]);
	    status = pjsua_vid_codec_set_priority(&cid, (pj_uint8_t)prio);
	    if (status != PJ_SUCCESS)
		PJ_PERROR(1,(THIS_FILE, status, "Set codec priority error"));
	} else if (argc==6 && strcmp(argv[2], "fps") == 0) {
	    pjmedia_vid_codec_param cp;
	    pj_str_t cid;
	    int M, N;
	    cid = pj_str(argv[3]);
	    M = atoi(argv[4]);
	    N = atoi(argv[5]);
	    status = pjsua_vid_codec_get_param(&cid, &cp);
	    if (status == PJ_SUCCESS) {
		cp.enc_fmt.det.vid.fps.num = M;
		cp.enc_fmt.det.vid.fps.denum = N;
		status = pjsua_vid_codec_set_param(&cid, &cp);
	    }
	    if (status != PJ_SUCCESS)
		PJ_PERROR(1,(THIS_FILE, status, "Set codec framerate error"));
	} else if (argc==6 && strcmp(argv[2], "bw") == 0) {
	    pjmedia_vid_codec_param cp;
	    pj_str_t cid;
	    int M, N;
	    cid = pj_str(argv[3]);
	    M = atoi(argv[4]);
	    N = atoi(argv[5]);
	    status = pjsua_vid_codec_get_param(&cid, &cp);
	    if (status == PJ_SUCCESS) {
		cp.enc_fmt.det.vid.avg_bps = M * 1000;
		cp.enc_fmt.det.vid.max_bps = N * 1000;
		status = pjsua_vid_codec_set_param(&cid, &cp);
	    }
	    if (status != PJ_SUCCESS)
		PJ_PERROR(1,(THIS_FILE, status, "Set codec bitrate error"));
	} else if (argc==6 && strcmp(argv[2], "size") == 0) {
	    pjmedia_vid_codec_param cp;
	    pj_str_t cid;
	    int M, N;
	    cid = pj_str(argv[3]);
	    M = atoi(argv[4]);
	    N = atoi(argv[5]);
	    status = pjsua_vid_codec_get_param(&cid, &cp);
	    if (status == PJ_SUCCESS) {
		cp.enc_fmt.det.vid.size.w = M;
		cp.enc_fmt.det.vid.size.h = N;
		status = pjsua_vid_codec_set_param(&cid, &cp);
	    }
	    if (status != PJ_SUCCESS)
		PJ_PERROR(1,(THIS_FILE, status, "Set codec bitrate error"));
	} else
	    goto on_error;
    } else
	goto on_error;
    
    return;
    
on_error:
    PJ_LOG(1, (THIS_FILE, "Invalid command, use 'vid help'"));
}

#else

static void app_config_init_video(
    pjsua_acc_config*   acc_cfg)
{
    PJ_UNUSED_ARG(acc_cfg);
}

#endif /* PJSUA_HAS_VIDEO */


/*
 * Main "user interface" loop.
 */
void console_app_main()
{
    char menuin[32];
    char buf[128];
    char text[128];
    int i, count;
    char *uri;
    pj_str_t tmp;
    struct input_result result;
    pjsua_msg_data msg_data;
    pjsua_call_info call_info;
    pjsua_acc_info acc_info;
    pjsua_call_setting call_opt;
    
    pjsua_call_setting_default(&call_opt);
    call_opt.aud_cnt = app_config.aud_cnt;
    call_opt.vid_cnt = app_config.vid.vid_cnt;
        
    for (;;)
    {
	printf(">>> ");
	fflush(stdout);
        
	if (fgets(menuin, sizeof(menuin), stdin) == NULL)
        {
	    /*
	     * Be friendly to users who redirect commands into
	     * program, when file ends, resume with kbd.
	     * If exit is desired end script with q for quit
	     */
 	    /* Reopen stdin/stdout/stderr to /dev/console */

            puts("Cannot switch back to console from file redirection");
            menuin[0] = 'q';
            menuin[1] = '\0';
            
            if (cmd_echo)
            {
                printf("%s", menuin);
            }
            
            /* Update call setting */
            pjsua_call_setting_default(&call_opt);
            call_opt.aud_cnt = app_config.aud_cnt;
            call_opt.vid_cnt = app_config.vid.vid_cnt;
            
            switch (menuin[0])
            {
                case 'm':
                    /* Make call! : */
                    printf("(You currently have %d calls)\n",
                           pjsua_call_get_count());
                    
                    uri = NULL;
                    ui_input_url("Make call", buf, sizeof(buf), &result);
                    if (result.nb_result != NO_NB) {
                        
                        if (result.nb_result == -1 || result.nb_result == 0) {
                            puts("You can't do that with make call!");
                            continue;
                        } else {
                            pjsua_buddy_info binfo;
                            pjsua_buddy_get_info(result.nb_result-1, &binfo);
                            tmp.ptr = buf;
                            pj_strncpy(&tmp, &binfo.uri, sizeof(buf));
                        }
                        
                    } else if (result.uri_result) {
                        tmp = pj_str(result.uri_result);
                    } else {
                        tmp.slen = 0;
                    }
                    
                    pjsua_msg_data_init(&msg_data);
                    pjsua_call_make_call( current_acc, &tmp, &call_opt, NULL, &msg_data, NULL);
                    break;
                    
                case 'M':
                    /* Make multiple calls! : */
                    printf("(You currently have %d calls)\n",
                           pjsua_call_get_count());
                    
                    if (!simple_input("Number of calls", menuin, sizeof(menuin)))
                        continue;
                    
                    count = my_atoi(menuin);
                    if (count < 1)
                        continue;
                    
                    ui_input_url("Make call", buf, sizeof(buf), &result);
                    if (result.nb_result != NO_NB) {
                        pjsua_buddy_info binfo;
                        if (result.nb_result == -1 || result.nb_result == 0) {
                            puts("You can't do that with make call!");
                            continue;
                        }
                        pjsua_buddy_get_info(result.nb_result-1, &binfo);
                        tmp.ptr = buf;
                        pj_strncpy(&tmp, &binfo.uri, sizeof(buf));
                    } else {
                        tmp = pj_str(result.uri_result);
                    }
                    
                    for (i=0; i<my_atoi(menuin); ++i) {
                        pj_status_t status;
                        
                        status = pjsua_call_make_call(current_acc, &tmp, &call_opt, NULL,
                                                      NULL, NULL);
                        if (status != PJ_SUCCESS)
                            break;
                    }
                    break;
                    
                case 'n':
                    i = pjsua_detect_nat_type();
                    if (i != PJ_SUCCESS)
                        pjsua_perror(THIS_FILE, "Error", i);
                    break;
                    
                case 'i':
                    /* Send instant messaeg */
                    
                    /* i is for call index to send message, if any */
                    i = -1;
                    
                    /* Make compiler happy. */
                    uri = NULL;
                    
                    /* Input destination. */
                    ui_input_url("Send IM to", buf, sizeof(buf), &result);
                    if (result.nb_result != NO_NB) {
                        
                        if (result.nb_result == -1) {
                            puts("You can't send broadcast IM like that!");
                            continue;
                            
                        } else if (result.nb_result == 0) {
                            
                            i = current_call;
                            
                        } else {
                            pjsua_buddy_info binfo;
                            pjsua_buddy_get_info(result.nb_result-1, &binfo);
                            tmp.ptr = buf;
                            pj_strncpy_with_null(&tmp, &binfo.uri, sizeof(buf));
                            uri = buf;
                        }
                        
                    } else if (result.uri_result) {
                        uri = result.uri_result;
                    }
                    
                    
                    /* Send typing indication. */
                    if (i != -1)
                        pjsua_call_send_typing_ind(i, PJ_TRUE, NULL);
                    else {
                        pj_str_t tmp_uri = pj_str(uri);
                        pjsua_im_typing(current_acc, &tmp_uri, PJ_TRUE, NULL);
                    }
                    
                    /* Input the IM . */
                    if (!simple_input("Message", text, sizeof(text))) {
                        /*
                         * Cancelled.
                         * Send typing notification too, saying we're not typing.
                         */
                        if (i != -1)
                            pjsua_call_send_typing_ind(i, PJ_FALSE, NULL);
                        else {
                            pj_str_t tmp_uri = pj_str(uri);
                            pjsua_im_typing(current_acc, &tmp_uri, PJ_FALSE, NULL);
                        }
                        continue;
                    }
                    
                    tmp = pj_str(text);
                    
                    /* Send the IM */
                    if (i != -1)
                        pjsua_call_send_im(i, NULL, &tmp, NULL, NULL);
                    else {
                        pj_str_t tmp_uri = pj_str(uri);
                        pjsua_im_send(current_acc, &tmp_uri, NULL, &tmp, NULL, NULL);
                    }
                    
                    break;
                    
                case 'a':
                    
                    if (current_call != -1) {
                        pjsua_call_get_info(current_call, &call_info);
                    } else {
                        /* Make compiler happy */
                        call_info.role = PJSIP_ROLE_UAC;
                        call_info.state = PJSIP_INV_STATE_DISCONNECTED;
                    }
                    
                    if (current_call == -1 ||
                        call_info.role != PJSIP_ROLE_UAS ||
                        call_info.state >= PJSIP_INV_STATE_CONNECTING)
                    {
                        puts("No pending incoming call");
                        fflush(stdout);
                        continue;
                        
                    } else {
                        int st_code;
                        char contact[120];
                        pj_str_t hname = { "Contact", 7 };
                        pj_str_t hvalue;
                        pjsip_generic_string_hdr hcontact;
                        
                        if (!simple_input("Answer with code (100-699)", buf, sizeof(buf)))
                            continue;
                        
                        st_code = my_atoi(buf);
                        if (st_code < 100)
                            continue;
                        
                        pjsua_msg_data_init(&msg_data);
                        
                        if (st_code/100 == 3) {
                            if (!simple_input("Enter URL to be put in Contact",
                                              contact, sizeof(contact)))
                                continue;
                            hvalue = pj_str(contact);
                            pjsip_generic_string_hdr_init2(&hcontact, &hname, &hvalue);
                            
                            pj_list_push_back(&msg_data.hdr_list, &hcontact);
                        }
                        
                        /*
                         * Must check again!
                         * Call may have been disconnected while we're waiting for
                         * keyboard input.
                         */
                        if (current_call == -1) {
                            puts("Call has been disconnected");
                            fflush(stdout);
                            continue;
                        }
                        
                        pjsua_call_answer2(current_call, &call_opt, st_code, NULL, &msg_data);
                    }
                    
                    break;
                    
                    
                case 'h':
                    
                    if (current_call == -1) {
                        puts("No current call");
                        fflush(stdout);
                        continue;
                        
                    } else if (menuin[1] == 'a') {
                        
                        /* Hangup all calls */
                        pjsua_call_hangup_all();
                        
                    } else {
                        
                        /* Hangup current calls */
                        pjsua_call_hangup(current_call, 0, NULL, NULL);
                    }
                    break;
                    
                case ']':
                case '[':
                    /*
                     * Cycle next/prev dialog.
                     */
                    if (menuin[0] == ']') {
                        find_next_call();
                        
                    } else {
                        find_prev_call();
                    }
                    
                    if (current_call != -1) {
                        
                        pjsua_call_get_info(current_call, &call_info);
                        PJ_LOG(3,(THIS_FILE,"Current dialog: %.*s",
                                  (int)call_info.remote_info.slen,
                                  call_info.remote_info.ptr));
                        
                    } else {
                        PJ_LOG(3,(THIS_FILE,"No current dialog"));
                    }
                    break;
                    
                    
                case '>':
                case '<':
                    if (!simple_input("Enter account ID to select", buf, sizeof(buf)))
                        break;
                    
                    i = my_atoi(buf);
                    if (pjsua_acc_is_valid(i)) {
                        pjsua_acc_set_default(i);
                        PJ_LOG(3,(THIS_FILE, "Current account changed to %d", i));
                    } else {
                        PJ_LOG(3,(THIS_FILE, "Invalid account id %d", i));
                    }
                    break;
                    
                    
                case '+':
                    if (menuin[1] == 'b') {
                        
                        pjsua_buddy_config buddy_cfg;
                        pjsua_buddy_id buddy_id;
                        pj_status_t status;
                        
                        if (!simple_input("Enter buddy's URI:", buf, sizeof(buf)))
                            break;
                        
                        if (pjsua_verify_url(buf) != PJ_SUCCESS) {
                            printf("Invalid URI '%s'\n", buf);
                            break;
                        }
                        
                        pj_bzero(&buddy_cfg, sizeof(pjsua_buddy_config));
                        
                        buddy_cfg.uri = pj_str(buf);
                        buddy_cfg.subscribe = PJ_TRUE;
                        
                        status = pjsua_buddy_add(&buddy_cfg, &buddy_id);
                        if (status == PJ_SUCCESS) {
                            printf("New buddy '%s' added at index %d\n",
                                   buf, buddy_id+1);
                        }
                        
                    } else if (menuin[1] == 'a') {
                        
                        char id[80], registrar[80], realm[80], uname[80], passwd[30];
                        pjsua_acc_config acc_cfg;
                        pj_status_t status;
                        
                        if (!simple_input("Your SIP URL:", id, sizeof(id)))
                            break;
                        if (!simple_input("URL of the registrar:", registrar, sizeof(registrar)))
                            break;
                        if (!simple_input("Auth Realm:", realm, sizeof(realm)))
                            break;
                        if (!simple_input("Auth Username:", uname, sizeof(uname)))
                            break;
                        if (!simple_input("Auth Password:", passwd, sizeof(passwd)))
                            break;
                        
                        pjsua_acc_config_default(&acc_cfg);
                        acc_cfg.id = pj_str(id);
                        acc_cfg.reg_uri = pj_str(registrar);
                        acc_cfg.cred_count = 1;
                        acc_cfg.cred_info[0].scheme = pj_str("Digest");
                        acc_cfg.cred_info[0].realm = pj_str(realm);
                        acc_cfg.cred_info[0].username = pj_str(uname);
                        acc_cfg.cred_info[0].data_type = 0;
                        acc_cfg.cred_info[0].data = pj_str(passwd);
                        
                        acc_cfg.rtp_cfg = app_config.rtp_cfg;
                        app_config_init_video(&acc_cfg);
                        
                        status = pjsua_acc_add(&acc_cfg, PJ_TRUE, NULL);
                        if (status != PJ_SUCCESS) {
                            pjsua_perror(THIS_FILE, "Error adding new account", status);
                        }
                        
                    } else {
                        printf("Invalid input %s\n", menuin);
                    }
                    break;
                    
                case '-':
                    if (menuin[1] == 'b') {
                        if (!simple_input("Enter buddy ID to delete",buf,sizeof(buf)))
                            break;
                        
                        i = my_atoi(buf) - 1;
                        
                        if (!pjsua_buddy_is_valid(i)) {
                            printf("Invalid buddy id %d\n", i);
                        } else {
                            pjsua_buddy_del(i);
                            printf("Buddy %d deleted\n", i);
                        }
                        
                    } else if (menuin[1] == 'a') {
                        
                        if (!simple_input("Enter account ID to delete",buf,sizeof(buf)))
                            break;
                        
                        i = my_atoi(buf);
                        
                        if (!pjsua_acc_is_valid(i)) {
                            printf("Invalid account id %d\n", i);
                        } else {
                            pjsua_acc_del(i);
                            printf("Account %d deleted\n", i);
                        }
                        
                    } else {
                        printf("Invalid input %s\n", menuin);
                    }
                    break;
                    
                case 'H':
                    /*
                     * Hold call.
                     */
                    if (current_call != -1) {
                        
                        pjsua_call_set_hold(current_call, NULL);
                        
                    } else {
                        PJ_LOG(3,(THIS_FILE, "No current call"));
                    }
                    break;
                    
                case 'v':
#if PJSUA_HAS_VIDEO
                    if (menuin[1]=='i' && menuin[2]=='d' && menuin[3]==' ') {
                        
                        vid_handle_menu(menuin);
                        
                    } else
#endif
                        if (current_call != -1) {
                            /*
                             * re-INVITE
                             */
                            call_opt.flag |= PJSUA_CALL_UNHOLD;
                            pjsua_call_reinvite2(current_call, &call_opt, NULL);
                            
                        } else {
                            PJ_LOG(3,(THIS_FILE, "No current call"));
                        }
                    break;
                    
                case 'U':
                    /*
                     * Send UPDATE
                     */
                    if (current_call != -1) {
                        
                        pjsua_call_update2(current_call, &call_opt, NULL);
                        
                    } else {
                        PJ_LOG(3,(THIS_FILE, "No current call"));
                    }
                    break;
                    
                case 'C':
                    if (menuin[1] == 'p') {
                        manage_codec_prio();
                    }
                    break;
                    
                case 'x':
                    /*
                     * Transfer call.
                     */
                    if (current_call == -1) {
                        
                        PJ_LOG(3,(THIS_FILE, "No current call"));
                        
                    } else {
                        int call = current_call;
                        pjsip_generic_string_hdr refer_sub;
                        pj_str_t STR_REFER_SUB = { "Refer-Sub", 9 };
                        pj_str_t STR_FALSE = { "false", 5 };
                        pjsua_call_info ci;
                        
                        pjsua_call_get_info(current_call, &ci);
                        printf("Transfering current call [%d] %.*s\n",
                               current_call,
                               (int)ci.remote_info.slen, ci.remote_info.ptr);
                        
                        ui_input_url("Transfer to URL", buf, sizeof(buf), &result);
                        
                        /* Check if call is still there. */
                        
                        if (call != current_call) {
                            puts("Call has been disconnected");
                            continue;
                        }
                        
                        pjsua_msg_data_init(&msg_data);
                        if (app_config.no_refersub) {
                            /* Add Refer-Sub: false in outgoing REFER request */
                            pjsip_generic_string_hdr_init2(&refer_sub, &STR_REFER_SUB,
                                                           &STR_FALSE);
                            pj_list_push_back(&msg_data.hdr_list, &refer_sub);
                        }
                        if (result.nb_result != NO_NB) {
                            if (result.nb_result == -1 || result.nb_result == 0)
                                puts("You can't do that with transfer call!");
                            else {
                                pjsua_buddy_info binfo;
                                pjsua_buddy_get_info(result.nb_result-1, &binfo);
                                pjsua_call_xfer( current_call, &binfo.uri, &msg_data);
                            }
                            
                        } else if (result.uri_result) {
                            pj_str_t tmp;
                            tmp = pj_str(result.uri_result);
                            pjsua_call_xfer( current_call, &tmp, &msg_data);
                        }
                    }
                    break;
                    
                case 'X':
                    /*
                     * Transfer call with replaces.
                     */
                    if (current_call == -1) {
                        
                        PJ_LOG(3,(THIS_FILE, "No current call"));
                        
                    } else {
                        int call = current_call;
                        int dst_call;
                        pjsip_generic_string_hdr refer_sub;
                        pj_str_t STR_REFER_SUB = { "Refer-Sub", 9 };
                        pj_str_t STR_FALSE = { "false", 5 };
                        pjsua_call_id ids[PJSUA_MAX_CALLS];
                        pjsua_call_info ci;
                        unsigned i, count;
                        
                        count = PJ_ARRAY_SIZE(ids);
                        pjsua_enum_calls(ids, &count);
                        
                        if (count <= 1) {
                            puts("There are no other calls");
                            continue;
                        }
                        
                        pjsua_call_get_info(current_call, &ci);
                        printf("Transfer call [%d] %.*s to one of the following:\n",
                               current_call,
                               (int)ci.remote_info.slen, ci.remote_info.ptr);
                        
                        for (i=0; i<count; ++i) {
                            pjsua_call_info call_info;
                            
                            if (ids[i] == call)
                                continue;
                            
                            pjsua_call_get_info(ids[i], &call_info);
                            printf("%d  %.*s [%.*s]\n",
                                   ids[i],
                                   (int)call_info.remote_info.slen,
                                   call_info.remote_info.ptr,
                                   (int)call_info.state_text.slen,
                                   call_info.state_text.ptr);
                        }
                        
                        if (!simple_input("Enter call number to be replaced",
                                          buf, sizeof(buf)))
                            continue;
                        
                        dst_call = my_atoi(buf);
                        
                        /* Check if call is still there. */
                        
                        if (call != current_call) {
                            puts("Call has been disconnected");
                            continue;
                        }
                        
                        /* Check that destination call is valid. */
                        if (dst_call == call) {
                            puts("Destination call number must not be the same "
                                 "as the call being transfered");
                            continue;
                        }
                        if (dst_call >= PJSUA_MAX_CALLS) {
                            puts("Invalid destination call number");
                            continue;
                        }
                        if (!pjsua_call_is_active(dst_call)) {
                            puts("Invalid destination call number");
                            continue;
                        }
                        
                        pjsua_msg_data_init(&msg_data);
                        if (app_config.no_refersub) {
                            /* Add Refer-Sub: false in outgoing REFER request */
                            pjsip_generic_string_hdr_init2(&refer_sub, &STR_REFER_SUB,
                                                           &STR_FALSE);
                            pj_list_push_back(&msg_data.hdr_list, &refer_sub);
                        }
                        
                        pjsua_call_xfer_replaces(call, dst_call,
                                                 PJSUA_XFER_NO_REQUIRE_REPLACES,
                                                 &msg_data);
                    }
                    break;
                    
                case '#':
                    /*
                     * Send DTMF strings.
                     */
                    if (current_call == -1) {
                        
                        PJ_LOG(3,(THIS_FILE, "No current call"));
                        
                    } else if (!pjsua_call_has_media(current_call)) {
                        
                        PJ_LOG(3,(THIS_FILE, "Media is not established yet!"));
                        
                    } else {
                        pj_str_t digits;
                        int call = current_call;
                        pj_status_t status;
                        
                        if (!simple_input("DTMF strings to send (0-9*#A-B)", buf,
                                          sizeof(buf)))
                        {
                            break;
                        }
                        
                        if (call != current_call) {
                            puts("Call has been disconnected");
                            continue;
                        }
                        
                        digits = pj_str(buf);
                        status = pjsua_call_dial_dtmf(current_call, &digits);
                        if (status != PJ_SUCCESS) {
                            pjsua_perror(THIS_FILE, "Unable to send DTMF", status);
                        } else {
                            puts("DTMF digits enqueued for transmission");
                        }
                    }
                    break;
                    
                case '*':
                    /* Send DTMF with INFO */
                    if (current_call == -1) {
                        
                        PJ_LOG(3,(THIS_FILE, "No current call"));
                        
                    } else {
                        const pj_str_t SIP_INFO = pj_str("INFO");
                        pj_str_t digits;
                        int call = current_call;
                        int i;
                        pj_status_t status;
                        
                        if (!simple_input("DTMF strings to send (0-9*#A-B)", buf,
                                          sizeof(buf)))
                        {
                            break;
                        }
                        
                        if (call != current_call) {
                            puts("Call has been disconnected");
                            continue;
                        }
                        
                        digits = pj_str(buf);
                        for (i=0; i<digits.slen; ++i) {
                            char body[80];
                            
                            pjsua_msg_data_init(&msg_data);
                            msg_data.content_type = pj_str("application/dtmf-relay");
                            
                            pj_ansi_snprintf(body, sizeof(body),
                                             "Signal=%c\r\n"
                                             "Duration=160",
                                             buf[i]);
                            msg_data.msg_body = pj_str(body);
                            
                            status = pjsua_call_send_request(current_call, &SIP_INFO,
                                                             &msg_data);
                            if (status != PJ_SUCCESS) {
                                break;
                            }
                        }
                    }
                    break;
                    
                case 'S':
                    /*
                     * Send arbitrary request
                     */
                    if (pjsua_acc_get_count() == 0) {
                        puts("Sorry, need at least one account configured");
                        break;
                    }
                    
                    puts("Send arbitrary request to remote host");
                    
                    /* Input METHOD */
                    if (!simple_input("Request method:",text,sizeof(text)))
                        break;
                    
                    /* Input destination URI */
                    uri = NULL;
                    ui_input_url("Destination URI", buf, sizeof(buf), &result);
                    if (result.nb_result != NO_NB) {
                        
                        if (result.nb_result == -1) {
                            puts("Sorry you can't do that!");
                            continue;
                        } else if (result.nb_result == 0) {
                            uri = NULL;
                            if (current_call == PJSUA_INVALID_ID) {
                                puts("No current call");
                                continue;
                            }
                        } else {
                            pjsua_buddy_info binfo;
                            pjsua_buddy_get_info(result.nb_result-1, &binfo);
                            tmp.ptr = buf;
                            pj_strncpy_with_null(&tmp, &binfo.uri, sizeof(buf));
                            uri = buf;
                        }
                        
                    } else if (result.uri_result) {
                        uri = result.uri_result;
                    } else {
                        continue;
                    }
                    
                    if (uri) {
                        tmp = pj_str(uri);
                        send_request(text, &tmp);
                    } else {
                        /* If you send call control request using this method
                         * (such requests includes BYE, CANCEL, etc.), it will
                         * not go well with the call state, so don't do it
                         * unless it's for testing.
                         */
                        pj_str_t method = pj_str(text);
                        pjsua_call_send_request(current_call, &method, NULL);
                    }
                    break;
                    
                case 'e':
                    if (pj_ansi_strnicmp(menuin, "echo", 4) == 0) {
                        pj_str_t tmp;
                        
                        tmp.ptr = menuin+5;
                        tmp.slen = pj_ansi_strlen(menuin)-6;
                        
                        if (tmp.slen < 1) {
                            puts("Usage: echo [0|1]");
                            break;
                        }
                        
                        cmd_echo = *tmp.ptr != '0' || tmp.slen!=1;
                    }
                    break;
                    
                case 's':
                    if (pj_ansi_strnicmp(menuin, "sleep", 5) == 0) {
                        pj_str_t tmp;
                        int delay;
                        
                        tmp.ptr = menuin+6;
                        tmp.slen = pj_ansi_strlen(menuin)-7;
                        
                        if (tmp.slen < 1) {
                            puts("Usage: sleep MSEC");
                            break;
                        }
                        
                        delay = pj_strtoul(&tmp);
                        if (delay < 0) delay = 0;
                        pj_thread_sleep(delay);
                        break;
                    }
                    /* Continue below */
                    
                case 'u':
                    /*
                     * Subscribe/unsubscribe presence.
                     */
                    ui_input_url("(un)Subscribe presence of", buf, sizeof(buf), &result);
                    if (result.nb_result != NO_NB) {
                        if (result.nb_result == -1) {
                            int i, count;
                            count = pjsua_get_buddy_count();
                            for (i=0; i<count; ++i)
                                pjsua_buddy_subscribe_pres(i, menuin[0]=='s');
                        } else if (result.nb_result == 0) {
                            puts("Sorry, can only subscribe to buddy's presence, "
                                 "not from existing call");
                        } else {
                            pjsua_buddy_subscribe_pres(result.nb_result-1, (menuin[0]=='s'));
                        }
                        
                    } else if (result.uri_result) {
                        puts("Sorry, can only subscribe to buddy's presence, "
                             "not arbitrary URL (for now)");
                    }
                    
                    break;
                    
                case 'r':
                    switch (menuin[1]) {
                        case 'r':
                            /*
                             * Re-Register.
                             */
                            pjsua_acc_set_registration(current_acc, PJ_TRUE);
                            break;
                        case 'u':
                            /*
                             * Unregister
                             */
                            pjsua_acc_set_registration(current_acc, PJ_FALSE);
                            break;
                    }
                    break;
                    
                case 't':
                    pjsua_acc_get_info(current_acc, &acc_info);
                    acc_info.online_status = !acc_info.online_status;
                    pjsua_acc_set_online_status(current_acc, acc_info.online_status);
                    printf("Setting %s online status to %s\n",
                           acc_info.acc_uri.ptr,
                           (acc_info.online_status?"online":"offline"));
                    break;
                    
                case 'T':
                    change_online_status();
                    break;
                    
                case 'c':
                    switch (menuin[1]) {
                        case 'l':
                            conf_list();
                            break;
                        case 'c':
                        case 'd':
                        {
                            char tmp[10], src_port[10], dst_port[10];
                            pj_status_t status;
                            int cnt;
                            const char *src_title, *dst_title;
                            
                            cnt = sscanf(menuin, "%s %s %s", tmp, src_port, dst_port);
                            
                            if (cnt != 3) {
                                conf_list();
                                
                                src_title = (menuin[1]=='c'?
                                             "Connect src port #":
                                             "Disconnect src port #");
                                dst_title = (menuin[1]=='c'?
                                             "To dst port #":
                                             "From dst port #");
                                
                                if (!simple_input(src_title, src_port, sizeof(src_port)))
                                    break;
                                
                                if (!simple_input(dst_title, dst_port, sizeof(dst_port)))
                                    break;
                            }
                            
                            if (menuin[1]=='c') {
                                status = pjsua_conf_connect(my_atoi(src_port), 
                                                            my_atoi(dst_port));
                            } else {
                                status = pjsua_conf_disconnect(my_atoi(src_port), 
                                                               my_atoi(dst_port));
                            }
                            if (status == PJ_SUCCESS) {
                                puts("Success");
                            } else {
                                puts("ERROR!!");
                            }
                        }
                            break;
                    }
                    break;
                    
                case 'V':
                    /* Adjust audio volume */
                    sprintf(buf, "Adjust mic level: [%4.1fx] ", app_config.mic_level);
                    if (simple_input(buf,text,sizeof(text))) {
                        char *err;
                        app_config.mic_level = (float)strtod(text, &err);
                        pjsua_conf_adjust_rx_level(0, app_config.mic_level);
                    }
                    sprintf(buf, "Adjust speaker level: [%4.1fx] ", 
                            app_config.speaker_level);
                    if (simple_input(buf,text,sizeof(text))) {
                        char *err;
                        app_config.speaker_level = (float)strtod(text, &err);
                        pjsua_conf_adjust_tx_level(0, app_config.speaker_level);
                    }
                    
                    break;
                    
                case 'L':   /* Restart */
                    app_restart = PJ_TRUE;
                    /* Continues below */
                    
                case 'q':
                    goto on_exit;
                    
                case 'R':
                    if (!pjsua_call_is_active(current_call)) {
                        PJ_LOG(1, (THIS_FILE, "Call %d has gone", current_call));
                    } else if (menuin[1] == 'a') {
                        pjsua_call_process_redirect(current_call, 
                                                    PJSIP_REDIRECT_ACCEPT);
                    } else if (menuin[1] == 'r') {
                        pjsua_call_process_redirect(current_call,
                                                    PJSIP_REDIRECT_REJECT);
                    } else {
                        pjsua_call_process_redirect(current_call,
                                                    PJSIP_REDIRECT_STOP);
                    }
                    break;
                    
                default:
                    if (menuin[0] != '\n' && menuin[0] != '\r') {
                        printf("Invalid input %s", menuin);
                    }
                    break;
            }
        }
        
    on_exit:
        ;
    }
}

/*
 * A simple registrar, invoked by default_mod_on_rx_request()
 */
static void simple_registrar(pjsip_rx_data *rdata)
{
    pjsip_tx_data *tdata;
    const pjsip_expires_hdr *exp;
    const pjsip_hdr *h;
    unsigned cnt = 0;
    pjsip_generic_string_hdr *srv;
    pj_status_t status;
    
    status = pjsip_endpt_create_response(pjsua_get_pjsip_endpt(),
                                         rdata, 200, NULL, &tdata);
    if (status != PJ_SUCCESS)
        return;
    
    exp = pjsip_msg_find_hdr(rdata->msg_info.msg, PJSIP_H_EXPIRES, NULL);
    
    h = rdata->msg_info.msg->hdr.next;
    while (h != &rdata->msg_info.msg->hdr) {
        if (h->type == PJSIP_H_CONTACT) {
            const pjsip_contact_hdr *c = (const pjsip_contact_hdr*)h;
            int e = c->expires;
            
            if (e < 0) {
                if (exp)
                    e = exp->ivalue;
                else
                    e = 3600;
            }
            
            if (e > 0) {
                pjsip_contact_hdr *nc = pjsip_hdr_clone(tdata->pool, h);
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
    
    pjsip_endpt_send_response2(pjsua_get_pjsip_endpt(),
                               rdata, tdata, NULL, NULL);
}



/*****************************************************************************
 * A simple module to handle otherwise unhandled request. We will register
 * this with the lowest priority.
 */

/* Notification on incoming request */
static pj_bool_t default_mod_on_rx_request(pjsip_rx_data *rdata)
{
    pjsip_tx_data *tdata;
    pjsip_status_code status_code;
    pj_status_t status;
    
    /* Don't respond to ACK! */
    if (pjsip_method_cmp(&rdata->msg_info.msg->line.req.method,
                         &pjsip_ack_method) == 0)
        return PJ_TRUE;
    
    /* Simple registrar */
    if (pjsip_method_cmp(&rdata->msg_info.msg->line.req.method,
                         &pjsip_register_method) == 0)
    {
        simple_registrar(rdata);
        return PJ_TRUE;
    }
    
    /* Create basic response. */
    if (pjsip_method_cmp(&rdata->msg_info.msg->line.req.method,
                         &pjsip_notify_method) == 0)
    {
        /* Unsolicited NOTIFY's, send with Bad Request */
        status_code = PJSIP_SC_BAD_REQUEST;
    } else {
        /* Probably unknown method */
        status_code = PJSIP_SC_METHOD_NOT_ALLOWED;
    }
    status = pjsip_endpt_create_response(pjsua_get_pjsip_endpt(),
                                         rdata, status_code,
                                         NULL, &tdata);
    if (status != PJ_SUCCESS) {
        pjsua_perror(THIS_FILE, "Unable to create response", status);
        return PJ_TRUE;
    }
    
    /* Add Allow if we're responding with 405 */
    if (status_code == PJSIP_SC_METHOD_NOT_ALLOWED) {
        const pjsip_hdr *cap_hdr;
        cap_hdr = pjsip_endpt_get_capability(pjsua_get_pjsip_endpt(),
                                             PJSIP_H_ALLOW, NULL);
        if (cap_hdr) {
            pjsip_msg_add_hdr(tdata->msg, pjsip_hdr_clone(tdata->pool,
                                                          cap_hdr));
        }
    }
    
    /* Add User-Agent header */
    {
        pj_str_t user_agent;
        char tmp[80];
        const pj_str_t USER_AGENT = { "User-Agent", 10};
        pjsip_hdr *h;
        
        pj_ansi_snprintf(tmp, sizeof(tmp), "PJSUA v%s/%s",
                         pj_get_version(), PJ_OS_NAME);
        pj_strdup2_with_null(tdata->pool, &user_agent, tmp);
        
        h = (pjsip_hdr*) pjsip_generic_string_hdr_create(tdata->pool,
                                                         &USER_AGENT,
                                                         &user_agent);
        pjsip_msg_add_hdr(tdata->msg, h);
    }
    
    pjsip_endpt_send_response2(pjsua_get_pjsip_endpt(), rdata, tdata,
                               NULL, NULL);
    
    return PJ_TRUE;
}


/* The module instance. */
static pjsip_module mod_default_handler =
{
    NULL, NULL,				/* prev, next.		*/
    { "mod-default-handler", 19 },	/* Name.		*/
    -1,					/* Id			*/
    PJSIP_MOD_PRIORITY_APPLICATION+99,	/* Priority	        */
    NULL,				/* load()		*/
    NULL,				/* start()		*/
    NULL,				/* stop()		*/
    NULL,				/* unload()		*/
    &default_mod_on_rx_request,		/* on_rx_request()	*/
    NULL,				/* on_rx_response()	*/
    NULL,				/* on_tx_request.	*/
    NULL,				/* on_tx_response()	*/
    NULL,				/* on_tsx_state()	*/
    
};




/*****************************************************************************
 * Public API
 */

pj_status_t app_init(int argc, char *argv[])
{
    pjsua_transport_id transport_id = -1;
    pjsua_transport_config tcp_cfg;
    unsigned i;
    pj_status_t status;
    
    app_restart = PJ_FALSE;
    
    /* Create pjsua */
    status = pjsua_create();
    if (status != PJ_SUCCESS)
        return status;
    
    /* Create pool for application */
    app_config.pool = pjsua_pool_create("pjsua-app", 1000, 1000);
    
    /* Initialize default config */
    default_config(&app_config);
    
    /* Parse the arguments */
    status = parse_args(argc, argv, &app_config);
    if (status != PJ_SUCCESS)
        return status;
    
    /* Initialize application callbacks */
    app_config.cfg.cb.on_call_state = &on_call_state;
    app_config.cfg.cb.on_call_media_state = &on_call_media_state;
    app_config.cfg.cb.on_incoming_call = &on_incoming_call;
    app_config.cfg.cb.on_call_tsx_state = &on_call_tsx_state;
    app_config.cfg.cb.on_dtmf_digit = &call_on_dtmf_callback;
    app_config.cfg.cb.on_call_redirected = &call_on_redirected;
    app_config.cfg.cb.on_reg_state = &on_reg_state;
    app_config.cfg.cb.on_incoming_subscribe = &on_incoming_subscribe;
    app_config.cfg.cb.on_buddy_state = &on_buddy_state;
    app_config.cfg.cb.on_buddy_evsub_state = &on_buddy_evsub_state;
    app_config.cfg.cb.on_pager = &on_pager;
    app_config.cfg.cb.on_typing = &on_typing;
    app_config.cfg.cb.on_call_transfer_status = &on_call_transfer_status;
    app_config.cfg.cb.on_call_replaced = &on_call_replaced;
    app_config.cfg.cb.on_nat_detect = &on_nat_detect;
    app_config.cfg.cb.on_mwi_info = &on_mwi_info;
    app_config.cfg.cb.on_transport_state = &on_transport_state;
    app_config.cfg.cb.on_ice_transport_error = &on_ice_transport_error;
    app_config.cfg.cb.on_snd_dev_operation = &on_snd_dev_operation;
    app_config.cfg.cb.on_call_media_event = &on_call_media_event;
    app_config.log_cfg.cb = log_cb;
    
    /* Set sound device latency */
    if (app_config.capture_lat > 0)
        app_config.media_cfg.snd_rec_latency = app_config.capture_lat;
    if (app_config.playback_lat)
        app_config.media_cfg.snd_play_latency = app_config.playback_lat;
    
    /* Initialize pjsua */
    status = pjsua_init(&app_config.cfg, &app_config.log_cfg,
                        &app_config.media_cfg);
    if (status != PJ_SUCCESS)
        return status;
    
    /* Initialize our module to handle otherwise unhandled request */
    status = pjsip_endpt_register_module(pjsua_get_pjsip_endpt(),
                                         &mod_default_handler);
    if (status != PJ_SUCCESS)
        return status;
    
    /* Initialize calls data */
    for (i=0; i<PJ_ARRAY_SIZE(app_config.call_data); ++i) {
        app_config.call_data[i].timer.id = PJSUA_INVALID_ID;
        app_config.call_data[i].timer.cb = &call_timeout_callback;
    }
    
    /* Optionally registers WAV file */
    for (i=0; i<app_config.wav_count; ++i) {
        pjsua_player_id wav_id;
        unsigned play_options = 0;
        
        if (app_config.auto_play_hangup)
            play_options |= PJMEDIA_FILE_NO_LOOP;
        
        status = pjsua_player_create(&app_config.wav_files[i], play_options,
                                     &wav_id);
        if (status != PJ_SUCCESS)
            goto on_error;
        
        if (app_config.wav_id == PJSUA_INVALID_ID) {
            app_config.wav_id = wav_id;
            app_config.wav_port = pjsua_player_get_conf_port(app_config.wav_id);
            if (app_config.auto_play_hangup) {
                pjmedia_port *port;
                
                pjsua_player_get_port(app_config.wav_id, &port);
                status = pjmedia_wav_player_set_eof_cb(port, NULL,
                                                       &on_playfile_done);
                if (status != PJ_SUCCESS)
                    goto on_error;
                
                pj_timer_entry_init(&app_config.auto_hangup_timer, 0, NULL,
                                    &hangup_timeout_callback);
            }
        }
    }
    
    /* Optionally registers tone players */
    for (i=0; i<app_config.tone_count; ++i) {
        pjmedia_port *tport;
        char name[80];
        pj_str_t label;
        pj_status_t status;
        
        pj_ansi_snprintf(name, sizeof(name), "tone-%d,%d",
                         app_config.tones[i].freq1,
                         app_config.tones[i].freq2);
        label = pj_str(name);
        status = pjmedia_tonegen_create2(app_config.pool, &label,
                                         8000, 1, 160, 16,
                                         PJMEDIA_TONEGEN_LOOP,  &tport);
        if (status != PJ_SUCCESS) {
            pjsua_perror(THIS_FILE, "Unable to create tone generator", status);
            goto on_error;
        }
        
        status = pjsua_conf_add_port(app_config.pool, tport,
                                     &app_config.tone_slots[i]);
        pj_assert(status == PJ_SUCCESS);
        
        status = pjmedia_tonegen_play(tport, 1, &app_config.tones[i], 0);
        pj_assert(status == PJ_SUCCESS);
    }
    
    /* Optionally create recorder file, if any. */
    if (app_config.rec_file.slen) {
        status = pjsua_recorder_create(&app_config.rec_file, 0, NULL, 0, 0,
                                       &app_config.rec_id);
        if (status != PJ_SUCCESS)
            goto on_error;
        
        app_config.rec_port = pjsua_recorder_get_conf_port(app_config.rec_id);
    }
    
    pj_memcpy(&tcp_cfg, &app_config.udp_cfg, sizeof(tcp_cfg));
    
    /* Create ringback tones */
    if (app_config.no_tones == PJ_FALSE) {
        unsigned i, samples_per_frame;
        pjmedia_tone_desc tone[RING_CNT+RINGBACK_CNT];
        pj_str_t name;
        
        samples_per_frame = app_config.media_cfg.audio_frame_ptime *
        app_config.media_cfg.clock_rate *
        app_config.media_cfg.channel_count / 1000;
        
        /* Ringback tone (call is ringing) */
        name = pj_str("ringback");
        status = pjmedia_tonegen_create2(app_config.pool, &name,
                                         app_config.media_cfg.clock_rate,
                                         app_config.media_cfg.channel_count,
                                         samples_per_frame,
                                         16, PJMEDIA_TONEGEN_LOOP,
                                         &app_config.ringback_port);
        if (status != PJ_SUCCESS)
            goto on_error;
        
        pj_bzero(&tone, sizeof(tone));
        for (i=0; i<RINGBACK_CNT; ++i) {
            tone[i].freq1 = RINGBACK_FREQ1;
            tone[i].freq2 = RINGBACK_FREQ2;
            tone[i].on_msec = RINGBACK_ON;
            tone[i].off_msec = RINGBACK_OFF;
        }
        tone[RINGBACK_CNT-1].off_msec = RINGBACK_INTERVAL;
        
        pjmedia_tonegen_play(app_config.ringback_port, RINGBACK_CNT, tone,
                             PJMEDIA_TONEGEN_LOOP);
        
        
        status = pjsua_conf_add_port(app_config.pool, app_config.ringback_port,
                                     &app_config.ringback_slot);
        if (status != PJ_SUCCESS)
            goto on_error;
        
        /* Ring (to alert incoming call) */
        name = pj_str("ring");
        status = pjmedia_tonegen_create2(app_config.pool, &name,
                                         app_config.media_cfg.clock_rate,
                                         app_config.media_cfg.channel_count,
                                         samples_per_frame,
                                         16, PJMEDIA_TONEGEN_LOOP,
                                         &app_config.ring_port);
        if (status != PJ_SUCCESS)
            goto on_error;
        
        for (i=0; i<RING_CNT; ++i) {
            tone[i].freq1 = RING_FREQ1;
            tone[i].freq2 = RING_FREQ2;
            tone[i].on_msec = RING_ON;
            tone[i].off_msec = RING_OFF;
        }
        tone[RING_CNT-1].off_msec = RING_INTERVAL;
        
        pjmedia_tonegen_play(app_config.ring_port, RING_CNT,
                             tone, PJMEDIA_TONEGEN_LOOP);
        
        status = pjsua_conf_add_port(app_config.pool, app_config.ring_port,
                                     &app_config.ring_slot);
        if (status != PJ_SUCCESS)
            goto on_error;
        
    }
    
    /* Create AVI player virtual devices */
    if (app_config.avi_cnt) {
#if PJMEDIA_HAS_VIDEO && PJMEDIA_VIDEO_DEV_HAS_AVI
        pjmedia_vid_dev_factory *avi_factory;
        
        status = pjmedia_avi_dev_create_factory(pjsua_get_pool_factory(),
                                                app_config.avi_cnt,
                                                &avi_factory);
        if (status != PJ_SUCCESS) {
            PJ_PERROR(1,(THIS_FILE, status, "Error creating AVI factory"));
            goto on_error;
        }
        
        for (i=0; i<app_config.avi_cnt; ++i) {
            pjmedia_avi_dev_param avdp;
            pjmedia_vid_dev_index avid;
            unsigned strm_idx, strm_cnt;
            
            app_config.avi[i].dev_id = PJMEDIA_VID_INVALID_DEV;
            app_config.avi[i].slot = PJSUA_INVALID_ID;
            
            pjmedia_avi_dev_param_default(&avdp);
            avdp.path = app_config.avi[i].path;
            
            status =  pjmedia_avi_dev_alloc(avi_factory, &avdp, &avid);
            if (status != PJ_SUCCESS) {
                PJ_PERROR(1,(THIS_FILE, status,
                             "Error creating AVI player for %.*s",
                             (int)avdp.path.slen, avdp.path.ptr));
                goto on_error;
            }
            
            PJ_LOG(4,(THIS_FILE, "AVI player %.*s created, dev_id=%d",
                      (int)avdp.title.slen, avdp.title.ptr, avid));
            
            app_config.avi[i].dev_id = avid;
            if (app_config.avi_def_idx == PJSUA_INVALID_ID)
                app_config.avi_def_idx = i;
            
            strm_cnt = pjmedia_avi_streams_get_num_streams(avdp.avi_streams);
            for (strm_idx=0; strm_idx<strm_cnt; ++strm_idx) {
                pjmedia_port *aud;
                pjmedia_format *fmt;
                pjsua_conf_port_id slot;
                char fmt_name[5];
                
                aud = pjmedia_avi_streams_get_stream(avdp.avi_streams,
                                                     strm_idx);
                fmt = &aud->info.fmt;
                
                pjmedia_fourcc_name(fmt->id, fmt_name);
                
                if (fmt->id == PJMEDIA_FORMAT_PCM) {
                    status = pjsua_conf_add_port(app_config.pool, aud,
                                                 &slot);
                    if (status == PJ_SUCCESS) {
                        PJ_LOG(4,(THIS_FILE,
                                  "AVI %.*s: audio added to slot %d",
                                  (int)avdp.title.slen, avdp.title.ptr,
                                  slot));
                        app_config.avi[i].slot = slot;
                    }
                } else {
                    PJ_LOG(4,(THIS_FILE,
                              "AVI %.*s: audio ignored, format=%s",
                              (int)avdp.title.slen, avdp.title.ptr,
                              fmt_name));
                }
            }
        }
#else
        PJ_LOG(2,(THIS_FILE,
                  "Warning: --play-avi is ignored because AVI is disabled"));
#endif	/* PJMEDIA_VIDEO_DEV_HAS_AVI */
    }
    
    /* Add UDP transport unless it's disabled. */
    if (!app_config.no_udp) {
        pjsua_acc_id aid;
        pjsip_transport_type_e type = PJSIP_TRANSPORT_UDP;
        
        status = pjsua_transport_create(type,
                                        &app_config.udp_cfg,
                                        &transport_id);
        if (status != PJ_SUCCESS)
            goto on_error;
        
        /* Add local account */
        pjsua_acc_add_local(transport_id, PJ_TRUE, &aid);
        if (PJMEDIA_HAS_VIDEO) {
            pjsua_acc_config acc_cfg;
            pjsua_acc_get_config(aid, &acc_cfg);
            app_config_init_video(&acc_cfg);
            pjsua_acc_modify(aid, &acc_cfg);
        }
        //pjsua_acc_set_transport(aid, transport_id);
        pjsua_acc_set_online_status(current_acc, PJ_TRUE);
        
        if (app_config.udp_cfg.port == 0) {
            pjsua_transport_info ti;
            pj_sockaddr_in *a;
            
            pjsua_transport_get_info(transport_id, &ti);
            a = (pj_sockaddr_in*)&ti.local_addr;
            
            tcp_cfg.port = pj_ntohs(a->sin_port);
        }
    }
    
    /* Add UDP IPv6 transport unless it's disabled. */
    if (!app_config.no_udp && app_config.ipv6) {
        pjsua_acc_id aid;
        pjsip_transport_type_e type = PJSIP_TRANSPORT_UDP6;
        pjsua_transport_config udp_cfg;
        
        udp_cfg = app_config.udp_cfg;
        if (udp_cfg.port == 0)
            udp_cfg.port = 5060;
        else
            udp_cfg.port += 10;
        status = pjsua_transport_create(type,
                                        &udp_cfg,
                                        &transport_id);
        if (status != PJ_SUCCESS)
            goto on_error;
        
        /* Add local account */
        pjsua_acc_add_local(transport_id, PJ_TRUE, &aid);
        if (PJMEDIA_HAS_VIDEO) {
            pjsua_acc_config acc_cfg;
            pjsua_acc_get_config(aid, &acc_cfg);
            app_config_init_video(&acc_cfg);
            pjsua_acc_modify(aid, &acc_cfg);
        }
        //pjsua_acc_set_transport(aid, transport_id);
        pjsua_acc_set_online_status(current_acc, PJ_TRUE);
        
        if (app_config.udp_cfg.port == 0) {
            pjsua_transport_info ti;
            pj_sockaddr_in *a;
            
            pjsua_transport_get_info(transport_id, &ti);
            a = (pj_sockaddr_in*)&ti.local_addr;
            
            tcp_cfg.port = pj_ntohs(a->sin_port);
        }
    }
    
    /* Add TCP transport unless it's disabled */
    if (!app_config.no_tcp) {
        pjsua_acc_id aid;
        
        status = pjsua_transport_create(PJSIP_TRANSPORT_TCP,
                                        &tcp_cfg,
                                        &transport_id);
        if (status != PJ_SUCCESS)
            goto on_error;
        
        /* Add local account */
        pjsua_acc_add_local(transport_id, PJ_TRUE, &aid);
        if (PJMEDIA_HAS_VIDEO) {
            pjsua_acc_config acc_cfg;
            pjsua_acc_get_config(aid, &acc_cfg);
            app_config_init_video(&acc_cfg);
            pjsua_acc_modify(aid, &acc_cfg);
        }
        pjsua_acc_set_online_status(current_acc, PJ_TRUE);
        
    }
    
    
#if defined(PJSIP_HAS_TLS_TRANSPORT) && PJSIP_HAS_TLS_TRANSPORT!=0
    /* Add TLS transport when application wants one */
    if (app_config.use_tls) {
        
        pjsua_acc_id acc_id;
        
        /* Copy the QoS settings */
        tcp_cfg.tls_setting.qos_type = tcp_cfg.qos_type;
        pj_memcpy(&tcp_cfg.tls_setting.qos_params, &tcp_cfg.qos_params,
                  sizeof(tcp_cfg.qos_params));
        
        /* Set TLS port as TCP port+1 */
        tcp_cfg.port++;
        status = pjsua_transport_create(PJSIP_TRANSPORT_TLS,
                                        &tcp_cfg,
                                        &transport_id);
        tcp_cfg.port--;
        if (status != PJ_SUCCESS)
            goto on_error;
        
        /* Add local account */
        pjsua_acc_add_local(transport_id, PJ_FALSE, &acc_id);
        if (PJMEDIA_HAS_VIDEO) {
            pjsua_acc_config acc_cfg;
            pjsua_acc_get_config(acc_id, &acc_cfg);
            app_config_init_video(&acc_cfg);
            pjsua_acc_modify(acc_id, &acc_cfg);
        }
        pjsua_acc_set_online_status(acc_id, PJ_TRUE);
    }
#endif
    
    if (transport_id == -1) {
        PJ_LOG(1, (THIS_FILE, "Error: no transport is configured"));
        status = -1;
        goto on_error;
    }
    
    
    /* Add accounts */
    for (i=0; i<app_config.acc_cnt; ++i) {
        app_config.acc_cfg[i].rtp_cfg = app_config.rtp_cfg;
        app_config.acc_cfg[i].reg_retry_interval = 300;
        app_config.acc_cfg[i].reg_first_retry_interval = 60;
        
        app_config_init_video(&app_config.acc_cfg[i]);
        
        status = pjsua_acc_add(&app_config.acc_cfg[i], PJ_TRUE, NULL);
        if (status != PJ_SUCCESS)
            goto on_error;
        pjsua_acc_set_online_status(current_acc, PJ_TRUE);
    }
    
    /* Add buddies */
    for (i=0; i<app_config.buddy_cnt; ++i) {
        status = pjsua_buddy_add(&app_config.buddy_cfg[i], NULL);
        if (status != PJ_SUCCESS) {
            PJ_PERROR(1,(THIS_FILE, status, "Error adding buddy"));
            goto on_error;
        }
    }
    
    /* Optionally disable some codec */
    for (i=0; i<app_config.codec_dis_cnt; ++i) {
        pjsua_codec_set_priority(&app_config.codec_dis[i],PJMEDIA_CODEC_PRIO_DISABLED);
#if PJSUA_HAS_VIDEO
        pjsua_vid_codec_set_priority(&app_config.codec_dis[i],PJMEDIA_CODEC_PRIO_DISABLED);
#endif
    }
    
    /* Optionally set codec orders */
    for (i=0; i<app_config.codec_cnt; ++i) {
        pjsua_codec_set_priority(&app_config.codec_arg[i],
                                 (pj_uint8_t)(PJMEDIA_CODEC_PRIO_NORMAL+i+9));
#if PJSUA_HAS_VIDEO
        pjsua_vid_codec_set_priority(&app_config.codec_arg[i],
                                     (pj_uint8_t)(PJMEDIA_CODEC_PRIO_NORMAL+i+9));
#endif
    }
    
    /* Add RTP transports */
    if (app_config.ipv6)
        status = create_ipv6_media_transports();
#if DISABLED_FOR_TICKET_1185
    else
        status = pjsua_media_transports_create(&app_config.rtp_cfg);
#endif
    if (status != PJ_SUCCESS)
        goto on_error;
    
    /* Use null sound device? */
    
    if (app_config.capture_dev  != PJSUA_INVALID_ID ||
        app_config.playback_dev != PJSUA_INVALID_ID)
    {
        status = pjsua_set_snd_dev(app_config.capture_dev,
                                   app_config.playback_dev);
        if (status != PJ_SUCCESS)
            goto on_error;
    }
    
    return PJ_SUCCESS;
    
on_error:
    app_destroy();
    return status;
}


static int stdout_refresh_proc(void *arg)
{
    PJ_UNUSED_ARG(arg);
    
    /* Set thread to lowest priority so that it doesn't clobber
     * stdout output
     */
    pj_thread_set_prio(pj_thread_this(),
                       pj_thread_get_prio_min(pj_thread_this()));
    
    while (!stdout_refresh_quit) {
        pj_thread_sleep(stdout_refresh * 1000);
        puts(stdout_refresh_text);
        fflush(stdout);
    }
    
    return 0;
}

pj_status_t app_main(void)
{
    pj_thread_t *stdout_refresh_thread = NULL;
    pj_status_t status;
    
    /* Start pjsua */
    status = pjsua_start();
    if (status != PJ_SUCCESS) {
        app_destroy();
        return status;
    }
    
    /* Start console refresh thread */
    if (stdout_refresh > 0) {
        pj_thread_create(app_config.pool, "stdout", &stdout_refresh_proc,
                         NULL, 0, 0, &stdout_refresh_thread);
    }
    
    console_app_main();
    
    if (stdout_refresh_thread) {
        stdout_refresh_quit = PJ_TRUE;
        pj_thread_join(stdout_refresh_thread);
        pj_thread_destroy(stdout_refresh_thread);
    }
    
    return PJ_SUCCESS;
}

pj_status_t app_destroy(void)
{
    pj_status_t status;
    unsigned i;
    
    /* Close avi devs and ports */
    for (i=0; i<app_config.avi_cnt; ++i) {
        if (app_config.avi[i].slot != PJSUA_INVALID_ID)
            pjsua_conf_remove_port(app_config.avi[i].slot);
#if PJMEDIA_HAS_VIDEO && PJMEDIA_VIDEO_DEV_HAS_AVI
        if (app_config.avi[i].dev_id != PJMEDIA_VID_INVALID_DEV)
            pjmedia_avi_dev_free(app_config.avi[i].dev_id);
#endif
    }
    
    /* Close ringback port */
    if (app_config.ringback_port &&
        app_config.ringback_slot != PJSUA_INVALID_ID)
    {
        pjsua_conf_remove_port(app_config.ringback_slot);
        app_config.ringback_slot = PJSUA_INVALID_ID;
        pjmedia_port_destroy(app_config.ringback_port);
        app_config.ringback_port = NULL;
    }
    
    /* Close ring port */
    if (app_config.ring_port && app_config.ring_slot != PJSUA_INVALID_ID) {
        pjsua_conf_remove_port(app_config.ring_slot);
        app_config.ring_slot = PJSUA_INVALID_ID;
        pjmedia_port_destroy(app_config.ring_port);
        app_config.ring_port = NULL;
    }
    
    /* Close tone generators */
    for (i=0; i<app_config.tone_count; ++i) {
        pjsua_conf_remove_port(app_config.tone_slots[i]);
    }
    
    if (app_config.pool) {
        pj_pool_release(app_config.pool);
        app_config.pool = NULL;
    }
    
    status = pjsua_destroy();
    
    pj_bzero(&app_config, sizeof(app_config));
    
    return status;
}



static pj_status_t create_ipv6_media_transports(void)
{
    pjsua_media_transport tp[PJSUA_MAX_CALLS];
    pj_status_t status;
    int port = app_config.rtp_cfg.port;
    unsigned i;
    
    for (i=0; i<app_config.cfg.max_calls; ++i) {
        enum { MAX_RETRY = 10 };
        pj_sock_t sock[2];
        pjmedia_sock_info si;
        unsigned j;
        
        /* Get rid of uninitialized var compiler warning with MSVC */
        status = PJ_SUCCESS;
        
        for (j=0; j<MAX_RETRY; ++j) {
            unsigned k;
            
            for (k=0; k<2; ++k) {
                pj_sockaddr bound_addr;
                
                status = pj_sock_socket(pj_AF_INET6(), pj_SOCK_DGRAM(), 0, &sock[k]);
                if (status != PJ_SUCCESS)
                    break;
                
                status = pj_sockaddr_init(pj_AF_INET6(), &bound_addr,
                                          &app_config.rtp_cfg.bound_addr,
                                          (unsigned short)(port+k));
                if (status != PJ_SUCCESS)
                    break;
                
                status = pj_sock_bind(sock[k], &bound_addr,
                                      pj_sockaddr_get_len(&bound_addr));
                if (status != PJ_SUCCESS)
                    break;
            }
            if (status != PJ_SUCCESS) {
                if (k==1)
                    pj_sock_close(sock[0]);
                
                if (port != 0)
                    port += 10;
                else
                    break;
                
                continue;
            }
            
            pj_bzero(&si, sizeof(si));
            si.rtp_sock = sock[0];
            si.rtcp_sock = sock[1];
            
            pj_sockaddr_init(pj_AF_INET6(), &si.rtp_addr_name,
                             &app_config.rtp_cfg.public_addr,
                             (unsigned short)(port));
            pj_sockaddr_init(pj_AF_INET6(), &si.rtcp_addr_name,
                             &app_config.rtp_cfg.public_addr,
                             (unsigned short)(port+1));
            
            status = pjmedia_transport_udp_attach(pjsua_get_pjmedia_endpt(),
                                                  NULL,
                                                  &si,
                                                  0,
                                                  &tp[i].transport);
            if (port != 0)
                port += 10;
            else
                break;
            
            if (status == PJ_SUCCESS)
                break;
        }
        
        if (status != PJ_SUCCESS) {
            pjsua_perror(THIS_FILE, "Error creating IPv6 UDP media transport",
                         status);
            for (j=0; j<i; ++j) {
                pjmedia_transport_close(tp[j].transport);
            }
            return status;
        }
    }
    
#if DISABLED_FOR_TICKET_1185
    return pjsua_media_transports_attach(tp, i, PJ_TRUE);
#else
    return PJ_ENOTSUP;
#endif
}


@implementation SipInterface

- (id)initWithConfigPath:(NSString*)configPath
{
    if (self = [super init])
    {
        
    }
    
    return self;
}

@end

