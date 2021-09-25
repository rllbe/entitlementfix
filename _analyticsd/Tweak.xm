#include <substrate.h>

int64_t (*orig_std__string__compare)(uint64_t, uint64_t, char const *, uint64_t);
int64_t mod_std__string__compare(uint64_t a1, uint64_t a2, char const *string, uint64_t length) {
    if (length == 8 && strcmp(string, "log-dump") == 0) return -1;
    return orig_std__string__compare(a1, a2, string, length);
}

%ctor {
    void *symbol = MSFindSymbol(MSGetImageByName("/System/Library/PrivateFrameworks/CoreAnalytics.framework/Support/analyticsd"), "__ZNKSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE7compareEmmPKcm");
    if (symbol) MSHookFunction(symbol, (void *)mod_std__string__compare, (void **)&orig_std__string__compare);
}
