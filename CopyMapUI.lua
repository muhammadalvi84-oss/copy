--[[
    COPY MAP UI  |  BY MHMMDALVI
    Hanya GUI (tampilan + interaksi). Logika copy/import dipasang lewat:
        UI.OnCopy   = function(services, fileName) ... end
        UI.OnImport = function() ... end
        UI.OnScan   = function() ... end   -- opsional
    Update progress dari logika kamu:
        UI.Begin()
        UI.SetProgress(persen, "judul status", "keterangan")
        UI.SetProgress(100, "Selesai", "File tersimpan")
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

---------------------------------------------------------------------
-- THEME
---------------------------------------------------------------------
local T = {
    Window   = Color3.fromRGB(247, 241, 228),
    Panel    = Color3.fromRGB(241, 233, 216),
    Card     = Color3.fromRGB(252, 247, 237),
    Field    = Color3.fromRGB(236, 228, 210),
    Line     = Color3.fromRGB(214, 203, 178),
    Accent   = Color3.fromRGB(255, 184, 28),
    AccentLn = Color3.fromRGB(240, 170, 40),
    Text     = Color3.fromRGB(28, 24, 18),
    Muted    = Color3.fromRGB(135, 125, 108),
    Title    = Color3.fromRGB(176, 92, 200),
    Ok       = Color3.fromRGB(80, 170, 100),
    Bad      = Color3.fromRGB(210, 80, 70),
}

local SERVICES = {
    "Workspace", "Players", "Lighting", "MaterialService",
    "ReplicatedFirst", "ReplicatedStorage", "ServerScriptService", "ServerStorage",
    "StarterGui", "StarterPack", "StarterPlayer", "Teams",
    "SoundService", "Chat", "TextChatService", "LocalizationService",
}

---------------------------------------------------------------------
-- HELPER
---------------------------------------------------------------------
local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    o.Parent = parent
    return o
end

local function corner(p, r)
    return new("UICorner", {CornerRadius = UDim.new(0, r)}, p)
end

local function stroke(p, color, thick, trans)
    return new("UIStroke", {
        Color = color, Thickness = thick or 1, Transparency = trans or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, p)
end

local function label(parent, props)
    local d = {
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "",
    }
    for k, v in pairs(props) do d[k] = v end
    return new("TextLabel", d, parent)
end

local function button(parent, props)
    local d = {
        AutoButtonColor = false, BorderSizePixel = 0,
        Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = T.Text,
        BackgroundColor3 = T.Card, Text = "",
    }
    for k, v in pairs(props) do d[k] = v end
    local b = new("TextButton", d, parent)
    local base = b.BackgroundColor3
    b.MouseEnter:Connect(function()
        if b:GetAttribute("NoHover") then return end
        TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.35)}):Play()
    end)
    b.MouseLeave:Connect(function()
        if b:GetAttribute("NoHover") then return end
        TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = base}):Play()
    end)
    return b
end

local function fmt(n)
    local s = tostring(math.floor(n))
    local out = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
    return (out:gsub("^%.", ""))
end

local function mmss(sec)
    sec = math.max(0, math.floor(sec))
    return string.format("%02d:%02d", sec // 60, sec % 60)
end

---------------------------------------------------------------------
-- PARENT GUI
---------------------------------------------------------------------
local ok, host = pcall(function()
    return (gethui and gethui()) or game:GetService("CoreGui")
end)
if not ok or not host then
    host = Players.LocalPlayer:WaitForChild("PlayerGui")
end
local old = host:FindFirstChild("CopyMapUI")
if old then old:Destroy() end

local UI = {}
local gui = new("ScreenGui", {
    Name = "CopyMapUI", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, host)

local WIN_W, WIN_H = 760, 440
local main = new("Frame", {
    Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(WIN_W, WIN_H),
    BackgroundColor3 = T.Window, BorderSizePixel = 0,
}, gui)
corner(main, 18)
stroke(main, T.Line, 1.5)

local scale = new("UIScale", {}, main)
local function fitScale()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    scale.Scale = math.min(1, (vp.X * 0.94) / WIN_W, (vp.Y * 0.94) / WIN_H)
end
fitScale()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitScale)
end

---------------------------------------------------------------------
-- DRAG
---------------------------------------------------------------------
local function makeDraggable(handle)
    local dragging, startInput, startPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, startInput, startPos = true, i.Position, main.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = (i.Position - startInput) / scale.Scale
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

---------------------------------------------------------------------
-- HEADER
---------------------------------------------------------------------
local header = new("Frame", {
    Name = "Header", Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1,
}, main)
makeDraggable(header)

local logo = new("Frame", {
    Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(26, 22),
    BackgroundColor3 = T.Accent, Rotation = 45, BorderSizePixel = 0,
}, header)
corner(logo, 3)

label(header, {
    Text = "COPY MAP BY MHMMDALVI", Font = Enum.Font.GothamBold, TextSize = 11,
    TextColor3 = T.Title, Position = UDim2.fromOffset(48, 14), Size = UDim2.fromOffset(240, 28),
})

-- tab pill
local pill = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12),
    Size = UDim2.fromOffset(250, 34), BackgroundColor3 = T.Field, BorderSizePixel = 0,
}, header)
corner(pill, 17)
stroke(pill, T.Line, 1)

