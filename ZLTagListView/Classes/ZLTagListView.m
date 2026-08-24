#import "ZLTagListView.h"
#import <objc/runtime.h>
typedef void(^ZLBoundsDidChangeBlock)(UIView *view, CGRect oldBounds, CGRect newBounds);
@interface _ZLBoundsObserver : NSObject
@property (nonatomic, weak) UIView *view;
@property (nonatomic, copy) ZLBoundsDidChangeBlock block;
@property (nonatomic,assign)BOOL isFirst;
@end

@implementation _ZLBoundsObserver
- (instancetype)initWithView:(UIView *)view {
    if (self = [super init]) {
        _view = view;
        self.isFirst = YES;
        [view addObserver:self
               forKeyPath:@"bounds"
                  options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                  context:nil];
    }
    return self;
}

- (void)dealloc {
    @try {
        [_view removeObserver:self forKeyPath:@"bounds"];
    } @catch (__unused NSException *e) {
        
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {

    if (![keyPath isEqualToString:@"bounds"]) {
        return;
    }

    if (!self.block) {
        return;
    }
    
    if (self.isFirst) {
        self.isFirst = NO;
        return;
    }

    CGRect oldBounds = [change[NSKeyValueChangeOldKey] CGRectValue];
    CGRect newBounds = [change[NSKeyValueChangeNewKey] CGRectValue];

    if (CGRectEqualToRect(oldBounds, newBounds)) {
        return;
    }

    self.block((UIView *)object, oldBounds, newBounds);
}

@end

@implementation UIView (BoundsObserver)

static const void *kBoundsObserverKey = &kBoundsObserverKey;

- (void)setZl_boundsDidChangeBlock:(ZLBoundsDidChangeBlock)block {

    _ZLBoundsObserver *observer = objc_getAssociatedObject(self, kBoundsObserverKey);

    if (!block) {
        objc_setAssociatedObject(self,
                                 kBoundsObserverKey,
                                 nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }

    if (!observer) {
        observer = [[_ZLBoundsObserver alloc] initWithView:self];

        objc_setAssociatedObject(self,
                                 kBoundsObserverKey,
                                 observer,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    observer.block = block;
}

- (ZLBoundsDidChangeBlock)zl_boundsDidChangeBlock {

    _ZLBoundsObserver *observer = objc_getAssociatedObject(self, kBoundsObserverKey);

    return observer.block;
}

@end

@interface ZLTagCollectionView : UICollectionView

@end
@implementation ZLTagCollectionView
- (UIUserInterfaceLayoutDirection)effectiveUserInterfaceLayoutDirection {
    return  [UIView userInterfaceLayoutDirectionForSemanticContentAttribute:UIView.appearance.semanticContentAttribute];
}
@end
@implementation ZLTagFlowLayout

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *originalAttributes = [super layoutAttributesForElementsInRect:rect];
    NSMutableArray *attributes = [[NSMutableArray alloc] initWithArray:originalAttributes copyItems:YES];

    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        [self applyContentVerticalAlignment:attributes];
        return attributes;
    }

    NSMutableArray<NSMutableArray<UICollectionViewLayoutAttributes *> *> *rows = [NSMutableArray array];
    NSMutableArray<UICollectionViewLayoutAttributes *> *currentRow = nil;
    UICollectionViewLayoutAttributes *lastAttr = nil;

    for (UICollectionViewLayoutAttributes *attr in attributes) {

        if (attr.representedElementCategory != UICollectionElementCategoryCell) {
            continue;
        }

        if (lastAttr == nil) {
            currentRow = [NSMutableArray array];
            [rows addObject:currentRow];
        } else {
            // 判断是否与上一行最后一个 Cell 在 Y 方向重叠
            BOOL isSameRow = CGRectGetMinY(attr.frame) < CGRectGetMaxY(lastAttr.frame);

            if (!isSameRow) {
                currentRow = [NSMutableArray array];
                [rows addObject:currentRow];
            }
        }

        [currentRow addObject:attr];
        lastAttr = attr;
    }

    for (NSMutableArray<UICollectionViewLayoutAttributes *> *row in rows) {
        [self alignRow:row];
    }

    [self applyContentVerticalAlignment:attributes];

    return attributes;
}

/// 计算所有 cell 内容整体高度，并根据 contentVerticalAlignment 对所有 attributes 做统一垂直偏移
/// 仅当容器可用高度 > 内容占用高度时生效（例如设置了 minHeight）
- (void)applyContentVerticalAlignment:(NSArray<UICollectionViewLayoutAttributes *> *)attributes {
    if (self.contentVerticalAlignment == ZLTagContentVerticalAlignmentTop) return;
    if (attributes.count == 0) return;

    CGFloat containerHeight = self.collectionView.bounds.size.height;
    if (containerHeight <= 0) return;

    // 计算内容实际占用范围（top ~ bottom）
    CGFloat contentTop = CGFLOAT_MAX;
    CGFloat contentBottom = -CGFLOAT_MAX;
    BOOL hasCell = NO;
    for (UICollectionViewLayoutAttributes *attr in attributes) {
        if (attr.representedElementCategory != UICollectionElementCategoryCell) continue;
        hasCell = YES;
        contentTop = MIN(contentTop, CGRectGetMinY(attr.frame));
        contentBottom = MAX(contentBottom, CGRectGetMaxY(attr.frame));
    }
    if (!hasCell) return;

    // 使用 sectionInset 内的可用高度作为参考
    CGFloat usableHeight = containerHeight - self.sectionInset.top - self.sectionInset.bottom;
    CGFloat usedHeight = contentBottom - contentTop;
    if (usedHeight >= usableHeight) return; // 容器装不下，无需偏移

    CGFloat offset = 0;
    switch (self.contentVerticalAlignment) {
        case ZLTagContentVerticalAlignmentTop:
            return;
        case ZLTagContentVerticalAlignmentCenter:
            offset = (usableHeight - usedHeight) / 2.0;
            break;
        case ZLTagContentVerticalAlignmentBottom:
            offset = usableHeight - usedHeight;
            break;
    }
    if (offset <= 0) return;

    for (UICollectionViewLayoutAttributes *attr in attributes) {
        if (attr.representedElementCategory != UICollectionElementCategoryCell) continue;
        CGRect frame = attr.frame;
        frame.origin.y += offset;
        attr.frame = frame;
    }
}

- (void)alignRow:(NSMutableArray<UICollectionViewLayoutAttributes *> *)row {
    if (row.count == 0) return;
    
    CGFloat collectionViewWidth = self.collectionView.bounds.size.width - self.sectionInset.left - self.sectionInset.right;
    CGFloat totalWidth = 0;
    CGFloat maxRowHeight = 0;
    
    for (UICollectionViewLayoutAttributes *attr in row) {
        totalWidth += attr.frame.size.width;
        maxRowHeight = MAX(maxRowHeight, attr.frame.size.height);
    }
    totalWidth += (row.count - 1) * self.minimumInteritemSpacing;
    CGFloat offset = 0;
    ZLTagRowHorizontalAlignment effectiveAlignment = self.rowHorizontalAlignment;
    switch (effectiveAlignment) {
        case ZLTagRowHorizontalAlignmentStart:
            offset = 0;
            break;
        case ZLTagRowHorizontalAlignmentCenter:
            offset = (collectionViewWidth - totalWidth) / 2.0;
            break;
        case ZLTagRowHorizontalAlignmentEnd:
            offset = collectionViewWidth - totalWidth;
            break;
    }
    
    // 行基准 y（该行最顶部的 y）
    CGFloat rowTop = CGFLOAT_MAX;
    for (UICollectionViewLayoutAttributes *attr in row) {
        rowTop = MIN(rowTop, attr.frame.origin.y);
    }
    
    // LTR: 从左向右排列
    CGFloat currentX = self.sectionInset.left + offset;
    for (UICollectionViewLayoutAttributes *attr in row) {
        CGRect frame = attr.frame;
        frame.origin.x = currentX;
        // 行内垂直对齐
        switch (self.rowVerticalAlignment) {
            case ZLTagRowVerticalAlignmentTop:
                frame.origin.y = rowTop;
                break;
            case ZLTagRowVerticalAlignmentCenter:
                frame.origin.y = rowTop + (maxRowHeight - frame.size.height) / 2.0;
                break;
            case ZLTagRowVerticalAlignmentBottom:
                frame.origin.y = rowTop + (maxRowHeight - frame.size.height);
                break;
        }
        attr.frame = frame;
        currentX += frame.size.width + self.minimumInteritemSpacing;
    }
}
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
    return !CGSizeEqualToSize(self.collectionView.bounds.size, newBounds.size) ;
}
- (BOOL)flipsHorizontallyInOppositeLayoutDirection {
    return  [UIView userInterfaceLayoutDirectionForSemanticContentAttribute:UIView.appearance.semanticContentAttribute] == UIUserInterfaceLayoutDirectionRightToLeft;
}
@end

@interface ZLTagCell : UICollectionViewCell
@property (nonatomic,assign)UIEdgeInsets insets;
@property (nonatomic,weak)UIView *tagView;
@end
@implementation ZLTagCell
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = self.subviews.firstObject;
    /// 如果点击在 cell 内，但不在 view 内，则返回 nil，避免 cell 拦截点击事件
    if ( view && !CGRectContainsPoint(view.frame, point)) {
        return nil;
    }
    return  [super hitTest:point withEvent:event];
}
- (void)setTagView:(UIView *)tagView {
    [self.subviews.firstObject removeFromSuperview];
    [self addSubview:tagView];
    _tagView = tagView;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _tagView.frame = UIEdgeInsetsInsetRect(self.bounds, _insets);
}
@end



@interface ZLTagListView () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) ZLTagCollectionView *collectionView;
@property (nonatomic, strong) ZLTagFlowLayout *flowLayout;
@property (nonatomic,strong)NSMutableDictionary<NSNumber *,UIView *> *viewCache;
@property (nonatomic,strong)NSMutableDictionary<NSNumber *,NSValue *> *sizeCache;
@property (nonatomic, assign) CGSize preSize;

