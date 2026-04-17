//
//  ZLViewController.m
//  ZLTagListView
//
//  Created by fanpeng on 03/30/2026.
//  Copyright (c) 2026 fanpeng. All rights reserved.
//

#import "ZLViewController.h"
#import <ZLTagListView/ZLTagListView.h>
#import "MyTagCell.h"

@interface ZLViewController ()<ZLTagListViewDataSource>
@property (nonatomic, strong) ZLTagListView *tagListView;
@property (nonatomic, copy) NSArray<NSString *> *tags;
@property (nonatomic, assign) NSInteger randomCount;
@property (nonatomic,strong)NSMutableArray *randomArr;
@end

@implementation ZLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _tags = @[@"Swift", @"Objective-C", @"iOS开发", @"UIKit", @"SwiftUI", @"Objective-C", @"iOS开发", @"UIKit", @"SwiftUI", @"Objective-C", @"iOS开发", @"UIKit", @"SwiftUI", @"Objective-C", @"iOS开发", @"UIKit", @"SwiftUI"];
    self.randomCount =  arc4random_uniform(_tags.count); // 生成5到14之间的随机数
    self.randomArr = _tags.mutableCopy;
    ZLTagListView *tagListView = [[ZLTagListView alloc] initWithFrame:self.view.bounds];
    tagListView.maxWidth = 300;
    tagListView.dataSource = self;
    tagListView.alignment = ZLTagAlignmentEnd; // 左对齐
    tagListView.translatesAutoresizingMaskIntoConstraints = NO;
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[tagListView]];
    stackView.backgroundColor = UIColor.orangeColor;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentFill;
    [self.view addSubview:stackView];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [stackView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;
    [stackView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
}
- (ZLBlockTagListView *)setupBlockTagListView {
    ZLBlockTagListView *listView = [[ZLBlockTagListView alloc] initWithFrame:CGRectZero numberOfTags:^NSInteger(ZLBlockTagListView * _Nonnull tagListView) {
        return self.randomCount + 1;
    } dequeueView:^UIView * _Nonnull(ZLBlockTagListView * _Nonnull tagListView, __kindof UIView * _Nullable view, NSInteger index) {
        UILabel *label = view;
        if (!label) {
            label = [UILabel new];
        }
        ///随机颜色
         UIColor *color = [UIColor colorWithRed:((float)arc4random_uniform(256) / 255.0) green:((float)arc4random_uniform(256) / 255.0) blue:((float)arc4random_uniform(256) / 255.0) alpha:1.0];
        label.backgroundColor =  color;
        
        UIColor *textColor = [UIColor colorWithRed:((float)arc4random_uniform(256) / 255.0) green:((float)arc4random_uniform(256) / 255.0) blue:((float)arc4random_uniform(256) / 255.0) alpha:1.0];

        label.text = _tags[index];
        label.textColor = textColor;
        return label;
    }];
    listView.maxWidth = 350;
    listView.didSelectTag = ^(ZLBlockTagListView * _Nonnull tagListView, NSInteger index) {
        NSLog(@"选中: %@", _tags[index]);
        self.randomCount =  arc4random_uniform(_tags.count); // 生成5到14之间的随机数
        [tagListView syncReloadData];
    };

    return listView;
}



#pragma mark - ZLTagListViewDataSource

- (NSInteger)numberOfTagsInTagListView:(ZLTagListView *)tagListView {
    return self.randomArr.count;
}
- (UIView *)tagListView:(ZLTagListView *)tagListView dequeueView:(__kindof UIView *)view forTagAtIndex:(NSInteger)index {
    UILabel *label = view;
    if (!label) {
        label = [UILabel new];
    }
    UIColor *color = [UIColor colorWithRed:((float)arc4random_uniform(256) / 255.0) green:((float)arc4random_uniform(256) / 255.0) blue:((float)arc4random_uniform(256) / 255.0) alpha:1.0];

    label.backgroundColor = color;
//    [label invalidateIntrinsicContentSize];
    ///生成随机颜色
    label.text = self.randomArr[index];
//        [label invalidateIntrinsicContentSize];

//    label.preferredMaxLayoutWidth = 10000;
//
//    // 3. 强制刷新布局
//    [label setNeedsLayout];
//    [label layoutIfNeeded];
    
//    CGSize size = view ? [view systemLayoutSizeFittingSize:CGSizeMake(CGFLOAT_MAX, 600) withHorizontalFittingPriority:UILayoutPriorityFittingSizeLevel verticalFittingPriority:UILayoutPriorityRequired] : CGSizeZero;
//    NSLog(@"view: %@---size:%@",label.text,NSStringFromCGSize(size));
    
    return label;
}
#pragma mark - ZLTagListViewDelegate

- (void)tagListView:(ZLTagListView *)tagListView didSelectTagAtIndex:(NSInteger)index {
    NSLog(@"选中: %@", _tags[index]);
    self.randomCount =  arc4random_uniform(_tags.count); // 生成5到14之间的随机数
    self.randomArr = NSMutableArray.array;
    [self.tags enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger index =  arc4random_uniform(_tags.count); //
        [self.randomArr addObject:self.tags[index]];

    }];
    [tagListView syncReloadData];
}
- (void)tagListView:(ZLTagListView *)tagListView didUpdateContentHeight:(CGFloat)height {
    NSLog(@"内容高度更新: %.2f", height);
}
- (void)tagListView:(ZLTagListView *)tagListView didUpdateContentWidth:(CGFloat)width {
    NSLog(@"内容宽度更新: %.2f", width);
}
@end
