//
//  MoviePlayer.m
//  HEVPlayer
//
//  Created by Shengbin Meng on 13-2-25.
//  Copyright (c) 2013 Peking University. All rights reserved.
//

#import "MoviePlayer.h"
#import "GLRenderer.h"

#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "lenthevcdec.h"
#include <sys/sysctl.h>
#include <sys/time.h>

static AVFormatContext *ff_fmt_ctx = NULL;
static AVCodecContext *ff_vid_dec_ctx = NULL;
static int ff_vid_strm_idx = -1;
static AVFrame *ff_frame = NULL;
static AVPacket ff_pkt;
static int exit_decode_thread = 0;
static int ff_threads = 1;

static const uint32_t AU_COUNT_MAX = 1024 * 256;
static const uint32_t AU_BUF_SIZE_MAX = 1024 * 1024 * 128;
static uint32_t au_pos[AU_COUNT_MAX];
static uint32_t au_count, au_buf_size;
static uint8_t *au_buf;
static lenthevcdec_ctx ctx = NULL;

static struct VideoFrame frame;

static int frames_sum = 0;
static double tstart = 0;
static int frames = 0;
static double tlast = 0;
static float renderFPS = 0;
static uint64_t renderInterval = 0;
static struct timeval timeStart;

static unsigned int count_cores()
{
    size_t len;
    unsigned int ncpu = 0;
    
    len = sizeof(ncpu);
    sysctlbyname ("hw.ncpu", &ncpu, &len, NULL, 0);
    return ncpu;
}

uint32_t getms()
{
	struct timeval t;
	gettimeofday(&t, NULL);
	return (t.tv_sec * 1000) + (t.tv_usec / 1000);
}


@implementation MoviePlayer

{
    NSString *moviePath;
    NSThread *decodeThread;
    BOOL isBusy, stopRender;
}

@synthesize renderer, infoString;

- (id) init
{
    self = [super init];
    
    isBusy = NO;
    stopRender = NO;
    return self;
}

- (void) setupRenderer
{
    [self.renderer setRenderStateListener:self];
}

- (void) bufferDone {
    isBusy = NO;
}

- (void) renderFrame:(struct VideoFrame *) vf
{
    vf = &frame;
    
	struct timeval timeNow;
	gettimeofday(&timeNow, NULL);
	int64_t timePassed = ((int64_t)(timeNow.tv_sec - timeStart.tv_sec))*1000000 + (timeNow.tv_usec - timeStart.tv_usec);
	int64_t delay = vf->pts - timePassed;
	if (delay > 0) {
		usleep(delay);
	}
    
	gettimeofday(&timeNow, NULL);
	double tnow = timeNow.tv_sec + (timeNow.tv_usec / 1000000.0);
	if (tlast == 0) tlast = tnow;
	if (tstart == 0) tstart = tnow;
	if (tnow > tlast + 1) {
		double avg_fps;
        
		printf("Video Display FPS:%i", (int)frames);
		frames_sum += frames;
		avg_fps = frames_sum / (tnow - tstart);
		printf("Video AVG FPS:%.2lf", avg_fps);
        
        self.infoString = [NSString stringWithFormat:@"size:%dx%d, fps:%d", vf->width, vf->height, frames];
        
		tlast = tlast + 1;
		frames = 0;
	}
	frames++;
    
    
    while(isBusy && !stopRender) usleep(50);
    isBusy = YES;
    [renderer render:vf];
}

static int ff_open_codec_context(int *stream_idx,
                                 AVFormatContext *fmt_ctx, enum AVMediaType type)
{
    int ret;
    AVStream *st;
    AVCodecContext *dec_ctx = NULL;
    AVCodec *dec = NULL;
    
    ret = av_find_best_stream(fmt_ctx, type, -1, -1, NULL, 0);
    if (ret < 0) {
        return ret;
    } else {
        *stream_idx = ret;
        st = fmt_ctx->streams[*stream_idx];
        
        /* find decoder for the stream */
        dec_ctx = st->codec;
        dec = avcodec_find_decoder(dec_ctx->codec_id);
        if (!dec) {
            printf("failed to find %s codec\n",
                   av_get_media_type_string(type));
            return ret;
        }
        
        dec_ctx->thread_count = ff_threads;
        if ((ret = avcodec_open2(dec_ctx, dec, NULL)) < 0) {
            return ret;
        }
    }
    
    return 0;
}