@property (nonatomic,assign)BOOL useAutoLayout;
@end

@implementation ZLTagListView
#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupDefaults];
        [self setupCollectionView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupDefaults];
        [self setupCollectionView];
    }
    return self;
}

- (void)setupDefaults {
    self.viewCache = [NSMutableDictionary dictionary];
    self.sizeCache = [NSMutableDictionary dictionary];
    _rowHorizontalAlignment = ZLTagRowHorizontalAlignmentStart;
    _rowVerticalAlignment = ZLTagRowVerticalAlignmentCenter;
    _contentVerticalAlignment = ZLTagContentVerticalAlignmentTop;
    _lineSpacing = 10;
    _itemSpacing = 10;
    _contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
    _horizontalScroll = NO;
    _maxWidth = CGFLOAT_MAX;
    _maxHeight = CGFLOAT_MAX;
    _minWidth = 0;
    _minHeight = 0;
    _forceRTL = NO;
    _autoDetectRTL = YES;
    _headerBottomSpacing = 0;
    _footerTopSpacing = 0;
}

- (void)setupCollectionView {
    _flowLayout = [[ZLTagFlowLayout alloc] init];
    _flowLayout.rowHorizontalAlignment = _rowHorizontalAlignment;
    _flowLayout.rowVerticalAlignment = _rowVerticalAlignment;
    _flowLayout.contentVerticalAlignment = _contentVerticalAlignment;
    _flowLayout.minimumLineSpacing = _lineSpacing;
    _flowLayout.minimumInteritemSpacing = _itemSpacing;
    _flowLayout.sectionInset = _contentInset;
    _flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    _flowLayout.isRTL = [self isCurrentLayoutRTL];
    _collectionView = [[ZLTagCollectionView alloc] initWithFrame:self.bounds collectionViewLayout:_flowLayout];
    [_collectionView registerClass:ZLTagCell.class forCellWithReuseIdentifier:@"cell"];
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.showsVerticalScrollIndicator = NO;
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if (@available(iOS 11.0, *)) {
        _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self addSubview:_collectionView];
}

