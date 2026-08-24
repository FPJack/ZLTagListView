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
/// 该内边距对整体内容（headerView / 标签网格 / footerView）统一生效：
/// 左右两侧始终同时作用于头尾视图和标签网格；上边距作用于 headerView 顶部（若无 headerView 则作用于标签网格顶部）；
/// 下边距作用于 footerView 底部（若无 footerView 则作用于标签网格底部），不会与头尾视图重复叠加
@property (nonatomic, assign) UIEdgeInsets contentInset;
/// 是否水平滚动，默认NO
@property (nonatomic, assign) BOOL horizontalScroll;
/// 自定义头视图，宽度 = 父视图宽度 - contentInset.left - contentInset.right，左右位置随 contentInset 一同缩进
/// 高度根据自身内容自适应（优先使用 Auto Layout 约束计算，其次回退到 sizeThatFits:）
/// 设置后会自动加入视图层级，置于标签区域上方；其顶部与父视图顶部的间距即为 contentInset.top
@property (nonatomic, strong, nullable) UIView *headerView;
/// 自定义尾视图，宽度 = 父视图宽度 - contentInset.left - contentInset.right，左右位置随 contentInset 一同缩进
/// 高度根据自身内容自适应
/// 设置后会自动加入视图层级，置于标签区域下方；其底部与父视图底部的间距即为 contentInset.bottom
@property (nonatomic, strong, nullable) UIView *footerView;
/// 头视图底部与标签区域之间的间距，默认0（仅在设置了 headerView 时生效）
@property (nonatomic, assign) CGFloat headerBottomSpacing;
/// 尾视图顶部与标签区域之间的间距，默认0（仅在设置了 footerView 时生效）
@property (nonatomic, assign) CGFloat footerTopSpacing;
/// 计算实际内容尺寸（受最大宽高限制）。若设置了 headerView / footerView，返回结果会包含其自适应高度及对应间距；
/// 注意：maxHeight / minHeight 仅约束标签网格区域本身，头尾视图高度在此基础上额外累加
- (CGSize)calculateContentSize;
/// 计算内容尺寸，受最大宽度限制
- (CGSize)calculateContentSizeWithWidth:(CGFloat)width;
/// 刷新数据
- (void)reloadData;
/// 同步刷新数据，调用后立即更新布局并调整自身尺寸，适用于需要在刷新后立即获取正确布局的场景
- (void)syncReloadData;


/// 滚动到指定索引的标签位置
- (void)scrollToItemAtIndex:(NSInteger)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated;
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

/// 标签选择模式
typedef NS_ENUM(NSInteger, ZLTagSelectionMode) {
    ZLTagSelectionModeSingle,   // 单选（默认）
    ZLTagSelectionModeMultiple  // 多选
};

/// 便捷TagListView子类：在 ZLViewTagListView 基础上提供单选/多选能力
/// 无需自己管理选中状态，通过 selectedStyleBlock / normalStyleBlock 自定义选中与未选中样式
/// 通过 setSelectedIndex: / setSelectedIndexes: 设置默认选中标签（建议在 addView(s) 之后调用）
@interface ZLSelectableTagListView : ZLViewTagListView

/// 选择模式，默认单选。切换后会清空当前选中状态
@property (nonatomic, assign) ZLTagSelectionMode selectionMode;

/// 是否允许取消选中（再次点击已选中的标签是否可以取消选中），默认YES
/// 单选模式下为NO时，代表必须始终保留一个选中项（点击已选中项不会取消选中）
@property (nonatomic, assign) BOOL allowsEmptySelection;

/// 当前选中的标签索引（只读，按选中顺序排列）
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *selectedIndexes;
/// 当前选中的标签视图（只读，按选中顺序排列）
@property (nonatomic, copy, readonly) NSArray<__kindof UIView *> *selectedViews;

/// 选中态样式设置 Block：标签被选中时调用，在此设置选中时的外观（背景色/文字色等）
@property (nonatomic, copy, nullable) void (^selectedStyleBlock)(__kindof UIView *view, NSInteger index);
/// 未选中态（默认态）样式设置 Block：标签新增或被取消选中时调用
@property (nonatomic, copy, nullable) void (^normalStyleBlock)(__kindof UIView *view, NSInteger index);

/// 选中状态发生变化时回调（包含点击切换、以及调用 selectIndex:/setSelectedIndexes: 等接口触发的变化）
@property (nonatomic, copy, nullable) void (^didChangeSelection)(ZLSelectableTagListView *tagListView, NSArray<NSNumber *> *selectedIndexes);

/// 设置默认选中的标签索引（会先清空当前选中状态）。单选模式下仅第一个有效索引生效
- (void)setSelectedIndexes:(NSArray<NSNumber *> *)indexes;
/// 设置默认选中的单个标签索引（单选模式常用，等价于 setSelectedIndexes:@[@(index)]）
- (void)setSelectedIndex:(NSInteger)index;

/// 选中指定索引的标签（多选模式下不影响其他已选中项，单选模式下会先取消其他选中项）
- (void)selectIndex:(NSInteger)index;
/// 取消选中指定索引的标签
- (void)deselectIndex:(NSInteger)index;
/// 取消选中所有标签
- (void)deselectAll;
/// 指定索引的标签当前是否处于选中状态
- (BOOL)isIndexSelected:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
