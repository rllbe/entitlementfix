#include <substrate.h>

NSString *(*GKImageCacheRoot)(id);

NSString *(*orig_GKImageCachePathForURL)(NSURL *);
NSString *mod_GKImageCachePathForURL(NSURL *url) {
    if ([url isFileURL] && ![[url.path stringByResolvingSymlinksInPath] hasPrefix:GKImageCacheRoot(nil)])
        return [GKImageCacheRoot(url) stringByAppendingPathComponent:[[url lastPathComponent] cacheKeyRepresentation]];
    return orig_GKImageCachePathForURL(url);
}

NSString *(*orig_GKImageCachePathForSubdirectoryAndFilename)(NSString *, NSString *);
NSString *mod_GKImageCachePathForSubdirectoryAndFilename(NSString *subdirectory, NSString *filename) {
    return orig_GKImageCachePathForSubdirectoryAndFilename(subdirectory, [filename cacheKeyRepresentation]);
}

%hook NSString
-(NSString *)cacheKeyRepresentation {
    NSString *result = %orig;
    if ([result isEqualToString:@".."]) return @"__";
    return result;
}
%end

%hook GKAccountService
-(void)authenticatePlayerWithExistingCredentialsWithHandler:(id)handler {
    if (![[[self clientProxy] entitlements] hasEntitlements:[%c(GKAccountServicePrivate) requiredEntitlements]]) return;
    %orig;
}
%end

%hook GKEntitlements
-(instancetype)initWithConnection:(NSXPCConnection *)connection {
    id _self = %orig;
    if (![_self _valuesForEntitlement:@"com.apple.private.game-center" forConnection:connection]) {
        if (![_self _valuesForEntitlement:@"com.apple.developer.game-center" forConnection:connection]) MSHookIvar<uint64_t>(_self, "_entitlements") = 0;
        else MSHookIvar<uint64_t>(_self, "_entitlements") &= 0xF7F7;
    }
    return _self;
}
%end

%ctor {
    MSImageRef selfImage = MSGetImageByName("/usr/libexec/gamed");
    GKImageCacheRoot = (NSString *(*)(id))MSFindSymbol(selfImage, "_GKImageCacheRoot");
    
    void *symbol = NULL;
    if (symbol = MSFindSymbol(selfImage, "_GKImageCachePathForURL"))
        MSHookFunction(symbol, (void *)mod_GKImageCachePathForURL, (void **)&orig_GKImageCachePathForURL);
    if (symbol = MSFindSymbol(selfImage, "_GKImageCachePathForSubdirectoryAndFilename"))
            MSHookFunction(symbol, (void *)mod_GKImageCachePathForSubdirectoryAndFilename, (void **)&orig_GKImageCachePathForSubdirectoryAndFilename);
}
