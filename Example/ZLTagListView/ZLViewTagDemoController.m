//
//  ZLViewTagDemoController.m
//  ZLTagListView
//

#import "ZLViewTagDemoController.h"
#import <ZLTagListView/ZLTagListView.h>

@interface ZLViewTagDemoController ()
@property (nonatomic, strong) ZLViewTagListView *tagListView;
@property (nonatomic, assign) NSInteger counter;
@end

@implementation ZLViewTagDemoController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"ZLViewTagListView";

    [self setupTagListView];
    [self setupButtons];

    // 初始添加几个标签
    for (NSString *title in @[@"Swift", @"Objective-C", @"iOS", @"UIKit"]) {
        [self.tagListView addView:[self makeTagWithTitle:title]];
    }
}

#pragma mark - Setup

- (void)setupTagListView {
    ZLViewTagListView *tagListView = [[ZLViewTagListView alloc] initWithFrame:CGRectZero];
    tagListView.rowHorizontalAlignment = ZLTagRowHorizontalAlignmentStart;
    tagListView.lineSpacing  = 10;
    tagListView.itemSpacing  = 10;
    tagListView.contentInset = UIEdgeInsetsMake(12, 12, 12, 12);
//    tagListView.maxWidth     = self.view.bounds.size.width - 32;
    tagListView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    tagListView.layer.cornerRadius = 8;
    tagListView.layer.borderWidth = 1;
    tagListView.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
    tagListView.tagMargin = UIEdgeInsetsMake(15, 15, 15, 15);
    tagListView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:tagListView];
    self.tagListView = tagListView;
    tagListView.autoReload = YES;
    
    
    // 头视图：标题栏，高度自适应，宽度与父视图一致
    UILabel *header = [UILabel new];
    header.text = @"技术标签（headerView 示例）";
    header.font = [UIFont boldSystemFontOfSize:14];
    header.textColor = [UIColor whiteColor];
    header.backgroundColor = [UIColor systemBlueColor];
    header.textAlignment = NSTextAlignmentCenter;
    header.numberOfLines = 0;
    tagListView.headerView = header;
    tagListView.headerBottomSpacing = 8;

    // 尾视图：说明文字，高度自适应，宽度与父视图一致
    UILabel *footer = [UILabel new];
    footer.text = @"footerView 示例：点击标签可随机刷新字体大小";
    footer.font = [UIFont systemFontOfSize:12];
    footer.textColor = [UIColor darkGrayColor];
    footer.numberOfLines = 0;
    footer.textAlignment = NSTextAlignmentCenter;
    tagListView.footerView = footer;
    tagListView.footerTopSpacing = 8;

    // 点击标签即移除
    __weak typeof(self) weakSelf = self;
    tagListView.didSelectTag = ^(ZLViewTagListView *list, __kindof UIView *view, NSInteger index) {
        NSLog(@"点击并移除第 %ld 个标签", (long)index);
        [list removeView:view];
        (void)weakSelf;
    };

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [tagListView.topAnchor      constraintEqualToAnchor:safe.topAnchor      constant:20],
        [tagListView.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor  constant:16],
        [tagListView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
    ]];
}

- (void)setupButtons {
    UIButton *addBtn    = [self buttonWithTitle:@"添加标签"  action:@selector(onAdd)];
    UIButton *removeBtn = [self buttonWithTitle:@"移除末尾"  action:@selector(onRemoveLast)];
    UIButton *clearBtn  = [self buttonWithTitle:@"清空全部"  action:@selector(onRemoveAll)];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[addBtn, removeBtn, clearBtn]];
    stack.axis = UILayoutConstraintAxisHorizontal;
    stack.distribution = UIStackViewDistributionFillEqually;
    stack.spacing = 12;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stack];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor      constraintEqualToAnchor:self.tagListView.bottomAnchor constant:24],
        [stack.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor  constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [stack.heightAnchor   constraintEqualToConstant:44],
    ]];

    UILabel *tip = [UILabel new];
    tip.numberOfLines = 0;
    tip.font = [UIFont systemFontOfSize:13];
    tip.textColor = [UIColor darkGrayColor];
    tip.text = @"提示：点击任意标签可将其移除；下方按钮演示 addView / removeViewAtIndex / removeAllViews";
    tip.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:tip];
    [NSLayoutConstraint activateConstraints:@[
        [tip.topAnchor      constraintEqualToAnchor:stack.bottomAnchor constant:16],
        [tip.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor  constant:16],
        [tip.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
    ]];
}

#pragma mark - Actions

- (void)onAdd {
    self.counter += 1;
    NSString *title = [NSString stringWithFormat:@"Tag %ld", (long)self.counter];
    UILabel *labe = [self makeTagWithTitle:title];
    [self.tagListView addView:labe];
    [self.tagListView setTagMargin:UIEdgeInsetsMake(5, 5, 5, 5) atIndex:self.tagListView.tagViews.count - 1];
}

- (void)onRemoveLast {
    NSInteger last = self.tagListView.tagViews.count - 1;
    [self.tagListView removeViewAtIndex:last];
}

- (void)onRemoveAll {
    [self.tagListView removeAllViews];
}

#pragma mark - Helpers

- (UILabel *)makeTagWithTitle:(NSString *)title {
    UILabel *label = [UILabel new];
    label.text = title;
    ///字体大小随机
    label.font = [UIFont systemFontOfSize:10 + arc4random_uniform(10)];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor colorWithHue:(arc4random_uniform(100) / 100.0)
                                       saturation:0.55 brightness:0.85 alpha:1.0];
    label.layer.cornerRadius = 6;
    label.layer.masksToBounds = YES;
    // 通过内边距撑大点击区域
    label.preferredMaxLayoutWidth = 0;
    return label;
}

- (UIButton *)buttonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor systemBlueColor];
    btn.layer.cornerRadius = 8;
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

@end
