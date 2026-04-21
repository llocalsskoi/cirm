-- ╔═══════════════════════════════════════════════════════╗
-- ║           N E O N   U I   L I B R A R Y              ║
-- ║     Redesigned from scratch — Cyber / Neon theme     ║
-- ╚═══════════════════════════════════════════════════════╝

local InputService = game:GetService('UserInputService')
local TextService  = game:GetService('TextService')
local CoreGui      = game:GetService('CoreGui')
local Teams        = game:GetService('Teams')
local Players      = game:GetService('Players')
local RunService   = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local HttpService  = game:GetService('HttpService')
local RenderStepped = RunService.RenderStepped
local LocalPlayer  = Players.LocalPlayer
local Mouse        = LocalPlayer:GetMouse()

local ProtectGui   = protectgui or (syn and syn.protect_gui) or (function() end)

-- ─── ScreenGui ──────────────────────────────────────────────────────────────
local ScreenGui = Instance.new('ScreenGui')
ProtectGui(ScreenGui)
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = CoreGui

local Toggles = {}
local Options = {}
getgenv().Toggles = Toggles
getgenv().Options = Options

-- ─── Library core ───────────────────────────────────────────────────────────
local Library = {
    Registry     = {}; RegistryMap = {}; HudRegistry  = {};
    Signals      = {}; DependencyBoxes = {}; OpenedFrames = {};
    ScreenGui    = ScreenGui;

    -- NEW design tokens
    FontColor       = Color3.fromRGB(230, 230, 255);
    MainColor       = Color3.fromRGB(18, 18, 30);
    BackgroundColor = Color3.fromRGB(11, 11, 20);
    AccentColor     = Color3.fromRGB(80, 200, 255);
    SecondAccent    = Color3.fromRGB(180, 80, 255);
    OutlineColor    = Color3.fromRGB(50, 50, 80);
    RiskColor       = Color3.fromRGB(255, 70, 70);
    SuccessColor    = Color3.fromRGB(60, 220, 120);
    WarnColor       = Color3.fromRGB(255, 190, 30);
    Black           = Color3.new(0,0,0);

    Font            = Enum.Font.GothamBold;
    BodyFont        = Enum.Font.Gotham;

    -- NEW feature flags
    RainbowAccent   = false;
    BlurEnabled     = false;
    SoundEnabled    = true;
    AnimationSpeed  = 0.18;

    NotifyOnError   = true;
}

-- ─── Rainbow system ─────────────────────────────────────────────────────────
local RainbowStep, Hue = 0, 0
local RainbowColor = Library.AccentColor

Library:GetService = function(self, name) return game:GetService(name) end

table.insert(Library.Signals, RenderStepped:Connect(function(dt)
    RainbowStep = RainbowStep + dt
    if RainbowStep >= 1/60 then
        RainbowStep = 0
        Hue = (Hue + 1/400) % 1
        Library.CurrentRainbowHue   = Hue
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1)
        if Library.RainbowAccent then
            Library.AccentColor     = Library.CurrentRainbowColor
            Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
            Library:UpdateColorsUsingRegistry()
        end
    end
end))

-- ─── Sound helper ───────────────────────────────────────────────────────────
local function PlaySound(id, vol, pitch)
    if not Library.SoundEnabled then return end
    pcall(function()
        local s = Instance.new('Sound')
        s.SoundId = 'rbxassetid://' .. tostring(id)
        s.Volume  = vol   or 0.4
        s.PlaybackSpeed = pitch or 1
        s.Parent  = ScreenGui
        s:Play()
        game:GetService('Debris'):AddItem(s, 3)
    end)
end

-- ─── Helpers ────────────────────────────────────────────────────────────────
local function GetPlayersString()
    local t = Players:GetPlayers()
    for i,p in ipairs(t) do t[i] = p.Name end
    table.sort(t)
    return t
end

local function GetTeamsString()
    local t = Teams:GetTeams()
    for i,tm in ipairs(t) do t[i] = tm.Name end
    table.sort(t)
    return t
end

function Library:SafeCallback(f, ...)
    if not f then return end
    if not Library.NotifyOnError then return f(...) end
    local ok, err = pcall(f, ...)
    if not ok then
        local _, i = err:find(':%d+: ')
        Library:Notify(i and err:sub(i+1) or err, 3, 'error')
    end
end

function Library:AttemptSave()
    if Library.SaveManager then Library.SaveManager:Save() end
end

function Library:Create(Class, Props)
    local inst = type(Class)=='string' and Instance.new(Class) or Class
    for k,v in next, Props do inst[k] = v end
    return inst
end

function Library:Tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or Library.AnimationSpeed, Enum.EasingStyle.Quint), props):Play()
end

function Library:ApplyTextStroke(inst)
    inst.TextStrokeTransparency = 1
    Library:Create('UIStroke', {
        Color = Color3.new(0,0,0); Thickness = 1.2;
        LineJoinMode = Enum.LineJoinMode.Miter; Parent = inst;
    })
end

function Library:GetTextBounds(text, font, size, res)
    local b = TextService:GetTextSize(text, size, font, res or Vector2.new(1920,1080))
    return b.X, b.Y
end

function Library:GetDarkerColor(c)
    local h,s,v = Color3.toHSV(c)
    return Color3.fromHSV(h, s, v/1.5)
end
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)

-- ─── Registry ───────────────────────────────────────────────────────────────
function Library:AddToRegistry(inst, props, isHud)
    local d = { Instance=inst, Properties=props, Idx=#Library.Registry+1 }
    table.insert(Library.Registry, d)
    Library.RegistryMap[inst] = d
    if isHud then table.insert(Library.HudRegistry, d) end
end

function Library:RemoveFromRegistry(inst)
    local d = Library.RegistryMap[inst]
    if not d then return end
    for i=#Library.Registry,1,-1 do
        if Library.Registry[i]==d then table.remove(Library.Registry,i) end
    end
    for i=#Library.HudRegistry,1,-1 do
        if Library.HudRegistry[i]==d then table.remove(Library.HudRegistry,i) end
    end
    Library.RegistryMap[inst] = nil
end

function Library:UpdateColorsUsingRegistry()
    for _,obj in next, Library.Registry do
        for prop, idx in next, obj.Properties do
            if type(idx)=='string' then
                obj.Instance[prop] = Library[idx]
            elseif type(idx)=='function' then
                obj.Instance[prop] = idx()
            end
        end
    end
end

function Library:UpdateDependencyBoxes()
    for _,db in next, Library.DependencyBoxes do db:Update() end
end

function Library:GiveSignal(s)
    table.insert(Library.Signals, s)
end

function Library:Unload()
    for i=#Library.Signals,1,-1 do
        table.remove(Library.Signals,i):Disconnect()
    end
    if Library.OnUnload then Library.OnUnload() end
    ScreenGui:Destroy()
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(inst)
    if Library.RegistryMap[inst] then Library:RemoveFromRegistry(inst) end
end))

-- ─── Create label ───────────────────────────────────────────────────────────
function Library:CreateLabel(props, isHud)
    local lbl = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font = Library.BodyFont;
        TextColor3 = Library.FontColor;
        TextSize = 14;
        TextStrokeTransparency = 1;
    })
    Library:ApplyTextStroke(lbl)
    Library:AddToRegistry(lbl, { TextColor3 = 'FontColor' }, isHud)
    return Library:Create(lbl, props)
end

-- ─── Draggable ──────────────────────────────────────────────────────────────
function Library:MakeDraggable(frame, cutoff)
    frame.Active = true
    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local oPos = Vector2.new(Mouse.X - frame.AbsolutePosition.X, Mouse.Y - frame.AbsolutePosition.Y)
        if oPos.Y > (cutoff or 40) then return end
        while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
            frame.Position = UDim2.new(0,
                Mouse.X - oPos.X + frame.Size.X.Offset * frame.AnchorPoint.X, 0,
                Mouse.Y - oPos.Y + frame.Size.Y.Offset * frame.AnchorPoint.Y)
            RenderStepped:Wait()
        end
    end)
end

-- ─── Tooltip ────────────────────────────────────────────────────────────────
function Library:AddToolTip(str, hover)
    local x,y = Library:GetTextBounds(str, Library.BodyFont, 13)
    local tip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        Size = UDim2.fromOffset(x+10, y+6);
        ZIndex = 200; Visible = false; Parent = ScreenGui;
    })
    Library:Create('UICorner', { CornerRadius = UDim.new(0,4); Parent = tip })
    Library:Create('UIStroke', { Color = Library.AccentColor; Thickness = 1; Transparency = 0.5; Parent = tip })
    local lbl = Library:CreateLabel({
        Position = UDim2.fromOffset(5,2); Size = UDim2.fromOffset(x,y);
        TextSize = 13; Text = str; TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 201; Parent = tip;
    })
    Library:AddToRegistry(tip, { BackgroundColor3 = 'MainColor' })
    Library:AddToRegistry(lbl, { TextColor3 = 'FontColor' })
    local hovering = false
    hover.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then return end
        hovering = true
        tip.Position = UDim2.fromOffset(Mouse.X+16, Mouse.Y+14)
        tip.Visible = true
        while hovering do
            RunService.Heartbeat:Wait()
            tip.Position = UDim2.fromOffset(Mouse.X+16, Mouse.Y+14)
        end
    end)
    hover.MouseLeave:Connect(function()
        hovering = false; tip.Visible = false
    end)
end

-- ─── OnHighlight ────────────────────────────────────────────────────────────
function Library:OnHighlight(hInst, inst, enter, leave)
    hInst.MouseEnter:Connect(function()
        local reg = Library.RegistryMap[inst]
        for p,c in next, enter do
            inst[p] = Library[c] or c
            if reg and reg.Properties[p] then reg.Properties[p] = c end
        end
    end)
    hInst.MouseLeave:Connect(function()
        local reg = Library.RegistryMap[inst]
        for p,c in next, leave do
            inst[p] = Library[c] or c
            if reg and reg.Properties[p] then reg.Properties[p] = c end
        end
    end)
end

function Library:MouseIsOverOpenedFrame()
    for frame in next, Library.OpenedFrames do
        local pos, size = frame.AbsolutePosition, frame.AbsoluteSize
        if Mouse.X>=pos.X and Mouse.X<=pos.X+size.X and Mouse.Y>=pos.Y and Mouse.Y<=pos.Y+size.Y then
            return true
        end
    end
end

function Library:IsMouseOverFrame(frame)
    local pos, size = frame.AbsolutePosition, frame.AbsoluteSize
    return Mouse.X>=pos.X and Mouse.X<=pos.X+size.X and Mouse.Y>=pos.Y and Mouse.Y<=pos.Y+size.Y
end

function Library:MapValue(v, minA, maxA, minB, maxB)
    return (1 - (v-minA)/(maxA-minA))*minB + ((v-minA)/(maxA-minA))*maxB
end

-- ══════════════════════════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM (новый — с иконками и типами)
-- ══════════════════════════════════════════════════════════════════════════════
do
    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        AnchorPoint = Vector2.new(1,0);
        Position = UDim2.new(1,-12,0,12);
        Size = UDim2.new(0,300,0,600);
        ZIndex = 500; Parent = ScreenGui;
    })
    Library:Create('UIListLayout', {
        Padding = UDim.new(0,6);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        VerticalAlignment = Enum.VerticalAlignment.Top;
        Parent = Library.NotificationArea;
    })
end

local NotifTypes = {
    info    = { icon = 'ℹ', color = Color3.fromRGB(80,200,255) };
    success = { icon = '✔', color = Color3.fromRGB(60,220,120) };
    warn    = { icon = '⚠', color = Color3.fromRGB(255,190,30) };
    error   = { icon = '✖', color = Color3.fromRGB(255,70,70) };
}

