# ZLTagListView

`ZLTagListView` 是一个基于 `UICollectionView` 的轻量级标签流式布局组件。支持自动换行、多维度对齐（行内水平 / 行内垂直 / 内容整体垂直）、RTL 布局、自定义标签视图，以及通过 `intrinsicContentSize` 在 Auto Layout / `UIStackView` 中自动撑开。

---

## ✨ 功能特性

- ✅ 基于 `UICollectionView`，标签视图可复用
- ✅ 标签尺寸自动估算（内部通过 Auto Layout 计算，**无需外部传入 size**）
- ✅ 自动换行的流式布局
- ✅ **三种对齐维度**：
  - 行内水平对齐：`Start` / `Center` / `End`
  - 行内垂直对齐：`Top` / `Center` / `Bottom`（同一行内不同高度标签的对齐）
  - 内容整体垂直对齐：`Top` / `Center` / `Bottom`（容器高度大于内容高度时生效）
- ✅ 支持垂直换行布局 & 水平滚动模式
- ✅ 支持自定义标签视图（返回任意 `UIView`）
- ✅ 支持为每个标签单独设置外边距（`margin`）
- ✅ 支持设置最大 / 最小宽高，内容在范围内自适应
- ✅ 实现 `intrinsicContentSize`，可在 `UIStackView` / Auto Layout 中自动撑开
- ✅ 支持 RTL（阿拉伯语等从右到左布局），可自动检测或强制开启
- ✅ 提供 `ZLBlockTagListView` 子类，支持 Block 回调方式
- ✅ 提供 `ZLViewTagListView` 子类，直接以 `UIView` 增删标签（`addView:` / `removeView:` / `removeAllViews`），无需实现数据源
- ✅ 提供内容尺寸预计算与同步刷新 API

---

## 📦 安装

### CocoaPods

```ruby
pod 'ZLTagListView'
```

执行安装：

```bash
pod install
```

### 系统要求

- iOS 10.0+

---

## 🚀 快速开始

### 导入头文件

```objc
#import <ZLTagListView/ZLTagListView.h>
```

---

## 方式一：Delegate（数据源代理）

适合复杂场景、需要复用逻辑或有多个回调时使用。

### 1. 遵循协议

```objc
@interface ViewController () <ZLTagListViewDataSource>
@property (nonatomic, strong) ZLTagListView *tagListView;
@property (nonatomic, copy) NSArray<NSString *> *tags;
@end
```

### 2. 创建并配置

```objc
- (void)viewDidLoad {
    [super viewDidLoad];

    self.tags = @[@"Swift", @"Objective-C", @"UIKit", @"SwiftUI", @"iOS 开发"];

    ZLTagListView *tagListView = [[ZLTagListView alloc] initWithFrame:CGRectZero];
    tagListView.dataSource               = self;
    tagListView.rowHorizontalAlignment   = ZLTagRowHorizontalAlignmentStart;   // 行内左对齐
    tagListView.rowVerticalAlignment     = ZLTagRowVerticalAlignmentCenter;    // 行内垂直居中
    tagListView.contentVerticalAlignment = ZLTagContentVerticalAlignmentTop;   // 内容整体贴顶
    tagListView.lineSpacing              = 10;   // 行间距
    tagListView.itemSpacing              = 10;   // 列间距
    tagListView.contentInset             = UIEdgeInsetsMake(10, 10, 10, 10);
    tagListView.maxWidth                 = 320;   // 超过则换行

    // 支持 Auto Layout，可直接放入 UIStackView 自动撑开
    tagListView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:tagListView];

    self.tagListView = tagListView;
}
```

### 3. 实现数据源（必选）

```objc
- (NSInteger)numberOfTagsInTagListView:(ZLTagListView *)tagListView {
    return self.tags.count;
}

- (UIView *)tagListView:(ZLTagListView *)tagListView
            dequeueView:(__kindof UIView * _Nullable)view
          forTagAtIndex:(NSInteger)index {
    // view 是可复用的缓存视图，为 nil 时创建新视图
    UILabel *label = (UILabel *)view;
    if (![label isKindOfClass:[UILabel class]]) {
        label = [UILabel new];
        label.font            = [UIFont systemFontOfSize:14];
        label.textAlignment   = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor systemBlueColor];
        label.textColor       = [UIColor whiteColor];
        label.layer.cornerRadius = 6;
        label.clipsToBounds   = YES;
    }
    label.text = self.tags[index];
    return label;
}
```

