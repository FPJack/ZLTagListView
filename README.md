# ZLTagListView

`ZLTagListView` 是一个基于 `UICollectionView` 的轻量级标签列表视图组件。支持自动换行、多种对齐方式、RTL 布局、自定义标签视图，以及通过 Auto Layout 自动撑开父视图（如 `UIStackView`）。

## ✨ 功能特性

- ✅ 基于 `UICollectionView`，高效复用
- ✅ 标签尺寸自动估算（通过 `systemLayoutSizeFittingSize` 自动计算，无需外部传入 size）
- ✅ 支持左对齐（`Start`）、居中对齐（`Center`）、右对齐（`End`）
- ✅ 支持垂直换行布局 & 水平滚动模式
- ✅ 支持自定义标签视图（返回任意 `UIView`）
- ✅ 支持设置最大/最小宽高，内容在范围内自适应
- ✅ 支持 `intrinsicContentSize`，可在 `UIStackView` / Auto Layout 中自动撑开
- ✅ 支持 RTL（阿拉伯语等从右到左布局），可自动检测或强制开启
- ✅ 提供 `ZLBlockTagListView` 子类，支持 Block 回调方式

## 📦 安装

### CocoaPods

```ruby
pod 'ZLTagListView'
```

## 系统要求

- iOS 10.0+

## 🚀 快速开始

### 导入头文件

```objc
#import <ZLTagListView/ZLTagListView.h>
```

---

### 方式一：Delegate 方式

#### 1. 遵循协议

```objc
@interface ViewController () <ZLTagListViewDataSource>
@property (nonatomic, strong) ZLTagListView *tagListView;
@property (nonatomic, copy) NSArray<NSString *> *tags;
@end
```

#### 2. 创建并配置

```objc
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tags = @[@"Swift", @"Objective-C", @"UIKit", @"SwiftUI", @"iOS开发"];
    
    ZLTagListView *tagListView = [[ZLTagListView alloc] initWithFrame:CGRectZero];
    tagListView.alignment = ZLTagAlignmentStart; // 左对齐
    tagListView.maxWidth = 300;
    tagListView.lineSpacing = 10;
    tagListView.itemSpacing = 10;
    tagListView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
    tagListView.dataSource = self;
    [self.view addSubview:tagListView];
    
    // 支持 Auto Layout，可直接放入 UIStackView 自动撑开
    tagListView.translatesAutoresizingMaskIntoConstraints = NO;
}
```

#### 3. 实现数据源

```objc
- (NSInteger)numberOfTagsInTagListView:(ZLTagListView *)tagListView {
    return self.tags.count;
}

- (UIView *)tagListView:(ZLTagListView *)tagListView
            dequeueView:(__kindof UIView *)view
          forTagAtIndex:(NSInteger)index {
    UILabel *label = view;
    if (!label) {
        label = [UILabel new];
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor systemBlueColor];
        label.textColor = [UIColor whiteColor];
        label.layer.cornerRadius = 4;
        label.clipsToBounds = YES;
    }
    label.text = self.tags[index];
    return label;
}
```

> **说明**：`dequeueView:` 的 `view` 参数是之前缓存的视图实例，如果为 `nil` 则需要创建新视图。标签尺寸会通过 Auto Layout 自动计算，无需手动返回 size。

#### 4. 可选回调

```objc
// 标签点击
- (void)tagListView:(ZLTagListView *)tagListView didSelectTagAtIndex:(NSInteger)index {
    NSLog(@"选中: %@", self.tags[index]);
}

// 内容高度变化
- (void)tagListView:(ZLTagListView *)tagListView didUpdateContentHeight:(CGFloat)height {
    NSLog(@"高度更新: %.2f", height);
}

// 内容宽度变化
- (void)tagListView:(ZLTagListView *)tagListView didUpdateContentWidth:(CGFloat)width {
    NSLog(@"宽度更新: %.2f", width);
}
```

---

### 方式二：Block 方式（推荐简单场景）

使用 `ZLBlockTagListView` 子类，无需遵循协议，通过 Block 直接配置：

