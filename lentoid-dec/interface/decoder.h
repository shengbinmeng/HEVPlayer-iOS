//**********************************************
//decoder.h
//Unipipy @2011
//Main C++ entrance of this decoder
//**********************************************
#ifndef INTERFACE_DECODER_H
#define INTERFACE_DECODER_H

#include <inttypes.h>

struct LentCodecContext;
struct LentFrame;

class DecodeCore
{
public:

	DecodeCore();
	~DecodeCore();

	void Set_Thread(int n);
	void Clean();
	void FlushDecoder();


	void DecodeFrame(unsigned char *InputNalBuffer, unsigned char **OutputYUVBuffer, long *pDataLength, int64_t* pts, int *width, int stride[3]);

	int StartDecoder();
	void UninitDecoder();
	bool IsReleased();

private:

	int i_thread;

	LentCodecContext *ctx;
	LentFrame *frame;
};

#endif