> **说明**：`dequeueView:` 的 `view` 参数是之前缓存的视图实例，如果为 `nil` 则需要创建新视图。标签尺寸会由组件内部通过 Auto Layout 自动计算，**无需手动返回 size**。为保证尺寸估算正确，请确保返回的视图能够根据内容（如文本、字体）计算出 `intrinsicContentSize`。

### 4. 可选回调

```objc
// 标签点击
- (void)tagListView:(ZLTagListView *)tagListView didSelectTagAtIndex:(NSInteger)index {
    NSLog(@"选中: %@", self.tags[index]);
}

// 为指定标签设置外边距（标签四周的透明间隙）
- (UIEdgeInsets)tagListView:(ZLTagListView *)tagListView marginForTagAtIndex:(NSInteger)index {
    return UIEdgeInsetsMake(4, 4, 4, 4);
}

// 内容高度变化（换行、数据变化后触发）
- (void)tagListView:(ZLTagListView *)tagListView didUpdateContentHeight:(CGFloat)height {
    NSLog(@"高度更新: %.2f", height);
}

// 内容宽度变化
- (void)tagListView:(ZLTagListView *)tagListView didUpdateContentWidth:(CGFloat)width {
    NSLog(@"宽度更新: %.2f", width);
}
```

---

## 方式二：Block（推荐简单场景）

使用 `ZLBlockTagListView` 子类，无需遵循协议，通过 Block 直接配置：

```objc
ZLBlockTagListView *tagListView = [[ZLBlockTagListView alloc]
    initWithFrame:CGRectZero
    numberOfTags:^NSInteger(ZLBlockTagListView *tagListView) {
        return self.tags.count;
    }
    dequeueView:^UIView *(ZLBlockTagListView *tagListView, UIView *view, NSInteger index) {
        UILabel *label = (UILabel *)view;
        if (![label isKindOfClass:[UILabel class]]) {
            label = [UILabel new];
            label.font            = [UIFont systemFontOfSize:14];
            label.textAlignment   = NSTextAlignmentCenter;
            label.backgroundColor = [UIColor systemBlueColor];
            label.textColor       = [UIColor whiteColor];
            label.layer.cornerRadius = 6;
            label.clipsToBounds   = YES;
        }
        label.text = self.tags[index];
        return label;
    }];

tagListView.maxWidth               = 350;
tagListView.rowHorizontalAlignment = ZLTagRowHorizontalAlignmentCenter;

// 点击回调
tagListView.didSelectTag = ^(ZLBlockTagListView *tagListView, NSInteger index) {
    NSLog(@"选中第 %ld 个", (long)index);
    [tagListView reloadData];
};

// 高度变化回调
tagListView.didUpdateContentHeight = ^(ZLBlockTagListView *tagListView, CGFloat height) {
    NSLog(@"高度: %.2f", height);
};

// 宽度变化回调
tagListView.didUpdateContentWidth = ^(ZLBlockTagListView *tagListView, CGFloat width) {
    NSLog(@"宽度: %.2f", width);
};

tagListView.translatesAutoresizingMaskIntoConstraints = NO;
[self.view addSubview:tagListView];
```

---

## 方式三：ZLViewTagListView（直接以 UIView 管理标签）

`ZLViewTagListView` 是内置子类，**无需实现数据源**，直接通过 `addView:` / `removeView:` / `removeAllViews` 等方法增删标签，内部会自动刷新布局。适合标签数量动态变化、每个标签就是一个现成 `UIView` 的场景。

### 1. 创建与添加

```objc
ZLViewTagListView *tagListView = [[ZLViewTagListView alloc] initWithFrame:CGRectZero];
tagListView.rowHorizontalAlignment = ZLTagRowHorizontalAlignmentStart;
tagListView.lineSpacing  = 10;
tagListView.itemSpacing  = 10;
tagListView.contentInset = UIEdgeInsetsMake(12, 12, 12, 12);
tagListView.autoReload   = YES;   // 标签视图尺寸变化时自动刷新
tagListView.translatesAutoresizingMaskIntoConstraints = NO;
[self.view addSubview:tagListView];

// 逐个添加
for (NSString *title in @[@"Swift", @"Objective-C", @"iOS", @"UIKit"]) {
    UILabel *label = [UILabel new];
    label.text = title;
    label.textColor = UIColor.whiteColor;
    label.backgroundColor = UIColor.systemBlueColor;
    label.layer.cornerRadius = 6;
    label.layer.masksToBounds = YES;
    [tagListView addView:label];
}
```