function Library:Notify(text, duration, ntype)
    local t = NotifTypes[ntype] or NotifTypes.info
    local xSize, ySize = Library:GetTextBounds(text, Library.BodyFont, 13)
    ySize = math.max(ySize + 16, 38)
    xSize = math.min(xSize + 50, 280)

    local outer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel = 0;
        Size = UDim2.fromOffset(xSize, ySize);
        ClipsDescendants = true;
        ZIndex = 500; Parent = Library.NotificationArea;
    })
    Library:Create('UICorner',   { CornerRadius = UDim.new(0,6); Parent = outer })
    Library:Create('UIStroke',   { Color = t.color; Thickness = 1; Transparency = 0.3; Parent = outer })
    Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        }); Rotation = -90; Parent = outer;
    })

    -- left accent bar
    Library:Create('Frame', {
        BackgroundColor3 = t.color; BorderSizePixel = 0;
        Size = UDim2.new(0,3,1,0); ZIndex = 501; Parent = outer;
    })

    -- icon
    Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Position = UDim2.fromOffset(8,0);
        Size = UDim2.new(0,20,1,0);
        Text = t.icon; TextColor3 = t.color;
        Font = Library.Font; TextSize = 16;
        ZIndex = 502; Parent = outer;
    })

    -- text
    Library:CreateLabel({
        Position = UDim2.fromOffset(32,0);
        Size = UDim2.new(1,-38,1,0);
        Text = text; TextSize = 13;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextWrapped = true; ZIndex = 502; Parent = outer;
    })

    -- progress bar
    local bar = Library:Create('Frame', {
        BackgroundColor3 = t.color; BorderSizePixel = 0;
        Position = UDim2.new(0,0,1,-2);
        Size = UDim2.new(1,0,0,2);
        ZIndex = 503; Parent = outer;
    })

    -- slide in
    outer.Position = UDim2.fromOffset(xSize+10, 0)
    Library:Tween(outer, { Position = UDim2.fromOffset(0,0) }, 0.25)
    Library:Tween(bar, { Size = UDim2.new(0,0,0,2) }, duration or 4)

    task.delay(duration or 4, function()
        Library:Tween(outer, { Position = UDim2.fromOffset(xSize+30, 0) }, 0.2)
        task.wait(0.22)
        outer:Destroy()
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- WATERMARK (новый стиль)
-- ══════════════════════════════════════════════════════════════════════════════
do
    local wOuter = Library:Create('Frame', {
        BorderSizePixel = 0;
        Position = UDim2.fromOffset(12,12);
        Size = UDim2.fromOffset(200,26);
        ZIndex = 200; Visible = false; Parent = ScreenGui;
    })
    Library:Create('UICorner',   { CornerRadius = UDim.new(0,6); Parent = wOuter })
    Library:Create('UIStroke',   { Color = Library.AccentColor; Thickness = 1; Transparency = 0.4; Parent = wOuter })
    Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library.BackgroundColor),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        }); Rotation = 90; Parent = wOuter;
    })

    local wLabel = Library:CreateLabel({
        Position = UDim2.fromOffset(8,0);
        Size = UDim2.new(1,-8,1,0);
        TextSize = 13; TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 201; Parent = wOuter;
    })

    Library.Watermark    = wOuter
    Library.WatermarkText = wLabel
    Library:MakeDraggable(wOuter, 26)

    Library:AddToRegistry(Library.Watermark, { BackgroundColor3 = 'BackgroundColor' })
    Library:AddToRegistry(wLabel, { TextColor3 = 'FontColor' })
end

function Library:SetWatermarkVisibility(v)
    Library.Watermark.Visible = v
end

function Library:SetWatermark(text)
    local x,y = Library:GetTextBounds(text, Library.BodyFont, 13)
    Library.Watermark.Size = UDim2.fromOffset(x+20, y+10)
    Library.WatermarkText.Text = text
    Library:SetWatermarkVisibility(true)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- KEYBIND FRAME (новый стиль)
-- ══════════════════════════════════════════════════════════════════════════════
do
    local kOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0,0.5);
        BorderSizePixel = 0;
        Position = UDim2.new(0,12,0.5,0);
        Size = UDim2.fromOffset(210,22);
        Visible = false; ZIndex = 100; Parent = ScreenGui;
    })
    Library:Create('UICorner', { CornerRadius = UDim.new(0,6); Parent = kOuter })
    Library:Create('UIStroke', { Color = Library.AccentColor; Thickness = 1; Transparency = 0.5; Parent = kOuter })

    local kInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderSizePixel = 0;
        Size = UDim2.fromScale(1,1);
        ZIndex = 101; Parent = kOuter;
    })
    Library:Create('UICorner', { CornerRadius = UDim.new(0,6); Parent = kInner })
    Library:AddToRegistry(kInner, { BackgroundColor3 = 'MainColor' }, true)

    Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor; BorderSizePixel = 0;
        Size = UDim2.new(1,0,0,2); ZIndex = 102; Parent = kInner;
    })

    Library:CreateLabel({
        Position = UDim2.fromOffset(8,2);
        Size = UDim2.new(1,0,0,18);
        Text = '⌨ Keybinds'; Font = Library.Font;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 103; Parent = kInner;
    })

    local kContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0,0,0,20);
        Size = UDim2.new(1,0,1,-20);
        ZIndex = 1; Parent = kInner;
    })
    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = kContainer;
    })
    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0,8); Parent = kContainer;
    })

    Library.KeybindFrame     = kOuter
    Library.KeybindContainer = kContainer
    Library:MakeDraggable(kOuter)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- BASE ADDONS (ColorPicker + KeyPicker)
