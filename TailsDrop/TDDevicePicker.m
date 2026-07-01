#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "TDServiceBrowser.h"
#import "TDSender.h"

@interface TDDevicePickerController : UIViewController <TDServiceBrowserDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) TDServiceBrowser *browser;
@property (nonatomic, strong) NSMutableArray<NSNetService *> *foundServices;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) CAShapeLayer *pulseLayer;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
- (instancetype)initWithItems:(NSArray *)items;
@end

@implementation TDDevicePickerController

- (instancetype)initWithItems:(NSArray *)items {
    if (self = [super init]) {
        _items = items;
        _foundServices = [NSMutableArray array];
        self.modalPresentationStyle = UIModalPresentationPageSheet;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.95];

    UILabel *title = [[UILabel alloc] init];
    title.text = @"TailsDrop";
    title.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    title.textColor = UIColor.whiteColor;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:title];

    UIView *circleView = [[UIView alloc] init];
    circleView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:circleView];

    CGFloat radius = 60;
    CGRect oval = CGRectMake(0, 0, radius*2, radius*2);

    self.pulseLayer = [CAShapeLayer layer];
    self.pulseLayer.path = [UIBezierPath bezierPathWithOvalInRect:oval].CGPath;
    self.pulseLayer.fillColor = [UIColor colorWithRed:0.91 green:0.27 blue:0.38 alpha:0.3].CGColor;
    self.pulseLayer.position = CGPointMake(radius, radius);
    [circleView.layer addSublayer:self.pulseLayer];

    CAShapeLayer *ring = [CAShapeLayer layer];
    ring.path = [UIBezierPath bezierPathWithOvalInRect:oval].CGPath;
    ring.fillColor = UIColor.clearColor.CGColor;
    ring.strokeColor = [UIColor colorWithRed:0.91 green:0.27 blue:0.38 alpha:0.6].CGColor;
    ring.lineWidth = 2;
    ring.position = CGPointMake(radius, radius);
    [circleView.layer addSublayer:ring];

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"antenna.radiowaves.left.and.right"]];
    icon.tintColor = UIColor.whiteColor;
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [circleView addSubview:icon];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = @"Looking for devices...";
    self.statusLabel.font = [UIFont systemFontOfSize:15];
    self.statusLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.spinner.color = UIColor.whiteColor;
    self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.spinner];
    [self.spinner startAnimating];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(90, 110);
    layout.minimumInteritemSpacing = 12;
    layout.sectionInset = UIEdgeInsetsMake(8, 20, 8, 20);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = UIColor.clearColor;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    [self.view addSubview:self.collectionView];

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [closeBtn setTitle:@"Cancel" forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [closeBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    closeBtn.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    closeBtn.layer.cornerRadius = 14;
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [closeBtn addTarget:self action:@selector(dismissSelf) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBtn];

    [NSLayoutConstraint activateConstraints:@[
        [title.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:20],
        [title.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        [circleView.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:20],
        [circleView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [circleView.widthAnchor constraintEqualToConstant:radius*2],
        [circleView.heightAnchor constraintEqualToConstant:radius*2],

        [icon.centerXAnchor constraintEqualToAnchor:circleView.centerXAnchor],
        [icon.centerYAnchor constraintEqualToAnchor:circleView.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:36],
        [icon.heightAnchor constraintEqualToConstant:36],

        [self.spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.spinner.topAnchor constraintEqualToAnchor:circleView.bottomAnchor constant:16],

        [self.statusLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.spinner.bottomAnchor constant:6],

        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:0],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:0],
        [self.collectionView.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:20],
        [self.collectionView.heightAnchor constraintEqualToConstant:130],

        [closeBtn.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [closeBtn.topAnchor constraintEqualToAnchor:self.collectionView.bottomAnchor constant:20],
        [closeBtn.widthAnchor constraintEqualToConstant:200],
        [closeBtn.heightAnchor constraintEqualToConstant:50],
        [closeBtn.bottomAnchor constraintLessThanOrEqualToAnchor:self.view.bottomAnchor constant:-30],
    ]];

    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.fromValue = @1.0;
    pulse.toValue = @1.15;
    pulse.duration = 1.2;
    pulse.autoreverses = YES;
    pulse.repeatCount = INFINITY;
    [self.pulseLayer addAnimation:pulse forKey:@"pulse"];

    self.browser = [[TDServiceBrowser alloc] init];
    self.browser.delegate = self;
    [self.browser startBrowsing];
}

- (void)dismissSelf {
    [self.browser stopBrowsing];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.browser stopBrowsing];
}

#pragma mark - Browser delegate

- (void)browser:(TDServiceBrowser *)browser didFindService:(NSNetService *)service {
    if (![self.foundServices containsObject:service]) {
        [self.foundServices addObject:service];
    }
    self.statusLabel.text = [NSString stringWithFormat:@"%lu device(s) found", (unsigned long)self.foundServices.count];
    [self.spinner stopAnimating];
    self.spinner.hidden = YES;
    [self.collectionView reloadData];
}

- (void)browser:(TDServiceBrowser *)browser didRemoveService:(NSNetService *)service {
    [self.foundServices removeObject:service];
    if (self.foundServices.count == 0) {
        self.statusLabel.text = @"Looking for devices...";
        self.spinner.hidden = NO;
        [self.spinner startAnimating];
    } else {
        self.statusLabel.text = [NSString stringWithFormat:@"%lu device(s) found", (unsigned long)self.foundServices.count];
    }
    [self.collectionView reloadData];
}

#pragma mark - CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return MAX(self.foundServices.count, 1);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];

    for (UIView *v in cell.contentView.subviews) [v removeFromSuperview];

    if (self.foundServices.count == 0) {
        UILabel *l = [[UILabel alloc] initWithFrame:cell.contentView.bounds];
        l.text = @"No devices yet";
        l.textColor = [UIColor colorWithWhite:0.5 alpha:1];
        l.font = [UIFont systemFontOfSize:12];
        l.textAlignment = NSTextAlignmentCenter;
        l.numberOfLines = 0;
        [cell.contentView addSubview:l];
        return cell;
    }

    NSNetService *svc = self.foundServices[indexPath.item];
    NSString *name = svc.name ?: [svc.hostName ?: @"Device" stringByDeletingPathExtension];
    NSString *initial = name.length > 0 ? [[name substringToIndex:1] uppercaseString] : @"?";

    UIView *circle = [[UIView alloc] initWithFrame:CGRectMake(15, 0, 60, 60)];
    circle.backgroundColor = [UIColor colorWithRed:0.91 green:0.27 blue:0.38 alpha:1];
    circle.layer.cornerRadius = 30;
    circle.layer.masksToBounds = YES;
    [cell.contentView addSubview:circle];

    UILabel *letter = [[UILabel alloc] initWithFrame:circle.bounds];
    letter.text = initial;
    letter.textColor = UIColor.whiteColor;
    letter.font = [UIFont systemFontOfSize:26 weight:UIFontWeightMedium];
    letter.textAlignment = NSTextAlignmentCenter;
    [circle addSubview:letter];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 66, 90, 36)];
    label.text = name;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:12];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 2;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    [cell.contentView addSubview:label];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item >= self.foundServices.count) return;
    NSNetService *svc = self.foundServices[indexPath.item];
    NSString *host = svc.hostName;
    NSInteger port = svc.port;

    if (!host) return;

    NSString *msg = [NSString stringWithFormat:@"Send to %@?", svc.name ?: host];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"TailsDrop" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Send" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        UIActivityIndicatorView *loader = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
        loader.color = UIColor.whiteColor;
        loader.center = strongSelf.view.center;
        [strongSelf.view addSubview:loader];
        [loader startAnimating];

        dispatch_group_t group = dispatch_group_create();
        for (id item in strongSelf.items) {
            dispatch_group_enter(group);
            NSURL *url = nil;
            if ([item isKindOfClass:[NSURL class]]) url = item;
            else if ([item isKindOfClass:[NSString class]]) url = [NSURL fileURLWithPath:item];
            else if ([item isKindOfClass:[UIImage class]]) {
                NSString *tmp = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tailsdrop_share.png"];
                [UIImagePNGRepresentation(item) writeToFile:tmp atomically:YES];
                url = [NSURL fileURLWithPath:tmp];
            }
            if (url) {
                [TDSender sendFileAtURL:url toHost:host port:port completion:^(BOOL success, NSString *msg) {
                    dispatch_group_leave(group);
                }];
            } else {
                dispatch_group_leave(group);
            }
        }

        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            [loader stopAnimating];
            [loader removeFromSuperview];
            [strongSelf dismissSelf];
        });
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