### 2. 增删标签

```objc
// 追加单个标签
[tagListView addView:label];

// 追加标签并指定外边距
[tagListView addView:label margin:UIEdgeInsetsMake(5, 5, 5, 5)];

// 批量追加
[tagListView addViews:@[label1, label2, label3]];

// 指定位置插入
[tagListView insertView:label atIndex:0];
[tagListView insertView:label margin:UIEdgeInsetsMake(5, 5, 5, 5) atIndex:0];

// 移除指定视图
[tagListView removeView:label];

// 移除指定位置
[tagListView removeViewAtIndex:tagListView.tagViews.count - 1];

// 清空全部
[tagListView removeAllViews];

// 单独设置某个标签的外边距
[tagListView setMargin:UIEdgeInsetsMake(5, 5, 5, 5) atIndex:0];
```

### 3. 点击回调

```objc
tagListView.didSelectTag = ^(ZLViewTagListView *list, __kindof UIView *view, NSInteger index) {
    NSLog(@"点击第 %ld 个标签", (long)index);
    [list removeView:view];   // 例如：点击即移除
};
```

### 4. 读取当前标签

```objc
NSArray<__kindof UIView *> *views = tagListView.tagViews;   // 只读，当前所有标签视图
NSInteger count = tagListView.tagViews.count;
```

> **提示**：`ZLViewTagListView` 内部已把自身设为数据源，因此**不要**再手动设置 `dataSource`。`ZLTagListView` 的对齐、间距、最大最小宽高、RTL 等能力它全部继承可用。

---

## 📐 布局与尺寸

### 1. 自动布局（推荐）

`ZLTagListView` 实现了 `intrinsicContentSize`，可直接用于 Auto Layout 和 `UIStackView`，会随内容自动撑开：

```objc
tagListView.translatesAutoresizingMaskIntoConstraints = NO;

// 只需固定位置（如 leading / trailing / top），宽高由内容决定
[NSLayoutConstraint activateConstraints:@[
    [tagListView.leadingAnchor  constraintEqualToAnchor:self.view.leadingAnchor  constant:16],
    [tagListView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
    [tagListView.topAnchor      constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
]];
```

放入 `UIStackView`：

```objc
UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[tagListView]];
stackView.axis = UILayoutConstraintAxisVertical;
stackView.translatesAutoresizingMaskIntoConstraints = NO;
[self.view addSubview:stackView];
```

### 2. 最大 / 最小宽高

在给定范围内跟随内容自适应扩展：

```objc
tagListView.maxWidth  = 320;          // 超过则换行
tagListView.maxHeight = 200;          // 超过则可滚动
tagListView.minWidth  = 120;          // 内容不足时也不小于该宽度
tagListView.minHeight = 60;           // 内容不足时也不小于该高度
```

### 3. 手动预计算尺寸

在真正布局前就能拿到内容尺寸（例如用于 `UITableView` 行高计算）：

```objc
// 根据当前配置（含 maxWidth 限制）计算内容尺寸
CGSize size = [tagListView calculateContentSize];

// 指定宽度计算内容尺寸
CGSize size = [tagListView calculateContentSizeWithWidth:320];
```

### 4. 水平滚动模式

```objc
tagListView.horizontalScroll = YES;   // 标签横向排列并支持横向滚动
```

---

## 🔄 RTL（从右到左）支持

组件默认自动检测系统语言方向。对于阿拉伯语、希伯来语等 RTL 环境，标签会自动从右到左排列。

```objc
// 自动检测（默认 YES）：跟随系统语言方向
tagListView.autoDetectRTL = YES;

// 强制开启 RTL，不依赖系统语言
tagListView.forceRTL = YES;

// 关闭自动检测，完全由 forceRTL 控制
tagListView.autoDetectRTL = NO;
tagListView.forceRTL = YES;
```