-- ══════════════════════════════════════════════════════════════════════════════
local BaseAddons = {}
do
    local Funcs = {}

    -- ── ColorPicker ──────────────────────────────────────────────────────────
    function Funcs:AddColorPicker(idx, info)
        assert(info.Default, 'AddColorPicker: Missing default')
        local ToggleLabel = self.TextLabel

        local CP = {
            Value = info.Default; Transparency = info.Transparency or 0;
            Type = 'ColorPicker'; Title = info.Title or 'Color';
            Callback = info.Callback or function() end;
        }

        function CP:SetHSVFromRGB(c)
            CP.Hue, CP.Sat, CP.Vib = Color3.toHSV(c)
        end
        CP:SetHSVFromRGB(CP.Value)

        -- display swatch
        local swatch = Library:Create('Frame', {
            BackgroundColor3 = CP.Value;
            BorderSizePixel = 0;
            Size = UDim2.fromOffset(30,15);
            ZIndex = 6; Parent = ToggleLabel;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,3); Parent = swatch })
        Library:Create('UIStroke', { Color = Library.OutlineColor; Thickness = 1; Parent = swatch })

        if info.Transparency then
            Library:Create('ImageLabel', {
                BorderSizePixel=0; Size=UDim2.fromOffset(29,14);
                ZIndex=5; Image='http://www.roblox.com/asset/?id=12977615774';
                Parent=swatch;
            })
        end

        -- picker outer
        local pickerOuter = Library:Create('Frame', {
            Name = 'Color';
            BackgroundColor3 = Color3.new(0,0,0);
            BorderSizePixel = 0;
            Position = UDim2.fromOffset(swatch.AbsolutePosition.X, swatch.AbsolutePosition.Y+19);
            Size = UDim2.fromOffset(238, info.Transparency and 278 or 260);
            Visible = false; ZIndex = 20; Parent = ScreenGui;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,6); Parent = pickerOuter })

        swatch:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            pickerOuter.Position = UDim2.fromOffset(swatch.AbsolutePosition.X, swatch.AbsolutePosition.Y+19)
        end)

        local pickerInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderSizePixel = 0;
            Size = UDim2.fromScale(1,1);
            ZIndex = 21; Parent = pickerOuter;
        })
        Library:Create('UICorner',  { CornerRadius = UDim.new(0,6); Parent = pickerInner })
        Library:Create('UIStroke',  { Color = Library.AccentColor; Thickness = 1; Transparency = 0.5; Parent = pickerOuter })

        local titleLbl = Library:CreateLabel({
            Position = UDim2.fromOffset(8,5);
            Size = UDim2.new(1,-8,0,16);
            TextSize = 13; Font = Library.Font;
            Text = CP.Title; TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 22; Parent = pickerInner;
        })

        local topBar = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor; BorderSizePixel = 0;
            Size = UDim2.new(1,0,0,2); ZIndex = 22; Parent = pickerInner;
        })
        Library:AddToRegistry(topBar, { BackgroundColor3 = 'AccentColor' })
        Library:AddToRegistry(pickerInner, { BackgroundColor3 = 'BackgroundColor' })

        -- sat/vib map
        local svOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0,0,0);
            Position = UDim2.fromOffset(6,26);
            Size = UDim2.fromOffset(200,200);
            ZIndex = 22; Parent = pickerInner;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,3); Parent = svOuter })

        local svInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderSizePixel = 0;
            Size = UDim2.fromScale(1,1);
            ZIndex = 23; Parent = svOuter;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,3); Parent = svInner })
        Library:Create('UIStroke', { Color = Library.OutlineColor; Thickness = 1; Parent = svOuter })

        local svMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0; Size = UDim2.fromScale(1,1);
            ZIndex = 23; Image = 'rbxassetid://4155801252'; Parent = svInner;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,3); Parent = svMap })

        local cursor = Library:Create('Frame', {
            AnchorPoint = Vector2.new(0.5,0.5);
            BackgroundColor3 = Color3.new(1,1,1);
            BorderColor3 = Color3.new(0,0,0);
            Size = UDim2.fromOffset(8,8);
            ZIndex = 25; Parent = svMap;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0.5,0); Parent = cursor })
        Library:Create('UIStroke', { Color = Color3.new(0,0,0); Thickness = 1.5; Parent = cursor })

        -- hue bar
        local hueOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0,0,0);
            Position = UDim2.fromOffset(210,26);
            Size = UDim2.fromOffset(18,200);
            ZIndex = 22; Parent = pickerInner;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,3); Parent = hueOuter })
        Library:Create('UIStroke', { Color = Library.OutlineColor; Thickness = 1; Parent = hueOuter })

        local hueInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1,1,1); BorderSizePixel = 0;
            Size = UDim2.fromScale(1,1); ZIndex = 23; Parent = hueOuter;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,3); Parent = hueInner })

        local hueCursor = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1,1,1);
            AnchorPoint = Vector2.new(0,0.5);
            BorderColor3 = Color3.new(0,0,0);
            Size = UDim2.new(1,0,0,3);
            ZIndex = 24; Parent = hueInner;
        })
        Library:Create('UIStroke', { Color = Color3.new(0,0,0); Thickness = 1; Parent = hueCursor })

        -- hue gradient
        local seq = {}
        for h=0,1,0.1 do table.insert(seq, ColorSequenceKeypoint.new(math.min(h,1), Color3.fromHSV(math.min(h,1),1,1))) end
        Library:Create('UIGradient', { Color = ColorSequence.new(seq); Rotation = 90; Parent = hueInner })

        -- hex box
        local hexOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0,0,0);
            Position = UDim2.fromOffset(6,232);
            Size = UDim2.new(0.5,-10,0,22);
            ZIndex = 22; Parent = pickerInner;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,3); Parent = hexOuter })
        Library:Create('UIStroke', { Color = Library.OutlineColor; Thickness = 1; Parent = hexOuter })

        local hexInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor; BorderSizePixel = 0;
            Size = UDim2.fromScale(1,1); ZIndex = 23; Parent = hexOuter;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,3); Parent = hexInner })
        Library:AddToRegistry(hexInner, { BackgroundColor3 = 'MainColor' })

        local hexBox = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.fromOffset(5,0);
            Size = UDim2.new(1,-5,1,0);
            Font = Library.BodyFont; Text = '#FFFFFF';
            TextColor3 = Library.FontColor; TextSize = 13;
            PlaceholderText = 'Hex'; PlaceholderColor3 = Color3.fromRGB(120,120,160);
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 24; Parent = hexInner;
        })
        Library:ApplyTextStroke(hexBox)
        Library:AddToRegistry(hexBox, { TextColor3 = 'FontColor' })

        -- rgb box
        local rgbOuter = Library:Create(hexOuter:Clone(), {
            Position = UDim2.new(0.5,2,0,232);
            Size = UDim2.new(0.5,-8,0,22);
            Parent = pickerInner;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,3); Parent = rgbOuter })

        local rgbInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor; BorderSizePixel = 0;
            Size = UDim2.fromScale(1,1); ZIndex = 23; Parent = rgbOuter;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,3); Parent = rgbInner })
        Library:AddToRegistry(rgbInner, { BackgroundColor3 = 'MainColor' })

        local rgbBox = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.fromOffset(5,0); Size = UDim2.new(1,-5,1,0);
            Font = Library.BodyFont; Text = '255, 255, 255';
            TextColor3 = Library.FontColor; TextSize = 12;
            PlaceholderText = 'R, G, B'; PlaceholderColor3 = Color3.fromRGB(120,120,160);
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 24; Parent = rgbInner;
        })
        Library:ApplyTextStroke(rgbBox)
        Library:AddToRegistry(rgbBox, { TextColor3 = 'FontColor' })

        -- transparency bar
        local transCursor
        if info.Transparency then
            local transOuter = Library:Create('Frame', {
                BorderSizePixel = 0;
                Position = UDim2.fromOffset(6,258);
                Size = UDim2.new(1,-12,0,14);
                ZIndex = 22; Parent = pickerInner;
            })
            Library:Create('UICorner', { CornerRadius = UDim.new(0,3); Parent = transOuter })
            Library:Create('UIStroke', { Color = Library.OutlineColor; Thickness = 1; Parent = transOuter })

            local transInner = Library:Create('Frame', {
                BackgroundColor3 = CP.Value; BorderSizePixel = 0;
                Size = UDim2.fromScale(1,1); ZIndex = 23; Parent = transOuter;
            })
            Library:Create('UICorner', { CornerRadius = UDim.new(0,3); Parent = transInner })
            Library:Create('ImageLabel', {
                BackgroundTransparency = 1; Size = UDim2.fromScale(1,1);
                Image = 'http://www.roblox.com/asset/?id=12978095818';
                ZIndex = 24; Parent = transInner;
            })
            transCursor = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(1,1,1);
                AnchorPoint = Vector2.new(0.5,0);
                BorderSizePixel = 0; Size = UDim2.new(0,3,1,0);
                ZIndex = 25; Parent = transInner;
            })
            Library:Create('UIStroke', { Color = Color3.new(0,0,0); Thickness = 1; Parent = transCursor })

            transInner.InputBegan:Connect(function(inp)
                if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local mnX = transInner.AbsolutePosition.X
                    local mxX = mnX + transInner.AbsoluteSize.X
                    CP.Transparency = 1 - (math.clamp(Mouse.X,mnX,mxX)-mnX)/(mxX-mnX)
                    CP:Display(); RenderStepped:Wait()
                end
                Library:AttemptSave()
            end)
        end

        -- context menu
        local ctx = {}
        ctx.Container = Library:Create('Frame', {
            BorderSizePixel = 0; ZIndex = 50; Visible = false; Parent = ScreenGui;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,5); Parent = ctx.Container })
        Library:Create('UIStroke', { Color = Library.AccentColor; Thickness = 1; Transparency = 0.5; Parent = ctx.Container })

        local ctxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor; BorderSizePixel = 0;
            Size = UDim2.fromScale(1,1); ZIndex = 51; Parent = ctx.Container;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,5); Parent = ctxInner })
        Library:AddToRegistry(ctxInner, { BackgroundColor3 = 'BackgroundColor' })

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ctxInner;
        })
        Library:Create('UIPadding', {
            PaddingLeft = UDim.new(0,6); PaddingTop = UDim.new(0,3); PaddingBottom = UDim.new(0,3);
            Parent = ctxInner;
        })

        local function updateCtxPos()
            ctx.Container.Position = UDim2.fromOffset(
                swatch.AbsolutePosition.X + swatch.AbsoluteSize.X + 5,
                swatch.AbsolutePosition.Y + 1)
        end
        local function updateCtxSize()
            local w = 80
            for _,c in next, ctxInner:GetChildren() do
                if c:IsA('TextLabel') then w = math.max(w, c.TextBounds.X) end
            end
            local layout = ctxInner:FindFirstChildOfClass('UIListLayout')
            ctx.Container.Size = UDim2.fromOffset(w+14, (layout and layout.AbsoluteContentSize.Y or 0)+8)
        end
        swatch:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateCtxPos)
        task.spawn(updateCtxPos); task.spawn(updateCtxSize)

        function ctx:Show() self.Container.Visible = true end
        function ctx:Hide() self.Container.Visible = false end
        function ctx:AddOption(str, cb)
            if type(cb) ~= 'function' then cb = function() end end
            local btn = Library:CreateLabel({
                Active = false; Size = UDim2.new(1,0,0,16);
                TextSize = 13; Text = str;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 52; Parent = ctxInner;
            })
            Library:OnHighlight(btn, btn, { TextColor3 = 'AccentColor' }, { TextColor3 = 'FontColor' })
            btn.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then cb() end
            end)
            task.defer(updateCtxSize)
        end

        ctx:AddOption('Copy color',  function() Library.ColorClipboard = CP.Value; Library:Notify('Color copied!', 2, 'success') end)
        ctx:AddOption('Paste color', function()
            if not Library.ColorClipboard then return Library:Notify('No color copied!', 2, 'warn') end
            CP:SetValueRGB(Library.ColorClipboard)
        end)
        ctx:AddOption('Copy HEX', function()
            pcall(setclipboard, CP.Value:ToHex())
            Library:Notify('HEX copied!', 2, 'success')
        end)
        ctx:AddOption('Copy RGB', function()
            pcall(setclipboard, table.concat({
                math.floor(CP.Value.R*255), math.floor(CP.Value.G*255), math.floor(CP.Value.B*255)
            }, ', '))
            Library:Notify('RGB copied!', 2, 'success')
        end)

        -- Display function
        function CP:Display()
            CP.Value = Color3.fromHSV(CP.Hue, CP.Sat, CP.Vib)
            svMap.BackgroundColor3 = Color3.fromHSV(CP.Hue,1,1)
            swatch.BackgroundColor3 = CP.Value
            swatch.BackgroundTransparency = CP.Transparency
            Library:Create(swatch, { BackgroundColor3 = CP.Value })
            if transCursor then
                transCursor.Parent.BackgroundColor3 = CP.Value
                transCursor.Position = UDim2.new(1-CP.Transparency,0,0,0)
            end
            cursor.Position = UDim2.new(CP.Sat,0,1-CP.Vib,0)
            hueCursor.Position = UDim2.new(0,0,CP.Hue,0)
            hexBox.Text = '#'..CP.Value:ToHex()
            rgbBox.Text = table.concat({
                math.floor(CP.Value.R*255), math.floor(CP.Value.G*255), math.floor(CP.Value.B*255)
            }, ', ')
            Library:SafeCallback(CP.Callback, CP.Value)
            Library:SafeCallback(CP.Changed, CP.Value)
        end

        function CP:OnChanged(f) CP.Changed = f; f(CP.Value) end
        function CP:Show()
            for f in next, Library.OpenedFrames do
                if f.Name == 'Color' then f.Visible = false; Library.OpenedFrames[f] = nil end
            end
            pickerOuter.Visible = true
            Library.OpenedFrames[pickerOuter] = true
        end
        function CP:Hide()
            pickerOuter.Visible = false
            Library.OpenedFrames[pickerOuter] = nil
        end
        function CP:SetValue(hsv, trans)
            CP.Transparency = trans or 0
            CP:SetHSVFromRGB(Color3.fromHSV(hsv[1],hsv[2],hsv[3]))
            CP:Display()
        end
        function CP:SetValueRGB(c, trans)
            CP.Transparency = trans or 0
            CP:SetHSVFromRGB(c)
            CP:Display()
        end

        -- input events
        svMap.InputBegan:Connect(function(inp)
            if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local mnX,mxX = svMap.AbsolutePosition.X, svMap.AbsolutePosition.X+svMap.AbsoluteSize.X
                local mnY,mxY = svMap.AbsolutePosition.Y, svMap.AbsolutePosition.Y+svMap.AbsoluteSize.Y
                CP.Sat = (math.clamp(Mouse.X,mnX,mxX)-mnX)/(mxX-mnX)
                CP.Vib = 1-(math.clamp(Mouse.Y,mnY,mxY)-mnY)/(mxY-mnY)
                CP:Display(); RenderStepped:Wait()
            end
            Library:AttemptSave()
        end)

        hueInner.InputBegan:Connect(function(inp)
            if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local mnY,mxY = hueInner.AbsolutePosition.Y, hueInner.AbsolutePosition.Y+hueInner.AbsoluteSize.Y
                CP.Hue = (math.clamp(Mouse.Y,mnY,mxY)-mnY)/(mxY-mnY)
                CP:Display(); RenderStepped:Wait()
            end
            Library:AttemptSave()
        end)

        hexBox.FocusLost:Connect(function(enter)
            if enter then
                local ok,c = pcall(Color3.fromHex, hexBox.Text)
                if ok and typeof(c)=='Color3' then
                    CP.Hue,CP.Sat,CP.Vib = Color3.toHSV(c)
                end
            end
            CP:Display()
        end)

        rgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r,g,b = rgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if r then CP.Hue,CP.Sat,CP.Vib = Color3.toHSV(Color3.fromRGB(r,g,b)) end
            end
            CP:Display()
        end)

        swatch.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if pickerOuter.Visible then CP:Hide() else ctx:Hide(); CP:Show() end
            elseif inp.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ctx:Show(); CP:Hide()
            end
        end)

        Library:GiveSignal(InputService.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                local pos,sz = pickerOuter.AbsolutePosition, pickerOuter.AbsoluteSize
                if Mouse.X<pos.X or Mouse.X>pos.X+sz.X or Mouse.Y<(pos.Y-20) or Mouse.Y>pos.Y+sz.Y then
                    CP:Hide()
                end
                if not Library:IsMouseOverFrame(ctx.Container) then ctx:Hide() end
            end
            if inp.UserInputType == Enum.UserInputType.MouseButton2 and ctx.Container.Visible then
                if not Library:IsMouseOverFrame(ctx.Container) and not Library:IsMouseOverFrame(swatch) then
                    ctx:Hide()
                end
            end
        end))

        CP:Display()
        CP.DisplayFrame = swatch
        Options[idx] = CP
        return self
    end

    -- ── KeyPicker ─────────────────────────────────────────────────────────────
    function Funcs:AddKeyPicker(idx, info)
        local parentObj   = self
        local ToggleLabel = self.TextLabel
        assert(info.Default, 'AddKeyPicker: Missing default')

        local KP = {
            Value = info.Default; Toggled = false;
            Mode = info.Mode or 'Toggle';
            Type = 'KeyPicker';
            Callback = info.Callback or function() end;
            ChangedCallback = info.ChangedCallback or function() end;
            SyncToggleState = info.SyncToggleState or false;
        }

        if KP.SyncToggleState then info.Modes = {'Toggle'}; info.Mode = 'Toggle' end

        local pickOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0,0,0); BorderSizePixel = 0;
            Size = UDim2.fromOffset(32,16); ZIndex = 6; Parent = ToggleLabel;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,3); Parent = pickOuter })

        local pickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor; BorderSizePixel = 0;
            Size = UDim2.fromScale(1,1); ZIndex = 7; Parent = pickOuter;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,3); Parent = pickInner })
        Library:Create('UIStroke', { Color = Library.OutlineColor; Thickness = 1; Parent = pickOuter })
        Library:AddToRegistry(pickInner, { BackgroundColor3 = 'BackgroundColor' })

        local dispLabel = Library:CreateLabel({
            Size = UDim2.fromScale(1,1); TextSize = 12;
            Text = info.Default; TextWrapped = true;
            ZIndex = 8; Parent = pickInner;
        })

        local modeOuter = Library:Create('Frame', {
            BorderSizePixel = 0;
            Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X+ToggleLabel.AbsoluteSize.X+5, ToggleLabel.AbsolutePosition.Y+1);
            Size = UDim2.fromOffset(70,50);
            Visible = false; ZIndex = 20; Parent = ScreenGui;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,5); Parent = modeOuter })
        Library:Create('UIStroke', { Color = Library.AccentColor; Thickness = 1; Transparency = 0.5; Parent = modeOuter })

        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            modeOuter.Position = UDim2.fromOffset(
                ToggleLabel.AbsolutePosition.X+ToggleLabel.AbsoluteSize.X+5,
                ToggleLabel.AbsolutePosition.Y+1)
        end)

        local modeInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor; BorderSizePixel = 0;
            Size = UDim2.fromScale(1,1); ZIndex = 21; Parent = modeOuter;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,5); Parent = modeInner })
        Library:AddToRegistry(modeInner, { BackgroundColor3 = 'BackgroundColor' })
        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Padding = UDim.new(0,1); Parent = modeInner;
        })
        Library:Create('UIPadding', { PaddingLeft = UDim.new(0,5); PaddingTop = UDim.new(0,3); Parent = modeInner })

        local containerLabel = Library:CreateLabel({
            TextXAlignment = Enum.TextXAlignment.Left;
            Size = UDim2.new(1,0,0,18); TextSize = 12;
            Visible = false; ZIndex = 110;
            Parent = Library.KeybindContainer;
        }, true)

        local Modes = info.Modes or {'Always','Toggle','Hold'}
        local ModeButtons = {}

        for _,mode in next, Modes do
            local mb = {}
            local lbl = Library:CreateLabel({
                Active = false; Size = UDim2.new(1,0,0,16);
                TextSize = 13; Text = mode; ZIndex = 22; Parent = modeInner;
            })
            Library:OnHighlight(lbl, lbl, { TextColor3 = 'AccentColor' }, { TextColor3 = 'FontColor' })
            function mb:Select()
                for _,b in next, ModeButtons do b:Deselect() end
                KP.Mode = mode
                lbl.TextColor3 = Library.AccentColor
                Library.RegistryMap[lbl].Properties.TextColor3 = 'AccentColor'
                modeOuter.Visible = false
            end
            function mb:Deselect()
                KP.Mode = nil
                lbl.TextColor3 = Library.FontColor
                Library.RegistryMap[lbl].Properties.TextColor3 = 'FontColor'
            end
            lbl.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    mb:Select(); Library:AttemptSave()
                end
            end)
            if mode == KP.Mode then mb:Select() end
            ModeButtons[mode] = mb
        end

        function KP:Update()
            if info.NoUI then return end
            local state = KP:GetState()
            containerLabel.Text = string.format('[%s] %s (%s)', KP.Value, info.Text, KP.Mode)
            containerLabel.Visible = true
            containerLabel.TextColor3 = state and Library.AccentColor or Library.FontColor
            Library.RegistryMap[containerLabel].Properties.TextColor3 = state and 'AccentColor' or 'FontColor'
            local ySize, xSize = 0, 0
            for _,lbl in next, Library.KeybindContainer:GetChildren() do
                if lbl:IsA('TextLabel') and lbl.Visible then
                    ySize = ySize + 18
                    if lbl.TextBounds.X > xSize then xSize = lbl.TextBounds.X end
                end
            end
            Library.KeybindFrame.Size = UDim2.fromOffset(math.max(xSize+14, 210), ySize+24)
        end

        function KP:GetState()
            if KP.Mode == 'Always' then return true
            elseif KP.Mode == 'Hold' then
                if KP.Value == 'None' then return false end
                if KP.Value == 'MB1' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                elseif KP.Value == 'MB2' then return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                else return InputService:IsKeyDown(Enum.KeyCode[KP.Value]) end
            else return KP.Toggled end
        end

        function KP:SetValue(data)
            local key, mode = data[1], data[2]
            dispLabel.Text = key; KP.Value = key
            ModeButtons[mode]:Select(); KP:Update()
        end
        function KP:OnClick(cb)  KP.Clicked  = cb end
        function KP:OnChanged(cb) KP.Changed = cb; cb(KP.Value) end
        if parentObj.Addons then table.insert(parentObj.Addons, KP) end

        function KP:DoClick()
            if parentObj.Type == 'Toggle' and KP.SyncToggleState then
                parentObj:SetValue(not parentObj.Value)
            end
            Library:SafeCallback(KP.Callback, KP.Toggled)
            Library:SafeCallback(KP.Clicked,  KP.Toggled)
        end

        local picking = false
        pickOuter.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                picking = true; dispLabel.Text = ''
                local brk, txt = false, ''
                task.spawn(function()
                    while not brk do
                        txt = txt == '...' and '' or txt..'.'
                        dispLabel.Text = txt; task.wait(0.35)
                    end
                end)
                task.wait(0.2)
                local ev
                ev = InputService.InputBegan:Connect(function(i2)
                    local key
                    if i2.UserInputType == Enum.UserInputType.Keyboard then key = i2.KeyCode.Name
                    elseif i2.UserInputType == Enum.UserInputType.MouseButton1 then key = 'MB1'
                    elseif i2.UserInputType == Enum.UserInputType.MouseButton2 then key = 'MB2' end
                    brk = true; picking = false
                    dispLabel.Text = key; KP.Value = key
                    Library:SafeCallback(KP.ChangedCallback, i2.KeyCode or i2.UserInputType)
                    Library:SafeCallback(KP.Changed, i2.KeyCode or i2.UserInputType)
                    Library:AttemptSave(); ev:Disconnect()
                end)
            elseif inp.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                modeOuter.Visible = true
            end
        end)

        Library:GiveSignal(InputService.InputBegan:Connect(function(inp)
            if not picking then
                if KP.Mode == 'Toggle' then
                    local k = KP.Value
                    if k=='MB1' or k=='MB2' then
                        if (k=='MB1' and inp.UserInputType==Enum.UserInputType.MouseButton1)
                        or (k=='MB2' and inp.UserInputType==Enum.UserInputType.MouseButton2) then
                            KP.Toggled = not KP.Toggled; KP:DoClick()
                        end
                    elseif inp.UserInputType==Enum.UserInputType.Keyboard then
                        if inp.KeyCode.Name==k then KP.Toggled = not KP.Toggled; KP:DoClick() end
                    end
                end
                KP:Update()
            end
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                local pos,sz = modeOuter.AbsolutePosition, modeOuter.AbsoluteSize
                if Mouse.X<pos.X or Mouse.X>pos.X+sz.X or Mouse.Y<(pos.Y-21) or Mouse.Y>pos.Y+sz.Y then
                    modeOuter.Visible = false
                end
            end
        end))

        Library:GiveSignal(InputService.InputEnded:Connect(function()
            if not picking then KP:Update() end
        end))

        KP:Update()
        Options[idx] = KP
        return self
    end

    BaseAddons.__index = Funcs
    BaseAddons.__namecall = function(t,k,...) return Funcs[k](...) end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- BASE GROUPBOX (все контролы)
