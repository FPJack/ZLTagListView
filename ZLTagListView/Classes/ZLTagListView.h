#import <UIKit/UIKit.h>

@class ZLTagListView;
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, ZLTagAlignment) {
    ZLTagAlignmentLeft,
    ZLTagAlignmentCenter,
    ZLTagAlignmentRight
};
@protocol ZLTagListViewDataSource <NSObject>
@required
- (NSInteger)numberOfTagsInTagListView:(ZLTagListView *)tagListView;
- (UICollectionViewCell *)tagListView:(ZLTagListView *)tagListView cellForTagAtIndex:(NSInteger)index;
- (CGSize)tagListView:(ZLTagListView *)tagListView sizeForTagAtIndex:(NSInteger)index;
@end
@protocol ZLTagListViewDelegate <NSObject>
@optional
- (void)tagListView:(ZLTagListView *)tagListView didSelectTagAtIndex:(NSInteger)index;
@end


@interface ZLTagFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, assign) ZLTagAlignment alignment;

@end

@interface ZLTagListView : UIView
@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, strong, readonly) ZLTagFlowLayout *flowLayout;
@property (nonatomic, weak) id<ZLTagListViewDataSource> dataSource;
@property (nonatomic, weak) id<ZLTagListViewDelegate> delegate;
/// 最大宽度，默认CGFLOAT_MAX（无限制）
@property (nonatomic, assign) CGFloat maxWidth;
/// 最大高度，默认CGFLOAT_MAX（无限制）
@property (nonatomic, assign) CGFloat maxHeight;
/// 最小宽度，默认0
@property (nonatomic, assign) CGFloat minWidth;
/// 最小高度，默认0
@property (nonatomic, assign) CGFloat minHeight;
/// 对齐方式，默认左对齐
@property (nonatomic, assign) ZLTagAlignment alignment;
/// 行间距，默认10
@property (nonatomic, assign) CGFloat lineSpacing;
/// 列间距，默认10
@property (nonatomic, assign) CGFloat itemSpacing;
/// 内边距，默认UIEdgeInsetsMake(10, 10, 10, 10)
@property (nonatomic, assign) UIEdgeInsets contentInset;
/// 是否水平滚动，默认NO
@property (nonatomic, assign) BOOL horizontalScroll;
/// 注册自定义Cell
- (void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier;
- (void)registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier;
/// 获取可复用的Cell
- (__kindof UICollectionViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index;
/// 计算实际内容尺寸（受最大宽高限制）
- (CGSize)calculateContentSize;
- (CGSize)calculateContentSizeWithWidth:(CGFloat)width;
/// 刷新数据
- (void)reloadData;
@end
NS_ASSUME_NONNULL_END
