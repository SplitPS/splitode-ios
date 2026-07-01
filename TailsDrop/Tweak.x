#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface TDActivity : UIActivity
@property (nonatomic, strong) NSArray *items;
@end

@interface TDDevicePickerController : UIViewController
- (instancetype)initWithItems:(NSArray *)items;
@end

@implementation TDActivity

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryShare;
}

- (NSString *)activityType {
    return @"com.tailsdrop.send";
}

- (NSString *)activityTitle {
    return @"TailsDrop";
}

- (UIImage *)activityImage {
    UIImage *img;
    if (@available(iOS 13.0, *)) {
        img = [UIImage systemImageNamed:@"dot.radiowaves.left.and.right"];
    } else {
        img = [UIImage imageNamed:@"UIActivityViewController_icon_share"];
    }
    return img;
}

- (BOOL)canPerformWithActivityItems:(NSArray *)items {
    for (id item in items) {
        if ([item isKindOfClass:[NSURL class]] || [item isKindOfClass:[UIImage class]] || [item isKindOfClass:[NSString class]]) {
            return YES;
        }
    }
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)items {
    self.items = items;
}

- (UIViewController *)activityViewController {
    TDDevicePickerController *picker = [[TDDevicePickerController alloc] initWithItems:self.items];
    return picker;
}

@end

static void insertTailsDropActivity(NSMutableArray *activities) {
    for (UIActivity *a in activities) {
        if ([a.activityType isEqualToString:@"com.tailsdrop.send"]) return;
    }
    [activities insertObject:[[TDActivity alloc] init] atIndex:0];
}

%hook UIActivityViewController

- (instancetype)initWithActivityItems:(NSArray *)items applicationActivities:(NSArray *)activities {
    NSMutableArray *mut = activities ? [activities mutableCopy] : [NSMutableArray array];
    insertTailsDropActivity(mut);
    return %orig(items, mut);
}

%end
