#import <UIKit/UIKit.h>

@class ZLTagListView;
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, ZLTagAlignment) {
    ZLTagAlignmentStart,
    ZLTagAlignmentCenter,
    ZLTagAlignmentEnd
};
@protocol ZLTagListViewDataSource <NSObject>
@required
- (NSInteger)numberOfTagsInTagListView:(ZLTagListView *)tagListView;

/// 返回标签视图
/// - Parameters:
///   - tagListView: 标签列表视图
///   - view: 可重用的标签视图，如果为nil则需要创建一个新的视图
///   - index: 标签索引
- (UIView *)tagListView:(ZLTagListView *)tagListView
            dequeueView:(__kindof UIView * _Nullable)view
          forTagAtIndex:(NSInteger)index;
@optional
///标签被选中
- (void)tagListView:(ZLTagListView *)tagListView didSelectTagAtIndex:(NSInteger)index;
///高度发生变化
- (void)tagListView:(ZLTagListView *)tagListView didUpdateContentHeight:(CGFloat)height;
///宽度发生变化
- (void)tagListView:(ZLTagListView *)tagListView didUpdateContentWidth:(CGFloat)width;

@end

@interface ZLTagFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, assign) ZLTagAlignment alignment;
/// 是否RTL布局
@property (nonatomic, assign) BOOL isRTL;
@end

@interface ZLTagListView : UIView
@property (nonatomic, weak) id<ZLTagListViewDataSource> dataSource;
/// 是否支持RTL（从右到左）布局，默认跟随系统 默认NO
@property (nonatomic, assign) BOOL forceRTL;
/// 是否自动检测RTL，默认YES
@property (nonatomic, assign) BOOL autoDetectRTL;
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
/// 计算实际内容尺寸（受最大宽高限制）
- (CGSize)calculateContentSize;
/// 计算内容尺寸，受最大宽度限制
- (CGSize)calculateContentSizeWithWidth:(CGFloat)width;
/// 刷新数据
- (void)reloadData;
/// 同步刷新数据，调用后立即更新布局并调整自身尺寸，适用于需要在刷新后立即获取正确布局的场景
- (void)syncReloadData;
@end

///便捷TagListView子类 提供Block方式回调
@interface ZLBlockTagListView : ZLTagListView <ZLTagListViewDataSource>

@property (nonatomic, copy) NSInteger (^numberOfTags)(ZLBlockTagListView *tagListView);
@property (nonatomic, copy) UIView * (^dequeueView)(ZLBlockTagListView  *tagListView, __kindof UIView * _Nullable view, NSInteger index);
@property (nonatomic, copy) void (^didSelectTag)(ZLBlockTagListView * tagListView, NSInteger index);
@property (nonatomic, copy) void (^didUpdateContentHeight)(ZLBlockTagListView * tagListView, CGFloat height);
@property (nonatomic, copy) void (^didUpdateContentWidth)(ZLBlockTagListView * tagListView, CGFloat width);
- (instancetype)initWithFrame:(CGRect)frame
                 numberOfTags:(NSInteger (^)(ZLBlockTagListView *tagListView))numberOfTags
                  dequeueView:(UIView * (^)(ZLBlockTagListView  *tagListView, __kindof UIView * _Nullable view, NSInteger index))dequeueView;
@end
NS_ASSUME_NONNULL_END