- (BOOL)isCurrentLayoutRTL {
    if (_forceRTL) {
        return YES;
    }
    if (_autoDetectRTL) {
        BOOL rtl =  [UIView userInterfaceLayoutDirectionForSemanticContentAttribute:UIView.appearance.semanticContentAttribute] == UIUserInterfaceLayoutDirectionRightToLeft;
        return rtl;
    }
    return NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 更新RTL状态
    _flowLayout.isRTL = [self isCurrentLayoutRTL];
    if (self.preSize.width != [self caculateWidth]) {
        [self.sizeCache removeAllObjects];
        [_flowLayout invalidateLayout];
        [self invalidateIntrinsicContentSize];
    }

    CGFloat width = self.bounds.size.width;
    CGFloat auxWidth = MAX(0, width - _contentInset.left - _contentInset.right);
    CGFloat headerHeight = _headerView ? [self fittingHeightForAuxiliaryView:_headerView width:auxWidth] : 0;
    CGFloat footerHeight = _footerView ? [self fittingHeightForAuxiliaryView:_footerView width:auxWidth] : 0;

    CGFloat contentTop = 0;
    if (_headerView) {
        _headerView.frame = CGRectMake(_contentInset.left, _contentInset.top, auxWidth, headerHeight);
        contentTop = _contentInset.top + headerHeight + _headerBottomSpacing;
    }

    CGFloat contentBottom = self.bounds.size.height;
    if (_footerView) {
        contentBottom -= (_contentInset.bottom + footerHeight + _footerTopSpacing);
    }

    CGRect collectionFrame = CGRectMake(0, contentTop, width, MAX(0, contentBottom - contentTop));
    if (!CGRectEqualToRect(_collectionView.frame, collectionFrame)) {
        _collectionView.frame = collectionFrame;
    }

    if (_footerView) {
        _footerView.frame = CGRectMake(_contentInset.left, self.bounds.size.height - _contentInset.bottom - footerHeight, auxWidth, footerHeight);
    }

    // 头尾视图存在时，其对应方向的 contentInset 已由头尾视图自身承担，标签网格自身不再重复叠加该方向的内边距
    [self updateEffectiveSectionInset];
}

/// 根据 headerView / footerView 是否存在，动态调整标签网格（flowLayout）自身的上/下内边距，
/// 避免与已经由头尾视图承担的 contentInset.top / contentInset.bottom 重复叠加；左右内边距始终保持不变
- (void)updateEffectiveSectionInset {
    UIEdgeInsets inset = _contentInset;
    if (_headerView) inset.top = 0;
    if (_footerView) inset.bottom = 0;
    if (!UIEdgeInsetsEqualToEdgeInsets(_flowLayout.sectionInset, inset)) {
        _flowLayout.sectionInset = inset;
        [_flowLayout invalidateLayout];
    }
}

