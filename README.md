# miniWordLayout

miniWordLayout 是《迷你世界》UGC 工具的 Lua 布局管理器，用于动态创建和管理 UI 元素，支持视图树、属性设置、任务队列等。

## 功能

- 视图树管理：树状结构组织 UI 元素，支持嵌套、父子关系自动维护。
- 属性设置：文本、纹理、字体大小、颜色、透明度、位置、尺寸等。
- 任务队列：基于 Tick 的事件驱动处理器，分散布局操作到多个帧执行，避免卡顿。
- 布局指令：用表格描述布局结构，递归创建元素，自动处理名称冲突。
- 栈辅助：内置栈数据结构，用于深度优先遍历视图树。

## 快速开始

### 1. 创建处理器

lua
local handler = Layout:buildHandler(cmp, 10)  -- cmp 为拥有 OnTick 事件的组件，10 为每 tick 最大任务数


### 2. 创建布局管理器

lua
local manager = Layout:new(handler, player, "mainUI")


### 3. 定义布局并添加

lua
local layout = {
    { "Button" },
    id = "myBtn",
    Size = { x = 200, y = 50 },
    Position = { x = 100, y = 100, gravity = { x = HorizontalOffset.Left, y = VerticalOffset.Top } },
    Text = "Click me!",
    Color = { r = 255, g = 128, b = 64 }
}
manager:addViewTree(nil, layout, "buttonTree", function(tree)
    print("按钮视图树创建完成")
end)


### 4. 扩展已有视图树

lua
local childLayout = {
    { "Label" },
    id = "descLabel",
    Text = "This is a description",
    Position = { x = 210, y = 110 }
}
manager:extendViewTree("myBtn", childLayout, "buttonTree")


### 5. 操作视图实例

lua
local btn = manager.trees["buttonTree"].myBtn
btn:setAlpha(80)
btn:setText("New Text")
btn:hide()
btn:show()


## API 参考

### Layout 表

| 方法 | 说明 |
|------|------|
| `Layout:buildHandler(cmp, runTaskCountOnTick)` | 构建任务处理器 |
| `Layout:new(handler, player, UI)` | 创建布局管理器 |
| `Layout:buildViewManger(player, UI, id, form)` | 构建单个视图实例 |

### 布局管理器方法

| 方法 | 说明 |
|------|------|
| `manager:addViewTree(rootView, layout, tag, callback)` | 添加新视图树 |
| `manager:extendViewTree(rootView, layout, tag, callback)` | 扩展已有视图树 |
| `manager.trees[tag]` | 获取指定标签的视图树 |

### 视图实例方法

| 方法 | 说明 |
|------|------|
| `view:setText(text)` | 设置文本 |
| `view:setSrc(src)` | 设置纹理路径 |
| `view:setTextSize(size)` | 设置字体大小 |
| `view:setColor(color)` | 设置颜色（RGB） |
| `view:setAlpha(alpha)` | 设置透明度（0-100） |
| `view:setSize(w, h)` | 设置尺寸（支持像素/百分比） |
| `view:setPosition(x, y)` | 设置位置（支持像素/百分比） |
| `view:hide()` | 隐藏元素 |
| `view:show()` | 显示元素 |

### 布局描述格式

布局是一个表格，结构如下：

lua
{
    { "ElementType" },          -- 第一个元素指定 UI 类型（如 "Button", "Label"）
    id = "customId",            -- 可选，自定义标识符
    Size = { x = 100, y = 50 },
    Position = { x = 0, y = 0, gravity = { x = ..., y = ... } },
    Text = "Hello",
    Src = "path/to/image",
    TextSize = 14,
    Color = { r = 255, g = 255, b = 255 },
    -- 子元素（数字索引）
    { "Label" },
    ...
}


## 依赖

- 《迷你世界》UGC 环境（提供 `CustomUI`、`PixelUnits`、`HorizontalOffset`、`VerticalOffset` 等全局 API）。
- 无其他外部依赖。

## 许可

MIT License
