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
        return attributes;
    }
    NSMutableArray<NSMutableArray<UICollectionViewLayoutAttributes *> *> *rows = [NSMutableArray array];
    CGFloat currentY = -CGFLOAT_MAX;
    
    for (UICollectionViewLayoutAttributes *attr in attributes) {
        if (attr.representedElementCategory != UICollectionElementCategoryCell) continue;
        
        if (attr.frame.origin.y >= currentY + 1) {
            [rows addObject:[NSMutableArray array]];
            currentY = attr.frame.origin.y;
        }
        [rows.lastObject addObject:attr];
    }
    
    for (NSMutableArray<UICollectionViewLayoutAttributes *> *row in rows) {
        [self alignRow:row];
    }
    
    return attributes;
}


- (void)alignRow:(NSMutableArray<UICollectionViewLayoutAttributes *> *)row {
    if (row.count == 0) return;
    
    CGFloat collectionViewWidth = self.collectionView.bounds.size.width - self.sectionInset.left - self.sectionInset.right;
    CGFloat totalWidth = 0;
    
    for (UICollectionViewLayoutAttributes *attr in row) {
        totalWidth += attr.frame.size.width;
    }
    totalWidth += (row.count - 1) * self.minimumInteritemSpacing;
    
    CGFloat offset = 0;
    ZLTagAlignment effectiveAlignment = self.alignment;
    switch (effectiveAlignment) {
        case ZLTagAlignmentStart:
            offset = 0;
            break;
        case ZLTagAlignmentCenter:
            offset = (collectionViewWidth - totalWidth) / 2.0;
            break;
        case ZLTagAlignmentEnd:
            offset = collectionViewWidth - totalWidth;
            break;
    }
    
//    if (self.isRTL) {
//        // RTL: 从右向左排列
//        CGFloat currentX = self.collectionView.bounds.size.width - self.sectionInset.right - offset;
//        for (UICollectionViewLayoutAttributes *attr in row) {
//            CGRect frame = attr.frame;
//            currentX -= frame.size.width;
//            frame.origin.x = currentX;
//            attr.frame = frame;
//            currentX -= self.minimumInteritemSpacing;
//        }
//    } else {
        // LTR: 从左向右排列
        CGFloat currentX = self.sectionInset.left + offset;
        for (UICollectionViewLayoutAttributes *attr in row) {
            CGRect frame = attr.frame;
            frame.origin.x = currentX;
            attr.frame = frame;
            currentX += frame.size.width + self.minimumInteritemSpacing;
        }
//    }
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}
- (BOOL)flipsHorizontallyInOppositeLayoutDirection {
    return  [UIView userInterfaceLayoutDirectionForSemanticContentAttribute:UIView.appearance.semanticContentAttribute] == UIUserInterfaceLayoutDirectionRightToLeft;
}
@end

@interface ZLTagCell : UICollectionViewCell
@end
@implementation ZLTagCell
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
    _alignment = ZLTagAlignmentStart;
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
    _flowLayout.alignment = _alignment;
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
    
    if (!CGRectEqualToRect(_collectionView.frame, self.bounds)) {
        _collectionView.frame = self.bounds;
        [_flowLayout invalidateLayout];
    }
}

#pragma mark - Setters

- (void)setAlignment:(ZLTagAlignment)alignment {
    _alignment = alignment;
    _flowLayout.alignment = alignment;
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
    CGFloat width = 0;
    if (_maxWidth > 0) {
        width = _maxWidth;
    }else if (_minWidth > 0) {
        width = _minWidth;
    }else if (self.bounds.size.width > 0) {
        width = self.bounds.size.width;
    }
    return [self calculateContentSizeWithWidth:width];
}

- (CGSize)calculateContentSizeWithWidth:(CGFloat)width {
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
        [view invalidateIntrinsicContentSize];
        if (![cell.contentView.subviews.firstObject isEqual:view]) {
            [cell.contentView.subviews.firstObject removeFromSuperview];
            [cell.contentView addSubview:view];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            [view.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor].active = YES;
            [view.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor].active = YES;
            [view.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor].active = YES;
            [view.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor].active = YES;
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
    CGSize size = view ? [view systemLayoutSizeFittingSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) withHorizontalFittingPriority:UILayoutPriorityFittingSizeLevel verticalFittingPriority:UILayoutPriorityFittingSizeLevel] : CGSizeZero;
    cachedSize = [NSValue valueWithCGSize:size];
    if (cachedSize) self.sizeCache[@(index)] = cachedSize;
    return size;
}


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