/// 测量辅助视图（头/尾视图）在给定宽度下的自适应高度：优先按 Auto Layout 约束计算，失败则回退到 sizeThatFits:
- (CGFloat)fittingHeightForAuxiliaryView:(UIView *)view width:(CGFloat)width {
    if (!view || width <= 0) return 0;
    CGSize fitSize = [view systemLayoutSizeFittingSize:CGSizeMake(width, UILayoutFittingCompressedSize.height)
                                withHorizontalFittingPriority:UILayoutPriorityRequired
                                      verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
    if (fitSize.height <= 0) {
        fitSize = [view sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    }
    return ceil(MAX(fitSize.height, 0));
}

#pragma mark - Setters

- (void)setRowHorizontalAlignment:(ZLTagRowHorizontalAlignment)alignment {
    _rowHorizontalAlignment = alignment;
    _flowLayout.rowHorizontalAlignment = alignment;
    [_flowLayout invalidateLayout];
}

- (void)setRowVerticalAlignment:(ZLTagRowVerticalAlignment)verticalAlignment {
    _rowVerticalAlignment = verticalAlignment;
    _flowLayout.rowVerticalAlignment = verticalAlignment;
    [_flowLayout invalidateLayout];
}

- (void)setContentVerticalAlignment:(ZLTagContentVerticalAlignment)contentVerticalAlignment {
    _contentVerticalAlignment = contentVerticalAlignment;
    _flowLayout.contentVerticalAlignment = contentVerticalAlignment;
    [_flowLayout invalidateLayout];
}

- (void)setLineSpacing:(CGFloat)lineSpacing {
    _lineSpacing = lineSpacing;
    _flowLayout.minimumLineSpacing = lineSpacing;
    [_flowLayout invalidateLayout];
}

- (void)setItemSpacing:(CGFloat)itemSpacing {
    _itemSpacing = itemSpacing;
    _flowLayout.minimumInteritemSpacing = itemSpacing;
    [_flowLayout invalidateLayout];
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
    _contentInset = contentInset;
    [self updateEffectiveSectionInset];
    [self setNeedsLayout];
    [self invalidateIntrinsicContentSize];
}

- (void)setHorizontalScroll:(BOOL)horizontalScroll {
    _horizontalScroll = horizontalScroll;
    _flowLayout.scrollDirection = horizontalScroll ? UICollectionViewScrollDirectionHorizontal : UICollectionViewScrollDirectionVertical;
    [_flowLayout invalidateLayout];
}

- (void)setMaxWidth:(CGFloat)maxWidth {
    _maxWidth = maxWidth;
    [self setNeedsLayout];
}

- (void)setMaxHeight:(CGFloat)maxHeight {
    _maxHeight = maxHeight;
    [self setNeedsLayout];
}

- (void)setMinWidth:(CGFloat)minWidth {
    _minWidth = minWidth;
    [self setNeedsLayout];
}

- (void)setMinHeight:(CGFloat)minHeight {
    _minHeight = minHeight;
    [self setNeedsLayout];
}

- (void)setForceRTL:(BOOL)forceRTL {
    _forceRTL = forceRTL;
    _flowLayout.isRTL = [self isCurrentLayoutRTL];
    [_flowLayout invalidateLayout];
}

- (void)setAutoDetectRTL:(BOOL)autoDetectRTL {
    _autoDetectRTL = autoDetectRTL;
    _flowLayout.isRTL = [self isCurrentLayoutRTL];
    [_flowLayout invalidateLayout];
}

- (void)setHeaderView:(UIView *)headerView {
    if (_headerView == headerView) return;
    [_headerView removeFromSuperview];
    _headerView = headerView;
    if (headerView) {
        [self addSubview:headerView];
    }
    [self updateEffectiveSectionInset];
    [self setNeedsLayout];
    [self invalidateIntrinsicContentSize];
}

- (void)setFooterView:(UIView *)footerView {
    if (_footerView == footerView) return;
    [_footerView removeFromSuperview];
    _footerView = footerView;
    if (footerView) {
        [self addSubview:footerView];
    }
    [self updateEffectiveSectionInset];
    [self setNeedsLayout];
    [self invalidateIntrinsicContentSize];
}

- (void)setHeaderBottomSpacing:(CGFloat)headerBottomSpacing {
    _headerBottomSpacing = headerBottomSpacing;
    [self setNeedsLayout];
    [self invalidateIntrinsicContentSize];
}

- (void)setFooterTopSpacing:(CGFloat)footerTopSpacing {
    _footerTopSpacing = footerTopSpacing;
    [self setNeedsLayout];
    [self invalidateIntrinsicContentSize];
}

#pragma mark - Public Methods




- (CGFloat)calculateContentHeight {
    return [self calculateContentHeightWithWidth:self.bounds.size.width];
}

- (CGFloat)calculateContentHeightWithWidth:(CGFloat)width {
    CGSize size = [self calculateContentSizeWithWidth:width];
    return _horizontalScroll ? size.width : size.height;
}

- (CGSize)calculateContentSize {
    CGFloat width = [self caculateWidth];
    return [self calculateContentSizeWithWidth:width];
}
- (CGFloat)caculateWidth {
    CGFloat width = 0;
    if (_maxWidth == CGFLOAT_MAX && _maxHeight == CGFLOAT_MAX) {
        width = self.bounds.size.width;
    }else if (_maxWidth > 0) {
        width = _maxWidth;
    }else if (_minWidth > 0) {
        width = _minWidth;
    }else if (self.bounds.size.width > 0) {
        width = self.bounds.size.width;
    }
    return width;
}
- (CGSize)calculateContentSizeWithWidth:(CGFloat)width {
    CGSize tagSize = [self tagGridContentSizeWithWidth:width];

    if (!_headerView && !_footerView) {
        return tagSize;
    }

    // 头尾视图始终期望与父视图（可用宽度）等宽（左右两侧统一按 contentInset 收进）
    CGFloat containerWidth = MAX(tagSize.width, width);
    if (_maxWidth < CGFLOAT_MAX) {
        containerWidth = MIN(containerWidth, _maxWidth);
    }
    containerWidth = MAX(containerWidth, _minWidth);

    CGFloat auxWidth = MAX(0, containerWidth - _contentInset.left - _contentInset.right);
    CGFloat headerHeight = _headerView ? [self fittingHeightForAuxiliaryView:_headerView width:auxWidth] : 0;
    CGFloat footerHeight = _footerView ? [self fittingHeightForAuxiliaryView:_footerView width:auxWidth] : 0;

    // tagSize.height 内部已经恰好包含一份 contentInset.top 和一份 contentInset.bottom
    // （无论是否存在头尾视图，最外层顶部/底部间距始终只需要这一份），
    // 因此只需在此基础上直接累加头/尾视图自身的高度与间距即可，不能再重复扣减 contentInset
    CGFloat totalHeight = tagSize.height;
    if (_headerView) {
        totalHeight += headerHeight + _headerBottomSpacing;
    }
    if (_footerView) {
        totalHeight += footerHeight + _footerTopSpacing;
    }
    totalHeight = MAX(totalHeight, 0);

    return CGSizeMake(containerWidth, totalHeight);
}

/// 标签网格区域自身的内容尺寸计算（不含头尾视图），受 minWidth/maxWidth/minHeight/maxHeight 约束
- (CGSize)tagGridContentSizeWithWidth:(CGFloat)width {
    if (width <= 0) {
        return CGSizeZero;
    }
    if (!_dataSource) return CGSizeMake(_minWidth, _minHeight);

    NSInteger count = [_dataSource numberOfTagsInTagListView:self];
    if (count == 0) {
        CGFloat emptyWidth = _contentInset.left + _contentInset.right;
        CGFloat emptyHeight = _contentInset.top + _contentInset.bottom;
        emptyWidth = MAX(_minWidth, MIN(emptyWidth, _maxWidth));
        emptyHeight = MAX(_minHeight, MIN(emptyHeight, _maxHeight));
        return CGSizeMake(emptyWidth, emptyHeight);
    }

    CGFloat availableWidth = width;
    if (_maxWidth < CGFLOAT_MAX) {
        availableWidth = MIN(width, _maxWidth);
    }
    if (availableWidth <= 0) {
        availableWidth = _maxWidth < CGFLOAT_MAX ? _maxWidth : 300;
    }
    availableWidth = MAX(availableWidth, _minWidth);

    if (_horizontalScroll) {
        CGFloat totalWidth = _contentInset.left;
        CGFloat maxItemHeight = 0;

        for (NSInteger i = 0; i < count; i++) {
            CGSize size = [self tagListView:self sizeForTagAtIndex:i];
            totalWidth += size.width;
            if (i < count - 1) {
                totalWidth += _itemSpacing;
            }
            maxItemHeight = MAX(maxItemHeight, size.height);
        }
        totalWidth += _contentInset.right;

        CGFloat contentHeight = maxItemHeight + _contentInset.top + _contentInset.bottom;

        CGFloat finalWidth = MAX(_minWidth, MIN(totalWidth, _maxWidth));
        CGFloat finalHeight = MAX(_minHeight, MIN(contentHeight, _maxHeight));

        return CGSizeMake(finalWidth, finalHeight);
    } else {
//        {
//            CGFloat contentWidth = availableWidth - _contentInset.left - _contentInset.right;
//
//                CGFloat x = 0;
//
//                CGFloat y = _contentInset.top;
//
//                CGFloat lineHeight = 0;
//
//                CGFloat maxLineWidth = 0;
//
//                for (NSInteger i = 0; i < count; i++) {
//
//                    CGSize itemSize = [self tagListView:self sizeForTagAtIndex:i];
//                    CGFloat w = ceil(itemSize.width);
//                    CGFloat h = ceil(itemSize.height);
//                    itemSize.width = MIN(w, contentWidth);
//
//                    // 判断放下当前 item 后是否需要换行
//
//                    if (x > 0 && x + _itemSpacing + w > contentWidth) {
//
//                        maxLineWidth = MAX(maxLineWidth, x);
//
//                        y += lineHeight + _lineSpacing;
//
//                        x = 0;
//
//                        lineHeight = 0;
//
//                    }
//
//                    if (x > 0) {
//
//                        x += _itemSpacing;
//
//                    }
//
//                    x += w;
//
//                    lineHeight = MAX(lineHeight, h);
//                    NSLog(@"tag: %zd y: %f w %f res: %d", i, y,w);
//                }
//
//                maxLineWidth = MAX(maxLineWidth, x);
//
//                CGFloat totalWidth = maxLineWidth + _contentInset.left + _contentInset.right;
//
//                CGFloat totalHeight = y + lineHeight + _contentInset.bottom;
//
//                NSLog(@"y: %f, lineHeight: %f  %f", y, lineHeight,totalHeight);
//
//                return CGSizeMake(
//
//                    MIN(MAX(totalWidth, _minWidth), availableWidth),
//
//                    MIN(MAX(totalHeight, _minHeight), _maxHeight)
//
//                );
//        }
        

        
        
        CGFloat contentWidth = availableWidth - _contentInset.left - _contentInset.right;
        CGFloat currentX = 0;
        CGFloat currentY = _contentInset.top;
        CGFloat lineHeight = 0;
        CGFloat maxLineWidth = 0;
        CGFloat currentLineWidth = 0;

        for (NSInteger i = 0; i < count; i++) {
            CGSize size = [self tagListView:self sizeForTagAtIndex:i];

            if (currentX + size.width > contentWidth && currentX > 0) {
                maxLineWidth = MAX(maxLineWidth, currentLineWidth - _itemSpacing);
                currentX = 0;
                currentLineWidth = 0;

                currentY += lineHeight + _lineSpacing;
                lineHeight = 0;
            }

            lineHeight = MAX(lineHeight, size.height);
            currentX += size.width + _itemSpacing;
            currentLineWidth += size.width + _itemSpacing;
        }

        maxLineWidth = MAX(maxLineWidth, currentLineWidth - _itemSpacing);

        CGFloat totalHeight = currentY + lineHeight + _contentInset.bottom;
        CGFloat totalWidth = maxLineWidth + _contentInset.left + _contentInset.right;

        CGFloat finalWidth = MAX(_minWidth, MIN(totalWidth, _maxWidth));
        CGFloat finalHeight = MAX(_minHeight, MIN(totalHeight, _maxHeight));

        finalWidth = MIN(finalWidth, availableWidth);

        return CGSizeMake(finalWidth, finalHeight);
    }
}

- (CGSize)intrinsicContentSize {
    CGSize size = [self calculateContentSize];
    if (!CGSizeEqualToSize(size, self.preSize)) {
        if (size.height != self.preSize.height) {
            if ([self.dataSource respondsToSelector:@selector(tagListView:didUpdateContentHeight:)]) {
                [self.dataSource tagListView:self didUpdateContentHeight:size.height];
            }
        }
       
        if (size.width != self.preSize.width) {
            if ([self.dataSource respondsToSelector:@selector(tagListView:didUpdateContentWidth:)]) {
                [self.dataSource tagListView:self didUpdateContentWidth:size.height];
            }
        }
       
        self.preSize = size;
    }
    return size;
}

- (void)reloadData {
    [self.sizeCache removeAllObjects];
    [_collectionView reloadData];
    [self invalidateIntrinsicContentSize];
}
- (void)syncReloadData {
    [self reloadData];
    [self layoutIfNeeded];
}
- (void)scrollToItemAtIndex:(NSInteger)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated {
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:indexPath inSection:0] atScrollPosition:scrollPosition animated:animated];
}
- (void)sizeToFit {
    CGSize size = [self calculateContentSize];
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_dataSource && [_dataSource respondsToSelector:@selector(numberOfTagsInTagListView:)]) {
        return [_dataSource numberOfTagsInTagListView:self];
    }
    return 0;
}
- (UIView *)tagListView:(ZLTagListView *)tagListView
          forTagAtIndex:(NSInteger)index {
    UIView *cacheView = self.viewCache[@(index)];
    if (_dataSource && [_dataSource respondsToSelector:@selector(tagListView:dequeueView:forTagAtIndex:)]) {
        cacheView = [_dataSource tagListView:self dequeueView:cacheView forTagAtIndex:index];
        self.viewCache[@(index)] = cacheView;
    }
    return cacheView;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ZLTagCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    NSNumber *indexKey = @(indexPath.item);
    UIView *view = self.viewCache[indexKey];
    if (_dataSource && [_dataSource respondsToSelector:@selector(tagListView:dequeueView:forTagAtIndex:)]) {
        view = [_dataSource tagListView:self dequeueView:view forTagAtIndex:indexPath.item];
        [view removeFromSuperview];
        [view invalidateIntrinsicContentSize];
        
        UIEdgeInsets cellInsets = UIEdgeInsetsZero;
        if ([_dataSource respondsToSelector:@selector(tagListView:marginForTagAtIndex:)]) {
            cellInsets = [_dataSource tagListView:self marginForTagAtIndex:indexPath.item];
        }
        
        if (![cell.subviews.firstObject isEqual:view]) {
            if (self.useAutoLayout) {
                [cell.subviews.firstObject removeFromSuperview];
                [cell addSubview:view];
                view.translatesAutoresizingMaskIntoConstraints = NO;
                [view.topAnchor constraintEqualToAnchor:cell.topAnchor constant:cellInsets.top].active = YES;
                [view.leadingAnchor constraintEqualToAnchor:cell.leadingAnchor constant:cellInsets.left].active = YES;
            }else {
                cell.insets = cellInsets;
                cell.tagView = view;
            }
        }
        self.viewCache[indexKey] = view;
    }
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self tagListView:self sizeForTagAtIndex:indexPath.item];
}
- (CGSize)tagListView:(ZLTagListView *)tagListView sizeForTagAtIndex:(NSInteger)index {
    NSValue *cachedSize = self.sizeCache[@(index)];
    if (cachedSize) return cachedSize.CGSizeValue;
    
    UIView *view = [self tagListView:self forTagAtIndex:index];
    [view setNeedsLayout];
    [view layoutIfNeeded];
    CGSize size = view ? [view systemLayoutSizeFittingSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) withHorizontalFittingPriority:UILayoutPriorityFittingSizeLevel verticalFittingPriority:UILayoutPriorityFittingSizeLevel] : CGSizeZero;
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if ([_dataSource respondsToSelector:@selector(tagListView:marginForTagAtIndex:)]) {
        insets = [_dataSource tagListView:self marginForTagAtIndex:index];
    }
    
    
    size = CGSizeMake(ceil(size.width + insets.left + insets.right), ceil(size.height + insets.top + insets.bottom));

    cachedSize = [NSValue valueWithCGSize:size];
    if (cachedSize) self.sizeCache[@(index)] = cachedSize;
    return size;
}
//- (CGSize)tagListView:(ZLTagListView *)tagListView sizeForTagAtIndex:(NSInteger)index {
//    NSValue *cached = self.sizeCache[@(index)];
//    if (cached) return cached.CGSizeValue;
//
//    // 用一个专门的测量 view，不写 viewCache
//    UIView *view = nil;
//    if (_dataSource && [_dataSource respondsToSelector:@selector(tagListView:dequeueView:forTagAtIndex:)]) {
//        view = [_dataSource tagListView:self dequeueView:nil forTagAtIndex:index];
//    }
//    CGSize size = view ? [view systemLayoutSizeFittingSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
//                          withHorizontalFittingPriority:UILayoutPriorityFittingSizeLevel
//                                verticalFittingPriority:UILayoutPriorityFittingSizeLevel] : CGSizeZero;
//    self.sizeCache[@(index)] = [NSValue valueWithCGSize:size];
//    return size;
//}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_dataSource && [_dataSource respondsToSelector:@selector(tagListView:didSelectTagAtIndex:)]) {
        [_dataSource tagListView:self didSelectTagAtIndex:indexPath.item];
    }
}
@end