```objc
ZLBlockTagListView *tagListView = [[ZLBlockTagListView alloc]
    initWithFrame:CGRectZero
    numberOfTags:^NSInteger(ZLBlockTagListView *tagListView) {
        return self.tags.count;
    }
    dequeueView:^UIView *(ZLBlockTagListView *tagListView, UIView *view, NSInteger index) {
        UILabel *label = view;
        if (!label) {
            label = [UILabel new];
            label.font = [UIFont systemFontOfSize:14];
            label.backgroundColor = [UIColor systemBlueColor];
            label.textColor = [UIColor whiteColor];
        }
        label.text = self.tags[index];
        return label;
    }];

tagListView.maxWidth = 350;
tagListView.alignment = ZLTagAlignmentCenter;

// 点击回调
tagListView.didSelectTag = ^(ZLBlockTagListView *tagListView, NSInteger index) {
    NSLog(@"选中: %@", self.tags[index]);
    [tagListView reloadData];
};

// 高度变化回调
tagListView.didUpdateContentHeight = ^(ZLBlockTagListView *tagListView, CGFloat height) {
    NSLog(@"高度: %.2f", height);
};

[self.view addSubview:tagListView];
```

---

## 📐 布局与尺寸

### 自动布局（推荐）

`ZLTagListView` 实现了 `intrinsicContentSize`，可直接用于 Auto Layout 和 `UIStackView`：

```objc
tagListView.translatesAutoresizingMaskIntoConstraints = NO;

UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[tagListView]];
stackView.axis = UILayoutConstraintAxisVertical;
stackView.translatesAutoresizingMaskIntoConstraints = NO;
[self.view addSubview:stackView];
```

### 手动计算尺寸

```objc
// 根据当前配置计算内容尺寸
CGSize size = [tagListView calculateContentSize];

// 指定宽度计算
CGSize size = [tagListView calculateContentSizeWithWidth:320];

// 直接调整 frame
[tagListView sizeToFit];
```

---

## 📋 属性一览

| 属性 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `dataSource` | `id<ZLTagListViewDataSource>` | `nil` | 数据源代理 |
| `alignment` | `ZLTagAlignment` | `ZLTagAlignmentStart` | 对齐方式：`Start` / `Center` / `End` |
| `lineSpacing` | `CGFloat` | `10` | 行间距 |
| `itemSpacing` | `CGFloat` | `10` | 标签横向间距 |
| `contentInset` | `UIEdgeInsets` | `(10,10,10,10)` | 内边距 |
| `horizontalScroll` | `BOOL` | `NO` | 是否水平滚动模式 |
| `maxWidth` | `CGFloat` | `CGFLOAT_MAX` | 最大宽度 |
| `maxHeight` | `CGFloat` | `CGFLOAT_MAX` | 最大高度 |
| `minWidth` | `CGFloat` | `0` | 最小宽度 |
| `minHeight` | `CGFloat` | `0` | 最小高度 |
| `forceRTL` | `BOOL` | `NO` | 强制启用 RTL 布局 |
| `autoDetectRTL` | `BOOL` | `YES` | 自动检测系统 RTL 方向 |

---

## 🔄 RTL 支持

组件默认自动检测系统语言方向。对于阿拉伯语等 RTL 语言环境，标签会自动从右到左排列。

```objc
// 强制开启 RTL
tagListView.forceRTL = YES;

// 关闭自动检测，手动控制
tagListView.autoDetectRTL = NO;
```

---

## 🔁 刷新数据

数据源更新后调用：

```objc
[tagListView reloadData];
```

会自动清除尺寸缓存、刷新 `UICollectionView`，并更新 `intrinsicContentSize`。

---

## 🧩 协议方法

### ZLTagListViewDataSource

| 方法 | 必选 | 说明 |
| --- | --- | --- |
| `numberOfTagsInTagListView:` | ✅ | 返回标签总数 |
| `tagListView:dequeueView:forTagAtIndex:` | ✅ | 返回标签视图（支持复用） |
| `tagListView:didSelectTagAtIndex:` | ❌ | 标签点击回调 |
| `tagListView:didUpdateContentHeight:` | ❌ | 内容高度变化回调 |
| `tagListView:didUpdateContentWidth:` | ❌ | 内容宽度变化回调 |

---

## 📂 示例工程

```bash
cd Example
pod install
open ZLTagListView.xcworkspace
```

## License

MIT License
