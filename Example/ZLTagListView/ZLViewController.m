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
#import <ZLPopView/ZLPopView.h>
@interface ZLViewController ()<ZLTagListViewDelegate,ZLTagListViewDataSource>
@property (nonatomic, strong) ZLTagListView *tagListView;
@property (nonatomic, copy) NSArray<NSString *> *tags;
@end

@implementation ZLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tags = @[@"Swift", @"Objective-C", @"iOS开发", @"UIKit", @"SwiftUI", @"Objective-C", @"iOS开发", @"UIKit", @"SwiftUI" @"Objective-C", @"iOS开发", @"UIKit", @"SwiftUI", @"Objective-C", @"iOS开发", @"UIKit", @"SwiftUI"];
    
    ZLTagListView *tagListView = [[ZLTagListView alloc] initWithFrame:CGRectZero];
    tagListView.alignment = ZLTagAlignmentCenter; // 左对齐
    [tagListView registerClass:[MyTagCell class] forCellWithReuseIdentifier:@"MyTagCell"];
    tagListView.delegate = self;
    tagListView.dataSource = self;
    tagListView.maxWidth = 300;   // 最大宽度300
//    tagListView.maxHeight = 200;  // 最大高度200
//    tagListView.minWidth = 100;   // 最小宽度100
//    tagListView.minHeight = 50;   // 最小高度50
//    tagListView.horizontalScroll = YES;
    [self.view addSubview:tagListView];

    // 方式1：手动设置尺寸
    CGSize size = [tagListView calculateContentSize];
    tagListView.frame = CGRectMake(20, 100, size.width, size.height);

    // 方式2：使用sizeToFit自动调整
    [tagListView sizeToFit];

    // 方式3：配合Auto Layout使用intrinsicContentSize
    // tagListView会自动返回正确的intrinsicContentSize
    
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    kPopViewColumnBuilder
    .title(@"选择对齐方式")
    .alignmentCenter
    .addViewBK(^UIView * _Nonnull{
        ZLTagListView *tagListView = [[ZLTagListView alloc] initWithFrame:CGRectZero];
        tagListView.backgroundColor = [UIColor orangeColor];
        tagListView.alignment = ZLTagAlignmentRight; // 左对齐
        [tagListView registerClass:[MyTagCell class] forCellWithReuseIdentifier:@"MyTagCell"];
        tagListView.delegate = self;
        tagListView.dataSource = self;
        tagListView.maxWidth = self.view.bounds.size.width;   // 最大宽度300
//        tagListView.maxHeight = 200;  // 最大高度200
        return tagListView;
    })
    .showBottomPopView();
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