local tabCopy = button(pill, {
    Text = "COPY MAP", Size = UDim2.new(0.5, -5, 1, -6), Position = UDim2.fromOffset(3, 3),
    BackgroundColor3 = T.Accent, TextSize = 10,
})
corner(tabCopy, 14)
local tabImport = button(pill, {
    Text = "IMPORT MAP", Size = UDim2.new(0.5, -5, 1, -6), Position = UDim2.new(0.5, 2, 0, 3),
    BackgroundColor3 = T.Field, TextColor3 = T.Muted, TextSize = 10,
})
corner(tabImport, 14)

-- tombol kanan
local function roundIcon(text, x)
    local b = button(header, {
        Text = text, Size = UDim2.fromOffset(40, 40), Position = UDim2.new(1, x, 0, 9),
        BackgroundColor3 = T.Panel, TextSize = 16, Font = Enum.Font.GothamBold,
    })
    corner(b, 20)
    stroke(b, T.Line, 1)
    return b
end
local btnClose    = roundIcon("X", -52)
local btnMove     = roundIcon("+", -100)   -- juga bisa dipakai untuk drag
local btnSettings = roundIcon("*", -148)
btnClose.TextSize = 14
makeDraggable(btnMove)
btnClose.MouseButton1Click:Connect(function() gui:Destroy() end)

---------------------------------------------------------------------
-- PAGE: COPY MAP
---------------------------------------------------------------------
local copyPage = new("Frame", {
    Name = "CopyPage", Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 1, -58),
    BackgroundTransparency = 1,
}, main)

-- judul kolom
label(copyPage, {
    Text = "SERVICE STUDIO", Font = Enum.Font.GothamBold, TextSize = 11,
    Position = UDim2.fromOffset(16, 4), Size = UDim2.fromOffset(180, 20),
})
local lblSelected = label(copyPage, {
    Text = "0 dipilih", TextSize = 9, TextColor3 = T.Muted,
    TextXAlignment = Enum.TextXAlignment.Right,
    Position = UDim2.fromOffset(204, 4), Size = UDim2.fromOffset(98, 20),
})
label(copyPage, {
    Text = "COPY MAP", Font = Enum.Font.GothamBold, TextSize = 11,
    Position = UDim2.fromOffset(316, 4), Size = UDim2.fromOffset(120, 20),
})
label(copyPage, {
    Text = "FILE.RBXL  ·  SAMA DENGAN STUDIO", TextSize = 8, TextColor3 = T.Muted,
    TextXAlignment = Enum.TextXAlignment.Right,
    Position = UDim2.fromOffset(436, 4), Size = UDim2.fromOffset(310, 20),
})

-- ===== panel kiri =====
local left = new("Frame", {
    Position = UDim2.fromOffset(14, 30), Size = UDim2.fromOffset(290, 340),
    BackgroundColor3 = T.Panel, BorderSizePixel = 0,
}, copyPage)
corner(left, 14)
stroke(left, T.Line, 1)

local btnRow = new("Frame", {
    Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 0, 32), BackgroundTransparency = 1,
}, left)
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, btnRow)

local function smallBtn(text, order)
    local b = button(btnRow, {
        Text = text, Size = UDim2.new(1 / 3, -6, 1, 0), BackgroundColor3 = T.Field,
        TextSize = 8, LayoutOrder = order,
    })
    corner(b, 10)
    stroke(b, T.Line, 1)
    return b
end
local btnAll   = smallBtn("PILIH SEMUA", 1)
local btnNone  = smallBtn("KOSONGKAN", 2)
local btnScan  = smallBtn("SCAN ULANG", 3)

