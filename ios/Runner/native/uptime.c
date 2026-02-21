#include "uptime.h"
#include <time.h>

__attribute__((visibility("default")))
int64_t getUptimeMillis() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (ts.tv_sec * 1000LL) + (ts.tv_nsec / 1000000LL);
}