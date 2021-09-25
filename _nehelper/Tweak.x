#include <xpc/xpc.h>
#include <substrate.h>

%hook NEHelperCacheManager
-(void)onQueueHandleMessage:(xpc_object_t)xdict {
    if (xpc_dictionary_get_uint64(xdict, "cache-command") == 3uLL) {
        Class NEHelperServer = %c(NEHelperServer);
        if (![NEHelperServer verifyConnection:xpc_dictionary_get_remote_connection(xdict) hasEntitlement:"com.apple.private.nehelper.privileged"]) {
            [NEHelperServer sendReplyForMessage:xdict result:22LL data:0LL];
            return;
        }
    }
    return %orig;
}
%end

%hook NEHelperWiFiInfoManager
-(BOOL)checkIfEntitled:(NSUInteger)sdkVersion {
    NSUInteger _sdkVersion = sdkVersion <= 1 << 19 ? 1 << 19 : sdkVersion;
    return %orig(_sdkVersion);
}
%end

