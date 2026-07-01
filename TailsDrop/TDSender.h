#import <Foundation/Foundation.h>

@interface TDSender : NSObject
+ (void)sendFileAtURL:(NSURL *)fileURL toHost:(NSString *)host port:(NSInteger)port completion:(void(^)(BOOL success, NSString *msg))completion;
@end