> RTL 开启后，`rowHorizontalAlignment` 的 `Start` 表示右侧起始、`End` 表示左侧结束。

---

## 🔁 刷新数据

```objc
// 异步刷新：清除尺寸缓存并刷新 UICollectionView，更新 intrinsicContentSize
[tagListView reloadData];

// 同步刷新：调用后立即完成布局并调整自身尺寸
// 适用于刷新后需要立刻读取正确 frame / 内容尺寸的场景
[tagListView syncReloadData];
```

---

## 📋 API 一览

### ZLTagListView 属性

| 属性 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `dataSource` | `id<ZLTagListViewDataSource>` | `nil` | 数据源代理 |
| `rowHorizontalAlignment` | `ZLTagRowHorizontalAlignment` | `Start` | 行内水平对齐 |
| `rowVerticalAlignment` | `ZLTagRowVerticalAlignment` | `Center` | 行内垂直对齐（同行不同高度标签） |
| `contentVerticalAlignment` | `ZLTagContentVerticalAlignment` | `Top` | 内容整体垂直对齐（容器高于内容时生效） |
| `lineSpacing` | `CGFloat` | `10` | 行间距 |
| `itemSpacing` | `CGFloat` | `10` | 列间距 |
| `contentInset` | `UIEdgeInsets` | `(10,10,10,10)` | 内边距 |
| `horizontalScroll` | `BOOL` | `NO` | 是否水平滚动模式 |
| `maxWidth` | `CGFloat` | `CGFLOAT_MAX` | 最大宽度 |
| `maxHeight` | `CGFloat` | `CGFLOAT_MAX` | 最大高度 |
| `minWidth` | `CGFloat` | `0` | 最小宽度 |
| `minHeight` | `CGFloat` | `0` | 最小高度 |
| `forceRTL` | `BOOL` | `NO` | 强制启用 RTL 布局 |
| `autoDetectRTL` | `BOOL` | `YES` | 自动检测系统 RTL 方向 |

### ZLTagListView 方法

| 方法 | 说明 |
| --- | --- |
| `- (CGSize)calculateContentSize` | 按当前配置（含 `maxWidth`）计算内容尺寸 |
| `- (CGSize)calculateContentSizeWithWidth:` | 按指定宽度计算内容尺寸 |
| `- (void)reloadData` | 异步刷新数据 |
| `- (void)syncReloadData` | 同步刷新并立即更新布局与自身尺寸 |

### 枚举

```objc
// 行内水平对齐
typedef NS_ENUM(NSInteger, ZLTagRowHorizontalAlignment) {
    ZLTagRowHorizontalAlignmentStart,   // 起始对齐（默认，RTL 时为右）
    ZLTagRowHorizontalAlignmentCenter,  // 居中对齐
    ZLTagRowHorizontalAlignmentEnd      // 结束对齐
};

// 行内垂直对齐（同一行中不同高度的标签）
typedef NS_ENUM(NSInteger, ZLTagRowVerticalAlignment) {
    ZLTagRowVerticalAlignmentTop,       // 顶部对齐
    ZLTagRowVerticalAlignmentCenter,    // 居中对齐（默认）
    ZLTagRowVerticalAlignmentBottom     // 底部对齐
};

// 内容整体垂直对齐（容器高度大于内容高度时生效，例如设置了 minHeight）
typedef NS_ENUM(NSInteger, ZLTagContentVerticalAlignment) {
    ZLTagContentVerticalAlignmentTop,     // 顶部（默认）
    ZLTagContentVerticalAlignmentCenter,  // 整体居中
    ZLTagContentVerticalAlignmentBottom   // 底部
};
```

### ZLTagListViewDataSource 协议

| 方法 | 必选 | 说明 |
| --- | --- | --- |
| `numberOfTagsInTagListView:` | ✅ | 返回标签总数 |
| `tagListView:dequeueView:forTagAtIndex:` | ✅ | 返回标签视图（支持复用） |
| `tagListView:didSelectTagAtIndex:` | ❌ | 标签点击回调 |
| `tagListView:didUpdateContentHeight:` | ❌ | 内容高度变化回调 |
| `tagListView:didUpdateContentWidth:` | ❌ | 内容宽度变化回调 |