- (int) prepare:(int) thread_num
{
    // save decode thread number
	ff_threads = thread_num;
    
	// init ffmepg
	av_register_all();
    
	// open input file
	if ( avformat_open_input(&ff_fmt_ctx, [moviePath UTF8String], NULL, NULL) < 0 ) {
		printf("call avformat_open_intput() failed!\n");
		return -1;
	}
    
	// retrieve stream information
	if ( avformat_find_stream_info(ff_fmt_ctx, NULL) < 0 ) {
		printf("call avformat_find_stream_info() failed!\n");
		return -2;
	}
	if ( ff_open_codec_context(&ff_vid_strm_idx, ff_fmt_ctx, AVMEDIA_TYPE_VIDEO) < 0 ) {
		printf("Can not find video stream in the input file!\n");
		return -3;
	}
    
	AVStream *ff_vid_stream = ff_fmt_ctx->streams[ff_vid_strm_idx];
	ff_vid_dec_ctx = ff_vid_stream->codec;
    char codec_name[256];
    avcodec_string(codec_name, sizeof(codec_name), ff_vid_dec_ctx, 0);
    printf("vid_strm(%d): id = %d, codec = %d(%s)\n"
           "\t width = %d, height = %d\n",
           ff_vid_strm_idx, ff_vid_stream->id, ff_vid_dec_ctx->codec_id, codec_name,
           ff_vid_dec_ctx->width, ff_vid_dec_ctx->height);
	
	ff_frame = avcodec_alloc_frame();
	if ( NULL == ff_frame ) {
		printf("call avcodec_alloc_frame() failed!\n");
		return -5;
	}
    
	av_init_packet(&ff_pkt);
	ff_pkt.data = NULL;
	ff_pkt.size = 0;
    
    // save picture size
    frame.width = ff_vid_dec_ctx->width;
    frame.height = ff_vid_dec_ctx->height;
    
    return 0;
}



static int lent_hevc_get_sps(uint8_t* buf, int size, uint8_t** sps_ptr)
{
    int i, nal_type, sps_pos;
    sps_pos = -1;
    for ( i = 0; i < (size - 4); i++ ) {
        if ( 0 == buf[i] && 0 == buf[i+1] && 1 == buf[i+2] ) {
            nal_type = (buf[i+3] & 0x7E) >> 1;
            if ( 33 != nal_type && sps_pos >= 0 ) {
                break;
            }
            if ( 33 == nal_type ) { // sps
                sps_pos = i;
            }
            i += 2;
        }
    }
    if ( sps_pos < 0 )
        return 0;
    if ( i == (size - 4) )
        i = size;
    *sps_ptr = buf + sps_pos;
    return i - sps_pos;
}

static int lent_hevc_get_frame(uint8_t* buf, int size, int *is_idr)
{
	static int seq_hdr = 0;
	int i, nal_type, idr = 0;
	for ( i = 0; i < (size - 6); i++ ) {
		if ( 0 == buf[i] && 0 == buf[i+1] && 1 == buf[i+2] ) {
			nal_type = (buf[i+3] & 0x7E) >> 1;
			if ( nal_type <= 21 ) {
				if ( buf[i+5] & 0x80 ) { /* first slice in pic */
					if ( !seq_hdr )
						break;
					else
						seq_hdr = 0;
				}
			}
			if ( nal_type >= 32 && nal_type <= 34 ) {
				if ( !seq_hdr ) {
					seq_hdr = 1;
					idr = 1;
					break;
				}
				seq_hdr = 1;
			}
			i += 2;
		}
	}
	if ( i == (size - 6) )
		i = size;
	if ( NULL != is_idr )
		*is_idr = idr;
	return i;
}

