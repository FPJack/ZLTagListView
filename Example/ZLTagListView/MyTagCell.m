//
//  MyTagCell.m
//  ZLTagListView_Example
//
//  Created by admin on 2026/3/30.
//  Copyright © 2026 fanpeng. All rights reserved.
//

#import "MyTagCell.h"
@implementation MyTagCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 15;
        self.backgroundColor = [UIColor systemBlueColor];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:14];
        [self.contentView addSubview:_titleLabel];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
        [_titleLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
        [_titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
        [_titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;

    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _titleLabel.frame = CGRectInset(self.contentView.bounds, 12, 6);
}
@end
