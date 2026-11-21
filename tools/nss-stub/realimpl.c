#include <time.h>
#include <string.h>
#include <stdint.h>
long long PR_Now(void){struct timespec ts;clock_gettime(CLOCK_REALTIME,&ts);return (long long)ts.tv_sec*1000000LL+ts.tv_nsec/1000;}
long long PR_IntervalNow(void){struct timespec ts;clock_gettime(CLOCK_MONOTONIC,&ts);return (long long)ts.tv_sec*1000LL+ts.tv_nsec/1000000;}
long PR_Init(void*a,void*b,void*c,void*d,void*e,void*f,void*g,void*h){return 0;}
long PR_Cleanup(void*a,void*b,void*c,void*d,void*e,void*f,void*g,void*h){return 0;}
long PR_GetError(void*a,void*b,void*c,void*d,void*e,void*f,void*g,void*h){return 0;}
long PR_GetOSError(void*a,void*b,void*c,void*d,void*e,void*f,void*g,void*h){return 0;}
long PR_GetErrorTextLength(void*a,void*b,void*c,void*d,void*e,void*f,void*g,void*h){return 0;}
long PR_GetErrorText(void*a,void*b,void*c,void*d,void*e,void*f,void*g,void*h){return 0;}
