#ifdef WIN32
#include <Windows.h>
#include <tchar.h>
#endif
#include <stdint.h>
#include "log.h"
#include "../decoder/codec.h"
#include "sink.h"


enum LENTSINKTYPE{
	LENTSINKTYPE_DEC_IN_BS
};

struct LENTSINKHDR {
	uint32_t pid;
	uint32_t tid;
	uint32_t type;
	uint32_t len;
};

struct LENTBSSINKHDR {
	struct LENTSINKHDR sink_hdr;
	int64_t pts;
	uint8_t bs[1024 * 64 - sizeof(struct LENTSINKHDR) - sizeof(int64_t)];
};

#ifdef WIN32

#define LENT_SINK_MUTEX_NAME		_T("LentSinkMutex")
#define LENT_SINK_BUFFER_NAME		_T("LentSinkBuffer")
#define LENT_SINK_BUF_READY_NAME	_T("LentSinkBufferReady")
#define LENT_SINK_DATA_READY_NAME	_T("LentSinkDataReady")

static void lentoid_input_sink_win32(LentCodecContext *ctx, const uint8_t *data, int len, int64_t pts)
{
	HANDLE hFileMap = NULL, hBufEvt = NULL, hDataEvt = NULL;
	struct LENTBSSINKHDR *pSinkBuf = NULL;
	int success = 1;

	if ( NULL == ctx->sink_mutex )
		ctx->sink_mutex = CreateMutex(NULL, FALSE, LENT_SINK_MUTEX_NAME);

	if ( NULL == ctx->sink_mutex )
		return;

	WaitForSingleObject(ctx->sink_mutex, INFINITE);

	hFileMap = OpenFileMapping(FILE_MAP_WRITE, FALSE, LENT_SINK_BUFFER_NAME);
	if ( NULL == hFileMap )
		success = 0;
	if ( success ) {
		pSinkBuf = (struct LENTBSSINKHDR *) MapViewOfFile(hFileMap, FILE_MAP_READ|FILE_MAP_WRITE, 0, 0, 0);
		if ( NULL == pSinkBuf )
			success = 0;
	}
	if ( success ) {
		hBufEvt  = OpenEvent( SYNCHRONIZE, FALSE, LENT_SINK_BUF_READY_NAME);
		if ( NULL == hBufEvt )
			success = 0;
	}
	if ( success ) {
		hDataEvt = OpenEvent( EVENT_MODIFY_STATE, FALSE, LENT_SINK_DATA_READY_NAME);
		if ( NULL == hDataEvt )
			success = 0;
	}

	while ( success && len > 0 ) {

		int piece = min(len, sizeof(pSinkBuf->bs));

		if ( WaitForSingleObject(hBufEvt, 10*1000) != WAIT_OBJECT_0 )
		{
			/* ERROR: give up */
			break;
		}
		// populate the shared memory segment. The string
		// is limited to 4k or so.
		pSinkBuf->sink_hdr.pid = GetCurrentProcessId();
		pSinkBuf->sink_hdr.tid = GetCurrentThreadId();
		pSinkBuf->sink_hdr.type = LENTSINKTYPE_DEC_IN_BS;
		pSinkBuf->sink_hdr.len = sizeof(struct LENTBSSINKHDR) - sizeof(pSinkBuf->bs) + piece;

		memcpy(pSinkBuf->bs, data, piece);
		len -= piece;
		data += piece;

		SetEvent(hDataEvt);
	}

	// cleanup after ourselves
	if ( NULL != hBufEvt )
		CloseHandle(hBufEvt);
	if ( NULL != hDataEvt )
		CloseHandle(hDataEvt);
	if ( NULL != pSinkBuf )
		UnmapViewOfFile(pSinkBuf);
	if ( NULL != hFileMap )
		CloseHandle(hFileMap);
	ReleaseMutex(ctx->sink_mutex);
}

#endif

void lentoid_input_sink(LentCodecContext *ctx, const uint8_t *data, int len, int64_t pts)
{
#ifdef WIN32
	lentoid_input_sink_win32(ctx, data, len, pts);
#endif
}
