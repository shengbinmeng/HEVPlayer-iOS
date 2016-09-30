#ifndef __PLAYER_UTILS_H__
#define __PLAYER_UTILS_H__

#ifdef __cplusplus
	#define __STDC_CONSTANT_MACROS
	#define __STDC_LIMIT_MACROS
	#ifdef _STDINT_H
		#undef _STDINT_H
	#endif
	#include <stdint.h>
	#define __STDC_FORMAT_MACROS
#endif

#define ENABLE_LOGD 0

#if ENABLE_LOGD
#define LOGD(...)  printf(__VA_ARGS__)
#else
#define LOGD(...)
#endif
#define LOGI(...) printf(__VA_ARGS__)
#define LOGE LOGI

#endif
