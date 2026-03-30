# ZLTagListView

`ZLTagListView` 是一个基于 `UICollectionView` 封装的标签列表视图，适合用来展示技能标签、兴趣标签、搜索历史、分类项等内容。它支持自动换行、左中右对齐、动态计算内容尺寸，也可以直接配合 `Auto Layout` 使用。

## 功能特性

- 基于 `UICollectionView`，复用能力完整，适合展示大量标签
- 支持标签左对齐、居中对齐、右对齐
- 支持垂直换行布局，也支持水平滚动展示
- 支持自定义 `UICollectionViewCell`
- 支持通过代理返回每个标签的尺寸
- 支持 `sizeToFit`、`intrinsicContentSize` 和手动计算内容尺寸
- 支持设置最大/最小宽高、行间距、列间距和内边距

## 适用场景

- 商品属性标签
- 用户兴趣或技能标签
- 搜索历史
- 筛选条件面板
- 动态内容标签墙

## 安装

### CocoaPods

```ruby
pod 'ZLTagListView'
```

## 系统要求

- iOS 10.0+

## 快速开始

### 1. 导入头文件

```objc
#import <ZLTagListView/ZLTagListView.h>
```

### 2. 遵循协议

```objc
@interface ViewController () <ZLTagListViewDelegate, ZLTagListViewDataSource>
@property (nonatomic, strong) ZLTagListView *tagListView;
@property (nonatomic, copy) NSArray<NSString *> *tags;
@end
```

### 3. 创建并配置标签视图

```objc
- (void)viewDidLoad {
    [super viewDidLoad];

    self.tags = @[@"Swift", @"Objective-C", @"UIKit", @"SwiftUI"];

    self.tagListView = [[ZLTagListView alloc] initWithFrame:CGRectZero];
    self.tagListView.alignment = ZLTagAlignmentCenter;
    self.tagListView.maxWidth = 300;
    self.tagListView.lineSpacing = 10;
    self.tagListView.itemSpacing = 10;
    self.tagListView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
    self.tagListView.delegate = self;
    self.tagListView.dataSource = self;

    [self.tagListView registerClass:[MyTagCell class] forCellWithReuseIdentifier:@"MyTagCell"];
    [self.view addSubview:self.tagListView];

    [self.tagListView sizeToFit];
    self.tagListView.frame = CGRectMake(20, 100, self.tagListView.frame.size.width, self.tagListView.frame.size.height);
}
```

### 4. 实现数据源方法

```objc
- (NSInteger)numberOfTagsInTagListView:(ZLTagListView *)tagListView {
    return self.tags.count;
}

- (UICollectionViewCell *)tagListView:(ZLTagListView *)tagListView cellForTagAtIndex:(NSInteger)index {
    MyTagCell *cell = [tagListView dequeueReusableCellWithReuseIdentifier:@"MyTagCell" forIndex:index];
    cell.titleLabel.text = self.tags[index];
    return cell;
}

- (CGSize)tagListView:(ZLTagListView *)tagListView sizeForTagAtIndex:(NSInteger)index {
    NSString *tag = self.tags[index];
    CGSize textSize = [tag boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                        options:NSStringDrawingUsesLineFragmentOrigin
                                     attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14]}
                                        context:nil].size;
    return CGSizeMake(ceil(textSize.width) + 24, ceil(textSize.height) + 12);
}
```

### 5. 实现点击回调

```objc
- (void)tagListView:(ZLTagListView *)tagListView didSelectTagAtIndex:(NSInteger)index {
    NSLog(@"选中标签: %@", self.tags[index]);
}
```

## 布局方式

### 自动计算尺寸

`ZLTagListView` 提供了几种常见的尺寸适配方式：

```objc
CGSize size = [tagListView calculateContentSize];
```

```objc
[tagListView sizeToFit];
```

同时它也实现了 `intrinsicContentSize`，可以直接用于 `Auto Layout`。

## 主要属性

| 属性 | 说明 |
| --- | --- |
| `alignment` | 标签对齐方式，支持左、中、右对齐 |
| `lineSpacing` | 行间距 |
| `itemSpacing` | 标签之间的横向间距 |
| `contentInset` | 内容内边距 |
| `horizontalScroll` | 是否启用水平滚动 |
| `maxWidth` / `maxHeight` | 视图允许的最大宽高 |
| `minWidth` / `minHeight` | 视图允许的最小宽高 |
| `collectionView` | 内部的集合视图，只读 |
| `flowLayout` | 内部布局对象，只读 |

## 自定义 Cell

库本身不限制标签样式，你可以注册任意自定义 `UICollectionViewCell`，自行实现：

- 文本标签
- 带圆角背景的胶囊标签
- 带图标的标签
- 可选中/可删除标签

## 刷新数据

当数据源更新后，调用：

```objc
[tagListView reloadData];
```

它会同时刷新内部布局并更新 `intrinsicContentSize`。

## 示例工程

进入 `Example` 目录后执行：

```bash
pod install
```

然后打开生成的 `xcworkspace` 运行示例工程。

## License

`ZLTagListView` 使用 MIT License，详见 `LICENSE`。
