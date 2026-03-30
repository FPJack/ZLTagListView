#import "ZLTagListView.h"


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
    switch (self.alignment) {
        case ZLTagAlignmentLeft:
            offset = 0;
            break;
        case ZLTagAlignmentCenter:
            offset = (collectionViewWidth - totalWidth) / 2.0;
            break;
        case ZLTagAlignmentRight:
            offset = collectionViewWidth - totalWidth;
            break;
    }
    
    CGFloat currentX = self.sectionInset.left + offset;
    for (UICollectionViewLayoutAttributes *attr in row) {
        CGRect frame = attr.frame;
        frame.origin.x = currentX;
        attr.frame = frame;
        currentX += frame.size.width + self.minimumInteritemSpacing;
    }
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

@end


@interface ZLTagListView () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) ZLTagFlowLayout *flowLayout;

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
    _alignment = ZLTagAlignmentLeft;
    _lineSpacing = 10;
    _itemSpacing = 10;
    _contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
    _horizontalScroll = NO;
    _maxWidth = CGFLOAT_MAX;
    _maxHeight = CGFLOAT_MAX;
    _minWidth = 0;
    _minHeight = 0;
}

- (void)setupCollectionView {
    _flowLayout = [[ZLTagFlowLayout alloc] init];
    _flowLayout.alignment = _alignment;
    _flowLayout.minimumLineSpacing = _lineSpacing;
    _flowLayout.minimumInteritemSpacing = _itemSpacing;
    _flowLayout.sectionInset = _contentInset;
    _flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:_flowLayout];
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.showsVerticalScrollIndicator = NO;
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if (@available(iOS 11.0, *)) {
        _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
    }
    [self addSubview:_collectionView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
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

#pragma mark - Public Methods

- (void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier {
    [_collectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
}

- (void)registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier {
    [_collectionView registerNib:nib forCellWithReuseIdentifier:identifier];
}

- (__kindof UICollectionViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    return [_collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
}

- (CGFloat)calculateContentHeight {
    return [self calculateContentHeightWithWidth:self.bounds.size.width];
}

- (CGFloat)calculateContentHeightWithWidth:(CGFloat)width {
    CGSize size = [self calculateContentSizeWithWidth:width];
    return _horizontalScroll ? size.width : size.height;
}

- (CGSize)calculateContentSize {
    CGFloat width = self.bounds.size.width > 0 ? self.bounds.size.width : _maxWidth;
    return [self calculateContentSizeWithWidth:width];
}
- (CGSize)calculateContentSizeWithWidth:(CGFloat)width {
    if (!_dataSource) return CGSizeMake(_minWidth, _minHeight);

    NSInteger count = [_dataSource numberOfTagsInTagListView:self];
    if (count == 0) {
        CGFloat emptyWidth = _contentInset.left + _contentInset.right;
        CGFloat emptyHeight = _contentInset.top + _contentInset.bottom;
        // 应用最小最大限制
        emptyWidth = MAX(_minWidth, MIN(emptyWidth, _maxWidth));
        emptyHeight = MAX(_minHeight, MIN(emptyHeight, _maxHeight));
        return CGSizeMake(emptyWidth, emptyHeight);
    }

    // 计算可用宽度（受maxWidth限制）
    CGFloat availableWidth = width;
    if (_maxWidth < CGFLOAT_MAX) {
        availableWidth = MIN(width, _maxWidth);
    }
    if (availableWidth <= 0) {
        availableWidth = _maxWidth < CGFLOAT_MAX ? _maxWidth : 300;
    }
    // 可用宽度不能小于最小宽度
    availableWidth = MAX(availableWidth, _minWidth);

    if (_horizontalScroll) {
        // 水平滚动时计算总宽度和高度
        CGFloat totalWidth = _contentInset.left;
        CGFloat maxItemHeight = 0;

        for (NSInteger i = 0; i < count; i++) {
            CGSize size = [_dataSource tagListView:self sizeForTagAtIndex:i];
            totalWidth += size.width;
            if (i < count - 1) {
                totalWidth += _itemSpacing;
            }
            maxItemHeight = MAX(maxItemHeight, size.height);
        }
        totalWidth += _contentInset.right;

        CGFloat contentHeight = maxItemHeight + _contentInset.top + _contentInset.bottom;

        // 应用最小最大宽高限制
        CGFloat finalWidth = MAX(_minWidth, MIN(totalWidth, _maxWidth));
        CGFloat finalHeight = MAX(_minHeight, MIN(contentHeight, _maxHeight));

        return CGSizeMake(finalWidth, finalHeight);
    } else {
        // 垂直滚动时计算总高度和宽度
        CGFloat contentWidth = availableWidth - _contentInset.left - _contentInset.right;
        CGFloat currentX = 0;
        CGFloat currentY = _contentInset.top;
        CGFloat lineHeight = 0;
        CGFloat maxLineWidth = 0;
        CGFloat currentLineWidth = 0;

        for (NSInteger i = 0; i < count; i++) {
            CGSize size = [_dataSource tagListView:self sizeForTagAtIndex:i];

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

        // 应用最小最大宽高限制
        CGFloat finalWidth = MAX(_minWidth, MIN(totalWidth, _maxWidth));
        CGFloat finalHeight = MAX(_minHeight, MIN(totalHeight, _maxHeight));

        finalWidth = MIN(finalWidth, availableWidth);

        return CGSizeMake(finalWidth, finalHeight);
    }
}

- (CGSize)intrinsicContentSize {
    return [self calculateContentSize];
}

- (void)reloadData {
    [_collectionView reloadData];
    [self invalidateIntrinsicContentSize];
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

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_dataSource && [_dataSource respondsToSelector:@selector(tagListView:cellForTagAtIndex:)]) {
        return [_dataSource tagListView:self cellForTagAtIndex:indexPath.item];
    }
    return [[UICollectionViewCell alloc] init];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_dataSource && [_dataSource respondsToSelector:@selector(tagListView:sizeForTagAtIndex:)]) {
        return [_dataSource tagListView:self sizeForTagAtIndex:indexPath.item];
    }
    return CGSizeMake(50, 30);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_delegate && [_delegate respondsToSelector:@selector(tagListView:didSelectTagAtIndex:)]) {
        [_delegate tagListView:self didSelectTagAtIndex:indexPath.item];
    }
}
@end
