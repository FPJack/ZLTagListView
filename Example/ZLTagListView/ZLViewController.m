//
//  ZLViewController.m
//  ZLTagListView
//

#import "ZLViewController.h"
#import <ZLTagListView/ZLTagListView.h>

@interface ZLViewController ()<ZLTagListViewDataSource>
@property (nonatomic, strong) ZLTagListView *tagListView;
@property (nonatomic, copy) NSArray<NSString *> *tags;
/// 每个标签对应的字体大小（用于制造不同高度，凸显 verticalAlignment 效果）
@property (nonatomic, strong) NSMutableArray<NSNumber *> *fontSizes;
@property (nonatomic, strong) UISegmentedControl *hSeg;
@property (nonatomic, strong) UISegmentedControl *vSeg;
@property (nonatomic, strong) UISegmentedControl *cvSeg;
@end

@implementation ZLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"TagListView 对齐 Demo";

    _tags = @[@"Swift", @"Objective-C",
              @"iOS", @"UIKit", @"SwiftUI",
              @"Xcode", @"Auto Layout",
              @"Runtime", @"KVO", @"Block",
              @"GCD", @"CoreData", @"Metal",
              @"CALayer", @"Combine"
    ];

    _fontSizes = [NSMutableArray array];
    for (NSInteger i = 0; i < _tags.count; i++) {
        [_fontSizes addObject:@(12 + arc4random_uniform(17))]; // 12 ~ 28
    }

    [self setupControlPanel];
    [self setupTagListView];
}

#pragma mark - UI

- (void)setupControlPanel {
    _hSeg = [[UISegmentedControl alloc] initWithItems:@[@"Start", @"Center", @"End"]];
    _hSeg.selectedSegmentIndex = 0;
    [_hSeg addTarget:self action:@selector(onHChanged) forControlEvents:UIControlEventValueChanged];

    _vSeg = [[UISegmentedControl alloc] initWithItems:@[@"Top", @"Center", @"Bottom"]];
    _vSeg.selectedSegmentIndex = 1;
    [_vSeg addTarget:self action:@selector(onVChanged) forControlEvents:UIControlEventValueChanged];

    _cvSeg = [[UISegmentedControl alloc] initWithItems:@[@"Top", @"Center", @"Bottom"]];
    _cvSeg.selectedSegmentIndex = 0;
    [_cvSeg addTarget:self action:@selector(onCVChanged) forControlEvents:UIControlEventValueChanged];

    UILabel *tip = [UILabel new];
    tip.font = [UIFont systemFontOfSize:12];
    tip.textColor = [UIColor darkGrayColor];
    tip.numberOfLines = 0;
    tip.text = @"点击任意标签可随机刷新字体大小；容器已设置 minHeight=320，可观察整体垂直对齐效果";

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        [self makeTitleLabel:@"水平对齐 alignment"], _hSeg,
        [self makeTitleLabel:@"行内垂直对齐 verticalAlignment"], _vSeg,
        [self makeTitleLabel:@"整体垂直对齐 contentVerticalAlignment"], _cvSeg,
        tip
    ]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stack];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:safe.topAnchor constant:16],
        [stack.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
    ]];
}

- (UILabel *)makeTitleLabel:(NSString *)text {
    UILabel *l = [UILabel new];
    l.text = text;
    l.font = [UIFont boldSystemFontOfSize:14];
    l.textColor = [UIColor blackColor];
    return l;
}

- (void)setupTagListView {
    _tagListView = [[ZLTagListView alloc] init];
    _tagListView.dataSource = self;
    _tagListView.alignment = ZLTagAlignmentStart;
    _tagListView.verticalAlignment = ZLTagVerticalAlignmentCenter;
    _tagListView.contentVerticalAlignment = ZLTagContentVerticalAlignmentTop;
    _tagListView.lineSpacing = 12;
    _tagListView.itemSpacing = 10;
    _tagListView.contentInset = UIEdgeInsetsMake(12, 12, 12, 12);
    _tagListView.minHeight = 320; // 让容器高于内容，便于观察整体垂直对齐
    _tagListView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    _tagListView.layer.cornerRadius = 8;
    _tagListView.layer.borderWidth = 1;
    _tagListView.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
    _tagListView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_tagListView];
    _tagListView.maxWidth = self.view.bounds.size.width - 32;

    [NSLayoutConstraint activateConstraints:@[
        [_tagListView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [_tagListView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [_tagListView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:40],
    ]];
}

#pragma mark - Actions

- (void)onHChanged {
    ZLTagAlignment aligns[] = { ZLTagAlignmentStart, ZLTagAlignmentCenter, ZLTagAlignmentEnd };
    _tagListView.alignment = aligns[_hSeg.selectedSegmentIndex];
}

- (void)onVChanged {
    ZLTagVerticalAlignment aligns[] = {
        ZLTagVerticalAlignmentTop,
        ZLTagVerticalAlignmentCenter,
        ZLTagVerticalAlignmentBottom
    };
    _tagListView.verticalAlignment = aligns[_vSeg.selectedSegmentIndex];
}

- (void)onCVChanged {
    ZLTagContentVerticalAlignment aligns[] = {
        ZLTagContentVerticalAlignmentTop,
        ZLTagContentVerticalAlignmentCenter,
        ZLTagContentVerticalAlignmentBottom
    };
    _tagListView.contentVerticalAlignment = aligns[_cvSeg.selectedSegmentIndex];
}

- (void)randomizeFontSizes {
    for (NSInteger i = 0; i < _tags.count; i++) {
        _fontSizes[i] = @(12 + arc4random_uniform(17));
    }
    [_tagListView reloadData];
}

#pragma mark - ZLTagListViewDataSource

- (NSInteger)numberOfTagsInTagListView:(ZLTagListView *)tagListView {
    return self.tags.count;
}

- (UIView *)tagListView:(ZLTagListView *)tagListView
            dequeueView:(__kindof UIView *)view
          forTagAtIndex:(NSInteger)index {
    UILabel *label = (UILabel *)view;
    if (![label isKindOfClass:[UILabel class]]) {
        label = [UILabel new];
        label.textAlignment = NSTextAlignmentCenter;
        label.layer.cornerRadius = 6;
        label.layer.masksToBounds = YES;
    }
    CGFloat fontSize = self.fontSizes[index].floatValue;
//    fontSize = 15;
    label.font = [UIFont systemFontOfSize:fontSize];
    label.text = [NSString stringWithFormat:@"  %@  ", self.tags[index]];

    NSUInteger seed = [self.tags[index] hash];
    CGFloat r = ((seed & 0xFF)) / 255.0;
    CGFloat g = ((seed >> 8) & 0xFF) / 255.0;
    CGFloat b = ((seed >> 16) & 0xFF) / 255.0;
    label.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:0.35];
    label.textColor = [UIColor blackColor];
    return label;
}

- (void)tagListView:(ZLTagListView *)tagListView didSelectTagAtIndex:(NSInteger)index {
    NSLog(@"选中: %@", self.tags[index]);
    [self randomizeFontSizes];
}

- (void)tagListView:(ZLTagListView *)tagListView didUpdateContentHeight:(CGFloat)height {
    NSLog(@"内容高度更新: %.2f", height);
}

- (void)tagListView:(ZLTagListView *)tagListView didUpdateContentWidth:(CGFloat)width {
    NSLog(@"内容宽度更新: %.2f", width);
}

@end