-- ══════════════════════════════════════════════════════════════════════════════
local BaseGroupbox = {}
do
    local Funcs = {}

    function Funcs:AddBlank(size)
        Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1,0,0,size);
            ZIndex = 1; Parent = self.Container;
        })
    end

    -- ── Label ─────────────────────────────────────────────────────────────────
    function Funcs:AddLabel(text, wrap)
        local gb = self
        local lbl = {}
        local tl = Library:CreateLabel({
            Size = UDim2.new(1,-6,0,15); TextSize = 13; Text = text;
            TextWrapped = wrap or false;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5; Parent = gb.Container;
        })
        if wrap then
            local _,y = Library:GetTextBounds(text, Library.BodyFont, 13, Vector2.new(tl.AbsoluteSize.X, math.huge))
            tl.Size = UDim2.new(1,-6,0,y)
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0,4);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = tl;
            })
        end
        lbl.TextLabel = tl; lbl.Container = gb.Container
        function lbl:SetText(t2)
            tl.Text = t2
            if wrap then
                local _,y2 = Library:GetTextBounds(t2, Library.BodyFont, 13, Vector2.new(tl.AbsoluteSize.X, math.huge))
                tl.Size = UDim2.new(1,-6,0,y2)
            end
            gb:Resize()
        end
        if not wrap then setmetatable(lbl, BaseAddons) end
        gb:AddBlank(5); gb:Resize()
        return lbl
    end

    -- ── Button ────────────────────────────────────────────────────────────────
    function Funcs:AddButton(...)
        local btn = {}
        local function parseParams(obj, ...)
            local p = select(1,...)
            if type(p)=='table' then
                obj.Text = p.Text; obj.Func = p.Func
                obj.DoubleClick = p.DoubleClick; obj.Tooltip = p.Tooltip
            else
                obj.Text = select(1,...); obj.Func = select(2,...)
            end
            assert(type(obj.Func)=='function', 'AddButton: Func missing')
        end
        parseParams(btn, ...)

        local gb = self
        local function makeBtn(b)
            local outer = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(0,0,0); BorderSizePixel = 0;
                Size = UDim2.new(1,-6,0,22); ZIndex = 5;
            })
            Library:Create('UICorner', { CornerRadius = UDim.new(0,5); Parent = outer })

            local inner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor; BorderSizePixel = 0;
                Size = UDim2.fromScale(1,1); ZIndex = 6; Parent = outer;
            })
            Library:Create('UICorner', { CornerRadius = UDim.new(0,5); Parent = inner })
            Library:Create('UIStroke', { Color = Library.OutlineColor; Thickness = 1; Transparency = 0.4; Parent = outer })
            Library:Create('UIGradient', {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(220,220,220)),
                }); Rotation = 90; Parent = inner;
            })

            local lbl = Library:CreateLabel({
                Size = UDim2.fromScale(1,1); TextSize = 13;
                Font = Library.Font; Text = b.Text; ZIndex = 7; Parent = inner;
            })
            Library:AddToRegistry(outer, { BorderColor3 = 'OutlineColor' })
            Library:AddToRegistry(inner, { BackgroundColor3 = 'MainColor' })

            Library:OnHighlight(outer, outer,
                { BorderColor3 = 'AccentColor' },
                { BorderColor3 = 'OutlineColor' }
            )

            return outer, inner, lbl
        end

        local function initEvents(b)
            local function waitEv(ev, timeout, validate)
                local be = Instance.new('BindableEvent')
                local conn = ev:Once(function(...)
                    be:Fire(validate and validate(...) or true)
                end)
                task.delay(timeout, function() conn:Disconnect(); be:Fire(false) end)
                return be.Event:Wait()
            end
            local function validClick(inp)
                return not Library:MouseIsOverOpenedFrame() and inp.UserInputType == Enum.UserInputType.MouseButton1
            end

            b.Outer.InputBegan:Connect(function(inp)
                if not validClick(inp) or b.Locked then return end
                PlaySound(3927194625, 0.35, 1.1)
                if b.DoubleClick then
                    Library:RemoveFromRegistry(b.Label)
                    Library:AddToRegistry(b.Label, { TextColor3 = 'AccentColor' })
                    b.Label.TextColor3 = Library.AccentColor
                    b.Label.Text = 'Confirm?'
                    b.Locked = true
                    local clicked = waitEv(b.Outer.InputBegan, 0.6, validClick)
                    Library:RemoveFromRegistry(b.Label)
                    Library:AddToRegistry(b.Label, { TextColor3 = 'FontColor' })
                    b.Label.TextColor3 = Library.FontColor
                    b.Label.Text = b.Text
                    task.defer(rawset, b, 'Locked', false)
                    if clicked then Library:SafeCallback(b.Func) end
                    return
                end
                Library:SafeCallback(b.Func)
            end)
        end

        btn.Outer, btn.Inner, btn.Label = makeBtn(btn)
        btn.Outer.Parent = self.Container
        initEvents(btn)

        function btn:AddTooltip(t)
            if type(t)=='string' then Library:AddToolTip(t, self.Outer) end
            return self
        end
        function btn:AddButton(...)
            local sub = {}
            parseParams(sub, ...)
            self.Outer.Size = UDim2.new(0.5,-3,0,22)
            sub.Outer, sub.Inner, sub.Label = makeBtn(sub)
            sub.Outer.Position = UDim2.new(1,4,0,0)
            sub.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X-2, self.Outer.AbsoluteSize.Y)
            sub.Outer.Parent = self.Outer
            function sub:AddTooltip(t)
                if type(t)=='string' then Library:AddToolTip(t, self.Outer) end
                return sub
            end
            if type(sub.Tooltip)=='string' then sub:AddTooltip(sub.Tooltip) end
            initEvents(sub)
            return sub
        end
        if type(btn.Tooltip)=='string' then btn:AddTooltip(btn.Tooltip) end

        self:AddBlank(5); self:Resize()
        return btn
    end

    -- ── Divider ───────────────────────────────────────────────────────────────
    function Funcs:AddDivider()
        self:AddBlank(3)
        local div = Library:Create('Frame', {
            BackgroundColor3 = Library.OutlineColor; BorderSizePixel = 0;
            Size = UDim2.new(1,-8,0,1); ZIndex = 5;
            Parent = self.Container;
        })
        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
                ColorSequenceKeypoint.new(0.5, Color3.new(1,1,1)),
                ColorSequenceKeypoint.new(1, Color3.new(0,0,0)),
            }); Parent = div;
        })
        Library:AddToRegistry(div, { BackgroundColor3 = 'OutlineColor' })
        self:AddBlank(7); self:Resize()
    end

    -- ── Input ─────────────────────────────────────────────────────────────────
    function Funcs:AddInput(idx, info)
        assert(info.Text, 'AddInput: Missing Text')
        local gb = self
        local tb = {
            Value = info.Default or ''; Numeric = info.Numeric;
            Finished = info.Finished; Type = 'Input';
            Callback = info.Callback or function() end;
        }

        Library:CreateLabel({
            Size = UDim2.new(1,0,0,14); TextSize = 13; Text = info.Text;
            TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 5;
            Parent = gb.Container;
        })
        gb:AddBlank(2)

        local boxOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0,0,0); BorderSizePixel = 0;
            Size = UDim2.new(1,-6,0,22); ZIndex = 5; Parent = gb.Container;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,4); Parent = boxOuter })

        local boxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor; BorderSizePixel = 0;
            Size = UDim2.fromScale(1,1); ZIndex = 6; Parent = boxOuter;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,4); Parent = boxInner })
        Library:Create('UIStroke', { Color = Library.OutlineColor; Thickness = 1; Transparency = 0.3; Parent = boxOuter })
        Library:AddToRegistry(boxInner, { BackgroundColor3 = 'MainColor' })

        Library:OnHighlight(boxOuter, boxOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'OutlineColor' }
        )

        if type(info.Tooltip)=='string' then Library:AddToolTip(info.Tooltip, boxOuter) end

        local clipFrame = Library:Create('Frame', {
            BackgroundTransparency = 1; ClipsDescendants = true;
            Position = UDim2.fromOffset(6,0); Size = UDim2.new(1,-6,1,0);
            ZIndex = 7; Parent = boxInner;
        })
        local box = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.fromOffset(0,0); Size = UDim2.fromScale(5,1);
            Font = Library.BodyFont;
            PlaceholderColor3 = Color3.fromRGB(100,100,140);
            PlaceholderText = info.Placeholder or '';
            Text = info.Default or ''; TextColor3 = Library.FontColor;
            TextSize = 13; TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 7; Parent = clipFrame;
        })
        Library:ApplyTextStroke(box)
        Library:AddToRegistry(box, { TextColor3 = 'FontColor' })

        function tb:SetValue(t)
            if info.MaxLength and #t > info.MaxLength then t = t:sub(1,info.MaxLength) end
            if tb.Numeric and not tonumber(t) and #t>0 then t = tb.Value end
            tb.Value = t; box.Text = t
            Library:SafeCallback(tb.Callback, tb.Value)
            Library:SafeCallback(tb.Changed, tb.Value)
        end
        function tb:OnChanged(f) tb.Changed = f; f(tb.Value) end

        if tb.Finished then
            box.FocusLost:Connect(function(enter)
                if enter then tb:SetValue(box.Text); Library:AttemptSave() end
            end)
        else
            box:GetPropertyChangedSignal('Text'):Connect(function()
                tb:SetValue(box.Text); Library:AttemptSave()
            end)
        end

        -- cursor scroll
        local function updateCursor()
            local PAD, reveal = 2, clipFrame.AbsoluteSize.X
            if not box:IsFocused() or box.TextBounds.X <= reveal-2*PAD then
                box.Position = UDim2.fromOffset(PAD,0)
            else
                local cur = box.CursorPosition
                if cur ~= -1 then
                    local sub = box.Text:sub(1,cur-1)
                    local w = TextService:GetTextSize(sub, box.TextSize, box.Font, Vector2.new(math.huge,math.huge)).X
                    local cp = box.Position.X.Offset + w
                    if cp < PAD then box.Position = UDim2.fromOffset(PAD-w,0)
                    elseif cp > reveal-PAD-1 then box.Position = UDim2.fromOffset(reveal-w-PAD-1,0) end
                end
            end
        end
        task.spawn(updateCursor)
        box:GetPropertyChangedSignal('Text'):Connect(updateCursor)
        box:GetPropertyChangedSignal('CursorPosition'):Connect(updateCursor)
        box.FocusLost:Connect(updateCursor); box.Focused:Connect(updateCursor)

        gb:AddBlank(5); gb:Resize()
        Options[idx] = tb
        return tb
    end

    -- ── Toggle ────────────────────────────────────────────────────────────────
    function Funcs:AddToggle(idx, info)
        assert(info.Text, 'AddToggle: Missing Text')
        local gb = self

        local toggle = {
            Value = info.Default or false; Type = 'Toggle';
            Callback = info.Callback or function() end;
            Addons = {}; Risky = info.Risky;
        }

        -- outer container row
        local row = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1,0,0,16);
            ZIndex = 5; Parent = gb.Container;
        })

        -- toggle switch track
        local trackOuter = Library:Create('Frame', {
            BackgroundColor3 = Library.OutlineColor; BorderSizePixel = 0;
            Size = UDim2.fromOffset(28,14); ZIndex = 6; Parent = row;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,7); Parent = trackOuter })
        Library:AddToRegistry(trackOuter, { BackgroundColor3 = 'OutlineColor' })

        local thumb = Library:Create('Frame', {
            BackgroundColor3 = Library.FontColor; BorderSizePixel = 0;
            AnchorPoint = Vector2.new(0,0.5);
            Position = UDim2.new(0,2,0.5,0);
            Size = UDim2.fromOffset(10,10);
            ZIndex = 7; Parent = trackOuter;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0.5,0); Parent = thumb })

        -- label
        local tLabel = Library:CreateLabel({
            Position = UDim2.fromOffset(34,0);
            Size = UDim2.new(1,-34,1,0);
            TextSize = 13; Text = info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6; Parent = row;
        })
        Library:Create('UIListLayout', {
            Padding = UDim.new(0,4);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = tLabel;
        })

        if info.Risky then
            Library:RemoveFromRegistry(tLabel)
            tLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(tLabel, { TextColor3 = 'RiskColor' })
        end

        if type(info.Tooltip)=='string' then Library:AddToolTip(info.Tooltip, row) end

        function toggle:Display()
            local on = toggle.Value
            Library:Tween(trackOuter, { BackgroundColor3 = on and Library.AccentColor or Library.OutlineColor }, 0.14)
            Library:Tween(thumb, { Position = on and UDim2.new(1,-12,0.5,0) or UDim2.new(0,2,0.5,0) }, 0.14)
            Library.RegistryMap[trackOuter].Properties.BackgroundColor3 = on and 'AccentColor' or 'OutlineColor'
        end
        function toggle:OnChanged(f) toggle.Changed = f; f(toggle.Value) end
        function toggle:SetValue(v)
            v = not not v; toggle.Value = v
            toggle:Display()
            for _,a in next, toggle.Addons do
                if a.Type=='KeyPicker' and a.SyncToggleState then
                    a.Toggled = v; a:Update()
                end
            end
            PlaySound(v and 4590662766 or 4590662766, 0.25, v and 1.2 or 0.9)
            Library:SafeCallback(toggle.Callback, v)
            Library:SafeCallback(toggle.Changed, v)
            Library:UpdateDependencyBoxes()
        end

        row.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                toggle:SetValue(not toggle.Value)
                Library:AttemptSave()
            end
        end)
        Library:OnHighlight(row, trackOuter,
            { BackgroundColor3 = toggle.Value and 'AccentColor' or 'SecondAccent' },
            { BackgroundColor3 = toggle.Value and 'AccentColor' or 'OutlineColor' }
        )

        toggle:Display()
        gb:AddBlank(info.BlankSize or 7)
        gb:Resize()

        toggle.TextLabel = tLabel
        toggle.Container  = gb.Container
        setmetatable(toggle, BaseAddons)

        Toggles[idx] = toggle
        Library:UpdateDependencyBoxes()
        return toggle
    end

    -- ── Slider ────────────────────────────────────────────────────────────────
    function Funcs:AddSlider(idx, info)
        assert(info.Default, 'AddSlider: Missing default')
        assert(info.Text,    'AddSlider: Missing Text')
        assert(info.Min,     'AddSlider: Missing Min')
        assert(info.Max,     'AddSlider: Missing Max')
        assert(info.Rounding ~= nil, 'AddSlider: Missing Rounding')

        local gb = self
        local sl = {
            Value = info.Default; Min = info.Min; Max = info.Max;
            Rounding = info.Rounding; MaxSize = 230; Type = 'Slider';
            Callback = info.Callback or function() end;
        }

        if not info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1,0,0,12); TextSize = 13; Text = info.Text;
                TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 5;
                Parent = gb.Container;
            })
            gb:AddBlank(2)
        end

        local slOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0,0,0); BorderSizePixel = 0;
            Size = UDim2.new(1,-6,0,14); ZIndex = 5; Parent = gb.Container;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,7); Parent = slOuter })

        local slTrack = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor; BorderSizePixel = 0;
            Size = UDim2.fromScale(1,1); ZIndex = 6; Parent = slOuter;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,7); Parent = slTrack })
        Library:Create('UIStroke', { Color = Library.OutlineColor; Thickness = 1; Transparency = 0.3; Parent = slOuter })
        Library:AddToRegistry(slTrack, { BackgroundColor3 = 'MainColor' })

        local fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor; BorderSizePixel = 0;
            Size = UDim2.fromOffset(0,14); ZIndex = 7; Parent = slTrack;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,7); Parent = fill })
        Library:AddToRegistry(fill, { BackgroundColor3 = 'AccentColor' })

        local dispLbl = Library:CreateLabel({
            Size = UDim2.fromScale(1,1); TextSize = 12;
            Font = Library.Font; ZIndex = 8; Parent = slTrack;
        })

        Library:OnHighlight(slOuter, slOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'OutlineColor' }
        )
        if type(info.Tooltip)=='string' then Library:AddToolTip(info.Tooltip, slOuter) end

        local function round(v)
            if sl.Rounding==0 then return math.floor(v) end
            return tonumber(string.format('%.'..sl.Rounding..'f', v))
        end
        function sl:Display()
            local suf = info.Suffix or ''
            if info.Compact then dispLbl.Text = info.Text..': '..sl.Value..suf
            elseif info.HideMax then dispLbl.Text = sl.Value..suf
            else dispLbl.Text = sl.Value..suf..'/'..sl.Max..suf end
            local x = math.ceil(Library:MapValue(sl.Value, sl.Min, sl.Max, 0, sl.MaxSize))
            fill.Size = UDim2.fromOffset(x, 14)
        end
        function sl:OnChanged(f) sl.Changed = f; f(sl.Value) end
        function sl:GetValueFromX(x)
            return round(Library:MapValue(x, 0, sl.MaxSize, sl.Min, sl.Max))
        end
        function sl:SetValue(s)
            local n = tonumber(s)
            if not n then return end
            n = math.clamp(n, sl.Min, sl.Max)
            sl.Value = n; sl:Display()
            Library:SafeCallback(sl.Callback, sl.Value)
            Library:SafeCallback(sl.Changed, sl.Value)
        end

        slTrack.InputBegan:Connect(function(inp)
            if inp.UserInputType ~= Enum.UserInputType.MouseButton1 or Library:MouseIsOverOpenedFrame() then return end
            local mPos = Mouse.X
            local gPos = fill.Size.X.Offset
            local diff = mPos - (fill.AbsolutePosition.X + gPos)
            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local nx = math.clamp(gPos+(Mouse.X-mPos)+diff, 0, sl.MaxSize)
                local nv = sl:GetValueFromX(nx)
                local old = sl.Value; sl.Value = nv; sl:Display()
                if nv ~= old then
                    Library:SafeCallback(sl.Callback, sl.Value)
                    Library:SafeCallback(sl.Changed, sl.Value)
                end
                RenderStepped:Wait()
            end
            Library:AttemptSave()
        end)

        sl:Display()
        gb:AddBlank(info.BlankSize or 7)
        gb:Resize()

        Options[idx] = sl
        return sl
    end

    -- ── Dropdown ──────────────────────────────────────────────────────────────
    function Funcs:AddDropdown(idx, info)
        if info.SpecialType=='Player' then info.Values=GetPlayersString(); info.AllowNull=true
        elseif info.SpecialType=='Team' then info.Values=GetTeamsString(); info.AllowNull=true end

        assert(info.Values, 'AddDropdown: Missing Values')
        assert(info.AllowNull or info.Default, 'AddDropdown: Missing default or AllowNull')
        if not info.Text then info.Compact = true end

        local gb = self
        local dd = {
            Values = info.Values; Value = info.Multi and {};
            Multi = info.Multi; Type = 'Dropdown';
            SpecialType = info.SpecialType;
            Callback = info.Callback or function() end;
        }

        if not info.Compact then
            Library:CreateLabel({
                Size = UDim2.new(1,0,0,12); TextSize = 13; Text = info.Text;
                TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 5;
                Parent = gb.Container;
            })
            gb:AddBlank(2)
        end

        local ddOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0,0,0); BorderSizePixel = 0;
            Size = UDim2.new(1,-6,0,22); ZIndex = 5; Parent = gb.Container;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,5); Parent = ddOuter })
        Library:AddToRegistry(ddOuter, { BorderColor3 = 'OutlineColor' })

        local ddInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor; BorderSizePixel = 0;
            Size = UDim2.fromScale(1,1); ZIndex = 6; Parent = ddOuter;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,5); Parent = ddInner })
        Library:Create('UIStroke', { Color = Library.OutlineColor; Thickness = 1; Transparency = 0.3; Parent = ddOuter })
        Library:AddToRegistry(ddInner, { BackgroundColor3 = 'MainColor' })

        local arrow = Library:Create('TextLabel', {
            AnchorPoint = Vector2.new(1,0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1,-6,0.5,0);
            Size = UDim2.fromOffset(16,16);
            Text = '▾'; TextColor3 = Library.AccentColor;
            Font = Library.Font; TextSize = 14;
            ZIndex = 8; Parent = ddInner;
        })
        Library:AddToRegistry(arrow, { TextColor3 = 'AccentColor' })

        local selLbl = Library:CreateLabel({
            Position = UDim2.fromOffset(7,0); Size = UDim2.new(1,-28,1,0);
            TextSize = 13; Text = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = true; ZIndex = 7; Parent = ddInner;
        })

        Library:OnHighlight(ddOuter, ddOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'OutlineColor' }
        )
        if type(info.Tooltip)=='string' then Library:AddToolTip(info.Tooltip, ddOuter) end

        local MAX = 8
        local listOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0,0,0); BorderSizePixel = 0;
            ZIndex = 25; Visible = false; Parent = ScreenGui;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,5); Parent = listOuter })
        Library:Create('UIStroke', { Color = Library.AccentColor; Thickness = 1; Transparency = 0.5; Parent = listOuter })

        local function recalcPos()
            listOuter.Position = UDim2.fromOffset(ddOuter.AbsolutePosition.X, ddOuter.AbsolutePosition.Y + ddOuter.Size.Y.Offset + 2)
        end
        local function recalcSize(y)
            listOuter.Size = UDim2.fromOffset(ddOuter.AbsoluteSize.X, y or (MAX*20+2))
        end
        recalcPos(); recalcSize()
        ddOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(recalcPos)

        local listInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor; BorderSizePixel = 0;
            Size = UDim2.fromScale(1,1); ZIndex = 26; Parent = listOuter;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,5); Parent = listInner })
        Library:AddToRegistry(listInner, { BackgroundColor3 = 'BackgroundColor' })

        local scroll = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1; BorderSizePixel = 0;
            CanvasSize = UDim2.fromOffset(0,0);
            Size = UDim2.fromScale(1,1); ZIndex = 26;
            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
            ScrollBarThickness = 3;
            ScrollBarImageColor3 = Library.AccentColor;
            Parent = listInner;
        })
        Library:AddToRegistry(scroll, { ScrollBarImageColor3 = 'AccentColor' })
        Library:Create('UIListLayout', {
            Padding = UDim.new(0,1); FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder; Parent = scroll;
        })

        function dd:Display()
            local str = ''
            if info.Multi then
                for _,v in next, dd.Values do
                    if dd.Value[v] then str = str..v..', ' end
                end
                str = str:sub(1,#str-2)
            else
                str = dd.Value or ''
            end
            selLbl.Text = str=='' and '--' or str
        end

        function dd:GetActiveValues()
            if info.Multi then
                local n = 0
                for _ in next, dd.Value do n=n+1 end
                return n
            else return dd.Value and 1 or 0 end
        end

        function dd:BuildList()
            for _,c in next, scroll:GetChildren() do
                if not c:IsA('UIListLayout') then c:Destroy() end
            end
            local buttons, count = {}, 0
            for _,val in next, dd.Values do
                local bt = {}; count = count+1
                local frame = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor; BorderSizePixel = 0;
                    Size = UDim2.new(1,0,0,22); ZIndex = 27; Active = true;
                    Parent = scroll;
                })
                Library:Create('UIPadding', { PaddingLeft = UDim.new(0,1); Parent = frame })
                Library:AddToRegistry(frame, { BackgroundColor3 = 'MainColor' })

                local blbl = Library:CreateLabel({
                    Position = UDim2.fromOffset(8,0); Size = UDim2.new(1,-12,1,0);
                    TextSize = 13; Text = val;
                    TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 28; Parent = frame;
                })
                Library:OnHighlight(frame, frame,
                    { BackgroundColor3 = 'BackgroundColor' },
                    { BackgroundColor3 = 'MainColor' }
                )

                local selected = info.Multi and dd.Value[val] or dd.Value==val
                function bt:UpdateBtn()
                    selected = info.Multi and dd.Value[val] or dd.Value==val
                    blbl.TextColor3 = selected and Library.AccentColor or Library.FontColor
                    Library.RegistryMap[blbl].Properties.TextColor3 = selected and 'AccentColor' or 'FontColor'
                end

                blbl.InputBegan:Connect(function(inp)
                    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    local try = not selected
                    if dd:GetActiveValues()==1 and not try and not info.AllowNull then return end
                    PlaySound(3927194625, 0.3, 1.2)
                    if info.Multi then
                        selected = try
                        if try then dd.Value[val] = true else dd.Value[val] = nil end
                    else
                        selected = try
                        dd.Value = try and val or nil
                        for _,b in next, buttons do b:UpdateBtn() end
                    end
                    bt:UpdateBtn(); dd:Display()
                    Library:SafeCallback(dd.Callback, dd.Value)
                    Library:SafeCallback(dd.Changed, dd.Value)
                    Library:AttemptSave()
                end)

                bt:UpdateBtn(); dd:Display()
                buttons[frame] = bt
            end
            scroll.CanvasSize = UDim2.fromOffset(0, count*22+count)
            recalcSize(math.clamp(count*22, 0, MAX*22)+2)
        end

        function dd:SetValues(nv)
            if nv then dd.Values = nv end
            dd:BuildList()
        end
        function dd:OpenDropdown()
            listOuter.Visible = true; Library.OpenedFrames[listOuter] = true
            arrow.Text = '▴'
        end
        function dd:CloseDropdown()
            listOuter.Visible = false; Library.OpenedFrames[listOuter] = nil
            arrow.Text = '▾'
        end
        function dd:OnChanged(f) dd.Changed = f; f(dd.Value) end
        function dd:SetValue(v)
            if dd.Multi then
                local nt = {}
                for val in next, v do
                    if table.find(dd.Values, val) then nt[val] = true end
                end
                dd.Value = nt
            else
                if not v then dd.Value = nil
                elseif table.find(dd.Values, v) then dd.Value = v end
            end
            dd:BuildList()
            Library:SafeCallback(dd.Callback, dd.Value)
            Library:SafeCallback(dd.Changed, dd.Value)
        end

        ddOuter.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if listOuter.Visible then dd:CloseDropdown() else dd:OpenDropdown() end
            end
        end)
        InputService.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 then
                local pos,sz = listOuter.AbsolutePosition, listOuter.AbsoluteSize
                if Mouse.X<pos.X or Mouse.X>pos.X+sz.X or Mouse.Y<(pos.Y-23) or Mouse.Y>pos.Y+sz.Y then
                    dd:CloseDropdown()
                end
            end
        end)

        dd:BuildList(); dd:Display()

        -- default values
        local defs = {}
        if type(info.Default)=='string' then
            local i = table.find(dd.Values, info.Default)
            if i then table.insert(defs, i) end
        elseif type(info.Default)=='table' then
            for _,v in next, info.Default do
                local i = table.find(dd.Values, v)
                if i then table.insert(defs, i) end
            end
        elseif type(info.Default)=='number' and dd.Values[info.Default] then
            table.insert(defs, info.Default)
        end
        if next(defs) then
            for _,i in ipairs(defs) do
                if info.Multi then dd.Value[dd.Values[i]] = true
                else dd.Value = dd.Values[i]; break end
            end
            dd:BuildList(); dd:Display()
        end

        gb:AddBlank(info.BlankSize or 6); gb:Resize()
        Options[idx] = dd
        return dd
    end

    -- ── DependencyBox ─────────────────────────────────────────────────────────
    function Funcs:AddDependencyBox()
        local gb = self
        local db = { Dependencies = {} }

        local holder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1,0,0,0);
            Visible = false; Parent = gb.Container;
        })
        local frame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.fromScale(1,1);
            Parent = holder;
        })
        local layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = frame;
        })

        function db:Resize()
            holder.Size = UDim2.new(1,0,0,layout.AbsoluteContentSize.Y)
            gb:Resize()
        end
        layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function() db:Resize() end)
        holder:GetPropertyChangedSignal('Visible'):Connect(function() db:Resize() end)

        function db:Update()
            for _,dep in next, db.Dependencies do
                if dep[1].Type=='Toggle' and dep[1].Value ~= dep[2] then
                    holder.Visible = false; db:Resize(); return
                end
            end
            holder.Visible = true; db:Resize()
        end
        function db:SetupDependencies(deps)
            for _,d in next, deps do
                assert(type(d)=='table')
                assert(d[1]); assert(d[2]~=nil)
            end
            db.Dependencies = deps; db:Update()
        end

        db.Container = frame
        setmetatable(db, BaseGroupbox)
        table.insert(Library.DependencyBoxes, db)
        return db
    end

    BaseGroupbox.__index = Funcs
    BaseGroupbox.__namecall = function(t,k,...) return Funcs[k](...) end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- NEW: Progress Bar widget