@implementation ZLBlockTagListView
- (void)setDataSource:(id<ZLTagListViewDataSource>)dataSource {
    if (![dataSource isEqual:self]) return;
    [super setDataSource:dataSource];
}
- (instancetype)initWithFrame:(CGRect)frame
              numberOfTags:(NSInteger (^)(ZLBlockTagListView *tagListView))numberOfTags
                  dequeueView:(UIView * (^)(ZLBlockTagListView  *tagListView, __kindof UIView * _Nullable view, NSInteger index))dequeueView {
    self = [super initWithFrame:frame];
    if (self) {
        self.numberOfTags = numberOfTags;
        self.dequeueView = dequeueView;
        self.dataSource = self;
    }
    return self;
}
- (NSInteger)numberOfTagsInTagListView:(ZLTagListView *)tagListView {
    if (self.numberOfTags) {
        return self.numberOfTags(self);
    }
    return 0;
}

/// 返回标签视图
/// - Parameters:
///   - tagListView: 标签列表视图
///   - view: 可重用的标签视图，如果为nil则需要创建一个新的视图
///   - index: 标签索引
- (UIView *)tagListView:(ZLTagListView *)tagListView
            dequeueView:(__kindof UIView * _Nullable)view
          forTagAtIndex:(NSInteger)index {
    if (self.dequeueView) {
        return self.dequeueView(self, view, index);
    }
    return UIView.new;
}
///标签被选中
- (void)tagListView:(ZLTagListView *)tagListView didSelectTagAtIndex:(NSInteger)index {
    if (self.didSelectTag) {
        self.didSelectTag(self, index);
    }
}
///高度发生变化
- (void)tagListView:(ZLTagListView *)tagListView didUpdateContentHeight:(CGFloat)height {
    if (self.didUpdateContentHeight) {
        self.didUpdateContentHeight(self, height);
    }
}
///宽度发生变化
- (void)tagListView:(ZLTagListView *)tagListView didUpdateContentWidth:(CGFloat)width {
    if (self.didUpdateContentWidth) {
        self.didUpdateContentWidth(self, width);
    }
}
- (UIEdgeInsets)tagListView:(ZLTagListView *)tagListView marginForTagAtIndex:(NSInteger)index {
    if (self.marginForTag) {
        return self.marginForTag(self, index);
    }
    return UIEdgeInsetsZero;
}
@end


