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
