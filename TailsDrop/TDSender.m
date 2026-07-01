#import <Foundation/Foundation.h>

@interface TDSender : NSObject
+ (void)sendFileAtURL:(NSURL *)fileURL toHost:(NSString *)host port:(NSInteger)port completion:(void(^)(BOOL success, NSString *msg))completion;
@end

@implementation TDSender

+ (void)sendFileAtURL:(NSURL *)fileURL toHost:(NSString *)host port:(NSInteger)port completion:(void(^)(BOOL, NSString *))completion {
    NSData *data = [NSData dataWithContentsOfURL:fileURL];
    if (!data) {
        completion(NO, @"Could not read file");
        return;
    }

    NSString *name = fileURL.lastPathComponent ?: @"file";
    NSString *urlString = [NSString stringWithFormat:@"https://%@:%ld/up", host, (long)port];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    req.HTTPMethod = @"POST";
    req.HTTPBody = data;
    [req setValue:@(data.length).stringValue forHTTPHeaderField:@"Content-Length"];
    [req setValue:[name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] forHTTPHeaderField:@"X-Name"];
    [req setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];

    NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:cfg delegate:(id)self delegateQueue:nil];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:req completionHandler:^(NSData *respData, NSURLResponse *resp, NSError *err) {
        if (err) {
            completion(NO, err.localizedDescription);
        } else {
            NSHTTPURLResponse *http = (NSHTTPURLResponse *)resp;
            completion(http.statusCode == 200, http.statusCode == 200 ? @"Sent" : [NSString stringWithFormat:@"HTTP %ld", (long)http.statusCode]);
        }
    }];
    [task resume];
}

+ (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))handler {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *cred = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        handler(NSURLSessionAuthChallengeUseCredential, cred);
    } else {
        handler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

@end