@interface ZLViewTagListView ()
@property (nonatomic, strong) NSMutableArray<UIView *> *mutableTagViews;
@property (nonatomic,strong)NSMutableDictionary<NSNumber *,NSValue *> *marginCache;
@end

@implementation ZLViewTagListView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViewTagList];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupViewTagList];
    }
    return self;
}

- (void)setupViewTagList {
    _mutableTagViews = [NSMutableArray array];
    _marginCache = [NSMutableDictionary dictionary];
    self.dataSource = self;
    self.useAutoLayout = YES;
}
- (void)setAutoReload:(BOOL)autoReload {
    _autoReload = autoReload;
    self.useAutoLayout = autoReload;
}

// 强制数据源始终为自身
- (void)setDataSource:(id<ZLTagListViewDataSource>)dataSource {
    if (![dataSource isEqual:self]) return;
    [super setDataSource:dataSource];
}

- (NSArray<__kindof UIView *> *)tagViews {
    return [self.mutableTagViews copy];
}

#pragma mark - Public

- (void)addView:(UIView *)view {
    if (!view) return;
    [self.mutableTagViews addObject:view];
    [self reloadData];
}
- (void)addView:(UIView *)view margin:(UIEdgeInsets)margin {
    [self addView:view];
    [self setTagMargin:margin atIndex:(self.mutableTagViews.count - 1)];
}

