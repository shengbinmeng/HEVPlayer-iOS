//
//  MoviePlayer.m
//  HEVPlayer
//
//  Created by Shengbin Meng on 13-2-25.
//  Copyright (c) 2013年 Peking University. All rights reserved.
//

#import "MoviePlayer.h"

@implementation MoviePlayer {
    NSString * moviePath;
    NSThread *decodeThread;
    int frameWidth, frameHeight;
    int displayWidth, displayHeight;

}

- (void) setOutputViews:(UIImageView*)anImageView :(UILabel*)anInfoLabel
{
    self.imageView = anImageView;
    self.infoLabel = anInfoLabel;
}

- (int) openMovie:(NSString*) path {
    moviePath = path;
    frameWidth = 1280;
    frameHeight = 720;
    return 0;
}

- (int) play {
    
    decodeThread = [[NSThread alloc] initWithTarget:self selector:@selector(decodeVideo) object:nil];
    [decodeThread start];
    
    return 0;
}

- (int) stop {
    
    return 0;
}



typedef unsigned char PEL;

double getms()
{
	struct timeval pTime;
	gettimeofday(&pTime, NULL);
	double t2 = ((double)pTime.tv_usec / 1000.0);
	return t2;
}

void *align_malloc( int i_size )
{
    return lent_malloc(i_size);
}

void align_free( void *p )
{
    if(p)
		lent_free(p);
}



#define MAX_AU 10000

enum nal_unit_type_e
{
	NAL_UNIT_CODED_SLICE_TRAIL_N = 0,   // 0
	NAL_UNIT_CODED_SLICE_TRAIL_R,   // 1
    
	NAL_UNIT_CODED_SLICE_TSA_N,     // 2
	NAL_UNIT_CODED_SLICE_TLA,       // 3   // Current name in the spec: TSA_R
    
	NAL_UNIT_CODED_SLICE_STSA_N,    // 4
	NAL_UNIT_CODED_SLICE_STSA_R,    // 5
    
	NAL_UNIT_CODED_SLICE_RADL_N,    // 6
	NAL_UNIT_CODED_SLICE_DLP,       // 7 // Current name in the spec: RADL_R
    
	NAL_UNIT_CODED_SLICE_RASL_N,    // 8
	NAL_UNIT_CODED_SLICE_TFD,       // 9 // Current name in the spec: RASL_R
    
	NAL_UNIT_RESERVED_10,
	NAL_UNIT_RESERVED_11,
	NAL_UNIT_RESERVED_12,
	NAL_UNIT_RESERVED_13,
	NAL_UNIT_RESERVED_14,
	NAL_UNIT_RESERVED_15,
    
	NAL_UNIT_CODED_SLICE_BLA,       // 16   // Current name in the spec: BLA_W_LP
	NAL_UNIT_CODED_SLICE_BLANT,     // 17   // Current name in the spec: BLA_W_DLP
	NAL_UNIT_CODED_SLICE_BLA_N_LP,  // 18
	NAL_UNIT_CODED_SLICE_IDR,       // 19  // Current name in the spec: IDR_W_DLP
	NAL_UNIT_CODED_SLICE_IDR_N_LP,  // 20
	NAL_UNIT_CODED_SLICE_CRA,       // 21
	NAL_UNIT_RESERVED_22,
	NAL_UNIT_RESERVED_23,
    
	NAL_UNIT_RESERVED_24,
	NAL_UNIT_RESERVED_25,
	NAL_UNIT_RESERVED_26,
	NAL_UNIT_RESERVED_27,
	NAL_UNIT_RESERVED_28,
	NAL_UNIT_RESERVED_29,
	NAL_UNIT_RESERVED_30,
	NAL_UNIT_RESERVED_31,
    
	NAL_UNIT_VPS,                   // 32
	NAL_UNIT_SPS,                   // 33
	NAL_UNIT_PPS,                   // 34
	NAL_UNIT_ACCESS_UNIT_DELIMITER, // 35
	NAL_UNIT_EOS,                   // 36
	NAL_UNIT_EOB,                   // 37
	NAL_UNIT_FILLER_DATA,           // 38
	NAL_UNIT_SEI,                   // 39 Prefix SEI
	NAL_UNIT_SEI_SUFFIX,            // 40 Suffix SEI
    