- (int) lent_hevc_prepare:(int) thread_num
{
    // open hevc decoder
    int compatibility = INT32_MAX;
    if ([[moviePath pathExtension] isEqualToString:@"hm91"]) {
        compatibility = 91;
    } else if ([[moviePath pathExtension] isEqualToString:@"hm10"]) {
        compatibility = 100;
    }
    if (thread_num == 0) {
        thread_num = count_cores();
    }
    ctx = lenthevcdec_create(thread_num, compatibility, NULL);
    if ( NULL == ctx ) {
        fprintf(stderr, "call lenthevcdec_create failed!\n");
        return -1;
    }
    printf("raw bitstream, compatibility: %s\n",
           (91 == compatibility) ? "HM9.1" : ((100 == compatibility) ? "HM10.0" : "Unknown(Last)"));
    
    // read intput file
    printf("read input file ");
    fflush(stdout);
    FILE *in_file = fopen([moviePath UTF8String], "rb");
    if ( NULL == in_file ) {
        fprintf(stderr, " failed! can not open input file '%s'!\n",
                [moviePath UTF8String]);
        return -1;
    }
    
    fseek(in_file, 0, SEEK_END);
    au_buf_size = ftell(in_file);
    fseek(in_file, 0, SEEK_SET);
    printf("(%d bytes) ... ", au_buf_size);
    if ( au_buf_size > AU_BUF_SIZE_MAX )
        au_buf_size = AU_BUF_SIZE_MAX;
    au_buf = (uint8_t*)malloc(au_buf_size);
    if ( NULL == au_buf ) {
        perror("allocate AU buffer");
        fclose(in_file);
        return -1;
    }
    if ( fread(au_buf, 1, au_buf_size, in_file) != au_buf_size ) {
        perror("read intput file failed");
        fclose(in_file);
        return -1;
    }
    fclose(in_file);
    printf("done. %d bytes read.\n", au_buf_size);
    
    // find all AUs
	au_count = 0;
	for (int i = 0; i < au_buf_size && au_count < (AU_COUNT_MAX - 1); i+=3 ) {
		i += lent_hevc_get_frame(au_buf + i, au_buf_size - i, NULL);
		au_pos[au_count++] = i;
	}
	au_pos[au_count] = au_buf_size; // include last AU
    printf("found %d AUs\n", au_count);
    
    
    int64_t pts;
    int got_frame, width, height, stride[3];
    uint8_t* pixels[3];
    int ret;
    uint8_t *sps;
    int sps_len = lent_hevc_get_sps(au_buf, au_buf_size, &sps);
    if ( sps_len > 0 ) {
        width = 0;
        height = 0;
        lenthevcdec_ctx one_thread_ctx = lenthevcdec_create(1, compatibility, NULL);
        ret = lenthevcdec_decode_frame(one_thread_ctx, sps, sps_len, 0, &got_frame, &width, &height, stride, (void**)pixels, &pts);
        if ( 0 != width && 0 != height ) {
            printf("Video dimensions is %dx%d\n", width, height);
            // initialization that depends on width and heigt
            frame.width = width;
            frame.height = height;
        }
        lenthevcdec_destroy(one_thread_ctx);
        
    }
    
    return 0;
}

- (void) setOutputViews:(UIImageView*)anImageView :(UILabel*)anInfoLabel
{
    self.imageView = anImageView;
    self.infoLabel = anInfoLabel;
}

- (int) openMovie:(NSString*) path
{
    moviePath = path;
	if(!fopen([moviePath UTF8String], "rb")) {
		printf("can not open input file '%s'!\n", [moviePath UTF8String]);
        return -1;
	}
    
    frames_sum = 0;
	tstart = 0;
	frames = 0;
	tlast = 0;
	renderFPS = 0;
	renderInterval = 0;
    
    return 0;
}

- (int) play
{
    // prepare decoder
    NSString *num = [[NSUserDefaults standardUserDefaults] valueForKey:@"threadNum"];
    int thread_num = [num integerValue];
    
    NSString *fps = [[NSUserDefaults standardUserDefaults] valueForKey:@"renderFPS"];
    renderFPS = [fps floatValue];
	if (renderFPS == 0) renderInterval = 1;
	else {
		renderInterval = 1.0 / renderFPS * 1000000; // us
	}
    
    printf("will play with decoding thread number: %d, and FPS: %.2f", thread_num, renderFPS);

    
    if ([[moviePath pathExtension] isEqualToString:@"flv"]) {
        int ret = [self prepare:thread_num];
        if (ret < 0) {
            if (ff_vid_dec_ctx != NULL) avcodec_close(ff_vid_dec_ctx);
            if (ff_fmt_ctx != NULL) avformat_close_input(&ff_fmt_ctx);
            if (ff_frame != NULL) av_free(ff_frame);
            ff_fmt_ctx = NULL;
            ff_vid_dec_ctx = NULL;
            ff_vid_strm_idx = -1;
            ff_frame = NULL;
            ff_pkt.data = NULL;
            return ret;
        }
    } else {
        int ret = [self lent_hevc_prepare:thread_num];
        if (ret < 0) {
            if (au_buf != NULL) free(au_buf);
            if (ctx != NULL) lenthevcdec_destroy(ctx);
            return ret;
        }
    }
    
    decodeThread = [[NSThread alloc] initWithTarget:self selector:@selector(decodeVideo) object:nil];
    [decodeThread start];
    
    return 0;
}

- (int) stop
{
	exit_decode_thread = 1;
    stopRender = YES;
    return 0;
}