- (void)addViews:(NSArray<__kindof UIView *> *)views {
    if (views.count == 0) return;
    [self.mutableTagViews addObjectsFromArray:views];
    [self reloadData];
}

- (void)insertView:(UIView *)view atIndex:(NSInteger)index {
    if (!view) return;
    if (index < 0 || index > (NSInteger)self.mutableTagViews.count) {
        [self.mutableTagViews addObject:view];
    } else {
        [self.mutableTagViews insertObject:view atIndex:index];
    }
    [self reloadData];
}
- (void)insertView:(UIView *)view margin:(UIEdgeInsets)margin atIndex:(NSInteger)index {
    [self insertView:view atIndex:index];
    [self setTagMargin:margin atIndex:index];
}
- (void)removeView:(UIView *)view {
    if (!view) return;
    NSUInteger idx = [self.mutableTagViews indexOfObject:view];
    if (idx == NSNotFound) return;
    [self removeViewAtIndex:idx];
}

- (void)removeViewAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.mutableTagViews.count) return;
    [self.mutableTagViews removeObjectAtIndex:index];
    [self reloadData];
}

- (void)removeAllViews {
    [self.mutableTagViews removeAllObjects];
    [self reloadData];
}
- (void)setTagMargin:(UIEdgeInsets)margin atIndex:(NSInteger )index{
   self.marginCache[@(index)] = [NSValue valueWithUIEdgeInsets:margin];
   [self reloadData];
}


#pragma mark - ZLTagListViewDataSource

- (NSInteger)numberOfTagsInTagListView:(ZLTagListView *)tagListView {
    return self.mutableTagViews.count;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    if (self.autoReload) {
        __weak typeof(self) weakSelf = self;
        [cell.subviews.firstObject setZl_boundsDidChangeBlock:^(UIView *view, CGRect oldBounds, CGRect newBounds) {
            [weakSelf reloadData];
        }];
    }
    return cell;
}
- (UIView *)tagListView:(ZLTagListView *)tagListView
            dequeueView:(__kindof UIView * _Nullable)view
          forTagAtIndex:(NSInteger)index {
    if (index >= 0 && index < (NSInteger)self.mutableTagViews.count) {
        return self.mutableTagViews[index];
    }
    return [UIView new];
}

- (void)tagListView:(ZLTagListView *)tagListView didSelectTagAtIndex:(NSInteger)index {
    if (self.didSelectTag && index >= 0 && index < (NSInteger)self.mutableTagViews.count) {
        self.didSelectTag(self, self.mutableTagViews[index], index);
    }
}
- (UIEdgeInsets)tagListView:(ZLTagListView *)tagListView marginForTagAtIndex:(NSInteger)index {
    NSValue *value = self.marginCache[@(index)];
    return value ? value.UIEdgeInsetsValue : self.tagMargin;
}
@end


@interface ZLSelectableTagListView ()
/// 已选中的视图集合，使用有序集合保证按选中顺序输出，且不受插入/删除导致的索引变化影响
@property (nonatomic, strong) NSMutableOrderedSet<UIView *> *selectedViewsSet;
@end

@implementation ZLSelectableTagListView

- (void)setupViewTagList {
    [super setupViewTagList];
    _selectionMode = ZLTagSelectionModeSingle;
    _allowsEmptySelection = YES;
    _selectedViewsSet = [NSMutableOrderedSet orderedSet];
}

- (void)setSelectionMode:(ZLTagSelectionMode)selectionMode {
    if (_selectionMode == selectionMode) return;
    _selectionMode = selectionMode;
    // 切换模式后清空选中状态，避免多选态残留到单选模式下产生歧义
    [self deselectAll];
}

#pragma mark - 选中状态读取

- (NSArray<NSNumber *> *)selectedIndexes {
    NSArray<UIView *> *tagViews = self.tagViews;
    NSMutableArray<NSNumber *> *result = [NSMutableArray array];
    for (UIView *view in self.selectedViewsSet) {
        NSInteger idx = [tagViews indexOfObjectIdenticalTo:view];
        if (idx != NSNotFound) {
            [result addObject:@(idx)];
        }
    }
    return [result copy];
}

- (NSArray<__kindof UIView *> *)selectedViews {
    return self.selectedViewsSet.array;
}

- (BOOL)isIndexSelected:(NSInteger)index {
    NSArray<UIView *> *tagViews = self.tagViews;
    if (index < 0 || index >= (NSInteger)tagViews.count) return NO;
    return [self.selectedViewsSet containsObject:tagViews[index]];
}

#pragma mark - 选中态内部辅助