	NAL_UNIT_RESERVED_41,
	NAL_UNIT_RESERVED_42,
	NAL_UNIT_RESERVED_43,
	NAL_UNIT_RESERVED_44,
	NAL_UNIT_RESERVED_45,
	NAL_UNIT_RESERVED_46,
	NAL_UNIT_RESERVED_47,
	NAL_UNIT_UNSPECIFIED_48,
	NAL_UNIT_UNSPECIFIED_49,
	NAL_UNIT_UNSPECIFIED_50,
	NAL_UNIT_UNSPECIFIED_51,
	NAL_UNIT_UNSPECIFIED_52,
	NAL_UNIT_UNSPECIFIED_53,
	NAL_UNIT_UNSPECIFIED_54,
	NAL_UNIT_UNSPECIFIED_55,
	NAL_UNIT_UNSPECIFIED_56,
	NAL_UNIT_UNSPECIFIED_57,
	NAL_UNIT_UNSPECIFIED_58,
	NAL_UNIT_UNSPECIFIED_59,
	NAL_UNIT_UNSPECIFIED_60,
	NAL_UNIT_UNSPECIFIED_61,
	NAL_UNIT_UNSPECIFIED_62,
	NAL_UNIT_UNSPECIFIED_63,
	NAL_UNIT_INVALID,
};

unsigned int AUStart[MAX_AU];

int findAU(PEL *buffer,int start, int maxlen)
{
	int k=start;
	static int tag=0;
	while(1){
		if((buffer[k]==0&&buffer[k+1]==0&&buffer[k+2]==1&&(((buffer[k+3]&0x7F)>>1)<=21)))
		{
            break;
		}
		k++;
		if(k+1>maxlen)
			return maxlen;
	}
	return k;
}
void findAUs(PEL *buffer,int maxlen)
{
	int i=0,j=0;
	while(j<maxlen)
	{
		AUStart[i++]=j=findAU(buffer,j,maxlen);
		j++;
	}
	AUStart[0]=0;
	//AUStart[1]=maxlen;
}

void outputFrame(PEL *buffer[3], int frame_size, int width, int stride[3], FILE *file)
{
	int i, height = frame_size * 2 / 3 / width;
	PEL *out = buffer[0];
	for(i = 0; i < height; i ++)
	{
		fwrite(out,1,width,file);
		out += stride[0];
	}
	width >>= 1;
	out = buffer[1];
	for(i = 0; i < height; i += 2)
	{
		fwrite(out,1,width,file);
		out += stride[1];
	}
	out = buffer[2];
	for(i = 0; i < height; i += 2)
	{
		fwrite(out,1,width,file);
		out += stride[2];
	}
}


#define LERP(A,B,C) ((A)*(1.0-C)+(B)*C)

