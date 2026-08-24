//
//  ZLSelectableTagDemoController.m
//  ZLTagListView
//

#import "ZLSelectableTagDemoController.h"
#import <ZLTagListView/ZLTagListView.h>

@interface ZLSelectableTagDemoController ()

@property (nonatomic, strong) ZLSelectableTagListView *tagListView;
@property (nonatomic, strong) UISegmentedControl *modeSeg;
@property (nonatomic, strong) UISegmentedControl *emptySeg;
@property (nonatomic, strong) UILabel *resultLabel;
@property (nonatomic, copy) NSArray<NSString *> *tags;

@end

@implementation ZLSelectableTagDemoController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"ZLSelectableTagListView";

    self.tags = @[@"Swift", @"Objective-C", @"iOS", @"UIKit",
                  @"SwiftUI", @"Combine", @"Auto Layout", @"CoreData"];

    [self setupControlPanel];
    [self setupTagListView];
    [self setupResultLabel];

    // 添加标签
    for (NSString *title in self.tags) {
        [self.tagListView addView:[self makeTagWithTitle:title]];
    }
    // 默认选中第 0 个
    [self.tagListView setSelectedIndex:0];
}

#pragma mark - Setup

- (void)setupControlPanel {
    _modeSeg = [[UISegmentedControl alloc] initWithItems:@[@"单选", @"多选"]];
    _modeSeg.selectedSegmentIndex = 0;
    [_modeSeg addTarget:self action:@selector(onModeChanged) forControlEvents:UIControlEventValueChanged];

    _emptySeg = [[UISegmentedControl alloc] initWithItems:@[@"允许取消", @"禁止取消"]];
    _emptySeg.selectedSegmentIndex = 0;
    [_emptySeg addTarget:self action:@selector(onEmptyChanged) forControlEvents:UIControlEventValueChanged];

    UILabel *tip = [UILabel new];
    tip.font = [UIFont systemFontOfSize:12];
    tip.textColor = [UIColor darkGrayColor];
    tip.numberOfLines = 0;
    tip.text = @"点击标签切换选中状态；切换单选/多选、是否允许取消选中最后一项试试看";

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        [self makeTitleLabel:@"选择模式 selectionMode"], _modeSeg,
        [self makeTitleLabel:@"allowsEmptySelection"], _emptySeg,
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
    ZLSelectableTagListView *tagListView = [[ZLSelectableTagListView alloc] initWithFrame:CGRectZero];
    tagListView.selectionMode = ZLTagSelectionModeSingle;
    tagListView.allowsEmptySelection = YES;
    tagListView.rowHorizontalAlignment = ZLTagRowHorizontalAlignmentStart;
    tagListView.lineSpacing = 10;
    tagListView.itemSpacing = 10;
    tagListView.contentInset = UIEdgeInsetsMake(12, 12, 12, 12);
    tagListView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    tagListView.layer.cornerRadius = 8;
    tagListView.layer.borderWidth = 1;
    tagListView.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
    tagListView.autoReload = YES;
    tagListView.translatesAutoresizingMaskIntoConstraints = NO;

    // 选中态 / 未选中态样式
    tagListView.selectedStyleBlock = ^(UILabel *view, NSInteger index) {
        view.backgroundColor = [UIColor systemBlueColor];
        view.textColor = [UIColor whiteColor];
        view.layer.borderWidth = 0;
    };
    tagListView.normalStyleBlock = ^(UILabel *view, NSInteger index) {
        view.backgroundColor = [UIColor whiteColor];
        view.textColor = [UIColor darkTextColor];
        view.layer.borderWidth = 1;
        view.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
    };

    __weak typeof(self) weakSelf = self;
    tagListView.didChangeSelection = ^(ZLSelectableTagListView *list, NSArray<NSNumber *> *selectedIndexes) {
        [weakSelf updateResultLabelWithIndexes:selectedIndexes];
    };

    [self.view addSubview:tagListView];
    self.tagListView = tagListView;

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [tagListView.topAnchor      constraintEqualToAnchor:_modeSeg.superview.bottomAnchor constant:20],
        [tagListView.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor  constant:16],
        [tagListView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
    ]];
}

- (void)setupResultLabel {
    _resultLabel = [UILabel new];
    _resultLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    _resultLabel.textColor = [UIColor systemBlueColor];
    _resultLabel.numberOfLines = 0;
    _resultLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_resultLabel];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [_resultLabel.topAnchor constraintEqualToAnchor:self.tagListView.bottomAnchor constant:20],
        [_resultLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [_resultLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
    ]];
}

#pragma mark - Actions

- (void)onModeChanged {
    self.tagListView.selectionMode = (_modeSeg.selectedSegmentIndex == 0) ? ZLTagSelectionModeSingle : ZLTagSelectionModeMultiple;
    [self updateResultLabelWithIndexes:self.tagListView.selectedIndexes];
}

- (void)onEmptyChanged {
    self.tagListView.allowsEmptySelection = (_emptySeg.selectedSegmentIndex == 0);
}

- (void)updateResultLabelWithIndexes:(NSArray<NSNumber *> *)indexes {
    NSMutableArray<NSString *> *titles = [NSMutableArray array];
    for (NSNumber *idx in indexes) {
        NSInteger i = idx.integerValue;
        if (i >= 0 && i < (NSInteger)self.tags.count) {
            [titles addObject:self.tags[i]];
        }
    }
    self.resultLabel.text = [NSString stringWithFormat:@"已选中: %@", titles.count ? [titles componentsJoinedByString:@", "] : @"无"];
}

#pragma mark - Helpers

- (UILabel *)makeTagWithTitle:(NSString *)title {
    UILabel *label = [UILabel new];
    label.text = title;
    label.font = [UIFont systemFontOfSize:14];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor darkTextColor];
    label.backgroundColor = [UIColor whiteColor];
    label.layer.cornerRadius = 6;
    label.layer.masksToBounds = YES;
    label.layer.borderWidth = 1;
    label.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
    return label;
}

@end