local list = new("ScrollingFrame", {
    Position = UDim2.fromOffset(8, 52), Size = UDim2.new(1, -16, 1, -60),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
    ScrollBarImageColor3 = T.AccentLn, CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, left)
new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, list)
new("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 4)}, list)

-- ===== panel kanan =====
local stats = new("Frame", {
    Position = UDim2.fromOffset(316, 30), Size = UDim2.fromOffset(430, 112),
    BackgroundColor3 = T.Panel, BorderSizePixel = 0,
}, copyPage)
corner(stats, 14)
stroke(stats, T.Line, 1)

local function statCard(title, x, y)
    local c = new("Frame", {
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(203, 44),
        BackgroundColor3 = T.Field, BorderSizePixel = 0,
    }, stats)
    corner(c, 10)
    stroke(c, T.Line, 1, 0.3)
    label(c, {Text = title, Font = Enum.Font.GothamBold, TextSize = 8, TextColor3 = T.Muted,
        Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 12)})
    return label(c, {Text = "0", Font = Enum.Font.GothamBold, TextSize = 13,
        Position = UDim2.fromOffset(12, 21), Size = UDim2.new(1, -24, 0, 18)})
end
local valService = statCard("SERVICE", 8, 8)
local valItem    = statCard("ITEM", 219, 8)
local valScript  = statCard("SCRIPT", 8, 60)
local valFormat  = statCard("FORMAT", 219, 60)
valFormat.Text = "RBXL  ·  Binary"

-- nama file
local nameBox = new("Frame", {
    Position = UDim2.fromOffset(316, 150), Size = UDim2.fromOffset(430, 62),
    BackgroundColor3 = T.Card, BorderSizePixel = 0,
}, copyPage)
corner(nameBox, 14)
stroke(nameBox, T.Line, 1)
label(nameBox, {Text = "NAMA FILE  ·  OTOMATIS (EXPERIENCE)", Font = Enum.Font.GothamBold, TextSize = 8,
    TextColor3 = T.Muted, Position = UDim2.fromOffset(12, 7), Size = UDim2.fromOffset(250, 12)})
local lblFileOut = label(nameBox, {Text = "Studio Lite.rbxl", TextSize = 8, TextColor3 = T.AccentLn,
    TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.new(1, -172, 0, 7), Size = UDim2.fromOffset(160, 12)})

local nameField = new("Frame", {
    Position = UDim2.fromOffset(10, 26), Size = UDim2.new(1, -20, 0, 28),
    BackgroundColor3 = T.Field, BorderSizePixel = 0,
}, nameBox)
corner(nameField, 8)
stroke(nameField, T.Line, 1)
local nameInput = new("TextBox", {
    Size = UDim2.new(1, -112, 1, 0), Position = UDim2.fromOffset(10, 0),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 10,
    TextColor3 = T.Text, PlaceholderText = "Studio Lite", PlaceholderColor3 = T.Muted,
    Text = "", TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
}, nameField)
local btnAutoName = button(nameField, {
    Text = "NAMA MAP", Size = UDim2.fromOffset(92, 20), AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -4, 0.5, 0), BackgroundColor3 = T.Card, TextSize = 8,
})
corner(btnAutoName, 7)

local function currentFileName()
    local n = nameInput.Text:gsub("[\\/:*?\"<>|]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if n == "" then n = "Studio Lite" end
    return n
end
local function refreshFileLabel()
    lblFileOut.Text = currentFileName() .. ".rbxl"
end
nameInput:GetPropertyChangedSignal("Text"):Connect(refreshFileLabel)
btnAutoName.MouseButton1Click:Connect(function()
    local nm = "Studio Lite"
    pcall(function()
        local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        if info and info.Name then nm = info.Name end
    end)
    nameInput.Text = nm
end)
refreshFileLabel()

-- progress
local progBox = new("Frame", {
    Position = UDim2.fromOffset(316, 220), Size = UDim2.fromOffset(430, 98),
    BackgroundColor3 = T.Card, BorderSizePixel = 0,
}, copyPage)
corner(progBox, 14)
stroke(progBox, T.Line, 1)
local progTitle = label(progBox, {Text = "Siap copy map", Font = Enum.Font.GothamBold, TextSize = 11,
    Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 16)})
local progSub = label(progBox, {Text = "Pilih service lalu tekan COPY MAP", TextSize = 9, TextColor3 = T.Muted,
    Position = UDim2.fromOffset(14, 28), Size = UDim2.new(1, -28, 0, 14)})
