#ifndef UPTIME_H
#define UPTIME_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

__attribute__((visibility("default"))) __attribute__((used))
int64_t getUptimeMillis(void);

#ifdef __cplusplus
}
#endif

#endif