-- ══════════════════════════════════════════════════════════════════════════════
function BaseGroupbox.__index:AddProgressBar(idx, info)
    assert(info.Text,  'AddProgressBar: Missing Text')
    assert(info.Max,   'AddProgressBar: Missing Max')

    local gb = self
    local pb = {
        Value = info.Default or 0; Max = info.Max;
        Type = 'ProgressBar';
    }

    Library:CreateLabel({
        Size = UDim2.new(1,0,0,12); TextSize = 13; Text = info.Text;
        TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 5;
        Parent = gb.Container;
    })
    gb:AddBlank(2)

    local track = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor; BorderSizePixel = 0;
        Size = UDim2.new(1,-6,0,12); ZIndex = 5; Parent = gb.Container;
    })
    Library:Create('UICorner', { CornerRadius = UDim.new(0,6); Parent = track })
    Library:Create('UIStroke', { Color = Library.OutlineColor; Thickness = 1; Transparency = 0.4; Parent = track })
    Library:AddToRegistry(track, { BackgroundColor3 = 'MainColor' })

    local bar = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor; BorderSizePixel = 0;
        Size = UDim2.fromOffset(0,12); ZIndex = 6; Parent = track;
    })
    Library:Create('UICorner', { CornerRadius = UDim.new(0,6); Parent = bar })
    Library:AddToRegistry(bar, { BackgroundColor3 = 'AccentColor' })

    local pctLbl = Library:CreateLabel({
        Size = UDim2.fromScale(1,1); TextSize = 11; Font = Library.Font;
        ZIndex = 7; Parent = track;
    })

    function pb:SetValue(v)
        pb.Value = math.clamp(v, 0, pb.Max)
        local pct = pb.Value / pb.Max
        Library:Tween(bar, { Size = UDim2.new(pct,0,1,0) }, 0.25)
        pctLbl.Text = math.floor(pct*100)..'%'
    end

    pb:SetValue(pb.Value)
    gb:AddBlank(6); gb:Resize()

    if idx then Options[idx] = pb end
    return pb