- (void) decodeVideo
{
    exit_decode_thread = 0;
    
    [self setupRenderer];
    
    NSString *extension = [moviePath pathExtension];
    if ([extension isEqualToString:@"flv"]) {
        
        int end_of_file, got_frame, ret, frame_count;
        printf("decode thread start ... \n");
        frame_count = 0;
        end_of_file = 0;
        while ( !exit_decode_thread && (!end_of_file || (end_of_file && !got_frame)) ) {
            if ( !end_of_file ) {
                ret = av_read_frame(ff_fmt_ctx, &ff_pkt);
                if ( ret < 0 ) { // end of file
                    ff_pkt.data = NULL; // flush decoder
                    ff_pkt.size = 0;
                    end_of_file = 1;
                } else {
                    if ( ff_pkt.stream_index != ff_vid_strm_idx )
                        continue;
                    printf("read frame: size = %d\n", ff_pkt.size);
                }
            }
            ret = avcodec_decode_video2(ff_vid_dec_ctx, ff_frame, &got_frame, &ff_pkt);
            if ( ret < 0 ) {
                printf("call avcodec_decode_video2() failed !\n");
                break;
            }
            if ( got_frame ) {
                // draw frame to screen
                frame.linesize_y = ff_frame->linesize[0];
                frame.linesize_uv = ff_frame->linesize[1];
                frame.yuv_data[0] = ff_frame->data[0];
                frame.yuv_data[1] = ff_frame->data[1];
                frame.yuv_data[2] = ff_frame->data[2];
                frame.pts = frame_count * renderInterval;
                
                printf("decode frame: pts = %f\n", frame.pts);
                
                if (frame_count == 0) {
                    gettimeofday(&timeStart, NULL);
                }
                frame_count++;
                
                [self renderFrame:&frame];
                
            }
        }
        
        printf("decode thread exit\n");
        
        if (ff_vid_dec_ctx != NULL) avcodec_close(ff_vid_dec_ctx);
        if (ff_fmt_ctx != NULL) avformat_close_input(&ff_fmt_ctx);
        if (ff_frame != NULL) av_free(ff_frame);
        ff_fmt_ctx = NULL;
        ff_vid_dec_ctx = NULL;
        ff_vid_strm_idx = -1;
        ff_frame = NULL;
        ff_pkt.data = NULL;
        
    } else {
        
        // decode video
        int64_t pts, got_pts, ms_used;
        clock_t clock_start, clock_end, clock_used;
        struct timeval tv_start, tv_end;
        double real_time;
        int got_frame, width, height, stride[3];
        uint8_t* pixels[3];
        int ret;
        int frame_count = 0;
        
        gettimeofday(&tv_start, NULL);
        clock_start = clock();
        for (int i = 0; i < au_count; i++ ) {
            if (exit_decode_thread) {
                break;
            }
            pts = i * 40;
            ret = lenthevcdec_decode_frame(ctx, au_buf + au_pos[i], au_pos[i + 1] - au_pos[i], pts, &got_frame, &width, &height, stride, (void**)pixels, &got_pts);
            if ( ret < 0 ) {
                fprintf(stderr, "lenthevcdec_decode_frame failed! ret=%d\n", ret);
                return ;
            }
            if ( got_frame > 0 ) {
                
                // draw frame to screen
                frame.yuv_data[0] = pixels[0];
                frame.yuv_data[1] = pixels[1];
                frame.yuv_data[2] = pixels[2];
                frame.linesize_y = stride[0];
                frame.linesize_uv = stride[1];
                frame.pts = frame_count * renderInterval;
                
                printf("decode frame: pts = %f\n", frame.pts);
                
                if (frame_count == 0) {
                    gettimeofday(&timeStart, NULL);
                }
                frame_count++;
                
                [self renderFrame:&frame];
                
            }
        }
        
        // flush decoder
        while (1) {
            if (exit_decode_thread) {
                break;
            }
            ret = lenthevcdec_decode_frame(ctx, NULL, 0, pts,
                                           &got_frame, &width, &height, stride, (void**)pixels, &got_pts);
            if ( ret <= 0 )
                break;
            if ( got_frame > 0 ) {
                // draw frame to screen
                frame.yuv_data[0] = pixels[0];
                frame.yuv_data[1] = pixels[1];
                frame.yuv_data[2] = pixels[2];
                frame.linesize_y = stride[0];
                frame.linesize_uv = stride[1];
                frame.pts = frame_count * renderInterval;
                
                printf("decode frame: pts = %f\n", frame.pts);
                
                if (frame_count == 0) {
                    gettimeofday(&timeStart, NULL);
                }
                frame_count++;
                
                [self renderFrame:&frame];
            }
        }
        
        clock_end = clock();
        gettimeofday(&tv_end, NULL);
        clock_used = clock_end - clock_start;
        ms_used = (int64_t)(clock_used * 1000.0 / CLOCKS_PER_SEC);
        real_time = (tv_end.tv_sec + (tv_end.tv_usec / 1000000.0)) - (tv_start.tv_sec + (tv_start.tv_usec / 1000000.0));
        printf("%d frame decoded\n"
               "\ttime\tfps\n"
               "CPU\t%lldms\t%.2f\n"
               "Real\t%.3fs\t%.2f.\n",
               frame_count,
               ms_used, frame_count * 1000.0 / ms_used,
               real_time, frame_count / real_time);
        
        free(au_buf);
        au_buf = NULL;
        lenthevcdec_destroy(ctx);
    }
    
    exit_decode_thread = 0;
}


@end
