#import <Foundation/Foundation.h>

@class TDServiceBrowser;

@protocol TDServiceBrowserDelegate <NSObject>
- (void)browser:(TDServiceBrowser *)browser didFindService:(NSNetService *)service;
- (void)browser:(TDServiceBrowser *)browser didRemoveService:(NSNetService *)service;
@end

@interface TDServiceBrowser : NSObject
@property (nonatomic, weak) id<TDServiceBrowserDelegate> delegate;
@property (nonatomic, readonly) NSMutableArray<NSNetService *> *services;
- (void)startBrowsing;
- (void)stopBrowsing;
@end

@interface TDServiceBrowser () <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
@property (nonatomic, strong) NSNetServiceBrowser *browser;
@end

@implementation TDServiceBrowser

- (instancetype)init {
    if (self = [super init]) {
        _services = [NSMutableArray array];
    }
    return self;
}

- (void)startBrowsing {
    self.browser = [[NSNetServiceBrowser alloc] init];
    self.browser.delegate = self;
    [self.browser searchForServicesOfType:@"_tailsdrop._tcp." inDomain:@"local."];
}

- (void)stopBrowsing {
    [self.browser stop];
    self.browser = nil;
    [self.services removeAllObjects];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)more {
    service.delegate = self;
    [service resolveWithTimeout:5.0];
    [self.services addObject:service];
    if (!more) {
        [self.delegate browser:self didFindService:service];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)more {
    [self.services removeObject:service];
    if (!more) {
        [self.delegate browser:self didRemoveService:service];
    }
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    [self.delegate browser:self didFindService:sender];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    [self.services removeObject:sender];
}

@end