end

-- ══════════════════════════════════════════════════════════════════════════════
-- NEW: Searchable Dropdown (wraps normal dropdown with search box)
-- ══════════════════════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════════════════════════════════════════
-- WINDOW CREATION
-- ══════════════════════════════════════════════════════════════════════════════
function Library:CreateWindow(cfg)
    if type(cfg) ~= 'table' then cfg = { Title = tostring(cfg) } end
    cfg.Title        = cfg.Title or 'NeonUI'
    cfg.TabPadding   = cfg.TabPadding or 0
    cfg.MenuFadeTime = cfg.MenuFadeTime or 0.2
    cfg.AnchorPoint  = cfg.AnchorPoint or Vector2.zero
    if typeof(cfg.Position) ~= 'UDim2' then cfg.Position = UDim2.fromOffset(180,55) end
    if typeof(cfg.Size)     ~= 'UDim2' then cfg.Size     = UDim2.fromOffset(560,610) end
    if cfg.Center then cfg.AnchorPoint = Vector2.new(0.5,0.5); cfg.Position = UDim2.fromScale(0.5,0.5) end

    local Window = { Tabs = {} }

    -- outer shell
    local outer = Library:Create('Frame', {
        AnchorPoint = cfg.AnchorPoint;
        BackgroundColor3 = Color3.new(0,0,0);
        BorderSizePixel = 0;
        Position = cfg.Position; Size = cfg.Size;
        Visible = false; ZIndex = 1; Parent = ScreenGui;
    })
    Library:Create('UICorner', { CornerRadius = UDim.new(0,8); Parent = outer })

    local inner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor; BorderSizePixel = 0;
        Position = UDim2.fromOffset(1,1);
        Size = UDim2.new(1,-2,1,-2);
        ZIndex = 1; Parent = outer;
    })
    Library:Create('UICorner', { CornerRadius = UDim.new(0,7); Parent = inner })
    Library:Create('UIStroke', { Color = Library.AccentColor; Thickness = 1; Transparency = 0.5; Parent = outer })
    Library:AddToRegistry(inner, { BackgroundColor3 = 'MainColor' })

    -- title bar
    local titleBar = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor; BorderSizePixel = 0;
        Size = UDim2.new(1,0,0,28); ZIndex = 2; Parent = inner;
    })
    Library:Create('UICorner', { CornerRadius = UDim.new(0,7); Parent = titleBar })
    Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor; BorderSizePixel = 0;
        Position = UDim2.fromOffset(0,12); Size = UDim2.new(1,0,0,16);
        ZIndex = 1; Parent = titleBar;
    })
    Library:AddToRegistry(titleBar, { BackgroundColor3 = 'BackgroundColor' })

    -- accent line below title
    local accentLine = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor; BorderSizePixel = 0;
        Position = UDim2.fromOffset(0,27); Size = UDim2.new(1,0,0,1);
        ZIndex = 3; Parent = inner;
    })
    Library:AddToRegistry(accentLine, { BackgroundColor3 = 'AccentColor' })

    local titleLbl = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Position = UDim2.fromOffset(10,0); Size = UDim2.new(1,-10,1,0);
        Font = Library.Font; TextSize = 15;
        TextColor3 = Library.FontColor;
        Text = cfg.Title; TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 3; Parent = titleBar;
    })
    Library:ApplyTextStroke(titleLbl)
    Library:AddToRegistry(titleLbl, { TextColor3 = 'FontColor' })

    Library:MakeDraggable(outer, 28)

    -- main content area
    local mainArea = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor; BorderSizePixel = 0;
        Position = UDim2.fromOffset(8,34); Size = UDim2.new(1,-16,1,-42);
        ZIndex = 1; Parent = inner;
    })
    Library:Create('UICorner', { CornerRadius = UDim.new(0,5); Parent = mainArea })
    Library:Create('UIStroke', { Color = Library.OutlineColor; Thickness = 1; Transparency = 0.5; Parent = mainArea })
    Library:AddToRegistry(mainArea, { BackgroundColor3 = 'BackgroundColor' })

    -- tab button area
    local tabArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.fromOffset(8,8); Size = UDim2.new(1,-16,0,24);
        ZIndex = 2; Parent = mainArea;
    })
    Library:Create('UIListLayout', {
        Padding = UDim.new(0, cfg.TabPadding);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = tabArea;
    })

    -- tab container
    local tabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor; BorderSizePixel = 0;
        Position = UDim2.fromOffset(8,34); Size = UDim2.new(1,-16,1,-42);
        ZIndex = 2; Parent = mainArea;
    })
    Library:Create('UICorner', { CornerRadius = UDim.new(0,5); Parent = tabContainer })
    Library:Create('UIStroke', { Color = Library.OutlineColor; Thickness = 1; Transparency = 0.5; Parent = tabContainer })
    Library:AddToRegistry(tabContainer, { BackgroundColor3 = 'MainColor' })

    function Window:SetWindowTitle(t) titleLbl.Text = t end

    function Window:AddTab(name)
        local Tab = { Groupboxes = {}; Tabboxes = {} }

        local tbW = Library:GetTextBounds(name, Library.Font, 14)
        local tabBtn = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor; BorderSizePixel = 0;
            Size = UDim2.new(0, tbW+16, 1, 0); ZIndex = 2; Parent = tabArea;
        })
        Library:Create('UICorner', { CornerRadius = UDim.new(0,4); Parent = tabBtn })
        Library:Create('UIStroke', { Color = Library.OutlineColor; Thickness = 1; Transparency = 0.6; Parent = tabBtn })
        Library:AddToRegistry(tabBtn, { BackgroundColor3 = 'BackgroundColor' })

        local tabBtnLbl = Library:CreateLabel({
            Size = UDim2.new(1,0,1,-1); Font = Library.Font;
            TextSize = 13; Text = name; ZIndex = 2; Parent = tabBtn;
        })

        local blocker = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor; BorderSizePixel = 0;
            Position = UDim2.new(0,0,1,0); Size = UDim2.new(1,0,0,2);
            BackgroundTransparency = 1; ZIndex = 4; Parent = tabBtn;
        })
        Library:AddToRegistry(blocker, { BackgroundColor3 = 'MainColor' })

        local tabFrame = Library:Create('Frame', {
            Name = 'TabFrame'; BackgroundTransparency = 1;
            Size = UDim2.fromScale(1,1); Visible = false; ZIndex = 3; Parent = tabContainer;
        })

        local function makeSide(left)
            local s = Library:Create('ScrollingFrame', {
                BackgroundTransparency = 1; BorderSizePixel = 0;
                Position = left and UDim2.new(0,7,0,7) or UDim2.new(0.5,4,0,7);
                Size = UDim2.new(0.5,-12,0,510);
                CanvasSize = UDim2.fromOffset(0,0);
                BottomImage = ''; TopImage = '';
                ScrollBarThickness = 0;
                ZIndex = 3; Parent = tabFrame;
            })
            Library:Create('UIListLayout', {
                Padding = UDim.new(0,8);
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                HorizontalAlignment = Enum.HorizontalAlignment.Center;
                Parent = s;
            })
            s:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                s.CanvasSize = UDim2.fromOffset(0, s.UIListLayout.AbsoluteContentSize.Y)
            end)
            return s
        end

        local leftSide  = makeSide(true)
        local rightSide = makeSide(false)

        function Tab:ShowTab()
            for _,t in next, Window.Tabs do t:HideTab() end
            blocker.BackgroundTransparency = 0
            tabBtn.BackgroundColor3 = Library.MainColor
            Library.RegistryMap[tabBtn].Properties.BackgroundColor3 = 'MainColor'
            tabBtnLbl.TextColor3 = Library.AccentColor
            Library.RegistryMap[tabBtnLbl].Properties.TextColor3 = 'AccentColor'
            tabFrame.Visible = true
        end
        function Tab:HideTab()
            blocker.BackgroundTransparency = 1
            tabBtn.BackgroundColor3 = Library.BackgroundColor
            Library.RegistryMap[tabBtn].Properties.BackgroundColor3 = 'BackgroundColor'
            tabBtnLbl.TextColor3 = Library.FontColor
            Library.RegistryMap[tabBtnLbl].Properties.TextColor3 = 'FontColor'
            tabFrame.Visible = false
        end

        function Tab:AddGroupbox(info)
            local gb = {}

            local boxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor; BorderSizePixel = 0;
                Size = UDim2.new(1,0,0,510); ZIndex = 3;
                Parent = info.Side==1 and leftSide or rightSide;
            })
            Library:Create('UICorner', { CornerRadius = UDim.new(0,5); Parent = boxOuter })
            Library:Create('UIStroke', { Color = Library.OutlineColor; Thickness = 1; Transparency = 0.5; Parent = boxOuter })
            Library:AddToRegistry(boxOuter, { BackgroundColor3 = 'BackgroundColor' })

            local boxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor; BorderSizePixel = 0;
                Size = UDim2.new(1,-2,1,-2); Position = UDim2.fromOffset(1,1);
                ZIndex = 4; Parent = boxOuter;
            })
            Library:Create('UICorner', { CornerRadius = UDim.new(0,5); Parent = boxInner })
            Library:AddToRegistry(boxInner, { BackgroundColor3 = 'BackgroundColor' })

            local topAccent = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor; BorderSizePixel = 0;
                Size = UDim2.new(1,0,0,2); ZIndex = 5; Parent = boxInner;
            })
            Library:Create('UICorner', { CornerRadius = UDim.new(0,5); Parent = topAccent })
            Library:AddToRegistry(topAccent, { BackgroundColor3 = 'AccentColor' })

            local gbLbl = Library:CreateLabel({
                Size = UDim2.new(1,0,0,18); Position = UDim2.fromOffset(6,3);
                TextSize = 13; Font = Library.Font; Text = info.Name;
                TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 5; Parent = boxInner;
            })

            local container = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.fromOffset(4,21);
                Size = UDim2.new(1,-4,1,-21);
                ZIndex = 2; Parent = boxInner;
            })
            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = container;
            })

            function gb:Resize()
                local sz = 0
                for _,e in next, gb.Container:GetChildren() do
                    if not e:IsA('UIListLayout') and e.Visible then sz = sz + e.Size.Y.Offset end
                end
                boxOuter.Size = UDim2.new(1,0,0,21+sz+4)
            end

            gb.Container = container
            setmetatable(gb, BaseGroupbox)
            gb:AddBlank(3); gb:Resize()
            Tab.Groupboxes[info.Name] = gb
            return gb
        end

        function Tab:AddLeftGroupbox(n)  return Tab:AddGroupbox({ Side=1, Name=n }) end
        function Tab:AddRightGroupbox(n) return Tab:AddGroupbox({ Side=2, Name=n }) end

        function Tab:AddTabbox(info)
            local tbx = { Tabs = {} }

            local boxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor; BorderSizePixel = 0;
                Size = UDim2.new(1,0,0,0); ZIndex = 3;
                Parent = info.Side==1 and leftSide or rightSide;
            })
            Library:Create('UICorner', { CornerRadius = UDim.new(0,5); Parent = boxOuter })
            Library:Create('UIStroke', { Color = Library.OutlineColor; Thickness = 1; Transparency = 0.5; Parent = boxOuter })
            Library:AddToRegistry(boxOuter, { BackgroundColor3 = 'BackgroundColor' })

            local topAccent2 = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor; BorderSizePixel = 0;
                Size = UDim2.new(1,0,0,2); ZIndex = 5; Parent = boxOuter;
            })
            Library:Create('UICorner', { CornerRadius = UDim.new(0,5); Parent = topAccent2 })
            Library:AddToRegistry(topAccent2, { BackgroundColor3 = 'AccentColor' })

            local btnRow = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.fromOffset(0,2); Size = UDim2.new(1,0,0,20);
                ZIndex = 5; Parent = boxOuter;
            })
            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal;
                SortOrder = Enum.SortOrder.LayoutOrder; Parent = btnRow;
            })

            function tbx:AddTab(tabName)
                local t2 = {}

                local btn2 = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor; BorderSizePixel = 0;
                    Size = UDim2.new(0.5,0,1,0); ZIndex = 6; Parent = btnRow;
                })
                Library:Create('UICorner', { CornerRadius = UDim.new(0,4); Parent = btn2 })
                Library:AddToRegistry(btn2, { BackgroundColor3 = 'MainColor' })

                local btn2Lbl = Library:CreateLabel({
                    Size = UDim2.fromScale(1,1); TextSize = 13; Font = Library.Font;
                    Text = tabName; ZIndex = 7; Parent = btn2;
                })

                local block2 = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor; BorderSizePixel = 0;
                    Position = UDim2.new(0,0,1,0); Size = UDim2.new(1,0,0,1);
                    Visible = false; ZIndex = 9; Parent = btn2;
                })
                Library:AddToRegistry(block2, { BackgroundColor3 = 'BackgroundColor' })

                local cont2 = Library:Create('Frame', {
                    BackgroundTransparency = 1;
                    Position = UDim2.fromOffset(4,22);
                    Size = UDim2.new(1,-4,1,-22);
                    ZIndex = 2; Visible = false; Parent = boxOuter;
                })
                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder; Parent = cont2;
                })

                function t2:Show()
                    for _,t3 in next, tbx.Tabs do t3:Hide() end
                    cont2.Visible = true; block2.Visible = true
                    btn2.BackgroundColor3 = Library.BackgroundColor
                    Library.RegistryMap[btn2].Properties.BackgroundColor3 = 'BackgroundColor'
                    btn2Lbl.TextColor3 = Library.AccentColor
                    Library.RegistryMap[btn2Lbl].Properties.TextColor3 = 'AccentColor'
                    t2:Resize()
                end
                function t2:Hide()
                    cont2.Visible = false; block2.Visible = false
                    btn2.BackgroundColor3 = Library.MainColor
                    Library.RegistryMap[btn2].Properties.BackgroundColor3 = 'MainColor'
                    btn2Lbl.TextColor3 = Library.FontColor
                    Library.RegistryMap[btn2Lbl].Properties.TextColor3 = 'FontColor'
                end
                function t2:Resize()
                    local cnt = 0
                    for _ in next, tbx.Tabs do cnt=cnt+1 end
                    for _,b in next, btnRow:GetChildren() do
                        if not b:IsA('UIListLayout') then b.Size = UDim2.new(1/cnt,0,1,0) end
                    end
                    if not cont2.Visible then return end
                    local sz = 0
                    for _,e in next, t2.Container:GetChildren() do
                        if not e:IsA('UIListLayout') and e.Visible then sz=sz+e.Size.Y.Offset end
                    end
                    boxOuter.Size = UDim2.new(1,0,0,22+sz+4)
                end

                btn2.InputBegan:Connect(function(inp)
                    if inp.UserInputType==Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                        t2:Show(); t2:Resize()
                    end
                end)

                t2.Container = cont2
                tbx.Tabs[tabName] = t2
                setmetatable(t2, BaseGroupbox)
                t2:AddBlank(3); t2:Resize()
                if #btnRow:GetChildren()==2 then t2:Show() end
                return t2
            end

            Tab.Tabboxes[info.Name or ''] = tbx
            return tbx
        end

        function Tab:AddLeftTabbox(n)  return Tab:AddTabbox({ Name=n, Side=1 }) end
        function Tab:AddRightTabbox(n) return Tab:AddTabbox({ Name=n, Side=2 }) end

        tabBtn.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 then Tab:ShowTab() end
        end)
        if #tabContainer:GetChildren()==1 then Tab:ShowTab() end

        Window.Tabs[name] = Tab
        return Tab
    end

    -- ── Toggle menu ─────────────────────────────────────────────────────────
    local modal = Library:Create('TextButton', {
        BackgroundTransparency = 1; Size = UDim2.new(0,0,0,0);
        Text = ''; Modal = false; Parent = ScreenGui;
    })

    local transCache = {}
    local toggled, fading = false, false

    function Library:Toggle()
        if fading then return end
        local ft = cfg.MenuFadeTime; fading = true
        toggled = not toggled
        modal.Modal = toggled

        if toggled then
            outer.Visible = true
            -- custom cursor
            task.spawn(function()
                local state = InputService.MouseIconEnabled
                local cur  = Drawing.new('Triangle')
                cur.Thickness = 1; cur.Filled = true; cur.Visible = true
                local curOut = Drawing.new('Triangle')
                curOut.Thickness = 1.5; curOut.Filled = false
                curOut.Color = Color3.new(0,0,0); curOut.Visible = true

                while toggled and ScreenGui.Parent do
                    InputService.MouseIconEnabled = false
                    local mp = InputService:GetMouseLocation()
                    cur.Color = Library.AccentColor
                    cur.PointA  = Vector2.new(mp.X,    mp.Y)
                    cur.PointB  = Vector2.new(mp.X+14, mp.Y+5)
                    cur.PointC  = Vector2.new(mp.X+5,  mp.Y+14)
                    curOut.PointA = cur.PointA; curOut.PointB = cur.PointB; curOut.PointC = cur.PointC
                    RenderStepped:Wait()
                end
                InputService.MouseIconEnabled = state
                cur:Remove(); curOut:Remove()
            end)
        end

        for _,desc in next, outer:GetDescendants() do
            local props = {}
            if desc:IsA('ImageLabel') then
                props = {'ImageTransparency','BackgroundTransparency'}
            elseif desc:IsA('TextLabel') or desc:IsA('TextBox') then
                props = {'TextTransparency'}
            elseif desc:IsA('Frame') or desc:IsA('ScrollingFrame') then
                props = {'BackgroundTransparency'}
            elseif desc:IsA('UIStroke') then
                props = {'Transparency'}
            end

            local cache = transCache[desc] or {}
            transCache[desc] = cache
            for _,p in next, props do
                if not cache[p] then cache[p] = desc[p] end
                if cache[p] == 1 then continue end
                TweenService:Create(desc, TweenInfo.new(ft, Enum.EasingStyle.Linear), { [p] = toggled and cache[p] or 1 }):Play()
            end
        end

        task.wait(ft)
        outer.Visible = toggled
        fading = false
    end

    Library:GiveSignal(InputService.InputBegan:Connect(function(inp, proc)
        if type(Library.ToggleKeybind)=='table' and Library.ToggleKeybind.Type=='KeyPicker' then
            if inp.UserInputType==Enum.UserInputType.Keyboard and inp.KeyCode.Name==Library.ToggleKeybind.Value then
                task.spawn(Library.Toggle)
            end
        elseif inp.KeyCode==Enum.KeyCode.RightControl
            or (inp.KeyCode==Enum.KeyCode.RightShift and not proc) then
            task.spawn(Library.Toggle)
        end
    end))

    if cfg.AutoShow then task.spawn(Library.Toggle) end
    Window.Holder = outer
    return Window