local barBg = new("Frame", {
    Position = UDim2.fromOffset(14, 52), Size = UDim2.new(1, -28, 0, 14),
    BackgroundColor3 = T.Field, BorderSizePixel = 0,
}, progBox)
corner(barBg, 7)
stroke(barBg, T.Line, 1)
local barFill = new("Frame", {
    Size = UDim2.fromScale(0, 1), BackgroundColor3 = T.Accent, BorderSizePixel = 0,
}, barBg)
corner(barFill, 7)
local lblPct = label(progBox, {Text = "0%", Font = Enum.Font.GothamBold, TextSize = 9,
    Position = UDim2.fromOffset(14, 74), Size = UDim2.fromOffset(100, 14)})
local lblTime = label(progBox, {Text = "00:00", TextSize = 9, TextColor3 = T.Muted,
    TextXAlignment = Enum.TextXAlignment.Right,
    Position = UDim2.new(1, -114, 0, 74), Size = UDim2.fromOffset(100, 14)})

local btnCopy = button(copyPage, {
    Text = "COPY MAP", Position = UDim2.fromOffset(316, 326), Size = UDim2.fromOffset(430, 44),
    BackgroundColor3 = T.Accent, TextSize = 12,
})
corner(btnCopy, 12)

---------------------------------------------------------------------
-- PAGE: IMPORT MAP
---------------------------------------------------------------------
local importPage = new("Frame", {
    Name = "ImportPage", Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 1, -58),
    BackgroundTransparency = 1, Visible = false,
}, main)
label(importPage, {Text = "IMPORT MAP", Font = Enum.Font.GothamBold, TextSize = 11,
    Position = UDim2.fromOffset(16, 4), Size = UDim2.fromOffset(200, 20)})
local impBox = new("Frame", {
    Position = UDim2.fromOffset(14, 30), Size = UDim2.new(1, -28, 0, 280),
    BackgroundColor3 = T.Panel, BorderSizePixel = 0,
}, importPage)
corner(impBox, 14)
stroke(impBox, T.Line, 1)
label(impBox, {Text = "Pilih file .rbxl dari folder workspace executor", Font = Enum.Font.GothamBold,
    TextSize = 11, TextXAlignment = Enum.TextXAlignment.Center,
    Position = UDim2.new(0, 0, 0.5, -24), Size = UDim2.new(1, 0, 0, 18)})
label(impBox, {Text = "Hubungkan daftar file lewat UI.OnImport", TextSize = 9, TextColor3 = T.Muted,
    TextXAlignment = Enum.TextXAlignment.Center,
    Position = UDim2.new(0, 0, 0.5, -4), Size = UDim2.new(1, 0, 0, 14)})
local btnImport = button(importPage, {
    Text = "IMPORT MAP", Position = UDim2.fromOffset(14, 326), Size = UDim2.new(1, -28, 0, 44),
    BackgroundColor3 = T.Accent, TextSize = 12,
})
corner(btnImport, 12)

local function showTab(name)
    local isCopy = name == "copy"
    copyPage.Visible = isCopy
    importPage.Visible = not isCopy
    tabCopy.BackgroundColor3 = isCopy and T.Accent or T.Field
    tabCopy.TextColor3 = isCopy and T.Text or T.Muted
    tabImport.BackgroundColor3 = isCopy and T.Field or T.Accent
    tabImport.TextColor3 = isCopy and T.Muted or T.Text
    tabCopy:SetAttribute("NoHover", true)
    tabImport:SetAttribute("NoHover", true)
end
tabCopy.MouseButton1Click:Connect(function() showTab("copy") end)
tabImport.MouseButton1Click:Connect(function() showTab("import") end)
showTab("copy")

---------------------------------------------------------------------
-- DAFTAR SERVICE
---------------------------------------------------------------------
local cards, selected, info = {}, {}, {}

local function updateSummary()
    local n, items, scripts = 0, 0, 0
    for _, name in ipairs(SERVICES) do
        if selected[name] then
            n += 1
            local i = info[name]
            if i then items += i.items; scripts += i.scripts end
        end
    end
    lblSelected.Text = n .. " dipilih"
    valService.Text = n .. " / " .. #SERVICES
    valItem.Text = fmt(items)
    valScript.Text = fmt(scripts)
end

local function paintCard(name)
    local c = cards[name]
    if not c then return end
    local on = selected[name]
    TweenService:Create(c.stroke, TweenInfo.new(0.12), {
        Color = on and T.Accent or T.Line, Thickness = on and 1.6 or 1,
    }):Play()
    c.circle.BackgroundColor3 = on and T.Accent or T.Field
    c.dot.Visible = on
end

local function setSelected(name, v)
    selected[name] = v and true or false
    paintCard(name)
    updateSummary()
end

