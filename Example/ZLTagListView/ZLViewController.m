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
@interface ZLViewController ()<ZLTagListViewDelegate,ZLTagListViewDataSource>
@property (nonatomic, strong) ZLTagListView *tagListView;
@property (nonatomic, copy) NSArray<NSString *> *tags;
@end

@implementation ZLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tags = @[@"Swift", @"Objective-C", @"iOS开发", @"UIKit", @"SwiftUI", @"Objective-C", @"iOS开发", @"UIKit", @"SwiftUI" @"Objective-C", @"iOS开发", @"UIKit", @"SwiftUI", @"Objective-C", @"iOS开发", @"UIKit", @"SwiftUI"];
    
    ZLTagListView *tagListView = [[ZLTagListView alloc] initWithFrame:CGRectZero];
    tagListView.alignment = ZLTagAlignmentRight; // 左对齐
    [tagListView registerClass:[MyTagCell class] forCellWithReuseIdentifier:@"MyTagCell"];
    tagListView.delegate = self;
    tagListView.dataSource = self;
//    tagListView.minWidth = 10;   // 最大宽度300
    tagListView.maxWidth = 200;
//    tagListView.maxHeight = 200;  // 最大高度200
//    tagListView.minWidth = 100;   // 最小宽度100
//    tagListView.minHeight = 50;   // 最小高度50
//    tagListView.horizontalScroll = YES;
    
    tagListView.translatesAutoresizingMaskIntoConstraints = NO;
//    [tagListView setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
//    [tagListView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

//    [tagListView.heightAnchor constraintGreaterThanOrEqualToConstant:100].active = YES; // 设置最小高度
    
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[tagListView]];
    stackView.backgroundColor = UIColor.orangeColor;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentFill;
    [stackView addArrangedSubview:tagListView];
    [self.view addSubview:stackView];
//    [stackView addArrangedSubview:UISwitch.new];

    stackView.translatesAutoresizingMaskIntoConstraints = NO;

    [stackView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;
    [stackView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
//    [stackView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
//    [stackView.heightAnchor constraintEqualToConstant:100].active = YES;
    // 方式1：手动设置尺寸
//    CGSize size = [tagListView calculateContentSize];
//    tagListView.frame = CGRectMake(20, 100, size.width, size.height);
//
//    // 方式2：使用sizeToFit自动调整
//    [tagListView sizeToFit];

    // 方式3：配合Auto Layout使用intrinsicContentSize
    // tagListView会自动返回正确的intrinsicContentSize
    
}

#pragma mark - ZLTagListViewDataSource

- (NSInteger)numberOfTagsInTagListView:(ZLTagListView *)tagListView {
    return _tags.count;
}

- (UICollectionViewCell *)tagListView:(ZLTagListView *)tagListView cellForTagAtIndex:(NSInteger)index {
    MyTagCell *cell = [tagListView dequeueReusableCellWithReuseIdentifier:@"MyTagCell" forIndex:index];
    cell.titleLabel.text = _tags[index];
    return cell;
}

- (CGSize)tagListView:(ZLTagListView *)tagListView sizeForTagAtIndex:(NSInteger)index {
    NSString *tag = _tags[index];
    CGSize textSize = [tag boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                        options:NSStringDrawingUsesLineFragmentOrigin
                                     attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14]}
                                        context:nil].size;
    return CGSizeMake(ceil(textSize.width) + 24, ceil(textSize.height) + 12);
}

#pragma mark - ZLTagListViewDelegate

- (void)tagListView:(ZLTagListView *)tagListView didSelectTagAtIndex:(NSInteger)index {
    NSLog(@"选中: %@", _tags[index]);
}


@end