end

-- ─── Player / Team dropdown refresh ──────────────────────────────────────────
local function onPlayerChange()
    local list = GetPlayersString()
    for _,v in next, Options do
        if v.Type=='Dropdown' and v.SpecialType=='Player' then v:SetValues(list) end
    end
end
Players.PlayerAdded:Connect(onPlayerChange)
Players.PlayerRemoving:Connect(onPlayerChange)

-- ══════════════════════════════════════════════════════════════════════════════
-- NEW FEATURES
-- ══════════════════════════════════════════════════════════════════════════════

-- ── Theme presets ─────────────────────────────────────────────────────────────
Library.Themes = {
    Cyber  = { AccentColor = Color3.fromRGB(80,200,255);  SecondAccent = Color3.fromRGB(180,80,255); MainColor = Color3.fromRGB(18,18,30);  BackgroundColor = Color3.fromRGB(11,11,20) };
    Red    = { AccentColor = Color3.fromRGB(255,60,60);   SecondAccent = Color3.fromRGB(255,140,0);  MainColor = Color3.fromRGB(25,12,12);  BackgroundColor = Color3.fromRGB(16,7,7) };
    Green  = { AccentColor = Color3.fromRGB(60,220,120);  SecondAccent = Color3.fromRGB(0,200,80);   MainColor = Color3.fromRGB(12,22,15);  BackgroundColor = Color3.fromRGB(7,14,10) };
    Gold   = { AccentColor = Color3.fromRGB(255,195,30);  SecondAccent = Color3.fromRGB(255,130,0);  MainColor = Color3.fromRGB(22,19,10);  BackgroundColor = Color3.fromRGB(14,12,6) };
    Pink   = { AccentColor = Color3.fromRGB(255,100,180); SecondAccent = Color3.fromRGB(200,60,255); MainColor = Color3.fromRGB(22,12,20);  BackgroundColor = Color3.fromRGB(14,7,13) };
    White  = { AccentColor = Color3.fromRGB(200,200,200); SecondAccent = Color3.fromRGB(160,160,160); MainColor = Color3.fromRGB(230,230,230); BackgroundColor = Color3.fromRGB(245,245,245);
               FontColor   = Color3.fromRGB(30,30,30);    OutlineColor = Color3.fromRGB(190,190,190) };
}