### ZLBlockTagListView 属性

| 属性 | 说明 |
| --- | --- |
| `numberOfTags` | 返回标签总数的 Block |
| `dequeueView` | 返回标签视图的 Block |
| `didSelectTag` | 点击回调 Block |
| `didUpdateContentHeight` | 高度变化回调 Block |
| `didUpdateContentWidth` | 宽度变化回调 Block |

### ZLViewTagListView 属性

| 属性 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `tagViews` | `NSArray<__kindof UIView *>`（只读） | `@[]` | 当前所有标签视图 |
| `autoReload` | `BOOL` | `NO` | 标签视图尺寸变化时是否自动刷新 |
| `didSelectTag` | `void(^)(ZLViewTagListView *, __kindof UIView *, NSInteger)` | `nil` | 标签点击回调 |

### ZLViewTagListView 方法

| 方法 | 说明 |
| --- | --- |
| `- (void)addView:` | 追加一个标签视图 |
| `- (void)addView:margin:` | 追加标签视图并设置外边距 |
| `- (void)addViews:` | 批量追加标签视图 |
| `- (void)insertView:atIndex:` | 在指定位置插入标签视图 |
| `- (void)insertView:margin:atIndex:` | 在指定位置插入标签视图并设置外边距 |
| `- (void)removeView:` | 移除指定标签视图 |
| `- (void)removeViewAtIndex:` | 移除指定位置的标签视图 |
| `- (void)removeAllViews` | 移除所有标签视图 |
| `- (void)setMargin:atIndex:` | 设置指定位置标签视图的外边距 |

> 以上增删方法内部都会自动刷新布局并更新 `intrinsicContentSize`。

---

## 🧪 完整 Demo

下面是一个可运行的完整示例：通过三个 `UISegmentedControl` 分别切换「行内水平对齐」「行内垂直对齐」「内容整体垂直对齐」，并让每个标签使用随机字体大小以凸显垂直对齐效果。