- (void) decodeVideo
{
    
    DecodeCore decoder;
	long framesGot=0,bytesUsed;
	decoder.Set_Thread(4);
    
	decoder.StartDecoder(91);
    
    
	PEL *bitstream;
	int remainLen;//
	bitstream=(PEL*)align_malloc(1024*1024*100);
	memset(bitstream,0,1024*1024*100);
	FILE *in;
	in=fopen(media.data_src,"rb");
	if(!in) {
		lent_log(NULL, LENT_LOG_ERROR, "can not open input file '%s'!\n", media.data_src);
		return NULL;
	}
	remainLen=fread(bitstream,1,1024*1024*100,in);
	fclose(in);
	findAUs(bitstream,remainLen);
    
	lent_log(NULL, LENT_LOG_DEBUG, "input file opened\n");
    __android_log_print(ANDROID_LOG_INFO, TAG, "input file opened: %s\n", media.data_src);
    
    
#ifdef OUTPUTYUV
    FILE *fout = NULL;
    char out_file[1024];
    strcpy(out_file, media.data_src);
    strcat(out_file, ".yuv");
    fout = fopen(out_file, "wb");
    if ( NULL == fout ) {
        lent_log(NULL, LENT_LOG_ERROR, "can not create output file '%s'!\n", out_file);
        __android_log_print(ANDROID_LOG_ERROR, TAG, "can not create output file '%s'!\n", out_file);
        return NULL;
    }
#endif
    
	int count=0,i=0;
	int tStart=clock();
	PEL *OutputYUV[3];
	int stride[3], width = 0;
    
    
	while(AUStart[i+1])
	{
		__android_log_print(ANDROID_LOG_DEBUG, TAG, "before decode a frame: %.3f *****", getms());
		bytesUsed=AUStart[i+1]-AUStart[i];
		decoder.DecodeFrame(bitstream+AUStart[i],OutputYUV,&bytesUsed,NULL,&width,stride);
	    __android_log_print(ANDROID_LOG_INFO, TAG, "DecodeFrame returned\n");
		if(bytesUsed)
		{
			lent_dlog(NULL,"decoded a picture: %d\n",count);
		    __android_log_print(ANDROID_LOG_INFO, TAG, "decoded a picture: %d\n",count);
            
			count++;
            
			// draw frame to screen
			frame.yuv_data = OutputYUV;
			frame.linesize_y = stride[0];
			frame.linesize_uv = stride[1];
			drawFrame(&frame);
            
#ifdef OUTPUTYUV
			//if(count>100)
			if ( NULL != fout )
			{
				//fwrite(buffer,bytesUsed,1,fout);
				outputFrame(OutputYUV,bytesUsed,width,stride,fout);
			}
#endif
			{
				timeval pTime;
				static int frames = 0;
				static double t1 = 0;
				static double t2 = 0;
                
				gettimeofday(&pTime, NULL);
				t2 = pTime.tv_sec + (pTime.tv_usec / 1000000.0);
				if (t2 > t1 + 1) {
					if(FPS_DEBUGGING) __android_log_print(ANDROID_LOG_INFO, TAG, "Video Decode FPS:%i", int(frames));
					postEvent(903, int(frames), 0);
					t1 = t2;
					frames = 0;
				}
				frames++;
			}
			__android_log_print(ANDROID_LOG_DEBUG, TAG, "after render this frame: %.3f *****", getms());
            
		}
		else
		{
			//printf("decoded no pic!\n");
		    __android_log_print(ANDROID_LOG_INFO, TAG, "decoded no picture\n");
		}
        
		if(bytesUsed<0)
		{
			//printf("decode error\n");
			break;
		}
		i++;
		//if(i>=49)
		//	break;
	}
    
	do{
		bytesUsed=0;
		decoder.DecodeFrame(0,OutputYUV,&bytesUsed,0,&width,stride);
		if(bytesUsed)
		{
			lent_dlog(NULL,"decoded a picture: %d\n",count);
			count++;
#ifdef OUTPUTYUV
			//if(count>100)
			if ( NULL != fout )
			{
				//fwrite(buffer,bytesUsed,1,fout);
				outputFrame(OutputYUV,bytesUsed,width,stride,fout);
			}
#endif
		}
		if(bytesUsed<0)
		{
			//printf("decode error\n");
			break;
		}
	}while(bytesUsed);
    
	lent_log(NULL,LENT_LOG_DEBUG,"Decoding time: %d ms\nSpeed: %d FPS.\n",clock()-tStart,count*1000/(clock()-tStart));
#ifdef OUTPUTYUV
    if ( NULL != fout )
        fclose(fout);
#endif
	align_free(bitstream);
	//align_free(buffer);
	//getchar();
	decoder.UninitDecoder();
    
	detachJVM();

    //[NSThread setThreadPriority:0.6];
    
    while (1) {
        
        {
            struct timeval pTime;
            static int frames = 0;
            static double t1 = 0;
            static double t2 = 0;
            gettimeofday(&pTime, NULL);
            t2 = pTime.tv_sec + (pTime.tv_usec / 1000000.0);
            if (t2 > t1 + 1) {
                frameTime = LERP(frameTime, frames, 0.8);
                t1 = t2;
                frames = 0;
            }
            frames++;
        }
        
        [self performSelectorOnMainThread:@selector(displayFrame:) withObject:self waitUntilDone:YES];
    }
}

-(UIImage *)displayFrame:(struct VideoFrame *) vf {
    
    int width = stateInst.pMovieInst->video.frame_width;
    int height = stateInst.pMovieInst->video.frame_height;
    vf = currentVF;
    AVPicture *pict = vf->picture;
    //PMSG1("picture: %p, %d\n", pict, pict->linesize[0]);
    
	CGBitmapInfo bitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault;
	CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pict->data[0], pict->linesize[0] * height, kCFAllocatorDefault);
	CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGImageRef cgImage = CGImageCreate(width,
									   height,
									   8,
									   32,
									   pict->linesize[0],
									   colorSpace,
									   bitmapInfo,
									   provider,
									   NULL,
									   NO,
									   kCGRenderingIntentDefault);
	CGColorSpaceRelease(colorSpace);
	UIImage *image = [UIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	CGDataProviderRelease(provider);
	CFRelease(data);
    
	av_free(pict);
    free(vf);
    
    [self.imageView setImage:image];
    
    struct timeval pTime;
    static int frames = 0;
    static double t1 = 0;
    static double t2 = 0;
    gettimeofday(&pTime, NULL);
    t2 = pTime.tv_sec + (pTime.tv_usec / 1000000.0);
    if (t2 > t1 + 1) {
        [self.infoLabel setText:[NSString stringWithFormat:@"size:%dx%d\n display FPS:%d, decode PFS: %d",width, height, frames, (int)frameTime]];
        t1 = t2;
        frames = 0;
    }
    frames++;
    
	return image;
}



@end