function Library:SetTheme(name)
    local theme = Library.Themes[name]
    if not theme then return Library:Notify('Unknown theme: '..tostring(name), 3, 'warn') end
    for k,v in next, theme do Library[k] = v end
    Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
    Library:UpdateColorsUsingRegistry()
    Library:Notify('Theme changed to '..name, 2, 'success')
end

-- ── Rainbow mode toggle ───────────────────────────────────────────────────────
function Library:SetRainbow(bool)
    Library.RainbowAccent = bool
    if not bool then
        Library.AccentColor = Color3.fromRGB(80,200,255)
        Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
        Library:UpdateColorsUsingRegistry()
    end
end

-- ── Sound toggle ──────────────────────────────────────────────────────────────
function Library:SetSounds(bool)
    Library.SoundEnabled = bool
end

-- ── Global search (find option by idx) ───────────────────────────────────────
function Library:GetOption(idx)
    return Options[idx]
end
function Library:GetToggle(idx)
    return Toggles[idx]
end

-- ── Blur effect ───────────────────────────────────────────────────────────────
function Library:SetBlur(bool)
    Library.BlurEnabled = bool
    local cam = workspace.CurrentCamera
    if bool then
        if not Library._blur then
            Library._blur = Instance.new('BlurEffect')
            Library._blur.Size = 12
            Library._blur.Parent = cam
        end
    else
        if Library._blur then
            Library._blur:Destroy()
            Library._blur = nil
        end
    end
end

getgenv().Library = Library
return Library

-- ══════════════════════════════════════════════════════════════════════════════
-- USAGE EXAMPLE (comment out before using as library)
-- ══════════════════════════════════════════════════════════════════════════════
--[[
local win = Library:CreateWindow({ Title = '✦ NeonUI Demo', AutoShow = true, Center = true })
Library:SetWatermark('NeonUI v2.0 | fps: 60')

local mainTab = win:AddTab('Main')
local leftBox = mainTab:AddLeftGroupbox('Combat')

leftBox:AddToggle('AimAssist', { Text = 'Aim Assist', Default = false, Tooltip = 'Enable aim assist' })
leftBox:AddSlider('AimFOV', { Text = 'FOV', Default = 90, Min = 10, Max = 360, Rounding = 0 })
leftBox:AddDivider()
leftBox:AddButton({ Text = 'Reset settings', Func = function() print('reset!') end })
leftBox:AddProgressBar('Loadout', { Text = 'Loadout Power', Max = 100, Default = 65 })

local rightBox = mainTab:AddRightGroupbox('Visuals')
rightBox:AddToggle('ESP', { Text = 'Player ESP', Default = true })
rightBox:AddColorPicker('ESPColor', { Title = 'ESP Color', Default = Color3.fromRGB(80,200,255) })
rightBox:AddDropdown('Team', { Text = 'Target team', Values = {'Red','Blue','All'}, Default = 'All' })

Library:SetTheme('Cyber')
Library:Notify('NeonUI loaded!', 4, 'success')
]]
