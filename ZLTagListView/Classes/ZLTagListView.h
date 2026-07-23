#import <UIKit/UIKit.h>

@class ZLTagListView;
NS_ASSUME_NONNULL_BEGIN
/// 行内水平对齐方式
typedef NS_ENUM(NSInteger, ZLTagRowHorizontalAlignment) {
    ZLTagRowHorizontalAlignmentStart,   // 起始对齐（默认，RTL 时为右）
    ZLTagRowHorizontalAlignmentCenter,  // 居中对齐
    ZLTagRowHorizontalAlignmentEnd      // 结束对齐
};
/// 行内垂直对齐方式（针对同一行中不同高度的标签）
typedef NS_ENUM(NSInteger, ZLTagRowVerticalAlignment) {
    ZLTagRowVerticalAlignmentTop,       // 顶部对齐
    ZLTagRowVerticalAlignmentCenter,    // 居中对齐（默认）
    ZLTagRowVerticalAlignmentBottom     // 底部对齐
};
/// 整体内容在容器内的垂直对齐方式（当容器高度大于内容高度时生效，例如设置了 minHeight）
typedef NS_ENUM(NSInteger, ZLTagContentVerticalAlignment) {
    ZLTagContentVerticalAlignmentTop,     // 顶部（默认）
    ZLTagContentVerticalAlignmentCenter,  // 整体居中
    ZLTagContentVerticalAlignmentBottom   // 底部
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

/// 返回指定索引的标签视图的外边距（可选）
- (UIEdgeInsets)tagListView:(ZLTagListView *)tagListView marginForTagAtIndex:(NSInteger)index;

///高度发生变化
- (void)tagListView:(ZLTagListView *)tagListView didUpdateContentHeight:(CGFloat)height;
///宽度发生变化
- (void)tagListView:(ZLTagListView *)tagListView didUpdateContentWidth:(CGFloat)width;
@end

@interface ZLTagFlowLayout : UICollectionViewFlowLayout

/// 行内水平对齐方式
@property (nonatomic, assign) ZLTagRowHorizontalAlignment rowHorizontalAlignment;
/// 行内垂直对齐方式
@property (nonatomic, assign) ZLTagRowVerticalAlignment rowVerticalAlignment;
/// 内容整体垂直对齐方式
@property (nonatomic, assign) ZLTagContentVerticalAlignment contentVerticalAlignment;
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
/// 行内水平对齐方式，默认起始对齐
@property (nonatomic, assign) ZLTagRowHorizontalAlignment rowHorizontalAlignment;
/// 行内垂直对齐方式，默认居中对齐
@property (nonatomic, assign) ZLTagRowVerticalAlignment rowVerticalAlignment;
/// 内容整体垂直对齐方式，默认顶部（当容器高度大于内容高度时生效，例如设置了 minHeight）
@property (nonatomic, assign) ZLTagContentVerticalAlignment contentVerticalAlignment;
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

@property (nonatomic, copy) UIEdgeInsets (^marginForTag)(ZLBlockTagListView * tagListView, NSInteger index);

- (instancetype)initWithFrame:(CGRect)frame
                 numberOfTags:(NSInteger (^)(ZLBlockTagListView *tagListView))numberOfTags
                  dequeueView:(UIView * (^)(ZLBlockTagListView  *tagListView, __kindof UIView * _Nullable view, NSInteger index))dequeueView;
@end

/// 便捷TagListView子类：直接以 UIView 管理标签，无需实现数据源
/// 通过 addView: / removeView: / removeAllViews 增删标签，内部自动刷新
@interface ZLViewTagListView : ZLTagListView <ZLTagListViewDataSource>

///tagView 尺寸变化的时候是否自动刷新
@property (nonatomic, assign) BOOL autoReload;

/// 标签视图的默认外边距，默认UIEdgeInsetsMake(0, 0, 0, 0)，可通过 setMargin:atIndex: 设置指定标签的外边距
@property (nonatomic, assign)UIEdgeInsets tagMargin;

/// 当前所有标签视图（只读）
@property (nonatomic, copy, readonly) NSArray<__kindof UIView *> *tagViews;
/// 标签被选中回调（可选）
@property (nonatomic, copy, nullable) void (^didSelectTag)(ZLViewTagListView *tagListView, __kindof UIView *view, NSInteger index);

/// 添加一个标签视图（追加到末尾），并自动刷新
- (void)addView:(UIView *)view;
/// 添加一个标签视图（追加到末尾），并自动刷新，同时设置外边距
- (void)addView:(UIView *)view margin:(UIEdgeInsets)margin;

/// 批量添加标签视图，并自动刷新
- (void)addViews:(NSArray<__kindof UIView *> *)views;
/// 在指定位置插入标签视图，并自动刷新
- (void)insertView:(UIView *)view atIndex:(NSInteger)index;

/// 在指定位置插入标签视图，并自动刷新，同时设置外边距
- (void)insertView:(UIView *)view margin:(UIEdgeInsets)margin atIndex:(NSInteger)index;

/// 移除指定标签视图，并自动刷新
- (void)removeView:(UIView *)view;
/// 移除指定位置的标签视图，并自动刷新
- (void)removeViewAtIndex:(NSInteger)index;
/// 移除所有标签视图，并自动刷新
- (void)removeAllViews;
///设置指定标签视图的外边距，并自动刷新
- (void)setTagMargin:(UIEdgeInsets)margin atIndex:(NSInteger )index;

@end

NS_ASSUME_NONNULL_END
