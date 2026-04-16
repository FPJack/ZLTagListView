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
@end

@implementation ZLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _tags = @[@"Swift", @"Objective-C", @"iOS开发", @"UIKit", @"SwiftUI", @"Objective-C", @"iOS开发", @"UIKit", @"SwiftUI", @"Objective-C", @"iOS开发", @"UIKit", @"SwiftUI", @"Objective-C", @"iOS开发", @"UIKit", @"SwiftUI"];
    self.randomCount =  arc4random_uniform(_tags.count); // 生成5到14之间的随机数
    ZLTagListView *tagListView = [self setupBlockTagListView];
    tagListView.alignment = ZLTagAlignmentEnd; // 左对齐
    tagListView.translatesAutoresizingMaskIntoConstraints = NO;
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[tagListView]];
    stackView.backgroundColor = UIColor.orangeColor;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentFill;
    [stackView addArrangedSubview:tagListView];
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
        [tagListView reloadData];
    };

    return listView;
}



#pragma mark - ZLTagListViewDataSource

- (NSInteger)numberOfTagsInTagListView:(ZLTagListView *)tagListView {
    return self.randomCount + 1;
}
- (UIView *)tagListView:(ZLTagListView *)tagListView dequeueView:(__kindof UIView *)view forTagAtIndex:(NSInteger)index {
    UILabel *label = view;
    if (!label) {
        label = [UILabel new];
    }
    UIColor *color = [UIColor colorWithRed:((float)arc4random_uniform(256) / 255.0) green:((float)arc4random_uniform(256) / 255.0) blue:((float)arc4random_uniform(256) / 255.0) alpha:1.0];

    label.backgroundColor = color;
    
    ///生成随机颜色
    label.text = _tags[index];
    return label;
}
#pragma mark - ZLTagListViewDelegate

- (void)tagListView:(ZLTagListView *)tagListView didSelectTagAtIndex:(NSInteger)index {
    NSLog(@"选中: %@", _tags[index]);
    self.randomCount =  arc4random_uniform(_tags.count); // 生成5到14之间的随机数
    [tagListView reloadData];
}
- (void)tagListView:(ZLTagListView *)tagListView didUpdateContentHeight:(CGFloat)height {
    NSLog(@"内容高度更新: %.2f", height);
}
- (void)tagListView:(ZLTagListView *)tagListView didUpdateContentWidth:(CGFloat)width {
    NSLog(@"内容宽度更新: %.2f", width);
}
@end
