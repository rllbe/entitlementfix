#include <substrate.h>

@interface GKInternalRepresentation : NSObject
@end

@interface GKPlayerCredential : GKInternalRepresentation
@end

@interface GKAuthenticateResponse : GKInternalRepresentation
@property(nonatomic, retain) GKPlayerCredential *credential;
@property(nonatomic, retain) NSURL *passwordChangeURL;
@end

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
-(void)authenticatePlayerWithExistingCredentialsWithHandler:(void(^)(GKAuthenticateResponse *, NSError *))handler {
    void (^_handler)(GKAuthenticateResponse *, NSError *) = ^(GKAuthenticateResponse *response, NSError *error) {
        if (response && ![[[self clientProxy] entitlements] hasEntitlements:[%c(GKAccountServicePrivate) requiredEntitlements]]) { response.credential = nil;
            response.passwordChangeURL = nil;
        }
        handler(response, error);
    };
    %orig(_handler);
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
