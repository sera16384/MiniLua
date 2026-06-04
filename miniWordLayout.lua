--[[
  miniWordLayout.lua
  Mini World UGC 布局管理器
  提供视图树构建、属性设置、任务队列等功能
]]

-- ========== 栈（Stack）数据结构 ==========
-- Stack data structure
local Stack = {
    __index = Stack 
}

-- 入栈
function Stack:push(data)
    if data ~= nil then
        table.insert(self, data)
    end
end

-- 出栈
function Stack:pop()
    if self:isEmpty() then return nil end  
    local top = self[#self]
    self[#self] = nil
    return top
end

-- 清空栈
function Stack:clear()
    for i = 1, #self do
        self[i] = nil
    end
end

-- 创建新栈
function Stack:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- 查看栈顶元素（不移除）
function Stack:peek()
    if self:isEmpty() then return nil end
    return self[#self]
end

-- 判断栈是否为空
function Stack:isEmpty()
    return #self == 0
end

-- 打印栈内容（调试用）
function Stack:print()
    if self:isEmpty() then return nil end
    local p = "栈["..tostring(self).."]结构如下:\n{\n"
    for k,v in ipairs(self) do
        p = p.."Top[0d"..tostring(k-1).."]:"..tostring(v) .. "\n"
    end
    print(p.."}")
end


-- ========== 布局管理器核心 ==========
-- Core Layout Manager
local Layout = {
    initialise = {},                -- 视图实例的初始化方法表
    layoutMangerInitialise = {},    -- 布局管理器实例的方法表
    handlerInitialise = {},         -- 任务处理器实例的方法表
    viewTreeInitialise = {},        -- 视图树实例的方法表
    property = {                    -- 可设置的属性及其 get/set 方法
        Text = {
            get = function (self)
                return self.text
            end,
            set = function (self,text)
                self.text = text or self.text
                return CustomUI:SetText(self.player,self.UI,self.id, self.text)
            end,
        },
        Src = {
            get = function (self)
                return self.src
            end,
            set = function (self,src)
                self.src = src or self.src
                return CustomUI:SetTexture(self.player,self.UI,self.id, self.src)
            end,
        },
        TextSize = {
            get = function (self)
                return self.textSize
            end,
            set = function (self,textSize)
                self.textSize = textSize or self.textSize
                return CustomUI:SetFontSize(self.player,self.UI,self.id, self.textSize)
            end,
        },
        Color = {
            get = function (self)
                return self.color
            end,
            set = function (self,color)
                self.color = color or self.color
                return CustomUI:SetColor(self.player,self.UI,self.id,self.color)
            end,
        },
        SliderDir = {
            get = function (self)
                return self.sliderDir
            end,
            set = function (self,num)
                self.sliderDir = num or self.sliderDir
                return CustomUI:SetSliderDir(self.player, self.form,self.id, self.sliderDir)
            end
        }
    }
}

-- 将属性方法注入到 initialise 的元表中，使所有视图实例都能调用
Layout.propertyMetaTable = {
    __index = {}
}
for k,v in pairs(Layout.property) do
    for _k,_v in pairs(v) do
        Layout.propertyMetaTable.__index[_k..k] = _v
    end
end
setmetatable(Layout.initialise,Layout.propertyMetaTable)

-- ========== 视图实例的基础方法 ==========
-- Basic methods for each view instance

-- 获取透明度
function Layout.initialise:getAlpha()
    return self.alpha
end

-- 设置透明度
function Layout.initialise:setAlpha(alpha)
    self.alpha = alpha or self.alpha
    return  CustomUI:SetAlpha(self.player,self.UI,self.id, self.alpha)
end

-- 隐藏元素
function Layout.initialise:hide()
    return CustomUI:HideElement(self.player,self.UI,self.id)
end

-- 显示元素
function Layout.initialise:show()
    return CustomUI:ShowElement(self.player,self.UI,self.id)
end

-- 获取尺寸
function Layout.initialise:getSize()
    return self.w,self.h
end

-- 设置尺寸（支持像素和百分比）
function Layout.initialise:setSize(w,h)
    self.w = w or self.w
    self.h = h or self.h
    self.sizeType = {x=(type(w) == "number" and PixelUnits.Value) or PixelUnits.Percentage,
                     y=(type(h) == "number" and PixelUnits.Value) or PixelUnits.Percentage}
    return CustomUI:SetRelationSize(self.player,self.UI,self.id,self.w,self.sizeType.x,self.h,self.sizeType.y)
end

-- 获取位置
function Layout.initialise:getPosition()
    return self.x,self.y
end

-- 设置位置（支持像素和百分比，默认左上角锚点）
function Layout.initialise:setPosition(x,y)
    self.x = x or self.x
    self.y = y or self.y
    if self.gravity == nil then
           self.gravity = {x=HorizontalOffset.Left,y=VerticalOffset.Top}
    end
    self.posType= {x=(type(x) == "number" and PixelUnits.Value) or PixelUnits.Percentage,
                   y=(type(y) == "number" and PixelUnits.Value) or PixelUnits.Percentage}
    return CustomUI:SetRelationPosition(self.player,self.UI,self.id,self.gravity.x,self.x,self.posType.x,self.gravity.y,self.y,self.posType.y)
end

-- ========== 布局指令函数表 ==========
-- Layout instruction functions
Layout.layoutFun = {
    Size = function(arg)
        local manger = arg.manger
        return manger:setSize(arg.data.x,arg.data.y)
    end,
    Position = function(arg)
        local manger = arg.manger
        manger.gravity = arg.data.gravity
        return manger:setPosition(arg.data.x,arg.data.y)
    end,
    id = function(arg)
        return 
    end
}

-- 默认方法生成器：如果 layoutFun 中没有找到对应 key，则自动生成 "set+key" 的调用
setmetatable(Layout.layoutFun,{
    __index = function (table,key)
        return function (arg)
            local manger = arg.manger
            return manger["set"..key](manger,arg.data)
        end
    end
})

-- 视图实例的元表设置
do local meta = {__index = Layout.initialise}
    function Layout:ViewInitialise(manger)
        if manger.alpha == nil then
            manger.alpha = 100
        end
        return setmetatable(manger,meta)
    end
end

-- 构建视图实例（玩家、UI、ID、所属表单）
function Layout:buildViewManger(player,UI,id,form)
    local o = {
        parentLayout = form,
        UI = UI,
        id = id,
        player = player
    }
    Layout:ViewInitialise(o)
    return o
end

-- ========== 任务处理器 ==========
-- Task Handler: 用于延迟执行任务，每 tick 执行指定数量的任务

-- 添加一个任务到队列
function Layout.handlerInitialise:post(_function)
    table.insert(self.task,_function)
end

do local meta = {__index = Layout.handlerInitialise}
    function Layout:buildHandler(cmp,runTaskCountOnTick)
        -- 构建任务处理器，cmp 是组件（通常为 OnTick 事件），runTaskCountOnTick 是每 tick 最多执行的任务数
        local o = {
            task = {},
            runTaskCountOnTick = runTaskCountOnTick,
        }
        local f = cmp.OnTick
        function cmp:OnTick(t)
            if f then
                f(self,t)
            end
            local key,num = {},0
            for k,v in pairs(o.task) do
                if num < o.runTaskCountOnTick then
                    table.insert(key,k)
                    v()
                else
                    break
                end
                num = num + 1
            end
            for k,v in ipairs(key) do
                o.task[v] = nil
            end
        end
        return setmetatable(o,meta)
    end
end

-- ========== 布局管理器 ==========
-- Layout Manager: 管理多个视图树

do local meta = {__index = Layout.layoutMangerInitialise}
    function Layout:new(handler,player,UI)
        local o = {
            viewMap = {},
            player = player,
            UI = UI,
            handler = handler,
            trees = {}
        }
        return setmetatable(o,meta)
    end
end

-- ========== 视图树操作方法 ==========
-- View Tree operations

do local meta = {__index = Layout.viewTreeInitialise}
    local meta2 = {__index = function () return 0 end}

    -- 构建一棵空的视图树（可选择根视图）
    function Layout.layoutMangerInitialise:buildViewTree(rootView)
        local tree = (rootView and {rootView = self:buildViewObject(rootView)}) or {}
        tree.rMap = (rootView and {[rootView] = "rootView"}) or {}
        tree.treeStructMap = {rootView and {id = rootView}}
        tree.treeStruct = {rootView = rootView and tree.treeStructMap}
        tree.nameMap = setmetatable({},meta2)
        return tree
    end

    -- 根据 id 构建视图对象
    function Layout.layoutMangerInitialise:buildViewObject(id)
        return Layout:ViewInitialise({UI = self.UI,player = self.player,id = id})
    end

    -- 添加一棵视图树（根视图、布局信息、标签、回调）
    function Layout.layoutMangerInitialise:addViewTree(rootView,layout,tag,backFunction)
        local viewStack = Stack:new()
        if rootView then viewStack:push(self:buildViewObject(rootView)) end
        local tree = self:buildViewTree(rootView)
        self.trees[tag] = tree
        self:addLayout(layout,viewStack,backFunction and function()
            backFunction(tree)
        end,tree)
    end

    -- 递归添加布局（核心函数）
    function Layout.layoutMangerInitialise:addLayout(layout,stack,backFunction,tree)
        local key = self:checkName(tree,layout.id)
        for k,v in pairs(layout) do
            if k == 1 then
                -- 第一个元素是创建新元素的类型
                self.handler:post(function()
                    local parent = stack:peek() and stack:peek().id
                    local current = CustomUI:CreateElement(self.player, self.UI,v)
                    key = key or current
                    local manger = self:buildViewObject(current)
                    local treeStruct = {id = key}
                    tree.treeStructMap[key] = treeStruct
                    if tree.treeStruct.id == nil then tree.treeStruct = treeStruct end
                    if parent then
                        manger.parentLayout = parent
                        local rid = tree.rMap[parent]
                        local pTreeStruct = tree.treeStructMap[rid]
                        local l = #pTreeStruct+1
                        pTreeStruct[l] = treeStruct
                        treeStruct.index = l
                        CustomUI:ChangeParent(self.player, self.UI, current, parent)
                    end
                    stack:push(manger)
                    tree[key] = manger
                    tree.rMap[current] = key
                end)
            elseif type(k) == "number" then
                -- 数字索引表示子布局，递归处理
                self:addLayout(v,stack,nil,tree)
            else
                -- 其他键为属性设置指令
                self.handler:post(function () Layout.layoutFun[k]({data = v,manger = stack:peek()}) end)
            end
        end
        self.handler:post(function()stack:pop()end)
        if backFunction then 
            self.handler:post(backFunction)
        end
    end

    -- 检查名称是否重复，若重复则自动编号
    function Layout.layoutMangerInitialise:checkName(tree,name)
        if name then
            local map = tree.nameMap
            map[name] = map[name] + 1
            if map[name] == 1 then
                return name
            else
                return name .. map[name]
            end
        end
    end

    -- 扩展已有的视图树（在指定根节点下添加子布局）
    function Layout.layoutMangerInitialise:extendViewTree(rRootView,layout,tag,backFunction)
        local tree = self.trees[tag]
        local stack = Stack:new()
        if rRootView then
            self.handler:post(function ()
                local id = tree.rMap[rRootView] or rRootView
                stack:push(tree[id])
            end)
        end
        self:addLayout(layout,stack,backFunction and function()
            backFunction(tree)
        end,tree)
    end
end
