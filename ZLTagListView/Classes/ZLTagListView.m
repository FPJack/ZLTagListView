#import "ZLTagListView.h"

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
    if (!CGRectEqualToRect(_collectionView.frame, self.bounds)) {
        _collectionView.frame = self.bounds;
    }
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
    _flowLayout.sectionInset = contentInset;
    [_flowLayout invalidateLayout];
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
//            [cell.contentView.subviews.firstObject removeFromSuperview];
            cell.insets = cellInsets;
            cell.tagView = view;
//            [cell.contentView addSubview:view];
//            view.translatesAutoresizingMaskIntoConstraints = NO;
//            [view.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:cellInsets.top].active = YES;
//            [view.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-cellInsets.bottom].active = YES;
//            [view.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:cellInsets.left].active = YES;
//            [view.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-cellInsets.right].active = YES;
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
- (void)setMargin:(UIEdgeInsets)margin atIndex:(NSInteger )index{
   self.marginCache[@(index)] = [NSValue valueWithUIEdgeInsets:margin];
   [self reloadData];
}
#pragma mark - ZLTagListViewDataSource

- (NSInteger)numberOfTagsInTagListView:(ZLTagListView *)tagListView {
    return self.mutableTagViews.count;
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
    return [self.marginCache[@(index)] UIEdgeInsetsValue];
}
@end