for idx, name in ipairs(SERVICES) do
    local card = new("Frame", {
        Size = UDim2.new(1, 0, 0, 62), BackgroundColor3 = T.Card, BorderSizePixel = 0, LayoutOrder = idx,
    }, list)
    corner(card, 12)
    local st = stroke(card, T.Line, 1)
    label(card, {Text = name, Font = Enum.Font.GothamBold, TextSize = 12,
        Position = UDim2.fromOffset(18, 12), Size = UDim2.new(1, -80, 0, 18)})
    local sub = label(card, {Text = "memindai...", TextSize = 9, TextColor3 = T.Muted,
        Position = UDim2.fromOffset(18, 33), Size = UDim2.new(1, -80, 0, 14)})
    local circle = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(34, 34), BackgroundColor3 = T.Accent, BorderSizePixel = 0,
    }, card)
    corner(circle, 17)
    local dot = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(9, 9), BackgroundColor3 = T.Text, BorderSizePixel = 0,
    }, circle)
    corner(dot, 5)
    local hit = new("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 3,
    }, card)
    hit.MouseButton1Click:Connect(function() setSelected(name, not selected[name]) end)

    cards[name] = {frame = card, stroke = st, sub = sub, circle = circle, dot = dot}
    selected[name] = true
    paintCard(name)
end

local scanning = false
local function scan()
    if scanning then return end
    scanning = true
    for _, name in ipairs(SERVICES) do
        local items, scripts = 0, 0
        local okS, svc = pcall(game.GetService, game, name)
        if okS and svc then
            local okD, desc = pcall(svc.GetDescendants, svc)
            if okD then
                items = #desc
                for _, d in ipairs(desc) do
                    if d:IsA("LuaSourceContainer") then scripts += 1 end
                end
            end
        end
        info[name] = {items = items, scripts = scripts}
        local c = cards[name]
        if c and c.frame.Parent then
            c.sub.Text = items > 0 and (fmt(items) .. " item") or "kosong"
        end
        updateSummary()
        task.wait()
    end
    scanning = false
end

btnAll.MouseButton1Click:Connect(function()
    for _, n in ipairs(SERVICES) do selected[n] = true; paintCard(n) end
    updateSummary()
end)
btnNone.MouseButton1Click:Connect(function()
    for _, n in ipairs(SERVICES) do selected[n] = false; paintCard(n) end
    updateSummary()
end)
btnScan.MouseButton1Click:Connect(function()
    if UI.OnScan then task.spawn(UI.OnScan) end
    task.spawn(scan)
end)

---------------------------------------------------------------------
-- PROGRESS API
---------------------------------------------------------------------
local running, t0 = false, 0

function UI.Begin()
    running, t0 = true, os.clock()
    task.spawn(function()
        while running and gui.Parent do
            lblTime.Text = mmss(os.clock() - t0)
            task.wait(0.25)
        end
    end)
end

function UI.SetProgress(pct, title, sub)
    pct = math.clamp(pct or 0, 0, 100)
    TweenService:Create(barFill, TweenInfo.new(0.2), {Size = UDim2.fromScale(pct / 100, 1)}):Play()
    lblPct.Text = math.floor(pct) .. "%"
    if title then progTitle.Text = title end
    if sub then progSub.Text = sub end
    if pct >= 100 then
        running = false
        lblTime.Text = mmss(os.clock() - t0)
    end
end

function UI.GetSelected()
    local out = {}
    for _, n in ipairs(SERVICES) do
        if selected[n] then table.insert(out, n) end
    end
    return out
end

function UI.GetFileName()
    return currentFileName()
end

---------------------------------------------------------------------
-- TOMBOL AKSI
---------------------------------------------------------------------
btnCopy.MouseButton1Click:Connect(function()
    local picked = UI.GetSelected()
    if #picked == 0 then
        progTitle.Text = "Belum ada service dipilih"
        progSub.Text = "Pilih minimal satu service dulu"
        return
    end
    if not UI.OnCopy then
        progTitle.Text = "Fungsi copy belum dipasang"
        progSub.Text = "Isi UI.OnCopy dengan logika copy kamu"
        return
    end
    UI.SetProgress(0, "Memulai copy...", #picked .. " service dipilih")
    UI.Begin()
    task.spawn(UI.OnCopy, picked, UI.GetFileName())
end)

btnImport.MouseButton1Click:Connect(function()
    if UI.OnImport then task.spawn(UI.OnImport) end
end)

btnSettings.MouseButton1Click:Connect(function()
    -- tempat untuk menu pengaturan kamu
end)

task.spawn(scan)

UI.Gui = gui
return UI