- (void)applyStyleForView:(UIView *)view selected:(BOOL)selected {
    if (!view) return;
    NSInteger idx = [self.tagViews indexOfObjectIdenticalTo:view];
    if (selected) {
        if (self.selectedStyleBlock) self.selectedStyleBlock(view, idx);
    } else {
        if (self.normalStyleBlock) self.normalStyleBlock(view, idx);
    }
}

/// 选中一个 view（不处理互斥逻辑，互斥由调用方在合适的场景下处理）
- (void)markSelectView:(UIView *)view {
    if (!view || [self.selectedViewsSet containsObject:view]) return;
    [self.selectedViewsSet addObject:view];
    [self applyStyleForView:view selected:YES];
}

/// 取消选中一个 view
- (void)markDeselectView:(UIView *)view {
    if (!view || ![self.selectedViewsSet containsObject:view]) return;
    [self.selectedViewsSet removeObject:view];
    [self applyStyleForView:view selected:NO];
}

- (void)notifySelectionChanged {
    if (self.didChangeSelection) {
        self.didChangeSelection(self, self.selectedIndexes);
    }
}

#pragma mark - 点击切换选中态（拦截自 ZLViewTagListView 的点击回调入口）

- (void)tagListView:(ZLTagListView *)tagListView didSelectTagAtIndex:(NSInteger)index {
    NSArray<UIView *> *tagViews = self.tagViews;
    if (index >= 0 && index < (NSInteger)tagViews.count) {
        UIView *view = tagViews[index];
        BOOL currentlySelected = [self.selectedViewsSet containsObject:view];

        if (currentlySelected) {
            if (self.allowsEmptySelection) {
                [self markDeselectView:view];
                [self notifySelectionChanged];
            }
            // 不允许清空选中时，点击已选中项不产生变化
        } else {
            if (self.selectionMode == ZLTagSelectionModeSingle) {
                for (UIView *selected in self.selectedViewsSet.array) {
                    [self markDeselectView:selected];
                }
            }
            [self markSelectView:view];
            [self notifySelectionChanged];
        }
    }
    // 保留父类原始点击回调（didSelectTag Block），使外部仍能感知每次点击事件
    [super tagListView:tagListView didSelectTagAtIndex:index];
}

#pragma mark - Public 选中操作

- (void)selectIndex:(NSInteger)index {
    NSArray<UIView *> *tagViews = self.tagViews;
    if (index < 0 || index >= (NSInteger)tagViews.count) return;
    UIView *view = tagViews[index];
    if ([self.selectedViewsSet containsObject:view]) return;

    if (self.selectionMode == ZLTagSelectionModeSingle) {
        for (UIView *selected in self.selectedViewsSet.array) {
            [self markDeselectView:selected];
        }
    }
    [self markSelectView:view];
    [self notifySelectionChanged];
}

- (void)deselectIndex:(NSInteger)index {
    NSArray<UIView *> *tagViews = self.tagViews;
    if (index < 0 || index >= (NSInteger)tagViews.count) return;
    UIView *view = tagViews[index];
    if (![self.selectedViewsSet containsObject:view]) return;
    [self markDeselectView:view];
    [self notifySelectionChanged];
}

- (void)deselectAll {
    if (self.selectedViewsSet.count == 0) return;
    for (UIView *selected in self.selectedViewsSet.array) {
        [self markDeselectView:selected];
    }
    [self notifySelectionChanged];
}

- (void)setSelectedIndexes:(NSArray<NSNumber *> *)indexes {
    for (UIView *selected in self.selectedViewsSet.array) {
        [self markDeselectView:selected];
    }
    NSArray<UIView *> *tagViews = self.tagViews;
    if (self.selectionMode == ZLTagSelectionModeSingle) {
        NSNumber *first = indexes.firstObject;
        if (first) {
            NSInteger idx = first.integerValue;
            if (idx >= 0 && idx < (NSInteger)tagViews.count) {
                [self markSelectView:tagViews[idx]];
            }
        }
    } else {
        for (NSNumber *number in indexes) {
            NSInteger idx = number.integerValue;
            if (idx >= 0 && idx < (NSInteger)tagViews.count) {
                [self markSelectView:tagViews[idx]];
            }
        }
    }
    [self notifySelectionChanged];
}

- (void)setSelectedIndex:(NSInteger)index {
    [self setSelectedIndexes:@[@(index)]];
}

#pragma mark - 覆盖增删方法：新增视图默认应用未选中样式，删除视图时同步清理选中状态

- (void)addView:(UIView *)view {
    [super addView:view];
    if (view && ![self.selectedViewsSet containsObject:view]) {
        [self applyStyleForView:view selected:NO];
    }
}

- (void)addViews:(NSArray<__kindof UIView *> *)views {
    [super addViews:views];
    for (UIView *view in views) {
        if (view && ![self.selectedViewsSet containsObject:view]) {
            [self applyStyleForView:view selected:NO];
        }
    }
}

- (void)insertView:(UIView *)view atIndex:(NSInteger)index {
    [super insertView:view atIndex:index];
    if (view && ![self.selectedViewsSet containsObject:view]) {
        [self applyStyleForView:view selected:NO];
    }
}

- (void)removeView:(UIView *)view {
    if (view && [self.selectedViewsSet containsObject:view]) {
        [self.selectedViewsSet removeObject:view];
        [self notifySelectionChanged];
    }
    [super removeView:view];
}

- (void)removeViewAtIndex:(NSInteger)index {
    NSArray<UIView *> *tagViews = self.tagViews;
    if (index >= 0 && index < (NSInteger)tagViews.count) {
        UIView *view = tagViews[index];
        if ([self.selectedViewsSet containsObject:view]) {
            [self.selectedViewsSet removeObject:view];
            [self notifySelectionChanged];
        }
    }
    [super removeViewAtIndex:index];
}

- (void)removeAllViews {
    BOOL hadSelection = self.selectedViewsSet.count > 0;
    [self.selectedViewsSet removeAllObjects];
    [super removeAllViews];
    if (hadSelection) {
        [self notifySelectionChanged];
    }
}

@end