```objc
#import "ViewController.h"
#import <ZLTagListView/ZLTagListView.h>

@interface ViewController () <ZLTagListViewDataSource>
@property (nonatomic, strong) ZLTagListView *tagListView;
@property (nonatomic, copy)   NSArray<NSString *> *tags;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *fontSizes;
@property (nonatomic, strong) UISegmentedControl *hSeg;   // 行内水平对齐
@property (nonatomic, strong) UISegmentedControl *vSeg;   // 行内垂直对齐
@property (nonatomic, strong) UISegmentedControl *cvSeg;  // 内容整体垂直对齐
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.title = @"TagListView Demo";

    self.tags = @[@"Swift", @"Objective-C", @"iOS", @"UIKit",
                  @"SwiftUI", @"CALayer", @"Combine"];

    // 随机字体大小，制造不同高度以体现垂直对齐
    self.fontSizes = [NSMutableArray array];
    for (NSInteger i = 0; i < self.tags.count; i++) {
        [self.fontSizes addObject:@(12 + arc4random_uniform(17))]; // 12 ~ 28
    }

    [self setupControls];
    [self setupTagListView];
}

- (void)setupControls {
    self.hSeg  = [self segWithItems:@[@"Start", @"Center", @"End"]  selected:0 action:@selector(onH)];
    self.vSeg  = [self segWithItems:@[@"Top", @"Center", @"Bottom"] selected:1 action:@selector(onV)];
    self.cvSeg = [self segWithItems:@[@"Top", @"Center", @"Bottom"] selected:0 action:@selector(onCV)];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        [self titleLabel:@"行内水平对齐 rowHorizontalAlignment"],   self.hSeg,
        [self titleLabel:@"行内垂直对齐 rowVerticalAlignment"],      self.vSeg,
        [self titleLabel:@"整体垂直对齐 contentVerticalAlignment"],  self.cvSeg,
    ]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stack];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor      constraintEqualToAnchor:safe.topAnchor      constant:16],
        [stack.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor  constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
    ]];
}

- (void)setupTagListView {
    ZLTagListView *tagListView = [[ZLTagListView alloc] initWithFrame:CGRectZero];
    tagListView.dataSource               = self;
    tagListView.rowHorizontalAlignment   = ZLTagRowHorizontalAlignmentStart;
    tagListView.rowVerticalAlignment     = ZLTagRowVerticalAlignmentCenter;
    tagListView.contentVerticalAlignment = ZLTagContentVerticalAlignmentTop;
    tagListView.lineSpacing  = 10;
    tagListView.itemSpacing  = 10;
    tagListView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
    tagListView.maxWidth     = self.view.bounds.size.width - 32;
    tagListView.minHeight    = 300; // 让容器高于内容，便于观察整体垂直对齐
    tagListView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    tagListView.layer.cornerRadius = 8;
    tagListView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:tagListView];
    self.tagListView = tagListView;

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [tagListView.leadingAnchor  constraintEqualToAnchor:safe.leadingAnchor  constant:16],
        [tagListView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [tagListView.bottomAnchor   constraintEqualToAnchor:safe.bottomAnchor   constant:-16],
    ]];
}

#pragma mark - Actions

- (void)onH  { self.tagListView.rowHorizontalAlignment   = (ZLTagRowHorizontalAlignment)self.hSeg.selectedSegmentIndex; }
- (void)onV  { self.tagListView.rowVerticalAlignment     = (ZLTagRowVerticalAlignment)self.vSeg.selectedSegmentIndex; }
- (void)onCV { self.tagListView.contentVerticalAlignment = (ZLTagContentVerticalAlignment)self.cvSeg.selectedSegmentIndex; }

- (void)randomizeFontSizes {
    for (NSInteger i = 0; i < self.tags.count; i++) {
        self.fontSizes[i] = @(12 + arc4random_uniform(17));
    }
    [self.tagListView reloadData];
}

#pragma mark - ZLTagListViewDataSource

- (NSInteger)numberOfTagsInTagListView:(ZLTagListView *)tagListView {
    return self.tags.count;
}

- (UIView *)tagListView:(ZLTagListView *)tagListView
            dequeueView:(__kindof UIView *)view
          forTagAtIndex:(NSInteger)index {
    UILabel *label = (UILabel *)view;
    if (![label isKindOfClass:[UILabel class]]) {
        label = [UILabel new];
        label.textAlignment = NSTextAlignmentCenter;
        label.layer.cornerRadius = 6;
        label.layer.masksToBounds = YES;
    }
    label.font = [UIFont systemFontOfSize:self.fontSizes[index].floatValue];
    label.text = self.tags[index];
    label.backgroundColor = [UIColor colorWithRed:0.2 green:0.5 blue:0.9 alpha:0.35];
    label.textColor = UIColor.blackColor;
    return label;
}

- (void)tagListView:(ZLTagListView *)tagListView didSelectTagAtIndex:(NSInteger)index {
    NSLog(@"选中: %@", self.tags[index]);
    [self randomizeFontSizes]; // 点击刷新字体大小，观察对齐效果
}

- (void)tagListView:(ZLTagListView *)tagListView didUpdateContentHeight:(CGFloat)height {
    NSLog(@"内容高度更新: %.2f", height);
}

#pragma mark - Helpers

- (UISegmentedControl *)segWithItems:(NSArray *)items selected:(NSInteger)idx action:(SEL)sel {
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:items];
    seg.selectedSegmentIndex = idx;
    [seg addTarget:self action:sel forControlEvents:UIControlEventValueChanged];
    return seg;
}

- (UILabel *)titleLabel:(NSString *)text {
    UILabel *l = [UILabel new];
    l.text = text;
    l.font = [UIFont boldSystemFontOfSize:13];
    l.textColor = UIColor.blackColor;
    return l;
}

@end
```

**演示效果：**

- **行内水平对齐（hSeg）**：切换 `Start / Center / End`，每一行内标签整体水平位置改变。
- **行内垂直对齐（vSeg）**：由于字体大小随机，同一行标签高度不同，切换 `Top / Center / Bottom` 可看到矮标签相对最高标签的对齐变化。
- **整体垂直对齐（cvSeg）**：因设置了 `minHeight=300`，内容不足时容器有空白，切换 `Top / Center / Bottom`，所有标签作为整体贴顶 / 居中 / 贴底。
- **点击标签**：随机刷新字体大小，可反复观察各种组合下的表现。

---

## 📂 运行示例工程

```bash
cd Example
pod install
open ZLTagListView.xcworkspace
```

---

## License

MIT License
