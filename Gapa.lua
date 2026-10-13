--[[
	NurHub Visual  |  v5.0 MM2  |  универсальный (работает в любых играх Roblox)
	Только визуал: ESP, Chams, Hat, Trails, FOV, стрелки и т.д.
	Без Drawing API: всё на Frame / UIStroke / Highlight / PointLight / Trail.
	Меню: кнопка NH или RightShift. Telegram: https://t.me/NurHuboffical
]]

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local Workspace    = game:GetService("Workspace")
local GuiService   = game:GetService("GuiService")

local LP = Players.LocalPlayer
local WHITE = Color3.new(1, 1, 1)
local TG_LINK = "https://t.me/NurHuboffical"
local ENV = (typeof(getgenv) == "function" and getgenv()) or _G

-- выгружаем прошлый запуск (циклы, ESP, шляпы, трейлы)
if ENV.NurHubMM2Unload then pcall(ENV.NurHubMM2Unload) end

local conns = {}
local function track(c)
	conns[#conns + 1] = c
	return c
end

----------------------------------------------------------------
-- Утилиты
----------------------------------------------------------------
local function mount(gui)
	local ok = pcall(function()
		gui.Parent = (typeof(gethui) == "function" and gethui()) or game:GetService("CoreGui")
	end)
	if not ok or not gui.Parent then
		gui.Parent = LP:WaitForChild("PlayerGui")
	end
end

local function new(class, props, parent)
	local o = Instance.new(class)
	if props then
		for k, v in pairs(props) do o[k] = v end
	end
	if parent then o.Parent = parent end
	return o
end
local function corner(o, r) return new("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function stroke(o, c, th, tr)
	return new("UIStroke", {
		Color = c, Thickness = th or 1, Transparency = tr or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, o)
end
local function tw(o, t, props, style, dir)
	local tween = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end
local orderN = 0
local function ord()
	orderN += 1
	return orderN
end
local function isPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function isMove(i)
	return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

do -- остатки старых запусков
	local roots = { LP:FindFirstChildOfClass("PlayerGui") }
	pcall(function() table.insert(roots, game:GetService("CoreGui")) end)
	pcall(function() if typeof(gethui) == "function" then table.insert(roots, gethui()) end end)
	for _, r in ipairs(roots) do
		for _, n in ipairs({ "NurHubMM2_UI", "NurHubMM2_ESP" }) do
			local o = r and r:FindFirstChild(n)
			if o then pcall(function() o:Destroy() end) end
		end
	end
end

local C = {
	bg     = Color3.fromRGB(13, 13, 19),
	side   = Color3.fromRGB(16, 16, 24),
	card   = Color3.fromRGB(21, 20, 31),
	drawer = Color3.fromRGB(15, 15, 23),
	line   = Color3.fromRGB(38, 36, 54),
	text   = Color3.fromRGB(235, 235, 245),
	sub    = Color3.fromRGB(135, 133, 158),
	off    = Color3.fromRGB(50, 48, 70),
	track  = Color3.fromRGB(34, 33, 50),
	field  = Color3.fromRGB(11, 11, 17),
	accent = Color3.fromRGB(122, 92, 255),
	accent2 = Color3.fromRGB(88, 140, 255),
}

----------------------------------------------------------------
-- НАСТРОЙКИ (одна таблица, UI и ESP читают её напрямую)
----------------------------------------------------------------
local PURPLE = Color3.fromRGB(150, 110, 255)
local CFG = {
	esp     = { on = true, team = false, maxDist = 1500 },
	box2d   = { on = false, color = WHITE },
	corner  = { on = false, color = WHITE, len = 28 },
	fill    = { on = false, c1 = Color3.fromRGB(12, 12, 20), c2 = PURPLE, trans = 0.5 },
	box3d   = { on = false, color = Color3.fromRGB(80, 200, 255) },
	name    = { on = false, color = WHITE },
	dist    = { on = false, color = Color3.fromRGB(190, 190, 210) },
	health  = { on = false, color = Color3.fromRGB(70, 230, 120) },
	chams   = { on = false, color = PURPLE, trans = 0.5 },
	outline = { on = false, color = WHITE },
	glow    = { on = false, color = PURPLE, range = 16, bright = 2 },
	tracer  = { on = false, color = WHITE, origin = "Bottom" },
	skel    = { on = false, color = WHITE },
	head    = { on = false, color = Color3.fromRGB(255, 90, 110) },
	arrows  = { on = false, color = WHITE, radius = 130, size = 14 },
	fov     = { on = false, val = 90 },
	hat     = { on = false, color = Color3.fromRGB(150, 90, 230), trans = 0.4, scope = "Everyone", size = 100 },
	trail   = { on = false, color = Color3.fromRGB(122, 92, 255), len = 1.2, width = 0.8, scope = "Only me" },
}

----------------------------------------------------------------
-- MM2: общие хелперы (роли, аватары, настройки, конфиги)
----------------------------------------------------------------
local X = {
	SET = { lang = "en", scale = 1, trans = 0, accent = C.accent },
	refresh = {}, transReg = {}, lists = {}, hatInfo = {}, DICT = nil,
}
do
	local HttpService = game:GetService("HttpService")

	-- новые поля CFG
	CFG.esp.roles = true
	CFG.pcolor = {}
	CFG.target = { mode = "All", userId = 0 }
	CFG.avatar = { on = false, color = WHITE }
	CFG.wall = { on = false, hid = Color3.fromRGB(255, 60, 60), vis = Color3.fromRGB(70, 255, 110) }
	CFG.fps = { on = false, color = WHITE, custom = false, value = 999, x = 0.02, y = 0.03 }
	CFG.third = { on = false, dist = 12 }
	CFG.steps = { on = false, color = Color3.fromRGB(122, 92, 255), life = 2.5, shape = "Circle", scope = "Only me", dist = 2.4, delay = 0 }
	CFG.gun = { on = false, color = Color3.fromRGB(255, 200, 50), text = true, textColor = WHITE, tracer = false }
	CFG.coin = { on = false, color = Color3.fromRGB(255, 215, 60), text = true, textColor = WHITE }
	CFG.hat.lines = 24
	CFG.hat.rainbow = true
	CFG.hat.fill = false
	CFG.hat.mode = "Lines"
	CFG.hat.shimmer = false
	CFG.xray = { on = false, amount = 0.6 }
	CFG.walk = { on = false, val = 32 }
	CFG.jump = { on = false, val = 90 }
	CFG.spin = { on = false, val = 360 }
	CFG.noclip = { on = false }
	CFG.fly = { on = false, val = 60 }
	CFG.farm = { on = false, fly = 60, delay = 0.3 }
	CFG.shader = { on = false, preset = "4K" }
	CFG.wbright = { on = false, val = 0.1 }
	CFG.wglow = { on = false, int = 1, thr = 0.9 }
	CFG.wdark = { on = false, val = 0.4 }
	CFG.wgrade = { on = false, sat = 0.2, con = 0.1 }
	CFG.wblur = { on = false, val = 8 }
	CFG.wfog = { on = false, val = 0.3 }
	CFG.wrays = { on = false, val = 0.3 }
	CFG.wtime = { on = false, val = 12 }
	CFG.wfull = { on = false }
	CFG.wshadow = { on = false }

	-- файлы (если executor их поддерживает), иначе память
	local DIR = "NurHubMM2"
	local mem = ENV.NurHubMM2Mem or {}
	ENV.NurHubMM2Mem = mem
	local fsOk = typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
	pcall(function()
		if fsOk and typeof(makefolder) == "function" and typeof(isfolder) == "function" and not isfolder(DIR) then
			makefolder(DIR)
		end
	end)
	function X.fsRead(name)
		if fsOk then
			local ok, res = pcall(function()
				if isfile(DIR .. "/" .. name) then return readfile(DIR .. "/" .. name) end
				return nil
			end)
			if ok then return res end
			return nil
		end
		return mem[name]
	end
	function X.fsWrite(name, str)
		if fsOk then
			pcall(writefile, DIR .. "/" .. name, str)
		else
			mem[name] = str
		end
	end
	X.json = HttpService

	function X.saveSettings()
		local s = X.SET
		local a = s.accent
		pcall(function()
			X.fsWrite("settings.json", HttpService:JSONEncode({ lang = s.lang, scale = s.scale, trans = s.trans, accent = { a.R, a.G, a.B } }))
		end)
	end
	do
		local raw = X.fsRead("settings.json")
		if raw then
			local ok, t = pcall(function() return HttpService:JSONDecode(raw) end)
			if ok and type(t) == "table" then
				X.SET.lang = (t.lang == "ru") and "ru" or "en"
				X.SET.scale = math.clamp(tonumber(t.scale) or 1, .5, 1.3)
				X.SET.trans = math.clamp(tonumber(t.trans) or 0, 0, .6)
				if type(t.accent) == "table" and #t.accent == 3 then
					X.SET.accent = Color3.new(t.accent[1], t.accent[2], t.accent[3])
					C.accent = X.SET.accent
					local h, s, v = C.accent:ToHSV()
					C.accent2 = Color3.fromHSV((h + .07) % 1, s * .9, math.clamp(v + .05, 0, 1))
				end
			end
		end
	end

	-- прозрачность меню
	function X.regT(inst)
		X.transReg[#X.transReg + 1] = inst
		inst.BackgroundTransparency = X.SET.trans
	end
	function X.applyTrans()
		for _, i in ipairs(X.transReg) do i.BackgroundTransparency = X.SET.trans end
	end

	-- реестр обновления UI (после загрузки конфига)
	function X.reg(fn) X.refresh[#X.refresh + 1] = fn end
	function X.refreshAll()
		for _, f in ipairs(X.refresh) do pcall(f) end
	end

	X.searchReg, X.pageSF = {}, {}
	function X.regSearch(name, box)
		if X.inDrawer or not X.curTab then return end
		X.searchReg[#X.searchReg + 1] = { name = name, tab = X.curTab, box = box }
	end

	-- перевод
	function X.tr(s)
		local d = X.DICT and X.DICT[s]
		if X.SET.lang == "ru" and d then return d end
		return s
	end

	-- роли MM2 (по инструментам Knife / Gun)
	local function hasTool(plr, n)
		local c, b = plr.Character, plr:FindFirstChild("Backpack")
		return (c and c:FindFirstChild(n)) or (b and b:FindFirstChild(n)) or nil
	end
	function X.roleOf(plr)
		if hasTool(plr, "Knife") then return "Murderer" end
		if hasTool(plr, "Gun") then return "Sheriff" end
		return "Innocent"
	end
	X.ROLE_COL = { Murderer = Color3.fromRGB(255, 70, 70), Sheriff = Color3.fromRGB(70, 140, 255) }

	-- аватары (headshot)
	local avatarCache = {}
	function X.getAvatar(uid, cb)
		if avatarCache[uid] then
			cb(avatarCache[uid])
			return
		end
		task.spawn(function()
			local ok, url = pcall(function()
				return Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			end)
			if ok and url then
				avatarCache[uid] = url
				cb(url)
			end
		end)
	end

	-- цвет-переопределение для текущего игрока в ESP
	X.ov = nil
	function X.cc(c) return X.ov or c end

	-- видимость за стеной
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	function X.visibleTo(char)
		local cam = Workspace.CurrentCamera
		local head = char:FindFirstChild("Head") or char.PrimaryPart
		if not cam or not head then return false end
		rp.FilterDescendantsInstances = { char, LP.Character }
		local o = cam.CFrame.Position
		return Workspace:Raycast(o, head.Position - o, rp) == nil
	end

	-- фильтр «ESP for...»
	function X.passTarget(plr, role)
		local m = CFG.target.mode
		if m == "All" then return true end
		if m == "Murder" then return role == "Murderer" end
		if m == "Sheriff" then return role == "Sheriff" end
		return plr.UserId == CFG.target.userId
	end
end

----------------------------------------------------------------
-- ОКНО: слева основное меню, справа «ESP Editor» (предпросмотр)
----------------------------------------------------------------
local MAIN_W, H, SIDE, PREV_W, GAP = 640, 470, 128, 252, 12
local FULL_W = MAIN_W + GAP + PREV_W

local gui = new("ScreenGui", {
	Name = "NurHubMM2_UI", ResetOnSpawn = false, IgnoreGuiInset = true,
	DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
mount(gui)

local Root = new("Frame", {
	Name = "Root", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
	Size = UDim2.fromOffset(FULL_W, H), BackgroundTransparency = 1, Visible = false,
}, gui)
local fitScale = new("UIScale", { Scale = 1 }, Root)
local Anim = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, Root)
local animScale = new("UIScale", { Scale = .9 }, Anim)

local Main = new("CanvasGroup", {
	Size = UDim2.fromOffset(MAIN_W, H), BackgroundColor3 = C.bg, BorderSizePixel = 0, GroupTransparency = 1,
}, Anim)
corner(Main, 16)
stroke(Main, C.line, 1)

local Preview = new("CanvasGroup", {
	Position = UDim2.fromOffset(MAIN_W + GAP, 0), Size = UDim2.fromOffset(PREV_W, H),
	BackgroundColor3 = C.bg, BorderSizePixel = 0, GroupTransparency = 1, Visible = false,
}, Anim)
corner(Preview, 16)
stroke(Preview, C.line, 1)

-- масштаб под размер экрана (телефон / маленькие окна)
local function fit()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local vs = cam.ViewportSize
	fitScale.Scale = math.clamp(math.min((vs.X - 24) / FULL_W, (vs.Y - 24) / H), 0.35, 1) * X.SET.scale
end
fit()
do
	local cam = Workspace.CurrentCamera
	if cam then track(cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit)) end
end

-- перетаскивание за указанную область (с поправкой на UIScale)
local function makeDraggable(handle, target, onClick, scaleObj)
	local dragging, moved, startMouse, startPos = false, false, nil, nil
	handle.InputBegan:Connect(function(i)
		if isPress(i) then
			dragging, moved = true, false
			startMouse, startPos = i.Position, target.Position
		end
	end)
	track(UIS.InputChanged:Connect(function(i)
		if dragging and isMove(i) then
			local d = i.Position - startMouse
			if d.Magnitude > 5 then moved = true end
			if moved then
				local k = scaleObj and scaleObj.Scale or 1
				target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X / k, startPos.Y.Scale, startPos.Y.Offset + d.Y / k)
			end
		end
	end))
	track(UIS.InputEnded:Connect(function(i)
		if dragging and isPress(i) then
			dragging = false
			if not moved and onClick then onClick() end
		end
	end))
end

-- иконки из Frame
local function Icon(kind, parent, size)
	local box = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
		Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1,
	}, parent)
	new("UIScale", { Scale = (size or 20) / 20 }, box)
	local ss, ff = {}, {}
	local function ring(w, h, x, y, th, rad)
		local f = new("Frame", {
			AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
			BackgroundTransparency = 1, BorderSizePixel = 0,
		}, box)
		corner(f, rad or math.max(w, h) / 2)
		ss[#ss + 1] = stroke(f, WHITE, th or 2)
	end
	local function solid(w, h, x, y, rot, rad)
		local f = new("Frame", {
			AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
			Rotation = rot or 0, BackgroundColor3 = WHITE, BorderSizePixel = 0,
		}, box)
		if rad then corner(f, rad) end
		ff[#ff + 1] = f
	end
	if kind == "eye" then
		ring(18, 12, 10, 10, 2); solid(6, 6, 10, 10, 0, 3)
	elseif kind == "info" then
		ring(16, 16, 10, 10, 2); solid(2, 2, 10, 6, 0, 1); solid(2, 6, 10, 12)
	elseif kind == "user" then
		ring(8, 8, 10, 6, 2); ring(16, 9, 10, 15, 2, 4)
	elseif kind == "globe" then
		ring(17, 17, 10, 10, 2); solid(17, 2, 10, 10); ring(7, 17, 10, 10, 2)
	elseif kind == "grid" then
		solid(7, 7, 5, 5, 0, 2); solid(7, 7, 15, 5, 0, 2); solid(7, 7, 5, 15, 0, 2); solid(7, 7, 15, 15, 0, 2)
	elseif kind == "cfg" then
		ring(17, 17, 10, 10, 2, 4); solid(9, 2, 10, 7); solid(9, 2, 10, 10); solid(9, 2, 10, 13)
	elseif kind == "gear" then
		ring(11, 11, 10, 10, 2); solid(3, 20, 10, 10, 0, 1); solid(20, 3, 10, 10, 0, 1)
	elseif kind == "target" then
		ring(14, 14, 10, 10, 2); solid(2, 5, 10, 2); solid(2, 5, 10, 18); solid(5, 2, 2, 10); solid(5, 2, 18, 10)
	elseif kind == "emote" then
		ring(17, 17, 10, 10, 2); solid(3, 3, 7, 8, 0, 1); solid(3, 3, 13, 8, 0, 1); solid(8, 2, 10, 14, 0, 1)
	end
	local api = {}
	function api.paint(col, t)
		for _, s in ipairs(ss) do tw(s, t or .2, { Color = col }) end
		for _, f in ipairs(ff) do tw(f, t or .2, { BackgroundColor3 = col }) end
	end
	api.paint(C.sub, 0)
	return api
end

local function Arrow(parent, pos)
	local c = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = pos, Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1,
	}, parent)
	for _, d in ipairs({ { 3.5, 45 }, { 8.5, -45 } }) do
		corner(new("Frame", {
			AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(d[1], 6), Size = UDim2.fromOffset(7, 2),
			Rotation = d[2], BackgroundColor3 = C.sub, BorderSizePixel = 0,
		}, c), 1)
	end
	return c
end

-- шапка бокового меню
local Side = new("Frame", { Size = UDim2.new(0, SIDE, 1, 0), BackgroundColor3 = C.side, BorderSizePixel = 0 }, Main)
new("Frame", { Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = C.line, BorderSizePixel = 0 }, Side)
new("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 20), Size = UDim2.new(1, -20, 0, 26),
	Font = Enum.Font.GothamBlack, Text = "NURHUB", TextSize = 21, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left,
}, Side)
new("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 46), Size = UDim2.new(1, -20, 0, 14),
	Font = Enum.Font.GothamMedium, Text = "visual  •  v5.0 MM2", TextSize = 10, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
}, Side)
local dragZone = new("Frame", { Size = UDim2.new(1, 0, 0, 66), BackgroundTransparency = 1 }, Side)
makeDraggable(dragZone, Root, nil, fitScale)
local dragTop = new("Frame", { Position = UDim2.fromOffset(SIDE, 0), Size = UDim2.new(1, -SIDE, 0, 12), BackgroundTransparency = 1 }, Main)
makeDraggable(dragTop, Root, nil, fitScale)

local navList = new("Frame", { Position = UDim2.fromOffset(0, 76), Size = UDim2.new(1, 0, 1, -76), BackgroundTransparency = 1 }, Side)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, navList)
new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, navList)

local Content = new("Frame", {
	Position = UDim2.new(0, SIDE + 14, 0, 14), Size = UDim2.new(1, -(SIDE + 28), 1, -28), BackgroundTransparency = 1,
}, Main)

local tabs, pages, ptok = {}, {}, {}
local current
local onTabChanged

local function paintTab(name, sel, anim)
	local t = tabs[name]
	local d = anim and .22 or 0
	tw(t.btn, d, { BackgroundTransparency = sel and 0 or 1 })
	tw(t.lbl, d, { TextColor3 = sel and WHITE or C.sub })
	t.icon.paint(sel and WHITE or C.sub, d)
end

local function switchTab(name)
	if name == current then return end
	local prev = current
	current = name
	ptok[prev] = (ptok[prev] or 0) + 1
	local my = ptok[prev]
	local old, nxt = pages[prev], pages[name]
	tw(old, .18, { GroupTransparency = 1, Position = UDim2.new(0, 0, 0, -12) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(.2, function()
		if ptok[prev] == my and current ~= prev then old.Visible = false end
	end)
	nxt.Position = UDim2.new(0, 0, 0, 22)
	nxt.GroupTransparency = 1
	nxt.Visible = true
	tw(nxt, .45, { GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 0) })
	for n in pairs(tabs) do paintTab(n, n == name, true) end
	if onTabChanged then onTabChanged(name) end
end

-- страница: заголовок + прокрутка, возвращает ScrollingFrame
local function createTab(name, iconKind, sub)
	local btn = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.accent, BackgroundTransparency = 1,
		BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = ord(),
	}, navList)
	corner(btn, 10)
	new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2), Rotation = 0 }, btn)
	local holder = new("Frame", { Size = UDim2.fromOffset(34, 38), BackgroundTransparency = 1 }, btn)
	local icon = Icon(iconKind, holder, 19)
	local lbl = new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(36, 0), Size = UDim2.new(1, -40, 1, 0),
		Font = Enum.Font.GothamMedium, Text = name, TextSize = 13, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
	}, btn)
	tabs[name] = { btn = btn, lbl = lbl, icon = icon }
	btn.MouseEnter:Connect(function()
		if current ~= name then tw(lbl, .15, { TextColor3 = C.text }); icon.paint(C.text, .15) end
	end)
	btn.MouseLeave:Connect(function()
		if current ~= name then tw(lbl, .15, { TextColor3 = C.sub }); icon.paint(C.sub, .15) end
	end)
	btn.MouseButton1Click:Connect(function() switchTab(name) end)

	local cg = new("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, GroupTransparency = 1 }, Content)
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), Font = Enum.Font.GothamBold, RichText = true,
		TextSize = 16, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
		Text = name .. ' <font color="rgb(135,133,158)">· ' .. sub .. "</font>",
	}, cg)
	local sf = new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 1, -32), BackgroundTransparency = 1, BorderSizePixel = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.accent, ScrollingDirection = Enum.ScrollingDirection.Y,
	}, cg)
	new("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 12), PaddingTop = UDim.new(0, 2) }, sf)
	pages[name] = cg
	X.curTab = name
	X.pageSF[name] = sf
	return sf
end

-- две колонки внутри страницы
local function Columns(sf)
	local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, sf)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12),
		VerticalAlignment = Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder,
	}, holder)
	local function col(o)
		local c = new("Frame", {
			Size = UDim2.new(.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = o,
		}, holder)
		new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }, c)
		return c
	end
	return col(1), col(2)
end

----------------------------------------------------------------
-- Компоненты
----------------------------------------------------------------
local ROW = 28

local function Card(parent, title)
	local outer = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = ord(),
	}, parent)
	new("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, outer)
	if title then
		local t = new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 1, Font = Enum.Font.GothamBold,
			Text = string.upper(title), TextSize = 10, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
		}, outer)
		new("UIPadding", { PaddingLeft = UDim.new(0, 3) }, t)
	end
	local panel = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.card,
		BorderSizePixel = 0, LayoutOrder = 2,
	}, outer)
	corner(panel, 10)
	X.regT(panel)
	stroke(panel, C.line, 1)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
	}, panel)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, panel)
	return panel
end

local function Label(parent, text, color, size)
	return new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.Gotham, TextSize = size or 12, TextColor3 = color or C.sub, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, Text = text, LayoutOrder = ord(),
	}, parent)
end

local function Button(parent, text, cb, fill)
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = fill or C.drawer, BorderSizePixel = 0, AutoButtonColor = false,
		Font = Enum.Font.GothamBold, Text = text, TextSize = 12, TextColor3 = WHITE, LayoutOrder = ord(),
	}, parent)
	corner(b, 9)
	X.regSearch(text, b)
	if not fill then stroke(b, C.line, 1) end
	b.MouseEnter:Connect(function() tw(b, .15, { BackgroundColor3 = fill and fill:Lerp(WHITE, .12) or Color3.fromRGB(30, 29, 44) }) end)
	b.MouseLeave:Connect(function() tw(b, .15, { BackgroundColor3 = fill or C.drawer }) end)
	b.MouseButton1Click:Connect(function() if cb then cb(b) end end)
	return b
end

-- ползунок привязан к полю таблицы (opts.div — делитель, opts.fmt — формат)
local function Slider(parent, title, min, max, tbl, key, opts)
	opts = opts or {}
	local div = opts.div or 1
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, LayoutOrder = ord() }, parent)
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(.62, 0, 0, 16), Font = Enum.Font.GothamMedium, Text = title,
		TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local val = new("TextLabel", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(.38, 0, 0, 16), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.text,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, row)
	local bar = new("Frame", { Position = UDim2.fromOffset(0, 23), Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = C.track, BorderSizePixel = 0 }, row)
	corner(bar, 3)
	local fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, bar)
	corner(fill, 3)
	new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2) }, fill)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(1, 0, .5, 0), Size = UDim2.fromOffset(13, 13),
		BackgroundColor3 = WHITE, BorderSizePixel = 0,
	}, fill)
	corner(knob, 7)
	local hit = new("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 24),
	}, row)

	local function show()
		local v = tbl[key]
		fill.Size = UDim2.new(math.clamp((v * div - min) / (max - min), 0, 1), 0, 1, 0)
		val.Text = opts.fmt and opts.fmt(v) or tostring(v)
	end
	show()
	X.reg(show)
	X.regSearch(title, row)
	local dragging, scroller = false, nil
	local function upd(i)
		local p = math.clamp((i.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		tbl[key] = math.floor(min + (max - min) * p + .5) / div
		show()
	end
	hit.InputBegan:Connect(function(i)
		if isPress(i) then
			dragging = true
			scroller = hit:FindFirstAncestorOfClass("ScrollingFrame")
			if scroller then scroller.ScrollingEnabled = false end
			upd(i)
		end
	end)
	track(UIS.InputChanged:Connect(function(i)
		if dragging and isMove(i) then upd(i) end
	end))
	track(UIS.InputEnded:Connect(function(i)
		if dragging and isPress(i) then
			dragging = false
			if scroller then scroller.ScrollingEnabled = true end
		end
	end))
end

-- HSV-палитра с оттенками: быстрые цвета + Hue / Saturation / Brightness
local QUICK = {
	Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 70, 85), Color3.fromRGB(255, 190, 50),
	Color3.fromRGB(80, 235, 130), Color3.fromRGB(70, 215, 255), Color3.fromRGB(80, 120, 255),
	Color3.fromRGB(170, 100, 255), Color3.fromRGB(255, 100, 200),
}
local function ColorBar(parent, label, onChange)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = ord() }, parent)
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 10), Font = Enum.Font.GothamMedium, Text = label,
		TextSize = 10, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local bar = new("TextButton", {
		Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 8),
		BackgroundColor3 = WHITE, BorderSizePixel = 0,
	}, row)
	corner(bar, 4)
	local grad = new("UIGradient", {}, bar)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(0, 0, .5, 0), Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = WHITE, BorderSizePixel = 0,
	}, bar)
	corner(knob, 6)
	stroke(knob, Color3.fromRGB(18, 18, 24), 2)
	local dragging, scroller = false, nil
	local function upd(i) onChange(math.clamp((i.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)) end
	bar.InputBegan:Connect(function(i)
		if isPress(i) then
			dragging = true
			scroller = bar:FindFirstAncestorOfClass("ScrollingFrame")
			if scroller then scroller.ScrollingEnabled = false end
			upd(i)
		end
	end)
	track(UIS.InputChanged:Connect(function(i) if dragging and isMove(i) then upd(i) end end))
	track(UIS.InputEnded:Connect(function(i)
		if dragging and isPress(i) then
			dragging = false
			if scroller then scroller.ScrollingEnabled = true end
		end
	end))
	return { grad = grad, set = function(a) tw(knob, .06, { Position = UDim2.new(a, 0, .5, 0) }) end }
end

local function ColorPicker(parent, tbl, key)
	local h, s, v = tbl[key]:ToHSV()
	local top = new("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = ord() }, parent)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4),
		VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
	}, top)
	local prev = new("Frame", { Size = UDim2.fromOffset(26, 16), BorderSizePixel = 0, LayoutOrder = 0 }, top)
	corner(prev, 4)
	stroke(prev, Color3.fromRGB(70, 68, 92), 1)
	local hueB, satB, valB
	local function refresh()
		local c = Color3.fromHSV(h, s, v)
		prev.BackgroundColor3 = c
		satB.grad.Color = ColorSequence.new(Color3.fromHSV(h, 0, v), Color3.fromHSV(h, 1, v))
		valB.grad.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.fromHSV(h, s, 1))
		hueB.set(h); satB.set(s); valB.set(v)
		return c
	end
	for i, c in ipairs(QUICK) do
		local b = new("TextButton", {
			Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(14, 14), BackgroundColor3 = c, BorderSizePixel = 0, LayoutOrder = i,
		}, top)
		corner(b, 4)
		stroke(b, Color3.fromRGB(60, 58, 80), 1)
		b.MouseButton1Click:Connect(function()
			h, s, v = c:ToHSV()
			tbl[key] = refresh()
		end)
	end
	hueB = ColorBar(parent, "Hue", function(a) h = math.min(a, .999); tbl[key] = refresh() end)
	satB = ColorBar(parent, "Saturation", function(a) s = a; tbl[key] = refresh() end)
	valB = ColorBar(parent, "Brightness", function(a) v = a; tbl[key] = refresh() end)
	local keys = {}
	for i = 0, 6 do keys[#keys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(math.min(i / 6, .999), 1, 1)) end
	hueB.grad.Color = ColorSequence.new(keys)
	refresh()
	X.reg(function() h, s, v = tbl[key]:ToHSV(); refresh() end)
	return { set = function(c) h, s, v = c:ToHSV(); refresh() end }
end

-- палитра градиентов: готовые пары + два редактируемых цвета
local GRADS = {
	{ Color3.fromRGB(12, 12, 20), Color3.fromRGB(150, 110, 255) },
	{ Color3.fromRGB(255, 80, 100), Color3.fromRGB(255, 190, 70) },
	{ Color3.fromRGB(40, 220, 160), Color3.fromRGB(60, 140, 255) },
	{ Color3.fromRGB(255, 255, 255), Color3.fromRGB(70, 70, 90) },
	{ Color3.fromRGB(255, 100, 200), Color3.fromRGB(110, 90, 255) },
	{ Color3.fromRGB(0, 0, 0), Color3.fromRGB(230, 230, 240) },
}
local function GradientPicker(parent, tbl, k1, k2)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = ord() }, parent)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5),
		VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	X.FLabel(parent, "Top color")
	local p1 = ColorPicker(parent, tbl, k1)
	X.FLabel(parent, "Bottom color")
	local p2 = ColorPicker(parent, tbl, k2)
	for i, g in ipairs(GRADS) do
		local b = new("TextButton", {
			Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(24, 20), BackgroundColor3 = WHITE,
			BorderSizePixel = 0, LayoutOrder = i,
		}, row)
		corner(b, 5)
		stroke(b, Color3.fromRGB(60, 58, 80), 1)
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(g[1], g[2]) }, b)
		b.MouseButton1Click:Connect(function()
			tbl[k1], tbl[k2] = g[1], g[2]
			p1.set(g[1]); p2.set(g[2])
		end)
	end
end

-- выпадающий список (раскрывается внутри панели)
local function Dropdown(parent, title, list, tbl, key)
	local IT, GAPY = 22, 2
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = ord(),
	}, parent)
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), Font = Enum.Font.GothamMedium, Text = title,
		TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
	}, holder)
	local head = new("TextButton", {
		Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = C.field, BorderSizePixel = 0,
		AutoButtonColor = false, Text = "",
	}, holder)
	corner(head, 6)
	stroke(head, C.line, 1)
	local curLbl = new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -34, 1, 0),
		Font = Enum.Font.GothamMedium, Text = tbl[key], TextSize = 12, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
	}, head)
	local arrow = Arrow(head, UDim2.new(1, -14, .5, 0))
	local listH = #list * IT + (#list - 1) * GAPY + 8
	local box = new("Frame", {
		Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, listH), BackgroundColor3 = C.field, BorderSizePixel = 0,
	}, holder)
	corner(box, 6)
	stroke(box, C.line, 1)
	new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, box)
	new("UIListLayout", { Padding = UDim.new(0, GAPY), SortOrder = Enum.SortOrder.LayoutOrder }, box)
	local btns, open = {}, false
	local function render()
		curLbl.Text = tbl[key]
		for n, b in pairs(btns) do b.TextColor3 = (n == tbl[key]) and WHITE or C.sub end
	end
	local function setOpen(v)
		open = v
		tw(holder, .25, { Size = UDim2.new(1, 0, 0, v and (46 + listH) or 44) })
		tw(arrow, .25, { Rotation = v and 180 or 0 })
	end
	for i, n in ipairs(list) do
		local b = new("TextButton", {
			Size = UDim2.new(1, 0, 0, IT), BackgroundColor3 = C.accent, BackgroundTransparency = 1, AutoButtonColor = false,
			Text = n, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0, LayoutOrder = i,
		}, box)
		corner(b, 5)
		new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, b)
		btns[n] = b
		b.MouseEnter:Connect(function() tw(b, .12, { BackgroundTransparency = .75 }) end)
		b.MouseLeave:Connect(function() tw(b, .12, { BackgroundTransparency = 1 }) end)
		b.MouseButton1Click:Connect(function()
			tbl[key] = n
			render()
			setOpen(false)
		end)
	end
	head.MouseButton1Click:Connect(function() setOpen(not open) end)
	render()
	X.reg(render)
end

-- шторка с прокруткой внутри (если настроек много)
X.attachDrawer = function(box, head, arrowPos, builder)
	local arrow = Arrow(head, arrowPos)
	local drawer = new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, ROW + 6), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = C.drawer,
		BorderSizePixel = 0, CanvasSize = UDim2.new(), ScrollBarThickness = 4, ScrollBarImageColor3 = C.accent,
		ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never,
	}, box)
	corner(drawer, 8)
	stroke(drawer, C.line, 1)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, drawer)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12),
	}, drawer)
	local open = false
	local function calc()
		local h, n = 0, 0
		for _, c in ipairs(drawer:GetChildren()) do
			if c:IsA("GuiObject") and c.Visible then
				h += c.Size.Y.Offset
				n += 1
			end
		end
		local ch = h + math.max(n - 1, 0) * 8 + 18
		local vh = math.min(ch, 210)
		drawer.CanvasSize = UDim2.fromOffset(0, ch)
		drawer.Size = UDim2.new(1, 0, 0, vh)
		return ROW + 6 + vh + 2
	end
	local function resize()
		local target = calc()
		if open then tw(box, .22, { Size = UDim2.new(1, 0, 0, target) }) end
	end
	local function hook(c)
		if c:IsA("GuiObject") then
			c:GetPropertyChangedSignal("Size"):Connect(resize)
			c:GetPropertyChangedSignal("Visible"):Connect(resize)
		end
	end
	local pv = X.inDrawer
	X.inDrawer = true
	builder(drawer)
	X.inDrawer = pv
	for _, c in ipairs(drawer:GetChildren()) do hook(c) end
	drawer.ChildAdded:Connect(function(c) hook(c); resize() end)
	head.MouseButton1Click:Connect(function()
		open = not open
		local target = calc()
		tw(box, .35, { Size = UDim2.new(1, 0, 0, open and target or ROW) })
		tw(arrow, .28, { Rotation = open and 180 or 0 })
	end)
end

-- переключатель привязан к tbl[key]; со стрелкой и шторкой, если есть builder(drawer)
local function Toggle(parent, title, tbl, key, builder)
	local box = new("Frame", {
		Size = UDim2.new(1, 0, 0, ROW), BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = ord(),
	}, parent)
	local head = new("TextButton", { Size = UDim2.new(1, 0, 0, ROW), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, box)
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, -90, 1, 0), Font = Enum.Font.GothamMedium, Text = title,
		TextSize = 13, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, head)
	local sw = new("TextButton", {
		AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, 0, 0, ROW / 2), Size = UDim2.fromOffset(36, 18),
		BorderSizePixel = 0, AutoButtonColor = false, Text = "", BackgroundColor3 = C.off,
	}, box)
	corner(sw, 9)
	local swGrad = new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2), Enabled = false }, sw)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0, .5), Size = UDim2.fromOffset(12, 12), Position = UDim2.new(0, 3, .5, 0),
		BackgroundColor3 = WHITE, BorderSizePixel = 0,
	}, sw)
	corner(knob, 6)
	local function paint(anim)
		local on = tbl[key]
		local d = anim and .2 or 0
		swGrad.Enabled = on
		tw(sw, d, { BackgroundColor3 = on and WHITE or C.off })
		tw(knob, d, { Position = on and UDim2.new(1, -15, .5, 0) or UDim2.new(0, 3, .5, 0) }, Enum.EasingStyle.Back)
	end
	paint(false)
	X.reg(function() paint(true) end)
	X.regSearch(title, box)
	sw.MouseButton1Click:Connect(function()
		tbl[key] = not tbl[key]
		paint(true)
	end)

	if builder then
		X.attachDrawer(box, head, UDim2.new(1, -52, .5, 0), builder)
	else
		head.MouseButton1Click:Connect(function()
			tbl[key] = not tbl[key]
			paint(true)
		end)
	end
end

-- строка-шторка без переключателя
X.DrawerRow = function(parent, title, builder)
	local box = new("Frame", {
		Size = UDim2.new(1, 0, 0, ROW), BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = ord(),
	}, parent)
	local head = new("TextButton", { Size = UDim2.new(1, 0, 0, ROW), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, box)
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, -30, 1, 0), Font = Enum.Font.GothamMedium, Text = title,
		TextSize = 13, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
	}, head)
	X.regSearch(title, box)
	X.attachDrawer(box, head, UDim2.new(1, -10, .5, 0), builder)
end

-- маленькая подпись фиксированной высоты (для шторок)
X.FLabel = function(parent, text)
	return new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 12), Font = Enum.Font.GothamMedium, Text = text,
		TextSize = 10, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = ord(),
	}, parent)
end

-- сетка кнопок-вариантов (шейдеры и т.п.)
X.Grid = function(parent, list, get, set, cols)
	cols = cols or 2
	local rows = math.ceil(#list / cols)
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, rows * 24 + (rows - 1) * 4), BackgroundTransparency = 1, LayoutOrder = ord(),
	}, parent)
	new("UIGridLayout", {
		CellSize = UDim2.new(1 / cols, -4 * (cols - 1) / cols - 1, 0, 24), CellPadding = UDim2.fromOffset(4, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, holder)
	local btns = {}
	local function render()
		for n, b in pairs(btns) do
			local on = get() == n
			tw(b, .2, { BackgroundColor3 = on and C.accent or C.field, TextColor3 = on and WHITE or C.sub })
		end
	end
	for i, n in ipairs(list) do
		local b = new("TextButton", {
			Text = n, AutoButtonColor = false, Font = Enum.Font.GothamMedium, TextSize = 11, BorderSizePixel = 0,
			BackgroundColor3 = C.field, TextColor3 = C.sub, LayoutOrder = i,
		}, holder)
		corner(b, 6)
		btns[n] = b
		b.MouseButton1Click:Connect(function()
			set(n)
			render()
		end)
	end
	X.reg(render)
	render()
end

-- список игроков с аватаром и ником (ник шерифа синий, убийцы красный)
X.PlayerList = function(parent, height, onPick, withColor, isSel, ctbl)
	ctbl = ctbl or CFG.pcolor
	local sf = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = C.field, BorderSizePixel = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent,
		ScrollingDirection = Enum.ScrollingDirection.Y, LayoutOrder = ord(),
	}, parent)
	corner(sf, 8)
	stroke(sf, C.line, 1)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, sf)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 6),
	}, sf)
	local rows = {}
	local function rebuild()
		for _, r in pairs(rows) do r.f:Destroy() end
		rows = {}
		local i = 0
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LP then
				i += 1
				local f = new("TextButton", {
					Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.card, BorderSizePixel = 0, AutoButtonColor = false,
					Text = "", LayoutOrder = i,
				}, sf)
				corner(f, 8)
				local st = stroke(f, C.accent, 1.5, 1)
				local av = new("Frame", { Position = UDim2.fromOffset(6, 4), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = C.field, BorderSizePixel = 0 }, f)
				corner(av, 14)
				local img = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, av)
				corner(img, 14)
				X.getAvatar(plr.UserId, function(u) if img.Parent then img.Image = u end end)
				local nm = new("TextLabel", {
					BackgroundTransparency = 1, Position = UDim2.fromOffset(42, 0),
					Size = UDim2.new(1, -(withColor and 78 or 50), 1, 0), Font = Enum.Font.GothamMedium, TextSize = 12,
					TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
					Text = plr.DisplayName,
				}, f)
				local sw
				if withColor then
					sw = new("TextButton", {
						AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -6, .5, 0), Size = UDim2.fromOffset(22, 22),
						BorderSizePixel = 0, AutoButtonColor = false, Text = "", BackgroundColor3 = C.off,
					}, f)
					corner(sw, 11)
					stroke(sw, C.line, 1)
					sw.MouseButton1Click:Connect(function()
						local cur = ctbl[plr.UserId]
						local idx = 0
						for k, q in ipairs(QUICK) do
							if cur == q then idx = k end
						end
						idx += 1
						ctbl[plr.UserId] = QUICK[idx] -- после последнего цвета: сброс (nil)
					end)
				end
				f.MouseButton1Click:Connect(function() onPick(plr) end)
				rows[plr] = { f = f, nm = nm, st = st, sw = sw }
			end
		end
	end
	local function upd()
		for plr, r in pairs(rows) do
			r.nm.TextColor3 = X.ROLE_COL[X.roleOf(plr)] or C.text
			r.st.Transparency = (isSel and isSel(plr)) and 0 or 1
			if r.sw then r.sw.BackgroundColor3 = ctbl[plr.UserId] or C.off end
		end
	end
	rebuild()
	upd()
	X.lists[#X.lists + 1] = { rebuild = rebuild, upd = upd, frame = sf }
end

----------------------------------------------------------------
-- Рисование линий / стрелок (общее для ESP и превью)
----------------------------------------------------------------
local function mkLine(parent)
	return new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), BorderSizePixel = 0, BackgroundColor3 = WHITE,
		Visible = false, Size = UDim2.fromOffset(0, 1),
	}, parent)
end
local function setLine(f, a, b, col, th)
	local d = b - a
	f.Size = UDim2.fromOffset(d.Magnitude, th)
	f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
	f.Rotation = math.deg(math.atan2(d.Y, d.X))
	f.BackgroundColor3 = col
	f.Visible = true
end
local function hideList(l) if l then for _, f in ipairs(l) do f.Visible = false end end end

-- стрелка-указатель: цветной наконечник + белый хвост (из ровных срезов, без артефактов)
local function mkArrow(parent)
	local c = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(34, 28), BackgroundTransparency = 1, Visible = false,
	}, parent)
	local sc = new("UIScale", { Scale = 1 }, c)
	local N = 10
	local function tri(x0, w, h, col, tr, dx)
		local list = {}
		for i = 0, N - 1 do
			local fh = math.max(1, h * (1 - i / N))
			list[#list + 1] = new("Frame", {
				AnchorPoint = Vector2.new(0, .5), Position = UDim2.fromOffset(x0 + i * (w / N) + dx, 14 + dx),
				Size = UDim2.fromOffset(w / N + .7, fh), BackgroundColor3 = col, BackgroundTransparency = tr, BorderSizePixel = 0,
			}, c)
		end
		return list
	end
	local sh1, sh2 = tri(17, 16, 26, Color3.new(0, 0, 0), .55, 1), tri(2, 10, 16, Color3.new(0, 0, 0), .55, 1)
	local head, tail = tri(17, 16, 26, WHITE, 0, 0), tri(2, 10, 16, WHITE, 0, 0)
	return { frame = c, scale = sc, head = head, tail = tail, sh1 = sh1, sh2 = sh2 }
end
local function paintArrow(a, col, size, tailCol)
	for _, f in ipairs(a.head) do f.BackgroundColor3 = col end
	for _, f in ipairs(a.tail) do f.BackgroundColor3 = tailCol or WHITE end
	a.scale.Scale = size / 24
end

----------------------------------------------------------------
-- ESP слой (экранные Frame, без Drawing)
----------------------------------------------------------------
local espGui = new("ScreenGui", {
	Name = "NurHubMM2_ESP", ResetOnSpawn = false, IgnoreGuiInset = true,
	DisplayOrder = 50, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
mount(espGui)

local TH = 1.5
local function mkBox()
	return new("Frame", { BorderSizePixel = 0, BackgroundColor3 = WHITE, Visible = false }, espGui)
end
local function mkText()
	return new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromOffset(220, 14), Font = Enum.Font.GothamBold, TextSize = 11, TextScaled = false,
		TextStrokeTransparency = .35, TextStrokeColor3 = Color3.new(0, 0, 0), Visible = false,
	}, espGui)
end

local R15 = {
	{ "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}
local R6 = {
	{ "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
	{ "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}
local EDGES = {}
for i = 0, 7 do
	for _, b in ipairs({ 1, 2, 4 }) do
		if bit32.band(i, b) == 0 then EDGES[#EDGES + 1] = { i, i + b } end
	end
end

local S = {}
local function hideAll(d)
	for _, v in pairs(d) do
		if typeof(v) == "Instance" then
			if v:IsA("GuiObject") then
				v.Visible = false
			elseif v:IsA("Highlight") or v:IsA("Light") then
				v.Enabled = false
			end
		elseif type(v) == "table" then
			for _, f in ipairs(v) do
				if typeof(f) == "Instance" and f:IsA("GuiObject") then f.Visible = false end
			end
		end
	end
end
local function destroyData(d)
	for _, v in pairs(d) do
		if typeof(v) == "Instance" then
			pcall(function() v:Destroy() end)
		elseif type(v) == "table" then
			for _, x in ipairs(v) do
				if typeof(x) == "Instance" then pcall(function() x:Destroy() end) end
			end
		end
	end
end

local function setCorners(list, x0, y0, x1, y1, l, t, col)
	local spec = {
		{ x0, y0, l, t }, { x0, y0, t, l },
		{ x1 - l, y0, l, t }, { x1 - t, y0, t, l },
		{ x0, y1 - t, l, t }, { x0, y1 - l, t, l },
		{ x1 - l, y1 - t, l, t }, { x1 - t, y1 - l, t, l },
	}
	for i, s in ipairs(spec) do
		local f = list[i]
		f.Position = UDim2.fromOffset(s[1], s[2])
		f.Size = UDim2.fromOffset(s[3], s[4])
		f.BackgroundColor3 = col
		f.Visible = true
	end
end

local function drawPlayer(d, plr, char, hum, root, cam, vs)
	-- Chams + Outline (Highlight)
	if CFG.chams.on or CFG.outline.on or CFG.wall.on then
		local hl = d.hl
		if not hl then
			hl = new("Highlight", { DepthMode = Enum.HighlightDepthMode.AlwaysOnTop }, espGui)
			d.hl = hl
		end
		hl.Adornee = char
		local fc, oc = X.cc(CFG.chams.color), X.cc(CFG.outline.color)
		if CFG.wall.on then
			local c2 = X.visibleTo(char) and CFG.wall.vis or CFG.wall.hid
			fc, oc = c2, c2
		end
		hl.FillColor = fc
		hl.FillTransparency = CFG.chams.on and CFG.chams.trans or 1
		hl.OutlineColor = oc
		hl.OutlineTransparency = (CFG.outline.on or CFG.wall.on) and 0 or 1
		hl.Enabled = true
	elseif d.hl then
		d.hl.Enabled = false
	end

	-- Glow (PointLight)
	if CFG.glow.on then
		local l = d.light
		if not l or l.Parent ~= root then
			if l then l:Destroy() end
			l = new("PointLight", { Shadows = false }, root)
			d.light = l
		end
		l.Color = CFG.glow.color
		l.Range = CFG.glow.range
		l.Brightness = CFG.glow.bright
		l.Enabled = true
	elseif d.light then
		d.light.Enabled = false
	end

	-- Стрелки (враг вне экрана)
	local rp = cam:WorldToViewportPoint(root.Position)
	local off = rp.Z <= 0 or rp.X < 0 or rp.X > vs.X or rp.Y < 0 or rp.Y > vs.Y
	if CFG.arrows.on and off then
		local a = d.arrow
		if not a then
			a = mkArrow(espGui)
			d.arrow = a
			d.arrowF = a.frame
		end
		local center = vs / 2
		local dir
		if rp.Z > 0 then
			dir = Vector2.new(rp.X, rp.Y) - center
		else
			local v = cam.CFrame:PointToObjectSpace(root.Position)
			dir = Vector2.new(v.X, -v.Y)
		end
		if dir.Magnitude < 1e-3 then dir = Vector2.new(0, 1) end
		dir = dir.Unit
		local R = math.min(CFG.arrows.radius, math.min(vs.X, vs.Y) / 2 - 24)
		local pos = center + dir * R
		a.frame.Position = UDim2.fromOffset(pos.X, pos.Y)
		a.frame.Rotation = math.deg(math.atan2(dir.Y, dir.X))
		local rl = X.roleOf(plr)
		local acol = CFG.acolor[plr.UserId] or (rl == "Murderer" and CFG.arrows.murder) or (rl == "Sheriff" and CFG.arrows.sheriff) or CFG.arrows.color
		paintArrow(a, acol, CFG.arrows.size, WHITE)
		a.frame.Visible = true
	elseif d.arrowF then
		d.arrowF.Visible = false
	end

	-- Границы персонажа
	local needBox = CFG.box2d.on or CFG.corner.on or CFG.fill.on or CFG.box3d.on or CFG.name.on or CFG.dist.on or CFG.health.on
	local pts, allFront
	local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
	if needBox then
		local cf = root.CFrame * CFrame.new(0, -0.25, 0)
		local hs = Vector3.new(2, 2.95, 1)
		pts, allFront = {}, true
		for i = 0, 7 do
			local x = (i % 2) * 2 - 1
			local y = (math.floor(i / 2) % 2) * 2 - 1
			local z = math.floor(i / 4) * 2 - 1
			local p = cam:WorldToViewportPoint(cf:PointToWorldSpace(Vector3.new(x * hs.X, y * hs.Y, z * hs.Z)))
			pts[i] = p
			if p.Z <= 0 then
				allFront = false
			else
				x0 = math.min(x0, p.X); y0 = math.min(y0, p.Y)
				x1 = math.max(x1, p.X); y1 = math.max(y1, p.Y)
			end
		end
		if allFront then
			local tp = cam:WorldToViewportPoint(root.Position + Vector3.new(0, 2.7, 0))
			local bp = cam:WorldToViewportPoint(root.Position - Vector3.new(0, 3.2, 0))
			if tp.Z > 0 and bp.Z > 0 then
				local hgt = math.abs(bp.Y - tp.Y)
				local cx = (tp.X + bp.X) / 2
				x0, x1 = cx - hgt * .28, cx + hgt * .28
				y0, y1 = math.min(tp.Y, bp.Y), math.max(tp.Y, bp.Y)
			end
		end
	end
	local rect = pts ~= nil and allFront

	-- заливка (градиент)
	if CFG.fill.on and rect then
		local f = d.fill
		if not f then
			f = mkBox()
			d.fill = f
			d.fillG = new("UIGradient", { Rotation = 90 }, f)
		end
		f.Position = UDim2.fromOffset(x0, y0)
		f.Size = UDim2.fromOffset(x1 - x0, y1 - y0)
		f.BackgroundTransparency = CFG.fill.trans
		d.fillG.Color = ColorSequence.new(CFG.fill.c1, CFG.fill.c2)
		f.Visible = true
	elseif d.fill then
		d.fill.Visible = false
	end

	-- Box 2D
	if CFG.box2d.on and rect then
		local b = d.box
		if not b then
			b = new("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, espGui)
			d.box = b
			d.boxS = new("UIStroke", { Thickness = TH, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
		end
		b.Position = UDim2.fromOffset(x0, y0)
		b.Size = UDim2.fromOffset(x1 - x0, y1 - y0)
		d.boxS.Color = X.cc(CFG.box2d.color)
		b.Visible = true
	elseif d.box then
		d.box.Visible = false
	end

	-- Углы бокса
	if CFG.corner.on and rect then
		if not d.cn then
			d.cn = {}
			for i = 1, 8 do d.cn[i] = mkBox() end
		end
		local l = math.min(CFG.corner.len, (x1 - x0) / 2, (y1 - y0) / 2)
		setCorners(d.cn, x0, y0, x1, y1, l, 2, X.cc(CFG.corner.color))
	else
		hideList(d.cn)
	end

	-- Box 3D
	if CFG.box3d.on and pts then
		if not d.e3 then
			d.e3 = {}
			for i = 1, 12 do d.e3[i] = mkLine(espGui) end
		end
		for i, e in ipairs(EDGES) do
			local a, b = pts[e[1]], pts[e[2]]
			if a.Z > 0 and b.Z > 0 then
				setLine(d.e3[i], Vector2.new(a.X, a.Y), Vector2.new(b.X, b.Y), X.cc(CFG.box3d.color), TH)
			else
				d.e3[i].Visible = false
			end
		end
	else
		hideList(d.e3)
	end

	-- Ник
	if CFG.name.on and rect then
		local t = d.name
		if not t then t = mkText(); d.name = t end
		t.AnchorPoint = Vector2.new(.5, 1)
		t.Position = UDim2.fromOffset((x0 + x1) / 2, y0 - 2)
		t.Text = plr.DisplayName
		t.TextColor3 = CFG.name.color
		t.Visible = true
	elseif d.name then
		d.name.Visible = false
	end

	-- Аватар (круг с аватаркой рядом с игроком)
	if CFG.avatar.on and rect then
		local a = d.av
		if not a then
			a = new("Frame", { AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = Color3.fromRGB(20, 20, 30), BorderSizePixel = 0, Visible = false }, espGui)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, a)
			d.avS = new("UIStroke", { Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, a)
			local img = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, a)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, img)
			d.av = a
			X.getAvatar(plr.UserId, function(u) if img.Parent then img.Image = u end end)
		end
		a.Position = UDim2.fromOffset(x0 - 9, y0)
		d.avS.Color = X.cc(CFG.avatar.color)
		a.Visible = true
	elseif d.av then
		d.av.Visible = false
	end

	-- Дистанция
	if CFG.dist.on and rect then
		local t = d.dist
		if not t then t = mkText(); d.dist = t end
		t.AnchorPoint = Vector2.new(.5, 0)
		t.Position = UDim2.fromOffset((x0 + x1) / 2, y1 + 2)
		t.Text = math.floor((cam.CFrame.Position - root.Position).Magnitude) .. "m"
		t.TextColor3 = CFG.dist.color
		t.Visible = true
	elseif d.dist then
		d.dist.Visible = false
	end

	-- Здоровье
	if CFG.health.on and rect then
		local bg = d.hpBg
		if not bg then
			bg = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = .35, BorderSizePixel = 0, Visible = false }, espGui)
			d.hpBg = bg
			d.hpFill = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, bg)
		end
		local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		bg.Position = UDim2.fromOffset(x0 - 5, y0)
		bg.Size = UDim2.fromOffset(2, y1 - y0)
		d.hpFill.Size = UDim2.fromScale(1, frac)
		d.hpFill.BackgroundColor3 = CFG.health.color
		bg.Visible = true
	elseif d.hpBg then
		d.hpBg.Visible = false
	end

	-- Голова (кольцо)
	local head = char:FindFirstChild("Head")
	if CFG.head.on and head then
		local hp = cam:WorldToViewportPoint(head.Position)
		if hp.Z > 0 then
			local up = cam.CFrame.UpVector * (head.Size.Y / 2)
			local pt = cam:WorldToViewportPoint(head.Position + up)
			local pb = cam:WorldToViewportPoint(head.Position - up)
			local diam = math.max(6, math.abs(pt.Y - pb.Y))
			local r = d.ring
			if not r then
				r = new("Frame", { AnchorPoint = Vector2.new(.5, .5), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, espGui)
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, r)
				d.ringS = new("UIStroke", { Thickness = TH, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, r)
				d.ring = r
			end
			r.Position = UDim2.fromOffset(hp.X, hp.Y)
			r.Size = UDim2.fromOffset(diam, diam)
			d.ringS.Color = X.cc(CFG.head.color)
			r.Visible = true
		elseif d.ring then
			d.ring.Visible = false
		end
	elseif d.ring then
		d.ring.Visible = false
	end

	-- Skeleton
	if CFG.skel.on then
		local list = hum.RigType == Enum.HumanoidRigType.R15 and R15 or R6
		if not d.sk then
			d.sk = {}
			for i = 1, 14 do d.sk[i] = mkLine(espGui) end
		end
		for i = 1, 14 do
			local pr, line = list[i], d.sk[i]
			if pr then
				local a, b = char:FindFirstChild(pr[1]), char:FindFirstChild(pr[2])
				if a and b then
					local pa = cam:WorldToViewportPoint(a.Position)
					local pb = cam:WorldToViewportPoint(b.Position)
					if pa.Z > 0 and pb.Z > 0 then
						setLine(line, Vector2.new(pa.X, pa.Y), Vector2.new(pb.X, pb.Y), X.cc(CFG.skel.color), TH)
					else
						line.Visible = false
					end
				else
					line.Visible = false
				end
			else
				line.Visible = false
			end
		end
	else
		hideList(d.sk)
	end

	-- Tracers
	if CFG.tracer.on and rp.Z > 0 then
		local o = Vector2.new(vs.X / 2, vs.Y)
		if CFG.tracer.origin == "Top" then
			o = Vector2.new(vs.X / 2, 0)
		elseif CFG.tracer.origin == "Crosshair" then
			o = Vector2.new(vs.X / 2, vs.Y / 2)
		end
		if not d.tr then d.tr = mkLine(espGui) end
		setLine(d.tr, o, Vector2.new(rp.X, rp.Y), X.cc(CFG.tracer.color), TH)
	elseif d.tr then
		d.tr.Visible = false
	end
end

local function inTeam(plr)
	return CFG.esp.team and LP.Team ~= nil and plr.Team == LP.Team
end

track(RunService.RenderStepped:Connect(function()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local vs = cam.ViewportSize
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP then
			local d = S[plr]
			if not d then d = {}; S[plr] = d end
			local char = plr.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
			local role = X.roleOf(plr)
			if not CFG.esp.on or not hum or not root or hum.Health <= 0
				or (cam.CFrame.Position - root.Position).Magnitude > CFG.esp.maxDist or inTeam(plr) or not X.passTarget(plr, role) then
				hideAll(d)
			else
				X.ov = CFG.pcolor[plr.UserId] or (CFG.esp.roles and X.ROLE_COL[role]) or nil
				drawPlayer(d, plr, char, hum, root, cam, vs)
				X.ov = nil
			end
		end
	end
end))

----------------------------------------------------------------
-- HAT / TRAILS / FOV
----------------------------------------------------------------
local hats, trails = {}, {}
local alive = true

local function destroyTrail(t)
	if t then
		pcall(function() t.tr:Destroy() end)
		pcall(function() t.a0:Destroy() end)
		pcall(function() t.a1:Destroy() end)
	end
end

local function updateHat(plr, cam)
	local char = plr.Character
	local head = char and char:FindFirstChild("Head")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local h = hats[plr]
	local want = CFG.hat.on and head and hum and hum.Health > 0 and (CFG.hat.scope == "Everyone" or plr == LP)
	if not want then
		if h then
			pcall(function() h:Destroy() end)
			hats[plr] = nil
			X.hatInfo[plr] = nil
		end
		return
	end
	local info = X.hatInfo[plr]
	if not h or not h.Parent then
		h = new("Part", {
			Name = "NH_Hat", Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false,
			Size = Vector3.new(1, 1, 1), Transparency = 1, Material = Enum.Material.Neon,
		}, Workspace)
		new("SpecialMesh", { MeshId = "rbxassetid://1033714" }, h)
		hats[plr] = h
		info = { sig = "" }
		X.hatInfo[plr] = info
	end
	local k = CFG.hat.size / 100
	local R_, HGT = 1.7 * k, 1.0 * k
	local n = math.max(3, math.floor(CFG.hat.lines))
	local sig = n .. "|" .. tostring(CFG.hat.rainbow) .. "|" .. tostring(CFG.hat.color) .. "|" .. CFG.hat.trans
	if info.sig ~= sig then
		for _, c in ipairs(h:GetChildren()) do
			if not c:IsA("SpecialMesh") then c:Destroy() end
		end
		info.sig = sig
		info.rim, info.beams = {}, {}
		local apex = new("Attachment", { Name = "Apex" }, h)
		info.apex = apex
		for i = 1, n do info.rim[i] = new("Attachment", { Name = "R" .. i }, h) end
		local function beam(a0, a1, c0, c1)
			local b = new("Beam", {
				Attachment0 = a0, Attachment1 = a1, Width0 = .06, Width1 = .06, FaceCamera = true, LightEmission = 1,
				LightInfluence = 0, Segments = 1, Color = ColorSequence.new(c0, c1),
				Transparency = NumberSequence.new(math.clamp(CFG.hat.trans * .6, 0, .9)),
			}, h)
			info.beams[#info.beams + 1] = b
		end
		for i = 1, n do
			local j = i % n + 1
			local c0 = CFG.hat.rainbow and Color3.fromHSV((i - 1) / n, .9, 1) or CFG.hat.color
			local c1 = CFG.hat.rainbow and Color3.fromHSV((j - 1) / n, .9, 1) or CFG.hat.color
			beam(apex, info.rim[i], c0, c0)
			beam(info.rim[i], info.rim[j], c0, c1)
		end
		info.k = nil
	end
	if info.k ~= k then
		info.k = k
		info.apex.Position = Vector3.new(0, HGT / 2, 0)
		for i, at in ipairs(info.rim) do
			local ang = (i - 1) / n * math.pi * 2
			at.Position = Vector3.new(math.cos(ang) * R_, -HGT / 2, math.sin(ang) * R_)
		end
		local mesh = h:FindFirstChildOfClass("SpecialMesh")
		if mesh then mesh.Scale = Vector3.new(1.7 * k, 1.1 * k, 1.7 * k) end
	end
	local close = plr == LP and cam ~= nil and (cam.CFrame.Position - head.Position).Magnitude < 1.8
	local mode = CFG.hat.mode
	local showLines, showSolid = mode ~= "Solid", mode ~= "Lines"
	for _, b in ipairs(info.beams) do b.Enabled = showLines and not close end
	h.Transparency = (showSolid and not close) and CFG.hat.trans or 1
	h.Color = (CFG.hat.shimmer and showSolid) and Color3.fromHSV((os.clock() * .25) % 1, .7, 1) or CFG.hat.color
	h.CFrame = CFrame.new(head.Position + Vector3.new(0, head.Size.Y / 2 + HGT / 2 + .05, 0))
end

local function updateTrail(plr)
	local char = plr.Character
	local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
	local t = trails[plr]
	if CFG.trail.on and root and (CFG.trail.scope == "Everyone" or plr == LP) then
		if not t or not t.tr.Parent or t.a0.Parent ~= root then
			destroyTrail(t)
			local a0 = new("Attachment", { Name = "NH_T0" }, root)
			local a1 = new("Attachment", { Name = "NH_T1" }, root)
			local tr = new("Trail", { Name = "NH_Trail", Attachment0 = a0, Attachment1 = a1, FaceCamera = true, MinLength = 0.05 }, root)
			t = { a0 = a0, a1 = a1, tr = tr }
			trails[plr] = t
		end
		local w = CFG.trail.width
		t.a0.Position = Vector3.new(0, w / 2, 0)
		t.a1.Position = Vector3.new(0, -w / 2, 0)
		t.tr.Lifetime = CFG.trail.len
		t.tr.Color = ColorSequence.new(CFG.trail.color)
		t.tr.Transparency = NumberSequence.new(0.1, 1)
		t.tr.LightEmission = 1
		t.tr.Enabled = true
	elseif t then
		destroyTrail(t)
		trails[plr] = nil
	end
end

track(RunService.RenderStepped:Connect(function()
	local cam = Workspace.CurrentCamera
	for _, plr in ipairs(Players:GetPlayers()) do updateHat(plr, cam) end
end))

task.spawn(function()
	while alive do
		for _, plr in ipairs(Players:GetPlayers()) do pcall(updateTrail, plr) end
		task.wait(0.2)
	end
end)

track(Players.PlayerRemoving:Connect(function(p)
	local d = S[p]
	if d then destroyData(d); S[p] = nil end
	if hats[p] then pcall(function() hats[p]:Destroy() end); hats[p] = nil end
	if trails[p] then destroyTrail(trails[p]); trails[p] = nil end
end))

-- Custom FOV
local fovOn, fovSaved = false, nil
RunService:BindToRenderStep("NH_FOV", Enum.RenderPriority.Camera.Value + 1, function()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	if CFG.fov.on then
		if not fovOn then fovSaved = cam.FieldOfView end
		fovOn = true
		cam.FieldOfView = CFG.fov.val
	elseif fovOn then
		fovOn = false
		cam.FieldOfView = fovSaved or 70
	end
end)

----------------------------------------------------------------
-- ESP EDITOR (предпросмотр справа)
----------------------------------------------------------------
local STAGE_W, STAGE_H = PREV_W - 24, 400
local SC_W, SC_H = 160, 320
local OX, OY = (STAGE_W - SC_W) / 2, STAGE_H - SC_H - 4
local BX, BY, BW, BH = 12, 72, 136, 222
local FX, FY = BX + 8, BY + 6

new("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -32, 0, 22),
	Font = Enum.Font.GothamBold, Text = "ESP Editor", TextSize = 16, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
}, Preview)
new("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 34), Size = UDim2.new(1, -32, 0, 14),
	Font = Enum.Font.GothamMedium, Text = "live preview of your settings", TextSize = 10, TextColor3 = C.sub,
	TextXAlignment = Enum.TextXAlignment.Left,
}, Preview)

local stage = new("Frame", {
	Position = UDim2.fromOffset(12, 58), Size = UDim2.fromOffset(STAGE_W, STAGE_H),
	BackgroundColor3 = C.field, BorderSizePixel = 0, ClipsDescendants = true,
}, Preview)
corner(stage, 12)
stroke(stage, C.line, 1)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(24, 21, 38), Color3.fromRGB(10, 10, 16)) }, stage)

local scene = new("Frame", { Position = UDim2.fromOffset(OX, OY), Size = UDim2.fromOffset(SC_W, SC_H), BackgroundTransparency = 1 }, stage)

local function pvFrame(x, y, w, h, col, rad)
	local f = new("Frame", {
		Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = col or WHITE,
		BorderSizePixel = 0, Visible = false,
	}, scene)
	if rad then corner(f, rad) end
	return f
end

-- свечение
local gl1 = pvFrame(BX - 18, BY - 18, BW + 36, BH + 36, WHITE, 44)
local gl2 = pvFrame(BX - 36, BY - 36, BW + 72, BH + 72, WHITE, 60)
-- тень под ногами
local floorShadow = pvFrame(BX + 14, BY + BH - 8, 108, 12, Color3.new(0, 0, 0), 6)
floorShadow.BackgroundTransparency = .55
floorShadow.Visible = true
-- заливка
local pvFill = pvFrame(BX, BY, BW, BH, WHITE, 0)
local pvFillG = new("UIGradient", { Rotation = 90 }, pvFill)

-- фигура игрока
local BASE = Color3.fromRGB(72, 70, 96)
local pieces = {}
for _, p in ipairs({
	{ 43, 0, 34, 34, 17 }, { 30, 37, 60, 70, 8 }, { 10, 37, 18, 68, 7 },
	{ 92, 37, 18, 68, 7 }, { 31, 110, 28, 100, 7 }, { 61, 110, 28, 100, 7 },
}) do
	local f = pvFrame(FX + p[1], FY + p[2], p[3], p[4], BASE, p[5])
	f.Visible = true
	local s = stroke(f, WHITE, 1.5)
	s.Enabled = false
	pieces[#pieces + 1] = { f = f, s = s }
end

-- линии: 3D бокс, скелет, трейсер
local pv3 = {}
for i = 1, 12 do pv3[i] = mkLine(scene) end
local pvSk = {}
for i = 1, 14 do pvSk[i] = mkLine(scene) end
local pvTr = mkLine(scene)

-- 2D бокс
local pvBox = pvFrame(BX, BY, BW, BH, WHITE, 0)
pvBox.BackgroundTransparency = 1
local pvBoxS = new("UIStroke", { Thickness = TH, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, pvBox)
-- углы
local pvCn = {}
for i = 1, 8 do pvCn[i] = pvFrame(0, 0, 4, 4, WHITE, 0) end
-- кольцо головы
local pvRing = pvFrame(FX + 60 - 20, FY + 17 - 20, 40, 40, WHITE, 20)
pvRing.BackgroundTransparency = 1
local pvRingS = new("UIStroke", { Thickness = TH, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, pvRing)

-- шляпа (треугольник)
local pvHatBox = new("Frame", {
	Position = UDim2.fromOffset(FX + 30, FY + 3 - 30), Size = UDim2.fromOffset(60, 30),
	BackgroundTransparency = 1, ClipsDescendants = true, Visible = false,
}, scene)
local pvHat = new("Frame", {
	AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(30, 30), Size = UDim2.fromOffset(42, 42),
	Rotation = 45, BackgroundColor3 = WHITE, BorderSizePixel = 0,
}, pvHatBox)

-- подписи + здоровье
local function pvText()
	return new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromOffset(150, 14), Font = Enum.Font.GothamBold, TextSize = 12,
		TextStrokeTransparency = .35, TextStrokeColor3 = Color3.new(0, 0, 0), Visible = false,
	}, scene)
end
local pvName, pvDist = pvText(), pvText()
pvName.Text = "NurHub"
pvName.AnchorPoint = Vector2.new(.5, 1)
pvDist.Text = "37m"
pvDist.AnchorPoint = Vector2.new(.5, 0)
pvDist.Position = UDim2.fromOffset(BX + BW / 2, BY + BH + 3)
local pvHpBg = pvFrame(BX - 6, BY, 2, BH, Color3.new(0, 0, 0), 0)
pvHpBg.BackgroundTransparency = .35
local pvHpFill = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, pvHpBg)

-- стрелка-указатель
local pvArrow = mkArrow(scene)
pvArrow.frame.Position = UDim2.fromOffset(SC_W / 2 - 6, 20)

-- суставы скелета (в координатах фигуры)
local J = {
	head = { 60, 18 }, neck = { 60, 38 }, lsh = { 32, 42 }, rsh = { 88, 42 }, lel = { 20, 72 }, rel = { 100, 72 },
	lh = { 20, 102 }, rh = { 100, 102 }, pel = { 60, 108 }, lhip = { 45, 112 }, rhip = { 75, 112 },
	lkn = { 45, 160 }, rkn = { 75, 160 }, lft = { 45, 205 }, rft = { 75, 205 },
}
local BONES = {
	{ "head", "neck" }, { "neck", "pel" }, { "neck", "lsh" }, { "lsh", "lel" }, { "lel", "lh" },
	{ "neck", "rsh" }, { "rsh", "rel" }, { "rel", "rh" }, { "pel", "lhip" }, { "lhip", "lkn" },
	{ "lkn", "lft" }, { "pel", "rhip" }, { "rhip", "rkn" }, { "rkn", "rft" },
}
local function jp(n) return Vector2.new(FX + J[n][1], FY + J[n][2]) end

local function pvCorner3(i)
	local fx0, fy0, fx1, fy1 = BX, BY + 14, BX + 122, BY + BH
	local back = bit32.band(i, 4) ~= 0 and 14 or 0
	local x = (bit32.band(i, 1) ~= 0 and fx1 or fx0) + back
	local y = (bit32.band(i, 2) ~= 0 and fy1 or fy0) - back
	return Vector2.new(x, y)
end

local function pvUpdate(t)
	local e = CFG.esp.on

	-- chams / outline на фигуре
	for _, p in ipairs(pieces) do
		local col = BASE
		if e and CFG.chams.on then col = BASE:Lerp(CFG.chams.color, 1 - CFG.chams.trans) end
		p.f.BackgroundColor3 = col
		p.s.Enabled = e and CFG.outline.on
		p.s.Color = CFG.outline.color
	end

	-- glow
	local g = e and CFG.glow.on
	gl1.Visible = g; gl2.Visible = g
	if g then
		gl1.BackgroundColor3 = CFG.glow.color; gl2.BackgroundColor3 = CFG.glow.color
		gl1.BackgroundTransparency = math.clamp(1 - CFG.glow.bright / 9, .6, .92)
		gl2.BackgroundTransparency = math.clamp(1 - CFG.glow.bright / 18, .8, .96)
	end

	-- fill
	pvFill.Visible = e and CFG.fill.on
	if pvFill.Visible then
		pvFill.BackgroundTransparency = CFG.fill.trans
		pvFillG.Color = ColorSequence.new(CFG.fill.c1, CFG.fill.c2)
	end

	-- box 2D
	pvBox.Visible = e and CFG.box2d.on
	pvBoxS.Color = CFG.box2d.color

	-- corners
	if e and CFG.corner.on then
		local l = math.min(CFG.corner.len, BW / 2, BH / 2)
		setCorners(pvCn, BX, BY, BX + BW, BY + BH, l, 2, CFG.corner.color)
	else
		for _, f in ipairs(pvCn) do f.Visible = false end
	end

	-- box 3D
	if e and CFG.box3d.on then
		for i, ed in ipairs(EDGES) do
			setLine(pv3[i], pvCorner3(ed[1]), pvCorner3(ed[2]), CFG.box3d.color, TH)
		end
	else
		hideList(pv3)
	end

	-- skeleton
	if e and CFG.skel.on then
		for i, b in ipairs(BONES) do setLine(pvSk[i], jp(b[1]), jp(b[2]), CFG.skel.color, TH) end
	else
		hideList(pvSk)
	end

	-- head ring
	pvRing.Visible = e and CFG.head.on
	pvRingS.Color = CFG.head.color

	-- tracer
	if e and CFG.tracer.on then
		local o = Vector2.new(SC_W / 2, STAGE_H - OY)
		if CFG.tracer.origin == "Top" then
			o = Vector2.new(SC_W / 2, -OY)
		elseif CFG.tracer.origin == "Crosshair" then
			o = Vector2.new(SC_W / 2, STAGE_H / 2 - OY)
		end
		setLine(pvTr, o, Vector2.new(FX + 60, FY + 72), CFG.tracer.color, TH)
	else
		pvTr.Visible = false
	end

	-- hat
	pvHatBox.Visible = CFG.hat.on
	if CFG.hat.on then
		pvHat.BackgroundColor3 = CFG.hat.color
		pvHat.BackgroundTransparency = CFG.hat.trans
	end

	-- name / distance
	pvName.Visible = e and CFG.name.on
	pvName.TextColor3 = CFG.name.color
	pvName.Position = UDim2.fromOffset(BX + BW / 2, BY - 4 - (CFG.hat.on and 28 or 0))
	pvDist.Visible = e and CFG.dist.on
	pvDist.TextColor3 = CFG.dist.color

	-- health
	pvHpBg.Visible = e and CFG.health.on
	if pvHpBg.Visible then
		local frac = 0.7 + 0.3 * math.sin(t * 1.5)
		pvHpFill.Size = UDim2.fromScale(1, frac)
		pvHpFill.BackgroundColor3 = CFG.health.color
	end

	-- arrow
	pvArrow.frame.Visible = e and CFG.arrows.on
	if pvArrow.frame.Visible then
		pvArrow.frame.Rotation = (t * 50) % 360
		paintArrow(pvArrow, CFG.arrows.color, math.min(CFG.arrows.size, 30))
	end
end

----------------------------------------------------------------
-- Меню: открыть / закрыть, предпросмотр показываем только в Visual
----------------------------------------------------------------
local menuOpen = false
local menuTok, pvTok = 0, 0

local function showPreview(v)
	pvTok += 1
	local my = pvTok
	if v then
		Preview.Visible = true
		tw(Preview, .5, { GroupTransparency = 0 })
	else
		tw(Preview, .22, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(.25, function()
			if pvTok == my then Preview.Visible = false end
		end)
	end
end
onTabChanged = function(name)
	if menuOpen then showPreview(name == "Visual") end
end

local function setMenu(open)
	if open == menuOpen then return end
	menuOpen = open
	menuTok += 1
	local my = menuTok
	if open then
		Root.Visible = true
		tw(Main, .4, { GroupTransparency = 0 })
		tw(animScale, .5, { Scale = 1 }, Enum.EasingStyle.Back)
		if current == "Visual" then showPreview(true) end
	else
		tw(Main, .25, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tw(animScale, .28, { Scale = .9 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		showPreview(false)
		task.delay(.3, function()
			if menuTok == my then Root.Visible = false end
		end)
	end
end

----------------------------------------------------------------
-- MM2 ФУНКЦИИ: FPS, third person, следы, xray, мир, игрок, фарм, телепорт, конфиги
----------------------------------------------------------------
do
	local function run()
		local Lighting = game:GetService("Lighting")
		local HttpService = X.json

		for _, n in ipairs({ "NH_CC", "NH_Bloom", "NH_Rays", "NH_Blur" }) do
			local o = Lighting:FindFirstChild(n)
			if o then o:Destroy() end
		end

		------------------------------------------------ Show FPS
		local fpsLbl = new("TextLabel", {
			Name = "NH_FPS", BackgroundColor3 = Color3.fromRGB(14, 14, 20), BackgroundTransparency = .2,
			Size = UDim2.fromOffset(84, 26), Font = Enum.Font.GothamBold, TextSize = 14, Text = "60 FPS",
			BorderSizePixel = 0, Visible = false,
		}, espGui)
		corner(fpsLbl, 8)
		stroke(fpsLbl, C.line, 1)
		local acc, cnt, shown = 0, 0, 60
		track(RunService.RenderStepped:Connect(function(dt)
			acc += dt
			cnt += 1
			if acc >= .5 then
				shown = math.floor(cnt / acc + .5)
				acc, cnt = 0, 0
			end
			fpsLbl.Visible = CFG.fps.on
			if CFG.fps.on then
				fpsLbl.Text = (CFG.fps.custom and CFG.fps.value or shown) .. " FPS"
				fpsLbl.TextColor3 = CFG.fps.color
				fpsLbl.AnchorPoint = Vector2.new(CFG.fps.x, CFG.fps.y)
				fpsLbl.Position = UDim2.fromScale(CFG.fps.x, CFG.fps.y)
			end
		end))

		------------------------------------------------ Third person
		local saved
		track(RunService.RenderStepped:Connect(function()
			if CFG.third.on then
				if not saved then saved = { LP.CameraMinZoomDistance, LP.CameraMaxZoomDistance, LP.CameraMode } end
				pcall(function()
					LP.CameraMode = Enum.CameraMode.Classic
					LP.CameraMaxZoomDistance = CFG.third.dist
					LP.CameraMinZoomDistance = CFG.third.dist
				end)
			elseif saved then
				pcall(function()
					LP.CameraMinZoomDistance = saved[1]
					LP.CameraMaxZoomDistance = saved[2]
					LP.CameraMode = saved[3]
				end)
				saved = nil
			end
		end))

		------------------------------------------------ Следы игрока (с анимацией)
		local stepParams = RaycastParams.new()
		stepParams.FilterType = Enum.RaycastFilterType.Exclude
		local live, lastPos = 0, {}
		local function mkPart(round, size, cf, col)
			local p = new("Part", {
				Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false,
				Material = Enum.Material.Neon, Color = col, Transparency = .1, Name = "NH_Step",
			}, Workspace)
			if round then
				p.Shape = Enum.PartType.Cylinder
				p.Size = Vector3.new(.05, size, size)
				p.CFrame = cf * CFrame.Angles(0, 0, math.pi / 2)
			else
				p.Size = Vector3.new(size, .05, size)
				p.CFrame = cf
			end
			return p
		end
		local function spawnStep(pos, look, side)
			if live > 160 then return end
			local col, life, shape = CFG.steps.color, CFG.steps.life, CFG.steps.shape
			local base = CFrame.lookAt(pos, pos + look)
			local parts = {}
			local function add(round, size, cf, grow)
				local p = mkPart(round, size, cf, col)
				parts[#parts + 1] = p
				local goal = round and Vector3.new(.05, size * grow, size * grow) or Vector3.new(size * grow, .05, size * grow)
				TweenService:Create(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1, Size = goal }):Play()
			end
			if shape == "Circle" then
				add(true, 1.2, base, 2.2)
			elseif shape == "Square" then
				add(false, 1.1, base, 1.8)
			elseif shape == "Diamond" then
				add(false, 1.1, base * CFrame.Angles(0, math.rad(45), 0), 1.8)
			else
				add(true, .55, base * CFrame.new(side * .22, 0, -.45), 1.5)
				add(true, .38, base * CFrame.new(side * .22, 0, .35), 1.5)
			end
			live += #parts
			task.delay(life + .2, function()
				for _, p in ipairs(parts) do pcall(function() p:Destroy() end) end
				live -= #parts
			end)
		end
		track(RunService.Heartbeat:Connect(function()
			if not CFG.steps.on then return end
			for _, plr in ipairs(Players:GetPlayers()) do
				if CFG.steps.scope == "Everyone" or plr == LP then
					local ch = plr.Character
					local hum = ch and ch:FindFirstChildOfClass("Humanoid")
					local root = ch and ch:FindFirstChild("HumanoidRootPart")
					if hum and root and hum.Health > 0 and hum.FloorMaterial ~= Enum.Material.Air then
						local st = lastPos[plr]
						if not st then
							lastPos[plr] = { pos = root.Position, side = 1 }
						else
							local d = root.Position - st.pos
							local flat = Vector3.new(d.X, 0, d.Z)
							if flat.Magnitude >= CFG.steps.dist and os.clock() - (st.t or 0) >= CFG.steps.delay then
								stepParams.FilterDescendantsInstances = { ch }
								local r = Workspace:Raycast(root.Position, Vector3.new(0, -8, 0), stepParams)
								if r then spawnStep(r.Position + Vector3.new(0, .06, 0), flat.Unit, st.side) end
								st.side = -st.side
								st.t = os.clock()
								st.pos = root.Position
							end
						end
					end
				end
			end
		end))

		------------------------------------------------ Xray
		local xr = {}
		local function skip(p)
			if p.Size.Magnitude < 6 then return true end
			local m = p:FindFirstAncestorOfClass("Model")
			while m do
				if m:FindFirstChildOfClass("Humanoid") then return true end
				m = m.Parent and m.Parent:FindFirstAncestorOfClass("Model") or nil
			end
			return false
		end
		local function xrOne(p)
			if p:IsA("BasePart") and not p:IsA("Terrain") and not skip(p) then
				xr[p] = true
				p.LocalTransparencyModifier = CFG.xray.amount
			end
		end
		local was, lastAmt = false, nil
		task.spawn(function()
			while alive do
				if CFG.xray.on then
					if not was or lastAmt ~= CFG.xray.amount then
						was, lastAmt = true, CFG.xray.amount
						local n = 0
						for _, p in ipairs(Workspace:GetDescendants()) do
							xrOne(p)
							n += 1
							if n % 600 == 0 then task.wait() end
						end
					end
				elseif was then
					was = false
					for p in pairs(xr) do
						if p.Parent then p.LocalTransparencyModifier = 0 end
					end
					xr = {}
				end
				task.wait(.3)
			end
		end)
		track(Workspace.DescendantAdded:Connect(function(p)
			if CFG.xray.on then xrOne(p) end
		end))

		------------------------------------------------ Мир: шейдеры + свет
		local cc = new("ColorCorrectionEffect", { Name = "NH_CC" }, Lighting)
		local bloom = new("BloomEffect", { Name = "NH_Bloom", Intensity = 0, Size = 24, Threshold = 2 }, Lighting)
		local rays = new("SunRaysEffect", { Name = "NH_Rays", Intensity = 0, Spread = .6 }, Lighting)
		local blur = new("BlurEffect", { Name = "NH_Blur", Size = 0 }, Lighting)

		local PRESETS = {
			["Sakura"]    = { tint = Color3.fromRGB(255, 226, 236), sat = 0.15, contrast = 0.05, bloom = 0.4, weather = "sakura" },
			["Blood"]     = { tint = Color3.fromRGB(255, 165, 165), sat = 0.1, contrast = 0.2, bright = -0.08, bloom = 0.3, weather = "blood" },
			["4K"]        = { sat = 0.25, contrast = 0.22, bright = 0.02, bloom = 0.5, rays = 0.1 },
			["Snow"]      = { tint = Color3.fromRGB(226, 240, 255), sat = -0.1, bright = 0.05, weather = "snow" },
			["Sunset"]    = { tint = Color3.fromRGB(255, 200, 150), sat = 0.25, rays = 0.25, bloom = 0.6 },
			["Rain"]      = { tint = Color3.fromRGB(190, 205, 225), sat = -0.2, contrast = 0.1, bright = -0.05, weather = "rain" },
			["Neon"]      = { tint = Color3.fromRGB(220, 190, 255), sat = 0.5, contrast = 0.25, bloom = 1.2 },
			["Noir"]      = { sat = -1, contrast = 0.3 },
			["Vintage"]   = { tint = Color3.fromRGB(255, 235, 200), sat = -0.25, contrast = 0.1 },
			["Cyberpunk"] = { tint = Color3.fromRGB(200, 170, 255), sat = 0.45, contrast = 0.2, bloom = 0.9 },
			["Ocean"]     = { tint = Color3.fromRGB(170, 215, 255), sat = 0.2, bright = 0.02, rays = 0.15 },
			["Matrix"]    = { tint = Color3.fromRGB(150, 255, 170), sat = -0.2, contrast = 0.25, bloom = 0.5 },
			["Autumn"]    = { tint = Color3.fromRGB(255, 205, 150), sat = 0.2, weather = "leaves" },
			["Dreamy"]    = { tint = Color3.fromRGB(255, 230, 245), sat = 0.1, bright = 0.06, bloom = 1.0, rays = 0.2 },
		}
		X.PRESET_LIST = { "Sakura", "Blood", "4K", "Snow", "Sunset", "Rain", "Neon", "Noir", "Vintage", "Cyberpunk", "Ocean", "Matrix", "Autumn", "Dreamy" }

		local weatherPart = new("Part", {
			Name = "NH_Weather", Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false,
			Transparency = 1, Size = Vector3.new(90, 1, 90), CastShadow = false,
		})
		local emitters, curWeather = {}, nil
		local WEATHER = {
			snow = function(e)
				e.Rate = 260; e.Lifetime = NumberRange.new(5, 6); e.Speed = NumberRange.new(6, 9)
				e.Size = NumberSequence.new(0.3); e.Color = ColorSequence.new(WHITE)
				e.Transparency = NumberSequence.new(0.1); e.Acceleration = Vector3.new(2, 0, 1)
				e.RotSpeed = NumberRange.new(-60, 60); e.SpreadAngle = Vector2.new(12, 12)
			end,
			rain = function(e)
				e.Rate = 650; e.Lifetime = NumberRange.new(0.4, 0.45); e.Speed = NumberRange.new(95, 110)
				e.Size = NumberSequence.new(0.14); e.Color = ColorSequence.new(Color3.fromRGB(180, 200, 230))
				e.Transparency = NumberSequence.new(0.35); e.SpreadAngle = Vector2.new(3, 3)
				e.Orientation = Enum.ParticleOrientation.VelocityParallel
			end,
			sakura = function(e)
				e.Rate = 70; e.Lifetime = NumberRange.new(7, 9); e.Speed = NumberRange.new(3, 6)
				e.Size = NumberSequence.new(0.5)
				e.Color = ColorSequence.new(Color3.fromRGB(255, 170, 200), Color3.fromRGB(255, 205, 225))
				e.Transparency = NumberSequence.new(0.05); e.Acceleration = Vector3.new(3, 0, 1.5)
				e.RotSpeed = NumberRange.new(-120, 120); e.SpreadAngle = Vector2.new(25, 25)
			end,
			blood = function(e)
				e.Rate = 130; e.Lifetime = NumberRange.new(2.5, 3); e.Speed = NumberRange.new(12, 16)
				e.Size = NumberSequence.new(0.35); e.Color = ColorSequence.new(Color3.fromRGB(170, 0, 10))
				e.Transparency = NumberSequence.new(0.1); e.SpreadAngle = Vector2.new(6, 6)
			end,
			leaves = function(e)
				e.Rate = 60; e.Lifetime = NumberRange.new(7, 9); e.Speed = NumberRange.new(3, 6)
				e.Size = NumberSequence.new(0.5)
				e.Color = ColorSequence.new(Color3.fromRGB(230, 120, 40), Color3.fromRGB(150, 80, 30))
				e.Transparency = NumberSequence.new(0.05); e.Acceleration = Vector3.new(4, 0, 2)
				e.RotSpeed = NumberRange.new(-150, 150); e.SpreadAngle = Vector2.new(25, 25)
			end,
		}
		local function setWeather(kind)
			if kind == curWeather then return end
			curWeather = kind
			for k, e in pairs(emitters) do e.Enabled = (k == kind) end
			if kind then
				if not emitters[kind] then
					local e = new("ParticleEmitter", {
						EmissionDirection = Enum.NormalId.Bottom, LockedToPart = false, Rotation = NumberRange.new(0, 360),
					}, weatherPart)
					WEATHER[kind](e)
					emitters[kind] = e
				end
				emitters[kind].Enabled = true
				weatherPart.Parent = Workspace.CurrentCamera
			else
				weatherPart.Parent = nil
			end
		end

		local orig, active = nil, false
		local function snap()
			orig = {
				Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
				FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart, FogColor = Lighting.FogColor,
				GlobalShadows = Lighting.GlobalShadows, ExposureCompensation = Lighting.ExposureCompensation,
			}
		end
		local function neutral()
			cc.Brightness, cc.Contrast, cc.Saturation, cc.TintColor = 0, 0, 0, WHITE
			bloom.Intensity, bloom.Threshold = 0, 2
			rays.Intensity = 0
			blur.Size = 0
		end
		local function restore()
			neutral()
			setWeather(nil)
			if orig then
				for k, v in pairs(orig) do pcall(function() Lighting[k] = v end) end
			end
		end
		local function anyOn()
			return CFG.shader.on or CFG.wbright.on or CFG.wglow.on or CFG.wdark.on or CFG.wgrade.on or CFG.wblur.on
				or CFG.wfog.on or CFG.wrays.on or CFG.wfull.on or CFG.wshadow.on
		end
		local function apply()
			local p = (CFG.shader.on and PRESETS[CFG.shader.preset]) or {}
			local bright = (p.bright or 0) + (CFG.wbright.on and CFG.wbright.val or 0) - (CFG.wdark.on and CFG.wdark.val * .5 or 0)
			local contrast = (p.contrast or 0) + (CFG.wgrade.on and CFG.wgrade.con or 0)
			local sat = (p.sat or 0) + (CFG.wgrade.on and CFG.wgrade.sat or 0)
			cc.Brightness = math.clamp(bright, -1, 1)
			cc.Contrast = math.clamp(contrast, -1, 1)
			cc.Saturation = math.clamp(sat, -1, 1)
			cc.TintColor = p.tint or WHITE
			bloom.Intensity = (p.bloom or 0) + (CFG.wglow.on and CFG.wglow.int or 0)
			bloom.Threshold = CFG.wglow.on and CFG.wglow.thr or (p.bloom and 1.2 or 2)
			rays.Intensity = math.clamp((p.rays or 0) + (CFG.wrays.on and CFG.wrays.val or 0), 0, 1)
			Lighting.ExposureCompensation = orig.ExposureCompensation - (CFG.wdark.on and CFG.wdark.val * 1.5 or 0)
			Lighting.Brightness = orig.Brightness + (CFG.wfull.on and 2 or 0)
			if CFG.wfull.on then
				Lighting.Ambient = Color3.fromRGB(170, 170, 170)
				Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170)
			else
				Lighting.Ambient = orig.Ambient
				Lighting.OutdoorAmbient = orig.OutdoorAmbient
			end
			if CFG.wfog.on then
				Lighting.FogStart = 0
				Lighting.FogEnd = math.max(30, 2200 * (1 - CFG.wfog.val) ^ 2)
				Lighting.FogColor = Color3.fromRGB(180, 180, 190)
			else
				Lighting.FogStart = orig.FogStart
				Lighting.FogEnd = orig.FogEnd
				Lighting.FogColor = orig.FogColor
			end
			Lighting.GlobalShadows = (not CFG.wshadow.on) and orig.GlobalShadows or false
			setWeather(p.weather)
		end
		task.spawn(function()
			while alive do
				if anyOn() then
					if not active then
						active = true
						snap()
					end
					pcall(apply)
				elseif active then
					active = false
					restore()
				end
				task.wait(.12)
			end
		end)

		-- время суток + motion blur + погода за камерой
		local savedClock, lastLook = nil, Vector3.new(0, 0, -1)
		track(RunService.RenderStepped:Connect(function()
			local cam = Workspace.CurrentCamera
			if weatherPart.Parent and cam then
				weatherPart.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 38, 0))
			end
			if CFG.wtime.on then
				if not savedClock then savedClock = Lighting.ClockTime end
				Lighting.ClockTime = CFG.wtime.val
			elseif savedClock then
				Lighting.ClockTime = savedClock
				savedClock = nil
			end
			if CFG.wblur.on and cam then
				local look = cam.CFrame.LookVector
				local ang = math.acos(math.clamp(look:Dot(lastLook), -1, 1))
				lastLook = look
				local goal = math.clamp(ang * CFG.wblur.val * 30, 0, 28)
				blur.Size = blur.Size + (goal - blur.Size) * .4
			elseif cam then
				blur.Size = 0
			end
		end))

		------------------------------------------------ Монеты / пушка (сканер)
		local coins, guns = {}, {}
		X.coins, X.guns = coins, guns
		local function scan(v)
			if v.Name == "Coin_Server" and v:IsA("BasePart") then
				coins[v] = true
			elseif v.Name == "GunDrop" and (v:IsA("BasePart") or v:IsA("Model")) then
				guns[v] = true
			end
		end
		track(Workspace.DescendantAdded:Connect(scan))
		task.spawn(function()
			local n = 0
			for _, v in ipairs(Workspace:GetDescendants()) do
				scan(v)
				n += 1
				if n % 800 == 0 then task.wait() end
			end
		end)

		local gunO, coinO = {}, {}
		local function posOf(i)
			if i:IsA("Model") then return i:GetPivot().Position end
			return i.Position
		end
		track(RunService.RenderStepped:Connect(function()
			local cam = Workspace.CurrentCamera
			if not cam then return end
			local vs = cam.ViewportSize
			for g in pairs(guns) do
				local o = gunO[g]
				if not g.Parent then
					guns[g] = nil
					if o then
						for _, x in pairs(o) do pcall(function() x:Destroy() end) end
						gunO[g] = nil
					end
				elseif CFG.gun.on then
					if not o then
						o = {
							hl = new("Highlight", { DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, FillTransparency = .45 }, espGui),
							txt = mkText(), ln = mkLine(espGui),
						}
						gunO[g] = o
					end
					o.hl.Adornee = g
					o.hl.FillColor = CFG.gun.color
					o.hl.OutlineColor = CFG.gun.color
					o.hl.Enabled = true
					local p = cam:WorldToViewportPoint(posOf(g))
					if p.Z > 0 then
						if CFG.gun.text then
							o.txt.Text = "Gun"
							o.txt.TextColor3 = CFG.gun.textColor
							o.txt.AnchorPoint = Vector2.new(.5, 1)
							o.txt.Position = UDim2.fromOffset(p.X, p.Y - 10)
							o.txt.Visible = true
						else
							o.txt.Visible = false
						end
						if CFG.gun.tracer then
							local org = Vector2.new(vs.X / 2, vs.Y)
							if CFG.tracer.origin == "Top" then
								org = Vector2.new(vs.X / 2, 0)
							elseif CFG.tracer.origin == "Crosshair" then
								org = Vector2.new(vs.X / 2, vs.Y / 2)
							end
							setLine(o.ln, org, Vector2.new(p.X, p.Y), CFG.gun.color, TH)
						else
							o.ln.Visible = false
						end
					else
						o.txt.Visible = false
						o.ln.Visible = false
					end
				elseif o then
					o.hl.Enabled = false
					o.txt.Visible = false
					o.ln.Visible = false
				end
			end

			for c in pairs(coins) do
				local o = coinO[c]
				if not c.Parent then
					coins[c] = nil
					if o then
						o.f:Destroy()
						coinO[c] = nil
					end
				elseif CFG.coin.on then
					local p = cam:WorldToViewportPoint(c.Position)
					if p.Z > 0 and (cam.CFrame.Position - c.Position).Magnitude < CFG.esp.maxDist then
						if not o then
							local f = new("Frame", {
								AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1,
								BorderSizePixel = 0, Visible = false,
							}, espGui)
							corner(f, 6)
							local s = new("UIStroke", { Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
							local t = new("TextLabel", {
								BackgroundTransparency = 1, AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 0, -2),
								Size = UDim2.fromOffset(60, 12), Font = Enum.Font.GothamBold, TextSize = 11, Text = "Coin",
								TextStrokeTransparency = .35,
							}, f)
							o = { f = f, s = s, t = t }
							coinO[c] = o
						end
						o.f.Position = UDim2.fromOffset(p.X, p.Y)
						o.s.Color = CFG.coin.color
						o.t.Visible = CFG.coin.text
						o.t.TextColor3 = CFG.coin.textColor
						o.f.Visible = true
					elseif o then
						o.f.Visible = false
					end
				elseif o then
					o.f.Visible = false
				end
			end
		end))

		------------------------------------------------ Игрок: speed / jump / spin / noclip / fly / autofarm
		local bv, bg
		local oldWalk, oldJump
		local farmT, farmWait, cool = nil, 0, {}
		local function cleanFly()
			if bv then bv:Destroy(); bv = nil end
			if bg then bg:Destroy(); bg = nil end
		end
		track(RunService.Heartbeat:Connect(function(dt)
			local ch = LP.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			if not hum or not root or hum.Health <= 0 then
				cleanFly()
				return
			end
			if CFG.walk.on then
				oldWalk = oldWalk or hum.WalkSpeed
				hum.WalkSpeed = CFG.walk.val
			elseif oldWalk then
				hum.WalkSpeed = oldWalk
				oldWalk = nil
			end
			if CFG.jump.on then
				oldJump = oldJump or hum.JumpPower
				hum.UseJumpPower = true
				hum.JumpPower = CFG.jump.val
			elseif oldJump then
				hum.JumpPower = oldJump
				oldJump = nil
			end
			if CFG.spin.on then
				root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(CFG.spin.val * dt), 0)
			end

			-- fly / удержание на месте при автофарме
			if CFG.fly.on or CFG.farm.on then
				if not bv or bv.Parent ~= root then
					cleanFly()
					bv = new("BodyVelocity", { MaxForce = Vector3.new(1e9, 1e9, 1e9), Velocity = Vector3.zero }, root)
					bg = new("BodyGyro", { MaxTorque = Vector3.new(1e9, 1e9, 1e9), P = 1e4 }, root)
				end
				local cam = Workspace.CurrentCamera
				local vel = Vector3.zero
				if CFG.fly.on and not CFG.farm.on and cam then
					local md = hum.MoveDirection
					local lv = cam.CFrame.LookVector
					if md.Magnitude > 0 then
						local flat = Vector3.new(lv.X, 0, lv.Z)
						local fwd = flat.Magnitude > 0 and md:Dot(flat.Unit) or 0
						vel = md * CFG.fly.val + Vector3.new(0, lv.Y * CFG.fly.val * math.max(fwd, 0), 0)
					end
					if hum.Jump then vel += Vector3.new(0, CFG.fly.val, 0) end
					bg.CFrame = CFrame.new(root.Position, root.Position + Vector3.new(lv.X, 0, lv.Z))
				else
					bg.CFrame = root.CFrame
				end
				bv.Velocity = vel
			else
				cleanFly()
			end

			-- автофарм монет
			if CFG.farm.on then
				farmWait -= dt
				if farmWait <= 0 then
					if farmT and not farmT.Parent then farmT = nil end
					if not farmT then
						local best, bd, now = nil, math.huge, os.clock()
						for part in pairs(coins) do
							if part.Parent and (not cool[part] or cool[part] < now) then
								local d = (part.Position - root.Position).Magnitude
								if d < bd then best, bd = part, d end
							end
						end
						farmT = best
					end
					if farmT then
						local to = farmT.Position - root.Position
						local d = to.Magnitude
						if d < 3 then
							cool[farmT] = os.clock() + 4
							farmT = nil
							farmWait = CFG.farm.delay
						else
							root.CFrame = root.CFrame + to.Unit * math.min(d, CFG.farm.fly * dt)
						end
					end
				end
			else
				farmT = nil
			end
		end))
		track(RunService.Stepped:Connect(function()
			if CFG.noclip.on or CFG.farm.on then
				local ch = LP.Character
				if ch then
					for _, p in ipairs(ch:GetDescendants()) do
						if p:IsA("BasePart") then p.CanCollide = false end
					end
				end
			end
		end))

		------------------------------------------------ Телепорты
		local function myRoot()
			local c = LP.Character
			return c and c:FindFirstChild("HumanoidRootPart")
		end
		function X.tpPlayer(plr)
			local r = myRoot()
			local t = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if r and t then
				r.CFrame = t.CFrame * CFrame.new(0, 0, 3)
				return true
			end
			return false
		end
		function X.tpSpawn()
			local r = myRoot()
			if not r then return false end
			local lobby = Workspace:FindFirstChild("Lobby")
			local sp = nil
			if lobby and lobby:FindFirstChild("Spawns") then
				sp = lobby.Spawns:FindFirstChildWhichIsA("BasePart", true)
			end
			sp = sp or Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
			if sp then
				r.CFrame = sp.CFrame * CFrame.new(0, 4, 0)
				return true
			end
			return false
		end
		local function getMap()
			for _, m in ipairs(Workspace:GetChildren()) do
				if m:IsA("Model") and m.Name ~= "Lobby" and (m:FindFirstChild("CoinContainer") or m:FindFirstChild("Spawns"))
					and not Players:GetPlayerFromCharacter(m) then
					return m
				end
			end
			return nil
		end
		function X.tpMap()
			local r = myRoot()
			if not r then return false end
			local m = getMap()
			if m then
				local sp = m:FindFirstChild("Spawns")
				local part = sp and sp:FindFirstChildWhichIsA("BasePart", true)
				if part then
					r.CFrame = part.CFrame * CFrame.new(0, 4, 0)
				else
					r.CFrame = CFrame.new(m:GetPivot().Position + Vector3.new(0, 15, 0))
				end
				return true
			end
			for c in pairs(coins) do
				if c.Parent then
					r.CFrame = c.CFrame * CFrame.new(0, 3, 0)
					return true
				end
			end
			return false
		end
		function X.tpRole(role)
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LP and X.roleOf(p) == role then return X.tpPlayer(p) end
			end
			return false
		end

		-- обновление списков игроков (ники, роли, выбор)
		task.spawn(function()
			while alive do
				for _, l in ipairs(X.lists) do
					if l.frame.Parent then pcall(l.upd) end
				end
				task.wait(.8)
			end
		end)
		local function relist()
			for _, l in ipairs(X.lists) do
				if l.frame.Parent then
					pcall(l.rebuild)
					pcall(l.upd)
				end
			end
		end
		track(Players.PlayerAdded:Connect(function() task.delay(.6, relist) end))
		track(Players.PlayerRemoving:Connect(function() task.delay(.2, relist) end))

		------------------------------------------------ Конфиги (5 слотов)
		local SKIP = { pcolor = true, target = true }
		local function ser(v)
			if typeof(v) == "Color3" then return { __c = { v.R, v.G, v.B } } end
			if type(v) == "table" then
				local o = {}
				for k, x in pairs(v) do
					if type(k) == "string" then o[k] = ser(x) end
				end
				return o
			end
			return v
		end
		local function deser(dst, src)
			for k, v in pairs(src) do
				local cur = dst[k]
				if type(v) == "table" then
					if v.__c then
						dst[k] = Color3.new(v.__c[1], v.__c[2], v.__c[3])
					elseif type(cur) == "table" then
						deser(cur, v)
					end
				elseif cur ~= nil and type(cur) == type(v) then
					dst[k] = v
				end
			end
		end
		local slots = {}
		local function writeSlots()
			local o = {}
			for i = 1, 5 do
				if slots[i] then o[tostring(i)] = slots[i] end
			end
			pcall(function() X.fsWrite("configs.json", HttpService:JSONEncode(o)) end)
		end
		do
			local raw = X.fsRead("configs.json")
			if raw then
				local ok, t = pcall(function() return HttpService:JSONDecode(raw) end)
				if ok and type(t) == "table" then
					for i = 1, 5 do
						local s = t[tostring(i)]
						if type(s) == "table" and s.name and type(s.data) == "table" then slots[i] = s end
					end
				end
			end
		end
		X.cfgApi = {
			slots = function() return slots end,
			count = function()
				local n = 0
				for i = 1, 5 do
					if slots[i] then n += 1 end
				end
				return n
			end,
			save = function(name)
				name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
				if name == "" then name = "config" end
				local idx
				for i = 1, 5 do
					if slots[i] and slots[i].name == name then idx = i end
				end
				if not idx then
					for i = 1, 5 do
						if not slots[i] then idx = i break end
					end
				end
				if not idx then return nil end
				local snap = {}
				for k, v in pairs(CFG) do
					if not SKIP[k] then snap[k] = ser(v) end
				end
				slots[idx] = { name = name, data = snap }
				writeSlots()
				return idx
			end,
			load = function(i)
				local s = slots[i]
				if not s then return false end
				deser(CFG, s.data)
				X.refreshAll()
				return true
			end,
			delete = function(i)
				slots[i] = nil
				writeSlots()
			end,
		}

		------------------------------------------------ Выгрузка
		X.extraUnload = function()
			pcall(function() restore() end)
			pcall(function() cc:Destroy(); bloom:Destroy(); rays:Destroy(); blur:Destroy(); weatherPart:Destroy() end)
			pcall(cleanFly)
			for p in pairs(xr) do
				if p.Parent then p.LocalTransparencyModifier = 0 end
			end
			if saved then
				pcall(function()
					LP.CameraMinZoomDistance = saved[1]
					LP.CameraMaxZoomDistance = saved[2]
					LP.CameraMode = saved[3]
				end)
			end
			if savedClock then Lighting.ClockTime = savedClock end
			local ch = LP.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			if hum then
				if oldWalk then hum.WalkSpeed = oldWalk end
				if oldJump then hum.JumpPower = oldJump end
			end
			for _, o in pairs(coinO) do pcall(function() o.f:Destroy() end) end
			for _, o in pairs(gunO) do
				for _, x in pairs(o) do pcall(function() x:Destroy() end) end
			end
		end
	end
	run()
end

----------------------------------------------------------------
-- НОВОЕ: прицел, путь пули, звук попадания, крылья/нимб, скины, эмоции,
-- анимации, headless/korblox/god, bunnyhop, auto grab gun
----------------------------------------------------------------
do
	local function run()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local SoundService = game:GetService("SoundService")
		local Debris = game:GetService("Debris")

		-- настройки по умолчанию
		CFG.arrows.murder = Color3.fromRGB(255, 60, 60)
		CFG.arrows.sheriff = Color3.fromRGB(70, 140, 255)
		CFG.acolor = {}
		CFG.xhair = { on = false, shape = "Cross", color = WHITE, size = 12, thick = 2, spin = false, speed = 90 }
		CFG.bpath = { on = false, color = Color3.fromRGB(255, 80, 80), time = 2 }
		CFG.hsound = { on = false, sound = "Ping", volume = 6, id = "" }
		CFG.wings = { on = false, color = Color3.fromRGB(80, 200, 255), len = 4, width = 1, scope = "Only me" }
		CFG.halo = { on = false, color = Color3.fromRGB(80, 200, 255), radius = 1.6 }
		CFG.headless = { on = false }
		CFG.korblox = { on = false }
		CFG.god = { on = false }
		CFG.bhop = { on = false, dist = 45 }
		CFG.anim = { on = false, pack = "Ninja" }
		CFG.emote = { auto = false, name = "Dance", id = "", speed = 1 }
		CFG.grab = { on = false }
		CFG.skin = { gun = "", knife = "" }

		X.coins = X.coins or {}

		------------------------------------------------ Свой прицел (линии, вращение)
		local SHAPES = {
			Cross = { { -1, 0, 1, 0 }, { 0, -1, 0, 1 } },
			Plus = { { -1, 0, -.3, 0 }, { .3, 0, 1, 0 }, { 0, -1, 0, -.3 }, { 0, .3, 0, 1 } },
			X = { { -.8, -.8, .8, .8 }, { -.8, .8, .8, -.8 } },
			Square = { { -1, -1, 1, -1 }, { 1, -1, 1, 1 }, { 1, 1, -1, 1 }, { -1, 1, -1, -1 } },
			Diamond = { { 0, -1, 1, 0 }, { 1, 0, 0, 1 }, { 0, 1, -1, 0 }, { -1, 0, 0, -1 } },
			Triangle = { { 0, -1, 1, .8 }, { 1, .8, -1, .8 }, { -1, .8, 0, -1 } },
			Star = {},
			Circle = {},
			Dot = { { -.25, 0, .25, 0 }, { 0, -.25, 0, .25 } },
		}
		for k = 0, 4 do
			local a1 = math.rad(-90 + 72 * k)
			local a2 = math.rad(-90 + 72 * ((k + 2) % 5))
			SHAPES.Star[#SHAPES.Star + 1] = { math.cos(a1), math.sin(a1), math.cos(a2), math.sin(a2) }
		end
		for k = 0, 19 do
			local a1, a2 = math.rad(k * 18), math.rad((k + 1) * 18)
			SHAPES.Circle[#SHAPES.Circle + 1] = { math.cos(a1), math.sin(a1), math.cos(a2), math.sin(a2) }
		end
		X.SHAPE_LIST = { "Cross", "Plus", "X", "Square", "Diamond", "Triangle", "Star", "Circle", "Dot" }

		function X.drawShape(pool, parent, cx, cy, shape, size, thick, col, ang)
			local segs = SHAPES[shape] or SHAPES.Cross
			local ca, sa = math.cos(ang), math.sin(ang)
			for i = 1, #segs do
				local f = pool[i]
				if not f then
					f = mkLine(parent)
					pool[i] = f
				end
				local s = segs[i]
				local x1, y1 = (s[1] * ca - s[2] * sa) * size, (s[1] * sa + s[2] * ca) * size
				local x2, y2 = (s[3] * ca - s[4] * sa) * size, (s[3] * sa + s[4] * ca) * size
				setLine(f, Vector2.new(cx + x1, cy + y1), Vector2.new(cx + x2, cy + y2), col, thick)
			end
			for i = #segs + 1, #pool do pool[i].Visible = false end
		end

		local xPool = {}
		track(RunService.RenderStepped:Connect(function()
			local cam = Workspace.CurrentCamera
			if not cam then return end
			if CFG.xhair.on then
				local vs = cam.ViewportSize
				local ang = CFG.xhair.spin and (os.clock() * math.rad(CFG.xhair.speed)) or 0
				X.drawShape(xPool, espGui, vs.X / 2, vs.Y / 2, CFG.xhair.shape, CFG.xhair.size, CFG.xhair.thick, CFG.xhair.color, ang)
			else
				for _, f in ipairs(xPool) do f.Visible = false end
			end
		end))

		------------------------------------------------ Звук попадания
		local SOUNDS = {
			Ping = "rbxasset://sounds/electronicpingshort.wav", Click = "rbxasset://sounds/clickfast.wav",
			Switch = "rbxasset://sounds/switch.wav", Button = "rbxasset://sounds/button.wav", Bass = "rbxasset://sounds/bass.wav",
			Snap = "rbxasset://sounds/snap.mp3", Splat = "rbxasset://sounds/splat.wav", Victory = "rbxasset://sounds/victory.wav",
			Oof = "rbxasset://sounds/uuhhh.mp3",
		}
		X.SOUND_LIST = { "Ping", "Click", "Switch", "Button", "Bass", "Snap", "Splat", "Victory", "Oof" }
		function X.playHit()
			local s = new("Sound", { Volume = CFG.hsound.volume / 10 * 2 }, SoundService)
			if CFG.hsound.id ~= "" then
				s.SoundId = "rbxassetid://" .. CFG.hsound.id
			else
				s.SoundId = SOUNDS[CFG.hsound.sound] or SOUNDS.Ping
			end
			s:Play()
			Debris:AddItem(s, 4)
		end

		------------------------------------------------ Путь пули + попадание
		local rpHit = RaycastParams.new()
		rpHit.FilterType = Enum.RaycastFilterType.Exclude
		local function beamPart(a, b, col, life)
			local d = b - a
			local len = d.Magnitude
			if len < .1 then return end
			local p = new("Part", {
				Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false,
				Material = Enum.Material.Neon, Color = col, Size = Vector3.new(.12, .12, len), Transparency = .1, Name = "NH_Bullet",
			}, Workspace)
			p.CFrame = CFrame.lookAt(a + d / 2, b)
			TweenService:Create(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Transparency = 1, Size = Vector3.new(.02, .02, len) }):Play()
			task.delay(life + .1, function() p:Destroy() end)
		end
		local function onShoot(tool)
			local cam = Workspace.CurrentCamera
			if not cam then return end
			local ch = LP.Character
			rpHit.FilterDescendantsInstances = { ch }
			local pos = UIS.TouchEnabled and Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2) or UIS:GetMouseLocation()
			local ray = cam:ViewportPointToRay(pos.X, pos.Y)
			local res = Workspace:Raycast(ray.Origin, ray.Direction * 500, rpHit)
			local endp = res and res.Position or (ray.Origin + ray.Direction * 300)
			local handle = tool:FindFirstChild("Handle")
			local head = ch and ch:FindFirstChild("Head")
			local startp = handle and handle.Position or (head and head.Position) or ray.Origin
			if CFG.bpath.on then beamPart(startp, endp, CFG.bpath.color, CFG.bpath.time) end
			if CFG.hsound.on and res then
				local m = res.Instance:FindFirstAncestorOfClass("Model")
				local plr = m and Players:GetPlayerFromCharacter(m)
				if plr and plr ~= LP then X.playHit() end
			end
		end
		local hooked = {}
		local function hookTool(tool)
			if tool:IsA("Tool") and tool.Name == "Gun" and not hooked[tool] then
				hooked[tool] = true
				track(tool.Activated:Connect(function() onShoot(tool) end))
			end
		end
		local function hookChar(ch)
			for _, c in ipairs(ch:GetChildren()) do hookTool(c) end
			track(ch.ChildAdded:Connect(hookTool))
		end
		if LP.Character then hookChar(LP.Character) end
		track(LP.CharacterAdded:Connect(hookChar))

		------------------------------------------------ Крылья и нимб
		local fx = {}
		local WF = 9
		local function mkNeon(col, tr)
			return new("Part", {
				Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false,
				Material = Enum.Material.Neon, Color = col, Transparency = tr, Size = Vector3.new(.2, .04, 1), Name = "NH_FX",
			}, Workspace)
		end
		local function ensure(list, n, col, tr)
			while #list < n do list[#list + 1] = mkNeon(col, tr) end
			while #list > n do table.remove(list):Destroy() end
		end
		local function killFx(plr)
			local f = fx[plr]
			if f then
				for _, l in pairs(f) do
					for _, p in ipairs(l) do p:Destroy() end
				end
				fx[plr] = nil
			end
		end
		track(Players.PlayerRemoving:Connect(killFx))
		track(RunService.RenderStepped:Connect(function()
			local t = os.clock()
			for _, plr in ipairs(Players:GetPlayers()) do
				local ch = plr.Character
				local torso = ch and (ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso"))
				local head = ch and ch:FindFirstChild("Head")
				local hum = ch and ch:FindFirstChildOfClass("Humanoid")
				local alive_ = hum and hum.Health > 0
				local wantW = CFG.wings.on and (CFG.wings.scope == "Everyone" or plr == LP) and torso and alive_
				local wantH = CFG.halo.on and (CFG.wings.scope == "Everyone" or plr == LP) and head and alive_
				local f = fx[plr]
				if not (wantW or wantH) then
					if f then killFx(plr) end
				else
					if not f then
						f = { wings = {}, halo = {} }
						fx[plr] = f
					end
					if wantW then
						ensure(f.wings, WF * 2, CFG.wings.color, .25)
						local len, wid = CFG.wings.len, CFG.wings.width
						local flap = math.sin(t * 3) * .12
						local base = torso.CFrame
						local k = 0
						for side = -1, 1, 2 do
							for i = 1, WF do
								k += 1
								local u = (i - 1) / (WF - 1)
								local a = math.rad(-25 + u * 75 * wid) + flap
								local dir = Vector3.new(side * math.cos(a), math.sin(a), .3).Unit
								local L = len * (.55 + .45 * math.sin(math.pi * (.15 + .85 * u)))
								local shoulder = Vector3.new(side * .5, .6, .5)
								local cw = base:PointToWorldSpace(shoulder + dir * (L / 2))
								local dw = base:VectorToWorldSpace(dir)
								local p = f.wings[k]
								p.Size = Vector3.new(.14 * wid + .08, .04, L)
								p.Color = CFG.wings.color
								p.CFrame = CFrame.lookAt(cw, cw + dw)
							end
						end
					else
						ensure(f.wings, 0)
					end
					if wantH then
						local N = 20
						ensure(f.halo, N * 2, CFG.halo.color, .1)
						local r = CFG.halo.radius
						local center = head.Position + Vector3.new(0, head.Size.Y / 2 + .55, 0)
						local chord = 2 * r * math.sin(math.pi / N) * 1.08
						for ring = 1, 2 do
							local tilt = ring == 1 and CFrame.Angles(0, 0, 0) or CFrame.Angles(math.rad(35), 0, math.rad(20))
							local cf = CFrame.new(center) * tilt
							local spin = t * (ring == 1 and 1.2 or -1.6)
							for i = 1, N do
								local th = i / N * math.pi * 2 + spin
								local lp = Vector3.new(math.cos(th) * r, 0, math.sin(th) * r)
								local tan = Vector3.new(-math.sin(th), 0, math.cos(th))
								local wp = cf:PointToWorldSpace(lp)
								local p = f.halo[(ring - 1) * N + i]
								p.Size = Vector3.new(.1, .1, chord)
								p.Color = CFG.halo.color
								p.CFrame = CFrame.lookAt(wp, wp + cf:VectorToWorldSpace(tan))
							end
						end
					else
						ensure(f.halo, 0)
					end
				end
			end
		end))

		------------------------------------------------ Headless / Korblox / God / Bunnyhop
		local orig = { head = {}, kor = {} }
		local function setProp(key, part, prop, val)
			local o = orig[key]
			o[part] = o[part] or {}
			if o[part][prop] == nil then o[part][prop] = part[prop] end
			part[prop] = val
		end
		local function restoreKey(key)
			for part, props in pairs(orig[key]) do
				if part.Parent then
					for k, v in pairs(props) do pcall(function() part[k] = v end) end
				end
			end
			orig[key] = {}
		end
		local godWas = false
		track(RunService.Heartbeat:Connect(function()
			local ch = LP.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			if not hum or not root then return end

			if CFG.headless.on then
				local head = ch:FindFirstChild("Head")
				if head then
					setProp("head", head, "Transparency", 1)
					local face = head:FindFirstChildOfClass("Decal")
					if face then setProp("head", face, "Transparency", 1) end
				end
			elseif next(orig.head) then
				restoreKey("head")
			end

			if CFG.korblox.on then
				for _, n in ipairs({ "RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg" }) do
					local p = ch:FindFirstChild(n)
					if p then
						setProp("kor", p, "Color", Color3.fromRGB(28, 28, 34))
						setProp("kor", p, "Material", Enum.Material.Metal)
					end
				end
			elseif next(orig.kor) then
				restoreKey("kor")
			end

			if CFG.god.on then
				godWas = true
				pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
				if hum.Health < hum.MaxHealth and hum.Health > 0 then hum.Health = hum.MaxHealth end
			elseif godWas then
				godWas = false
				pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end)
			end

			if CFG.bhop.on then
				local md = hum.MoveDirection
				local hold = UIS:IsKeyDown(Enum.KeyCode.Space) or hum.Jump
				if hold and md.Magnitude > 0 then
					local v = root.AssemblyLinearVelocity
					if hum.FloorMaterial ~= Enum.Material.Air then
						hum:ChangeState(Enum.HumanoidStateType.Jumping)
						root.AssemblyLinearVelocity = Vector3.new(md.X * CFG.bhop.dist, math.max(hum.JumpPower, 45), md.Z * CFG.bhop.dist)
					else
						root.AssemblyLinearVelocity = Vector3.new(md.X * CFG.bhop.dist, v.Y, md.Z * CFG.bhop.dist)
					end
				end
			end
		end))

		------------------------------------------------ Походки (паки анимаций)
		local PACKS = {
			Ninja = { 656117400, 656118341, 656121766, 656118852, 656117878, 656115606, 656114359 },
			Superhero = { 616111295, 616113536, 616122287, 616117076, 616115533, 616108001, 616104706 },
			Robot = { 616088211, 616089559, 616095330, 616091570, 616090535, 616087089, 616086039 },
			Cartoony = { 742637544, 742638445, 742640026, 742638842, 742637942, 742637151, 742636889 },
			Zombie = { 616158929, 616160636, 616168032, 616163682, 616161997, 616157476, 616156119 },
			Mage = { 707742142, 707855907, 707897309, 707861613, 707853694, 707829716, 707826056 },
			Pirate = { 750781874, 750782770, 750785693, 750783738, 750782230, 750780242, 750779899 },
			Knight = { 657595757, 657568135, 657552124, 657564596, 658409194, 657600338, 658360781 },
			Astronaut = { 891621366, 891633237, 891667138, 891636393, 891627522, 891617961, 891609353 },
			Levitation = { 616006778, 616008087, 616013216, 616010382, 616008936, 616005863, 616003713 },
			Stylish = { 616136790, 616138447, 616146177, 616140816, 616139451, 616134815, 616133594 },
			Toy = { 782841498, 782845736, 782843345, 782842708, 782847020, 782846423, 782843869 },
			Vampire = { 1083445855, 1083450166, 1083473930, 1083462077, 1083455352, 1083443587, 1083439238 },
			Werewolf = { 1083195517, 1083214717, 1083178339, 1083216690, 1083218792, 1083189019, 1083182000 },
			Bubbly = { 910004836, 910009958, 910034870, 910025107, 910016857, 910001910, 909997997 },
			Elder = { 845397899, 845400520, 845403856, 845386501, 845398858, 845396048, 845392038 },
		}
		X.PACK_LIST = { "Ninja", "Superhero", "Robot", "Cartoony", "Zombie", "Mage", "Pirate", "Knight", "Astronaut", "Levitation", "Stylish", "Toy", "Vampire", "Werewolf", "Bubbly", "Elder" }
		local SLOTS = { { "idle", "Animation1" }, { "idle", "Animation2" }, { "walk", "WalkAnim" }, { "run", "RunAnim" }, { "jump", "JumpAnim" }, { "fall", "FallAnim" }, { "climb", "ClimbAnim" } }
		local origAnim, lastSig = {}, nil
		local function packTargets(ch)
			local an = ch:FindFirstChild("Animate")
			local out = {}
			if an then
				for i, s in ipairs(SLOTS) do
					local f = an:FindFirstChild(s[1])
					local a = f and f:FindFirstChild(s[2])
					if a then out[i] = a end
				end
			end
			return an, out
		end
		task.spawn(function()
			while alive do
				local ch = LP.Character
				if ch then
					local an, targets = packTargets(ch)
					if an then
						if CFG.anim.on then
							local sig = CFG.anim.pack .. tostring(ch)
							if sig ~= lastSig then
								lastSig = sig
								local pk = PACKS[CFG.anim.pack]
								for i, a in pairs(targets) do
									if origAnim[a] == nil then origAnim[a] = a.AnimationId end
									a.AnimationId = "rbxassetid://" .. pk[i]
								end
								an.Disabled = true
								task.wait(.05)
								an.Disabled = false
							end
						elseif lastSig then
							lastSig = nil
							for a, id in pairs(origAnim) do
								if a.Parent then a.AnimationId = id end
							end
							origAnim = {}
							an.Disabled = true
							task.wait(.05)
							an.Disabled = false
						end
					end
				end
				task.wait(.5)
			end
		end)

		------------------------------------------------ Эмоции
		local EMOTES = {
			["Wave"] = 507770239, ["Point"] = 507770453, ["Cheer"] = 507770677, ["Laugh"] = 507770818, ["Dance"] = 507771019,
			["Dance 2"] = 507776043, ["Dance 3"] = 507777268, ["Salute"] = 3360689775, ["Tilt"] = 3360692915,
			["Stadium"] = 3360686498, ["Shrug"] = 3576968026, ["Floss"] = 5917570207, ["Hype Dance"] = 3333499508,
		}
		X.EMOTE_LIST = { "Wave", "Point", "Cheer", "Laugh", "Dance", "Dance 2", "Dance 3", "Salute", "Tilt", "Stadium", "Shrug", "Floss", "Hype Dance" }
		local curTrack
		function X.stopEmote()
			if curTrack then
				pcall(function() curTrack:Stop(.2) end)
				curTrack = nil
			end
		end
		function X.playEmote()
			X.stopEmote()
			local ch = LP.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			if not hum then return false end
			local id = CFG.emote.id ~= "" and CFG.emote.id or tostring(EMOTES[CFG.emote.name] or "")
			if id == "" then return false end
			local animator = hum:FindFirstChildOfClass("Animator") or new("Animator", nil, hum)
			local a = new("Animation", { AnimationId = "rbxassetid://" .. id })
			local ok, tr = pcall(function() return animator:LoadAnimation(a) end)
			if not ok or not tr then return false end
			tr.Priority = Enum.AnimationPriority.Action
			tr.Looped = true
			tr:Play(.2)
			tr:AdjustSpeed(CFG.emote.speed)
			curTrack = tr
			return true
		end
		local stillT = 0
		track(RunService.Heartbeat:Connect(function(dt)
			if not CFG.emote.auto then
				stillT = 0
				return
			end
			local ch = LP.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			if not hum or not root or hum.Health <= 0 then return end
			local still = hum.MoveDirection.Magnitude < .1 and root.AssemblyLinearVelocity.Magnitude < 1.5
				and hum.FloorMaterial ~= Enum.Material.Air
			if still then
				stillT += dt
				if stillT > .5 and not (curTrack and curTrack.IsPlaying) then X.playEmote() end
			else
				stillT = 0
				if curTrack then X.stopEmote() end
			end
		end))

		------------------------------------------------ Auto grab gun
		local grabBusy, grabCool = false, {}
		track(RunService.Heartbeat:Connect(function()
			if not CFG.grab.on or grabBusy or not X.guns then return end
			local ch = LP.Character
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			if not root or not hum or hum.Health <= 0 then return end
			if X.roleOf(LP) == "Murderer" then return end
			local now = os.clock()
			for g in pairs(X.guns) do
				if g.Parent and (not grabCool[g] or grabCool[g] < now) then
					grabBusy = true
					grabCool[g] = now + 6
					task.spawn(function()
						local back = root.CFrame
						local part = g
						if g:IsA("Model") then part = g.PrimaryPart or g:FindFirstChildWhichIsA("BasePart", true) end
						if part then
							root.CFrame = part.CFrame * CFrame.new(0, 2, 0)
							if typeof(firetouchinterest) == "function" then
								pcall(function()
									firetouchinterest(root, part, 0)
									task.wait()
									firetouchinterest(root, part, 1)
								end)
							end
							local t0 = os.clock()
							while os.clock() - t0 < .7 and g.Parent do task.wait(.05) end
							if root.Parent then root.CFrame = back end
						end
						grabBusy = false
					end)
					break
				end
			end
		end))

		------------------------------------------------ Skin changer
		local function C3(t) return Color3.fromRGB(t[1], t[2], t[3]) end
		-- {имя, цвет1, цвет2, радужный}
		local function hsh(s)
			local h = 0
			for i = 1, #s do h = (h * 31 + s:byte(i)) % 360 end
			return h / 360
		end
		local function rgbOf(c) return { math.floor(c.R * 255 + .5), math.floor(c.G * 255 + .5), math.floor(c.B * 255 + .5) } end
		local function mkList(names)
			local out = {}
			for _, n in ipairs(names) do
				local h = hsh(n)
				out[#out + 1] = {
					n, rgbOf(Color3.fromHSV(h, .65, .95)), rgbOf(Color3.fromHSV((h + .08) % 1, .8, .5)),
					(n:sub(1, 6) == "Chroma") or n == "Rainbow Gun" or n == "Prismatic" or n == "Prismatic Gun",
				}
			end
			return out
		end
		X.SKINS = {
			Gun = mkList({
				"Rainbow Gun", "Raygun", "Red Luger", "Shark", "Snowcannon", "Soul", "Spectre", "Sugar", "Sunrise", "Swirly Gun",
				"Traveler's Gun", "Vampire's Gun", "Watergun", "Xenoshot", "Laser", "Elderwood Revolver", "Candy Gun", "Chroma Luger",
				"Chroma Shark", "Chroma Tides", "Chroma Fade", "Chroma Heat Gun", "Constellation", "Ice Cannon", "Frostbite Gun",
				"Blossom Gun", "Pumpkin Gun", "Ghost Gun", "Heartbreaker", "Prismatic Gun", "Virtual Gun", "Bubblegum Gun", "Cyber Gun",
				"Golden Gun", "Neon Gun", "Plasma Gun", "Dragon Gun", "Galaxy Gun",
			}),
			Knife = mkList({
				"Chroma Seer", "Chroma Fang", "Chroma Heat", "Chroma Slasher", "Chroma Gemstone", "Chroma Saw", "Chroma Boneblade",
				"Chroma Darkbringer", "Chroma Lightbringer", "Seer", "Fang", "Heat", "Slasher", "Gemstone", "Saw", "Boneblade", "Harvester",
				"Nikilis", "Ice Dragon", "Corrupt", "Lightbringer", "Darkbringer", "Icepiercer", "Batwing", "Eternal", "Eternal II",
				"Eternal III", "Eternal IV", "Gingerblade", "Heartblade", "Pumpking", "Blossom", "Hallow's Blade", "Ghostblade",
				"Cookiecane", "Candy Knife", "Flames", "Frostbite", "Bioblade", "Icewing", "Elderwood Scythe", "Elderwood Blade", "Ocean",
				"Swirly Blade", "Handlebar", "Prismatic", "Virtual", "Peppermint", "Deathshard", "Chill", "Fade", "Iceblade", "Xmas",
				"Splitter", "Prince", "Tides",
			}),
			Items = mkList({
				"Teddy Bear", "C4", "Rubber Duck", "Balloon", "Boombox", "Crown", "Gem", "Heart", "Star", "Lantern", "Ghost", "Pet Rock",
				"Candle", "Bomb", "Trophy", "Present", "Pizza", "Donut", "Bat", "Flashlight",
			}),
		}

		local byName = {}
		for kind, list in pairs(X.SKINS) do
			for _, s in ipairs(list) do byName[kind .. "|" .. s[1]] = s end
		end

		local function norm(s) return (s:lower():gsub("[^%w]", "")) end
		local assetIdx, idxT = {}, 0
		local function buildIdx()
			assetIdx = {}
			idxT = os.clock()
			local roots = { ReplicatedStorage, game:GetService("StarterPack"), LP:FindFirstChild("Backpack"), LP.Character }
			for _, r in ipairs(roots) do
				if r then
					for _, d in ipairs(r:GetDescendants()) do
						if d:IsA("Tool") or d:IsA("Model") or d:IsA("MeshPart") then
							local k = norm(d.Name)
							if not assetIdx[k] or d:IsA("Tool") then assetIdx[k] = d end
						end
					end
				end
			end
		end
		local function findAsset(name)
			if idxT == 0 then buildIdx() end
			local k = norm(name)
			local f = assetIdx[k]
			if not f and os.clock() - idxT > 15 then
				buildIdx()
				f = assetIdx[k]
			end
			return f
		end
		X.findAsset = findAsset
		X.rebuildAssets = function() idxT = 0 end

		-- реальные инструменты игры (для вкладки Found)
		local foundGiven = {}
		function X.scanFound()
			local out, seen = {}, {}
			for _, r in ipairs({ ReplicatedStorage, game:GetService("StarterPack"), LP:FindFirstChild("Backpack") }) do
				if r then
					for _, d in ipairs(r:GetDescendants()) do
						if d:IsA("Tool") and not seen[d.Name] and #out < 400 then
							seen[d.Name] = true
							out[#out + 1] = d
						end
					end
				end
			end
			table.sort(out, function(a, b) return a.Name < b.Name end)
			return out
		end
		function X.toggleFound(tool)
			if foundGiven[tool.Name] then
				foundGiven[tool.Name]:Destroy()
				foundGiven[tool.Name] = nil
				return false
			end
			local bp = LP:FindFirstChild("Backpack")
			if not bp then return false end
			local ok, c = pcall(function() return tool:Clone() end)
			if not ok or not c then return false end
			c.Parent = bp
			foundGiven[tool.Name] = c
			return true
		end
		X.hasFound = function(name) return foundGiven[name] ~= nil end

		local origTool = {}
		local applied = {}
		local function clearSkin(tool)
			for _, d in ipairs(tool:GetDescendants()) do
				if d.Name == "NH_SkinPart" then d:Destroy() end
			end
			for p, o in pairs(origTool) do
				if p.Parent and p:IsDescendantOf(tool) then
					for k, v in pairs(o) do pcall(function() p[k] = v end) end
				end
			end
			applied[tool] = nil
		end
		local rainbowParts = {}
		local function applySkin(tool, s)
			local handle = tool:FindFirstChild("Handle")
			if not handle then return end
			local asset = findAsset(s[1])
			local done = false
			if asset then
				local clone = asset:Clone()
				local ref = clone:FindFirstChild("Handle", true) or clone:FindFirstChildWhichIsA("BasePart", true)
				if ref then
					handle.Transparency = 1
					for _, p in ipairs(clone:GetDescendants()) do
						if p:IsA("BasePart") then
							local off = ref.CFrame:ToObjectSpace(p.CFrame)
							local np = p:Clone()
							np.Name = "NH_SkinPart"
							np.Anchored = false
							np.CanCollide = false
							np.Massless = true
							np.CFrame = handle.CFrame * off
							np.Parent = tool
							new("WeldConstraint", { Part0 = handle, Part1 = np }, np)
						end
					end
					done = true
				end
				clone:Destroy()
			end
			if not done then
				for _, d in ipairs(tool:GetDescendants()) do
					if d:IsA("BasePart") and d.Name ~= "NH_SkinPart" then
						origTool[d] = origTool[d] or { Color = d.Color, Material = d.Material }
						d.Color = C3(s[2])
						d.Material = Enum.Material.Neon
						if s[4] then rainbowParts[d] = true end
					end
				end
			end
			applied[tool] = s[1]
		end
		task.spawn(function()
			while alive do
				for kind, toolName in pairs({ gun = "Gun", knife = "Knife" }) do
					local want = CFG.skin[kind]
					local list = kind == "gun" and "Gun" or "Knife"
					for _, holder in ipairs({ LP.Character, LP:FindFirstChild("Backpack") }) do
						local tool = holder and holder:FindFirstChild(toolName)
						if tool and tool:IsA("Tool") then
							if want ~= "" and applied[tool] ~= want then
								if applied[tool] then clearSkin(tool) end
								local s = byName[list .. "|" .. want]
								if s then pcall(applySkin, tool, s) end
							elseif want == "" and applied[tool] then
								clearSkin(tool)
							end
						end
					end
				end
				task.wait(.5)
			end
		end)
		track(RunService.RenderStepped:Connect(function()
			if next(rainbowParts) then
				local c = Color3.fromHSV((os.clock() * .3) % 1, .85, 1)
				for p in pairs(rainbowParts) do
					if p.Parent then p.Color = c else rainbowParts[p] = nil end
				end
			end
		end))

		-- предметы в инвентаре (локальные Tool)
		local given = {}
		function X.toggleItem(name)
			if given[name] then
				given[name]:Destroy()
				given[name] = nil
				return false
			end
			local s = byName["Items|" .. name]
			local bp = LP:FindFirstChild("Backpack")
			if not s or not bp then return false end
			local tool = new("Tool", { Name = name, CanBeDropped = false, ToolTip = name, RequiresHandle = true })
			local h = new("Part", {
				Name = "Handle", Shape = Enum.PartType.Ball, Size = Vector3.new(1.3, 1.3, 1.3), Color = C3(s[2]),
				Material = Enum.Material.SmoothPlastic, CanCollide = false,
			}, tool)
			local function bit(size, off, col, shape)
				local p = new("Part", {
					Size = size, Color = col, Material = Enum.Material.SmoothPlastic, CanCollide = false, Massless = true,
					Shape = shape or Enum.PartType.Ball,
				}, tool)
				p.CFrame = h.CFrame * CFrame.new(off)
				new("WeldConstraint", { Part0 = h, Part1 = p }, p)
			end
			if name == "C4" or name == "Bomb" then
				h.Shape = Enum.PartType.Block
				h.Size = Vector3.new(1.5, 1, .6)
				h.Color = Color3.fromRGB(190, 40, 40)
				bit(Vector3.new(1, .4, .1), Vector3.new(0, .1, -.35), Color3.fromRGB(20, 20, 24), Enum.PartType.Block)
				bit(Vector3.new(.1, .6, .1), Vector3.new(.5, .7, 0), Color3.fromRGB(230, 230, 230), Enum.PartType.Block)
				bit(Vector3.new(.3, .3, .1), Vector3.new(-.4, .1, -.35), Color3.fromRGB(80, 255, 90), Enum.PartType.Block)
			else
				bit(Vector3.new(.55, .55, .55), Vector3.new(-.5, .75, 0), C3(s[3]))
				bit(Vector3.new(.55, .55, .55), Vector3.new(.5, .75, 0), C3(s[3]))
				bit(Vector3.new(.6, .6, .6), Vector3.new(0, -.2, -.6), C3(s[3]))
			end
			tool.Parent = bp
			given[name] = tool
			return true
		end
		X.hasItem = function(name) return given[name] ~= nil end

		------------------------------------------------ Выгрузка
		local prevUnload = X.extraUnload
		X.extraUnload = function()
			if prevUnload then pcall(prevUnload) end
			for plr in pairs(fx) do killFx(plr) end
			for _, t in pairs(given) do pcall(function() t:Destroy() end) end
			pcall(restoreKey, "head")
			pcall(restoreKey, "kor")
			pcall(X.stopEmote)
			for tool in pairs(applied) do
				if tool.Parent then pcall(clearSkin, tool) end
			end
			for a, id in pairs(origAnim) do
				if a.Parent then a.AnimationId = id end
			end
		end
	end
	run()
end

----------------------------------------------------------------
-- НОВОЕ: UI (Gun, Emote, дополнения Visual / Player / Misc)
----------------------------------------------------------------
do
	local function run()
		local FL = X.FLabel

		local function IdBox(parent, ph, get, set)
			local tb = new("TextBox", {
				Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.field, BorderSizePixel = 0, Font = Enum.Font.GothamMedium,
				TextSize = 12, TextColor3 = C.text, PlaceholderText = ph, PlaceholderColor3 = C.sub, Text = get(),
				ClearTextOnFocus = false, LayoutOrder = ord(),
			}, parent)
			corner(tb, 8)
			stroke(tb, C.line, 1)
			tb.FocusLost:Connect(function()
				local digits = tb.Text:gsub("%D", "")
				set(digits)
				tb.Text = digits
			end)
			X.reg(function() tb.Text = get() end)
			return tb
		end

		-- цвета стрелок: убийца / шериф / каждый игрок отдельно
		X.arrowDrawer = function(dr)
			FL(dr, "Murderer arrow")
			ColorPicker(dr, CFG.arrows, "murder")
			FL(dr, "Sheriff arrow")
			ColorPicker(dr, CFG.arrows, "sheriff")
			FL(dr, "Pick a player / tap the circle to change his arrow color")
			X.PlayerList(dr, 150, function() end, true, nil, CFG.acolor)
		end

		------------------------------------------------------------ Visual: прицел, пуля, крылья
		X.visualExtra = function(L, R)
			local cX = Card(L, "Crosshair")
			Toggle(cX, "Custom crosshair", CFG.xhair, "on", function(dr)
				FL(dr, "Preview")
				local stage = new("Frame", {
					Size = UDim2.new(1, 0, 0, 90), BackgroundColor3 = C.field, BorderSizePixel = 0, LayoutOrder = ord(),
					ClipsDescendants = true,
				}, dr)
				corner(stage, 10)
				stroke(stage, C.line, 1)
				local pool = {}
				track(RunService.RenderStepped:Connect(function()
					if not stage.Parent then return end
					local sc = math.max(fitScale.Scale * animScale.Scale, .01)
					local w = stage.AbsoluteSize.X / sc
					local ang = CFG.xhair.spin and (os.clock() * math.rad(CFG.xhair.speed)) or 0
					X.drawShape(pool, stage, w / 2, 45, CFG.xhair.shape, math.min(CFG.xhair.size, 36), CFG.xhair.thick, CFG.xhair.color, ang)
				end))
				X.Grid(dr, X.SHAPE_LIST, function() return CFG.xhair.shape end, function(n) CFG.xhair.shape = n end, 3)
				ColorPicker(dr, CFG.xhair, "color")
				Slider(dr, "Size", 4, 40, CFG.xhair, "size")
				Slider(dr, "Thickness", 1, 6, CFG.xhair, "thick")
				Toggle(dr, "Spin", CFG.xhair, "spin")
				Slider(dr, "Spin speed", 10, 720, CFG.xhair, "speed", { fmt = function(v) return v .. " deg/s" end })
			end)
			local cB = Card(L, "Bullet")
			Toggle(cB, "Bullet path", CFG.bpath, "on", function(dr)
				ColorPicker(dr, CFG.bpath, "color")
				Slider(dr, "Fade time", 5, 80, CFG.bpath, "time", { div = 10, fmt = function(v) return v .. " s" end })
			end)

			local cC = Card(R, "Cosmetics")
			Toggle(cC, "Wings", CFG.wings, "on", function(dr)
				ColorPicker(dr, CFG.wings, "color")
				Slider(dr, "Wing length", 15, 80, CFG.wings, "len", { div = 10 })
				Slider(dr, "Wing width", 5, 20, CFG.wings, "width", { div = 10 })
				Dropdown(dr, "Show for", { "Only me", "Everyone" }, CFG.wings, "scope")
			end)
			Toggle(cC, "Halo", CFG.halo, "on", function(dr)
				ColorPicker(dr, CFG.halo, "color")
				Slider(dr, "Radius", 8, 40, CFG.halo, "radius", { div = 10 })
			end)
		end

		------------------------------------------------------------ Player: внешний вид, bhop, походки
		X.playerExtra = function(L, R)
			local cA = Card(L, "Appearance")
			Toggle(cA, "Headless", CFG.headless, "on")
			Toggle(cA, "Korblox", CFG.korblox, "on")
			Toggle(cA, "God mode", CFG.god, "on")
			local cH = Card(R, "Extra movement")
			Toggle(cH, "Bunnyhop", CFG.bhop, "on", function(dr)
				Slider(dr, "Jump distance", 20, 120, CFG.bhop, "dist")
				FL(dr, "Hold jump while moving")
			end)
			local cW = Card(R, "Animations")
			Toggle(cW, "Animation pack", CFG.anim, "on", function(dr)
				X.Grid(dr, X.PACK_LIST, function() return CFG.anim.pack end, function(n) CFG.anim.pack = n end, 2)
			end)
		end

		------------------------------------------------------------ Misc: auto grab, звук попадания
		X.miscExtra = function(L, R)
			local cG = Card(L, "Combat")
			Toggle(cG, "Auto grab gun", CFG.grab, "on", function(dr)
				FL(dr, "Teleports to the dropped gun and back")
			end)
			Toggle(cG, "Hit sound", CFG.hsound, "on", function(dr)
				X.Grid(dr, X.SOUND_LIST, function() return CFG.hsound.id == "" and CFG.hsound.sound or "" end, function(n)
					CFG.hsound.sound = n
					CFG.hsound.id = ""
				end, 3)
				Slider(dr, "Volume", 1, 10, CFG.hsound, "volume")
				FL(dr, "Or paste a sound ID")
				IdBox(dr, "Sound ID", function() return CFG.hsound.id end, function(v) CFG.hsound.id = v end)
				Button(dr, "Test sound", function() X.playHit() end)
			end)
		end

		------------------------------------------------------------ Gun: skin changer
		local function art(parent, kind, c1, c2)
			local parts = {}
			local function box(w, h, x, y, rot, col, rad)
				local f = new("Frame", {
					AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
					Rotation = rot, BackgroundColor3 = col, BorderSizePixel = 0,
				}, parent)
				corner(f, rad or 3)
				parts[#parts + 1] = f
				return f
			end
			if kind == "Gun" then
				box(36, 12, 28, 18, 0, c1, 4)
				box(12, 6, 52, 20, 0, c2, 2)
				box(9, 20, 20, 32, 14, c2, 3)
				box(8, 4, 40, 28, 0, c1, 2)
			elseif kind == "Knife" then
				box(36, 8, 36, 20, -38, c1, 4)
				box(8, 14, 22, 30, -38, c2, 2)
				box(14, 6, 16, 38, -38, c2, 3)
			else
				box(26, 26, 30, 28, 0, c1, 13)
				box(12, 12, 20, 12, 0, c2, 6)
				box(12, 12, 40, 12, 0, c2, 6)
				box(10, 10, 30, 32, 0, c2, 5)
			end
			return parts
		end

		local function thumb(parent, asset)
			local vp = new("ViewportFrame", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(170, 170, 180),
				LightColor = WHITE, LightDirection = Vector3.new(-1, -1, -.5), ZIndex = 3,
			}, parent)
			local model = new("Model", nil, vp)
			local count = 0
			local function add(p)
				if count >= 60 then return end
				local ok, c = pcall(function() return p:Clone() end)
				if ok and c then
					for _, ch in ipairs(c:GetChildren()) do
						if ch:IsA("LuaSourceContainer") then ch:Destroy() end
					end
					c.Anchored = true
					c.Parent = model
					count += 1
				end
			end
			if asset:IsA("BasePart") then
				add(asset)
			else
				for _, d in ipairs(asset:GetDescendants()) do
					if d:IsA("BasePart") then add(d) end
				end
			end
			if count == 0 then
				vp:Destroy()
				return false
			end
			local cf, size = model:GetBoundingBox()
			local cam = new("Camera", { FieldOfView = 35 }, vp)
			vp.CurrentCamera = cam
			local dist = math.max(size.Magnitude, 1) * 1.6
			cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(1, .55, 1).Unit * dist, cf.Position)
			return true
		end

		X.buildGun = function()
			local sf = createTab("Gun", "target", "skin changer")
			new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, sf)

			local cTop = Card(sf, "Skin changer")
			local cat, query = "Gun", ""
			local filter, buildFound, render
			local tiles, rainbow, queue = {}, {}, {}
			X.Grid(cTop, { "Gun", "Knife", "Items", "Found" }, function() return cat end, function(n)
				cat = n
				if n == "Found" then buildFound() end
				filter()
			end, 4)
			local sb = new("TextBox", {
				Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.field, BorderSizePixel = 0, Font = Enum.Font.GothamMedium,
				TextSize = 12, TextColor3 = C.text, PlaceholderText = "Search skin...", PlaceholderColor3 = C.sub, Text = "",
				ClearTextOnFocus = false, LayoutOrder = ord(),
			}, cTop)
			corner(sb, 8)
			stroke(sb, C.line, 1)
			Label(cTop, "Real models from the game are shown as photos. Skins are applied on your client (only you see them).", C.sub, 11)

			local cGrid = Card(sf, nil)
			local holder = new("Frame", {
				Size = UDim2.new(1, 0, 0, 60), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = ord(),
			}, cGrid)
			new("UIGridLayout", {
				CellSize = UDim2.fromOffset(68, 84), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder,
			}, holder)

			local function makeTile(kind, name, c1, c2, rb, asset)
				local idx = #tiles + 1
				local b = new("TextButton", {
					Size = UDim2.fromOffset(68, 84), BackgroundColor3 = Color3.fromRGB(16, 14, 24), BorderSizePixel = 0,
					AutoButtonColor = false, Text = "", Visible = false, LayoutOrder = idx,
				}, holder)
				corner(b, 10)
				local st = stroke(b, Color3.fromRGB(150, 60, 220), 1.5)
				local artBox = new("Frame", {
					Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(60, 50), BackgroundColor3 = c2,
					BackgroundTransparency = .82, BorderSizePixel = 0, ClipsDescendants = true,
				}, b)
				corner(artBox, 8)
				local parts = art(artBox, kind == "Found" and "Items" or kind, c1, c2)
				if rb then
					for _, p in ipairs(parts) do rainbow[#rainbow + 1] = p end
				end
				new("TextLabel", {
					BackgroundTransparency = 1, Position = UDim2.fromOffset(2, 56), Size = UDim2.fromOffset(64, 26),
					Font = Enum.Font.GothamMedium, Text = name, TextSize = 9, TextColor3 = C.text, TextWrapped = true,
				}, b)
				local t = { btn = b, st = st, kind = kind, name = name, parts = parts, art = artBox, asset = asset }
				tiles[idx] = t
				b.MouseButton1Click:Connect(function()
					if kind == "Items" then
						X.toggleItem(name)
					elseif kind == "Found" then
						X.toggleFound(asset)
					else
						local key = kind:lower()
						CFG.skin[key] = (CFG.skin[key] == name) and "" or name
					end
					X.refreshAll()
				end)
				return t
			end

			for _, kind in ipairs({ "Gun", "Knife", "Items" }) do
				for _, s in ipairs(X.SKINS[kind]) do
					makeTile(kind, s[1], Color3.fromRGB(s[2][1], s[2][2], s[2][3]), Color3.fromRGB(s[3][1], s[3][2], s[3][3]), s[4], nil)
				end
			end

			-- загрузка фото (ViewportFrame с реальными моделями) по очереди
			task.spawn(function()
				while alive do
					local n = 0
					while #queue > 0 and n < 3 do
						local t = table.remove(queue, 1)
						n += 1
						local asset = t.asset or X.findAsset(t.name)
						if asset then
							local ok, res = pcall(thumb, t.art, asset)
							if ok and res then
								for _, p in ipairs(t.parts) do p.Visible = false end
							end
						end
					end
					task.wait(.05)
				end
			end)
			track(RunService.RenderStepped:Connect(function()
				local col = Color3.fromHSV((os.clock() * .3) % 1, .8, 1)
				for _, p in ipairs(rainbow) do
					if p.Visible then p.BackgroundColor3 = col end
				end
			end))

			function filter()
				for _, t in ipairs(tiles) do
					local show = t.kind == cat and (query == "" or t.name:lower():find(query, 1, true) ~= nil)
					t.btn.Visible = show
					if show and not t.done then
						t.done = true
						queue[#queue + 1] = t
					end
				end
			end
			function render()
				for _, t in ipairs(tiles) do
					local sel
					if t.kind == "Items" then
						sel = X.hasItem(t.name)
					elseif t.kind == "Found" then
						sel = X.hasFound(t.name)
					else
						sel = CFG.skin[t.kind:lower()] == t.name
					end
					t.st.Color = sel and WHITE or Color3.fromRGB(150, 60, 220)
					t.st.Thickness = sel and 2.5 or 1.5
				end
			end
			local builtFound = false
			function buildFound()
				if builtFound then return end
				builtFound = true
				for _, tool in ipairs(X.scanFound()) do
					makeTile("Found", tool.Name, Color3.fromRGB(150, 110, 255), Color3.fromRGB(70, 50, 120), false, tool)
				end
				render()
			end
			sb:GetPropertyChangedSignal("Text"):Connect(function()
				query = sb.Text:lower()
				filter()
			end)
			X.reg(render)
			render()
			filter()
			Button(cTop, "Rescan game assets", function()
				for i = #tiles, 1, -1 do
					if tiles[i].kind == "Found" then
						tiles[i].btn:Destroy()
						table.remove(tiles, i)
					end
				end
				builtFound = false
				X.rebuildAssets()
				for _, t in ipairs(tiles) do
					if t.done then
						t.done = false
						for _, p in ipairs(t.parts) do p.Visible = true end
						for _, c in ipairs(t.art:GetChildren()) do
							if c:IsA("ViewportFrame") then c:Destroy() end
						end
					end
				end
				if cat == "Found" then buildFound() end
				filter()
				render()
			end)
			Button(cTop, "Reset skins", function()
				CFG.skin.gun, CFG.skin.knife = "", ""
				for _, t in ipairs(tiles) do
					if t.kind == "Items" and X.hasItem(t.name) then X.toggleItem(t.name) end
					if t.kind == "Found" and X.hasFound(t.name) then X.toggleFound(t.asset) end
				end
				X.refreshAll()
			end)
		end

		------------------------------------------------------------ Emote
		X.buildEmote = function()
			local sf = createTab("Emote", "emote", "emotes")
			local L, R = Columns(sf)
			local idbox
			local c1 = Card(L, "Emote")
			Toggle(c1, "Auto emote", CFG.emote, "auto")
			Label(c1, "Plays the chosen emote when you stop moving", C.sub, 11)
			X.Grid(c1, X.EMOTE_LIST, function() return CFG.emote.id ~= "" and "" or CFG.emote.name end, function(n)
				CFG.emote.name = n
				CFG.emote.id = ""
				if idbox then idbox.Text = "" end
			end, 2)
			local c2 = Card(R, "Any emote (ID)")
			Label(c2, "Paste the animation asset ID of any emote, including paid ones", C.sub, 11)
			idbox = IdBox(c2, "Animation ID", function() return CFG.emote.id end, function(v) CFG.emote.id = v end)
			Slider(c2, "Speed", 3, 30, CFG.emote, "speed", { div = 10 })
			Button(c2, "Play", function() X.playEmote() end, C.accent)
			Button(c2, "Stop", function() X.stopEmote() end)
		end
	end
	run()
end

----------------------------------------------------------------
-- СТРАНИЦЫ: Visual / Player / World / Misc / Config / Setting
----------------------------------------------------------------
do
	local function build()
		local FL, DR, Grid, PL = X.FLabel, X.DrawerRow, X.Grid, X.PlayerList
		local function pct(v) return math.floor(v * 100 + .5) .. "%" end

		------------------------------------------------------------ VISUAL
		local sfV = createTab("Visual", "eye", "esp & render")
		local L, R = Columns(sfV)

		local cGen = Card(L, "General")
		Toggle(cGen, "ESP master", CFG.esp, "on")
		Toggle(cGen, "Role colors", CFG.esp, "roles")
		Slider(cGen, "Max distance", 100, 5000, CFG.esp, "maxDist", { fmt = function(v) return v .. " st" end })
		DR(cGen, "ESP for...", function(dr)
			FL(dr, "Show ESP only for")
			Grid(dr, { "All", "Murder", "Sheriff" }, function() return CFG.target.mode end, function(n) CFG.target.mode = n end, 3)
			FL(dr, "Pick a player / tap the circle to change his color")
			PL(dr, 150, function(plr)
				CFG.target.mode = "Player"
				CFG.target.userId = plr.UserId
			end, true, function(plr) return CFG.target.mode == "Player" and CFG.target.userId == plr.UserId end)
		end)

		local cBox = Card(L, "Boxes")
		Toggle(cBox, "Esp box 2D", CFG.box2d, "on", function(dr) ColorPicker(dr, CFG.box2d, "color") end)
		Toggle(cBox, "Esp box 3D", CFG.box3d, "on", function(dr) ColorPicker(dr, CFG.box3d, "color") end)
		Toggle(cBox, "Corner box", CFG.corner, "on", function(dr)
			ColorPicker(dr, CFG.corner, "color")
			Slider(dr, "Length", 8, 80, CFG.corner, "len", { fmt = function(v) return v .. " px" end })
		end)
		Toggle(cBox, "Filled box", CFG.fill, "on", function(dr)
			GradientPicker(dr, CFG.fill, "c1", "c2")
			Slider(dr, "Transparency", 0, 100, CFG.fill, "trans", { div = 100, fmt = pct })
		end)

		local cInfo = Card(L, "Info")
		Toggle(cInfo, "Show nickname", CFG.name, "on", function(dr) ColorPicker(dr, CFG.name, "color") end)
		Toggle(cInfo, "Show distance", CFG.dist, "on", function(dr) ColorPicker(dr, CFG.dist, "color") end)
		Toggle(cInfo, "Show health", CFG.health, "on", function(dr) ColorPicker(dr, CFG.health, "color") end)
		Toggle(cInfo, "Show avatar", CFG.avatar, "on", function(dr) ColorPicker(dr, CFG.avatar, "color") end)

		local cHud = Card(L, "HUD")
		Toggle(cHud, "Show FPS", CFG.fps, "on", function(dr)
			ColorPicker(dr, CFG.fps, "color")
			Toggle(dr, "Custom FPS", CFG.fps, "custom")
			local row = new("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, LayoutOrder = ord() }, dr)
			local tb = new("TextBox", {
				Size = UDim2.fromOffset(84, 38), BackgroundColor3 = C.field, BorderSizePixel = 0, Font = Enum.Font.GothamBold,
				TextSize = 16, TextColor3 = C.accent, Text = tostring(CFG.fps.value), ClearTextOnFocus = false,
				PlaceholderText = "999", PlaceholderColor3 = C.sub,
			}, row)
			corner(tb, 10)
			stroke(tb, C.line, 1.5)
			new("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(92, 0), Size = UDim2.new(1, -92, 1, 0),
				Font = Enum.Font.GothamMedium, Text = "Drag the badge across the screen", TextSize = 10, TextColor3 = C.sub,
				TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
			}, row)
			tb.FocusLost:Connect(function()
				local n = tonumber(tb.Text)
				if n then CFG.fps.value = math.clamp(math.floor(n), 1, 99999) end
				tb.Text = tostring(CFG.fps.value)
			end)
			X.reg(function() tb.Text = tostring(CFG.fps.value) end)

			local st = new("TextButton", {
				Size = UDim2.new(1, 0, 0, 90), BackgroundColor3 = WHITE, BorderSizePixel = 0, AutoButtonColor = false,
				Text = "", LayoutOrder = ord(),
			}, dr)
			corner(st, 10)
			stroke(st, C.line, 1)
			new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(40, 44, 78), Color3.fromRGB(16, 17, 30)) }, st)
			local badge = new("TextLabel", {
				Size = UDim2.fromOffset(58, 18), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, Text = "60 FPS",
			}, st)
			local function place()
				badge.AnchorPoint = Vector2.new(CFG.fps.x, CFG.fps.y)
				badge.Position = UDim2.fromScale(CFG.fps.x, CFG.fps.y)
				badge.TextColor3 = CFG.fps.color
			end
			place()
			X.reg(place)
			track(RunService.RenderStepped:Connect(function() badge.TextColor3 = CFG.fps.color end))
			local dragging = false
			local function upd(i)
				local pos = (i.UserInputType == Enum.UserInputType.Touch) and Vector2.new(i.Position.X, i.Position.Y) or UIS:GetMouseLocation()
				CFG.fps.x = math.clamp((pos.X - st.AbsolutePosition.X) / math.max(st.AbsoluteSize.X, 1), 0, 1)
				CFG.fps.y = math.clamp((pos.Y - st.AbsolutePosition.Y) / math.max(st.AbsoluteSize.Y, 1), 0, 1)
				place()
			end
			st.InputBegan:Connect(function(i)
				if isPress(i) then
					dragging = true
					upd(i)
				end
			end)
			track(UIS.InputChanged:Connect(function(i) if dragging and isMove(i) then upd(i) end end))
			track(UIS.InputEnded:Connect(function(i) if dragging and isPress(i) then dragging = false end end))
		end)

		local cRen = Card(R, "Render")
		Toggle(cRen, "Chams", CFG.chams, "on", function(dr)
			ColorPicker(dr, CFG.chams, "color")
			Slider(dr, "Fill transparency", 0, 100, CFG.chams, "trans", { div = 100, fmt = pct })
		end)
		Toggle(cRen, "Outline", CFG.outline, "on", function(dr) ColorPicker(dr, CFG.outline, "color") end)
		Toggle(cRen, "Wall check", CFG.wall, "on", function(dr)
			FL(dr, "Color behind a wall")
			ColorPicker(dr, CFG.wall, "hid")
			FL(dr, "Color when visible")
			ColorPicker(dr, CFG.wall, "vis")
		end)
		Toggle(cRen, "Glow", CFG.glow, "on", function(dr)
			ColorPicker(dr, CFG.glow, "color")
			Slider(dr, "Range", 5, 60, CFG.glow, "range")
			Slider(dr, "Brightness", 5, 60, CFG.glow, "bright", { div = 10 })
		end)
		Toggle(cRen, "Custom FOV", CFG.fov, "on", function(dr)
			Slider(dr, "Field of view", 30, 120, CFG.fov, "val")
		end)
		Toggle(cRen, "Third person", CFG.third, "on", function(dr)
			Slider(dr, "Distance", 4, 40, CFG.third, "dist", { fmt = function(v) return v .. " st" end })
		end)

		local cLin = Card(R, "Lines")
		Toggle(cLin, "Line / Tracers", CFG.tracer, "on", function(dr)
			Dropdown(dr, "Line origin", { "Crosshair", "Bottom", "Top" }, CFG.tracer, "origin")
			ColorPicker(dr, CFG.tracer, "color")
		end)
		Toggle(cLin, "Skeleton", CFG.skel, "on", function(dr) ColorPicker(dr, CFG.skel, "color") end)
		Toggle(cLin, "Show head", CFG.head, "on", function(dr) ColorPicker(dr, CFG.head, "color") end)
		Toggle(cLin, "Enemy arrows", CFG.arrows, "on", function(dr)
			ColorPicker(dr, CFG.arrows, "color")
			Slider(dr, "Radius", 60, 400, CFG.arrows, "radius", { fmt = function(v) return v .. " px" end })
			Slider(dr, "Size", 8, 30, CFG.arrows, "size")
			X.arrowDrawer(dr)
		end)

		local cItem = Card(R, "Items")
		Toggle(cItem, "Gun ESP", CFG.gun, "on", function(dr)
			ColorPicker(dr, CFG.gun, "color")
			Toggle(dr, "Show text", CFG.gun, "text", function(d2) ColorPicker(d2, CFG.gun, "textColor") end)
			Toggle(dr, "Tracers", CFG.gun, "tracer")
		end)
		Toggle(cItem, "Coin ESP", CFG.coin, "on", function(dr)
			ColorPicker(dr, CFG.coin, "color")
			Toggle(dr, "Show text", CFG.coin, "text", function(d2) ColorPicker(d2, CFG.coin, "textColor") end)
		end)

		local cEx = Card(R, "Extras")
		Toggle(cEx, "Hat", CFG.hat, "on", function(dr)
			Dropdown(dr, "Hat style", { "Lines", "Solid", "Both" }, CFG.hat, "mode")
			ColorPicker(dr, CFG.hat, "color")
			Toggle(dr, "Rainbow lines", CFG.hat, "rainbow")
			Toggle(dr, "Shimmer color", CFG.hat, "shimmer")
			Slider(dr, "Lines", 4, 60, CFG.hat, "lines")
			Slider(dr, "Transparency", 0, 100, CFG.hat, "trans", { div = 100, fmt = pct })
			Slider(dr, "Size", 50, 200, CFG.hat, "size", { fmt = function(v) return v .. "%" end })
			Dropdown(dr, "Show for", { "Everyone", "Only me" }, CFG.hat, "scope")
		end)
		Toggle(cEx, "Trails", CFG.trail, "on", function(dr)
			ColorPicker(dr, CFG.trail, "color")
			Slider(dr, "Length", 2, 50, CFG.trail, "len", { div = 10, fmt = function(v) return v .. " s" end })
			Slider(dr, "Width", 2, 40, CFG.trail, "width", { div = 10 })
			Dropdown(dr, "Show for", { "Everyone", "Only me" }, CFG.trail, "scope")
		end)
		Toggle(cEx, "Footsteps", CFG.steps, "on", function(dr)
			ColorPicker(dr, CFG.steps, "color")
			Slider(dr, "Fade time", 5, 80, CFG.steps, "life", { div = 10, fmt = function(v) return v .. " s" end })
			Slider(dr, "Step distance", 10, 100, CFG.steps, "dist", { div = 10, fmt = function(v) return v .. " st" end })
			Slider(dr, "Step delay", 0, 20, CFG.steps, "delay", { div = 10, fmt = function(v) return v .. " s" end })
			Dropdown(dr, "Shape", { "Circle", "Square", "Diamond", "Foot" }, CFG.steps, "shape")
			Dropdown(dr, "Show for", { "Only me", "Everyone" }, CFG.steps, "scope")
		end)

		X.visualExtra(L, R)
		X.buildGun()

		------------------------------------------------------------ PLAYER
		local sfP = createTab("Player", "user", "movement")
		local PL1, PR1 = Columns(sfP)
		local cMove = Card(PL1, "Movement")
		Toggle(cMove, "Walkspeed", CFG.walk, "on", function(dr)
			Slider(dr, "Speed", 16, 200, CFG.walk, "val")
		end)
		Toggle(cMove, "Jump power", CFG.jump, "on", function(dr)
			Slider(dr, "Power", 50, 300, CFG.jump, "val")
		end)
		Toggle(cMove, "Spin", CFG.spin, "on", function(dr)
			Slider(dr, "Spin speed", 30, 2000, CFG.spin, "val", { fmt = function(v) return v .. " deg/s" end })
		end)
		local cMove2 = Card(PR1, "Flight")
		Toggle(cMove2, "Noclip", CFG.noclip, "on")
		Toggle(cMove2, "Fly", CFG.fly, "on", function(dr)
			Slider(dr, "Fly speed", 10, 300, CFG.fly, "val")
		end)

		X.playerExtra(PL1, PR1)
		X.buildEmote()

		------------------------------------------------------------ WORLD
		local sfW = createTab("World", "globe", "world & shaders")
		local WL, WR = Columns(sfW)
		local cSh = Card(WL, "Shaders")
		Toggle(cSh, "Shaders", CFG.shader, "on", function(dr)
			Grid(dr, X.PRESET_LIST, function() return CFG.shader.preset end, function(n) CFG.shader.preset = n end, 2)
		end)
		local cT = Card(WL, "Time")
		Toggle(cT, "Time of day", CFG.wtime, "on", function(dr)
			Slider(dr, "Time", 0, 24, CFG.wtime, "val", { div = 10, fmt = function(v)
				local hh = math.floor(v) % 24
				return string.format("%02d:%02d", hh, math.floor((v - math.floor(v)) * 60))
			end })
		end)
		Toggle(cT, "Xray", CFG.xray, "on", function(dr)
			Slider(dr, "Wall transparency", 10, 90, CFG.xray, "amount", { div = 100, fmt = pct })
		end)
		local cL = Card(WR, "Lighting")
		Toggle(cL, "Brightness", CFG.wbright, "on", function(dr)
			Slider(dr, "Amount", -50, 50, CFG.wbright, "val", { div = 100, fmt = function(v) return string.format("%.2f", v) end })
		end)
		Toggle(cL, "Glow", CFG.wglow, "on", function(dr)
			Slider(dr, "Intensity", 0, 30, CFG.wglow, "int", { div = 10 })
			Slider(dr, "Threshold", 0, 20, CFG.wglow, "thr", { div = 10 })
		end)
		Toggle(cL, "Darkness", CFG.wdark, "on", function(dr)
			Slider(dr, "Strength", 0, 100, CFG.wdark, "val", { div = 100, fmt = pct })
		end)
		Toggle(cL, "Color grading", CFG.wgrade, "on", function(dr)
			Slider(dr, "Saturation", -100, 100, CFG.wgrade, "sat", { div = 100, fmt = pct })
			Slider(dr, "Contrast", -100, 100, CFG.wgrade, "con", { div = 100, fmt = pct })
		end)
		Toggle(cL, "Motion blur", CFG.wblur, "on", function(dr)
			Slider(dr, "Strength", 1, 30, CFG.wblur, "val")
		end)
		Toggle(cL, "Fog", CFG.wfog, "on", function(dr)
			Slider(dr, "Density", 0, 100, CFG.wfog, "val", { div = 100, fmt = pct })
		end)
		Toggle(cL, "Sun rays", CFG.wrays, "on", function(dr)
			Slider(dr, "Intensity", 0, 100, CFG.wrays, "val", { div = 100, fmt = pct })
		end)
		Toggle(cL, "Full bright", CFG.wfull, "on")
		Toggle(cL, "No shadows", CFG.wshadow, "on")

		------------------------------------------------------------ MISC
		local sfM = createTab("Misc", "grid", "teleport & farm")
		local ML, MR = Columns(sfM)
		local cF = Card(ML, "Autofarm")
		Toggle(cF, "Autofarm coins", CFG.farm, "on", function(dr)
			FL(dr, "Noclip turns on automatically")
			Slider(dr, "Fly speed", 20, 200, CFG.farm, "fly")
			Slider(dr, "Farm delay", 0, 30, CFG.farm, "delay", { div = 10, fmt = function(v) return v .. " s" end })
		end)

		local function tpBtn(parent, text, fn)
			Button(parent, text, function(b)
				if not fn() then
					local o = b.Text
					b.Text = "Not found"
					task.delay(1.2, function() if b.Parent then b.Text = o end end)
				end
			end)
		end
		local cTp = Card(MR, "Teleport")
		DR(cTp, "Teleport to player", function(dr)
			PL(dr, 170, function(plr) X.tpPlayer(plr) end, false, nil)
		end)
		tpBtn(cTp, "Teleport to spawn", function() return X.tpSpawn() end)
		tpBtn(cTp, "Teleport to map", function() return X.tpMap() end)
		tpBtn(cTp, "Teleport to murder", function() return X.tpRole("Murderer") end)
		tpBtn(cTp, "Teleport to sheriff", function() return X.tpRole("Sheriff") end)

		X.miscExtra(ML, MR)

		------------------------------------------------------------ CONFIG
		local sfC = createTab("Config", "cfg", "configs")
		local CL, CR = Columns(sfC)
		local cNew = Card(CL, "New config")
		Label(cNew, "Save your current settings under a name", C.sub, 11)
		local nameBox = new("TextBox", {
			Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.field, BorderSizePixel = 0, Font = Enum.Font.GothamMedium,
			TextSize = 13, TextColor3 = C.text, PlaceholderText = "Config name...", PlaceholderColor3 = C.sub, Text = "",
			ClearTextOnFocus = false, LayoutOrder = ord(),
		}, cNew)
		corner(nameBox, 10)
		stroke(nameBox, C.line, 1.5)
		local slotLbl
		local rowsUI = {}
		local function refreshSlots()
			local slots = X.cfgApi.slots()
			slotLbl.Text = X.tr("Slots:") .. " " .. X.cfgApi.count() .. " / 5"
			for i = 1, 5 do
				local r = rowsUI[i]
				if r then
					r.name.Text = slots[i] and slots[i].name or X.tr("— empty —")
					r.name.TextColor3 = slots[i] and C.text or Color3.fromRGB(80, 78, 104)
					r.del.Visible = slots[i] ~= nil
				end
			end
		end
		local saveBtn = Button(cNew, "Save", function(b)
			local idx = X.cfgApi.save(nameBox.Text)
			if idx then
				nameBox.Text = ""
				refreshSlots()
			else
				local o = b.Text
				b.Text = "No free slots"
				task.delay(1.2, function() if b.Parent then b.Text = o end end)
			end
		end, WHITE)
		new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2) }, saveBtn)
		saveBtn.TextColor3 = Color3.fromRGB(14, 14, 24)
		slotLbl = Label(cNew, "Slots: 0 / 5", C.sub, 11)

		local cSv = Card(CR, "Saved")
		for i = 1, 5 do
			local f = new("TextButton", {
				Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.field, BorderSizePixel = 0, AutoButtonColor = false,
				Text = "", LayoutOrder = ord(),
			}, cSv)
			corner(f, 10)
			stroke(f, C.line, 1.5)
			new("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0), Size = UDim2.fromOffset(16, 38),
				Font = Enum.Font.GothamBold, Text = tostring(i), TextSize = 12, TextColor3 = C.sub,
			}, f)
			local nm = new("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(36, 0), Size = UDim2.new(1, -84, 1, 0),
				Font = Enum.Font.GothamMedium, Text = "", TextSize = 13, TextColor3 = C.text,
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			}, f)
			local del = new("TextButton", {
				AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -6, .5, 0), Size = UDim2.fromOffset(28, 28),
				BackgroundColor3 = C.card, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold,
				Text = "x", TextSize = 13, TextColor3 = C.text,
			}, f)
			corner(del, 8)
			rowsUI[i] = { name = nm, del = del }
			f.MouseButton1Click:Connect(function()
				if X.cfgApi.slots()[i] then X.cfgApi.load(i) end
			end)
			del.MouseButton1Click:Connect(function()
				X.cfgApi.delete(i)
				refreshSlots()
			end)
		end
		refreshSlots()
		X.reg(refreshSlots)

		------------------------------------------------------------ SETTING
		local sfS = createTab("Setting", "gear", "menu & language")
		local SL, SR = Columns(sfS)
		local cMenu = Card(SL, "Menu")
		Slider(cMenu, "Menu scale", 50, 130, X.SET, "scale", { div = 100, fmt = pct })
		Slider(cMenu, "Transparency", 0, 60, X.SET, "trans", { div = 100, fmt = pct })
		DR(cMenu, "Menu color", function(dr)
			ColorPicker(dr, X.SET, "accent")
		end)
		local cLang = Card(SR, "Language")
		Label(cLang, "The chosen language is saved automatically", C.sub, 11)
		Grid(cLang, { "English", "Русский" }, function() return X.SET.lang == "ru" and "Русский" or "English" end, function(n)
			X.setLang(n == "Русский" and "ru" or "en")
		end, 2)
	end
	build()
end

----------------------------------------------------------------
-- СТРАНИЦА INFO
----------------------------------------------------------------
local unload
local sfI = createTab("Info", "info", "about")
local bannerGrad
do
	new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }, sfI)

	local banner = new("Frame", {
		Size = UDim2.new(1, 0, 0, 168), BackgroundColor3 = WHITE, BorderSizePixel = 0, LayoutOrder = ord(),
	}, sfI)
	corner(banner, 14)
	bannerGrad = new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2), Rotation = 35 }, banner)

	local logo = new("Frame", {
		Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(50, 50), BackgroundColor3 = WHITE, BackgroundTransparency = .8,
		BorderSizePixel = 0,
	}, banner)
	corner(logo, 25)
	stroke(logo, WHITE, 1.5, .4)
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBlack, Text = "NH",
		TextSize = 18, TextColor3 = WHITE,
	}, logo)
	new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(80, 20), Size = UDim2.new(1, -96, 0, 24),
		Font = Enum.Font.GothamBlack, Text = "NurHub Official", TextSize = 20, TextColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, banner)
	new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(80, 46), Size = UDim2.new(1, -96, 0, 16),
		Font = Enum.Font.GothamMedium, Text = "News, updates and support", TextSize = 12,
		TextColor3 = Color3.fromRGB(235, 235, 255), TextXAlignment = Enum.TextXAlignment.Left,
	}, banner)

	local pill = new("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 18, 1, -18), Size = UDim2.new(1, -36, 0, 40),
		BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = .65, BorderSizePixel = 0,
	}, banner)
	corner(pill, 12)
	stroke(pill, WHITE, 1, .7)
	new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -28, 1, 0),
		Font = Enum.Font.GothamBold, Text = "t.me/NurHuboffical", TextSize = 15, TextColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, pill)

	local cLinks = Card(sfI, "Telegram")
	Button(cLinks, "Copy link", function(b)
		local fn = (typeof(setclipboard) == "function" and setclipboard) or (typeof(toclipboard) == "function" and toclipboard)
		local ok = fn and pcall(fn, TG_LINK)
		b.Text = ok and "Copied!" or TG_LINK
		task.delay(1.6, function() if b.Parent then b.Text = "Copy link" end end)
	end, C.accent)
	Button(cLinks, "Open Telegram", function()
		pcall(function() GuiService:OpenBrowserWindow(TG_LINK) end)
	end)

	local cAbout = Card(sfI, "About")
	Label(cAbout, "NurHub Visual v5.0 MM2 — only visual features, works in any Roblox game. No Drawing API: everything is built from Frame, Highlight, Trail and Lighting objects.", C.sub, 12)
	Label(cAbout, "Menu key: RightShift  •  or the NH button.", C.sub, 11)
	Button(cAbout, "Unload script", function() unload() end)
end

----------------------------------------------------------------
-- Язык / цвет меню / сохранение настроек
----------------------------------------------------------------
do
	local function run()
		X.regT(Main)
		X.regT(Preview)
		X.regT(Side)

		X.DICT = {
			["Hat style"] = "Стиль шляпы", ["Shimmer color"] = "Переливающийся цвет", ["Solid"] = "Сплошная", ["Both"] = "Оба",
			["Step distance"] = "Дистанция шага", ["Step delay"] = "Задержка шага", ["Found"] = "Найдено", ["Rescan game assets"] = "Пересканировать игру",
			["Real models from the game are shown as photos. Skins are applied on your client (only you see them)."] = "Реальные модели из игры показываются как фото. Скины применяются на твоём клиенте (видишь только ты).",
			["Gun"] = "Оружие", ["Emote"] = "Эмоции", ["skin changer"] = "смена скинов", ["emotes"] = "эмоции",
			["Skin changer"] = "Скинченджер", ["Knife"] = "Нож", ["Items"] = "Предметы", ["Search skin..."] = "Поиск скина...",
			["Skins are applied on your client (only you see them)."] = "Скины применяются на твоём клиенте (видишь только ты).",
			["Reset skins"] = "Сбросить скины", ["Search..."] = "Поиск...", ["Nothing found"] = "Ничего не найдено",
			["Crosshair"] = "Прицел", ["Custom crosshair"] = "Свой прицел", ["Preview"] = "Предпросмотр", ["Thickness"] = "Толщина",
			["Spin"] = "Вращение", ["Spin speed"] = "Скорость вращения", ["Bullet"] = "Пуля", ["Bullet path"] = "Путь пули",
			["Fade time"] = "Время затухания", ["Cosmetics"] = "Косметика", ["Wings"] = "Крылья", ["Wing length"] = "Длина крыльев",
			["Wing width"] = "Ширина крыльев", ["Halo"] = "Нимб", ["Murderer arrow"] = "Стрелка убийцы", ["Sheriff arrow"] = "Стрелка шерифа",
			["Pick a player / tap the circle to change his arrow color"] = "Выбери игрока / нажми на круг, чтобы сменить цвет стрелки",
			["Appearance"] = "Внешний вид", ["Headless"] = "Без головы", ["Korblox"] = "Корблокс", ["God mode"] = "Режим бога",
			["Extra movement"] = "Доп. движение", ["Bunnyhop"] = "Банихоп", ["Jump distance"] = "Длина прыжка",
			["Hold jump while moving"] = "Зажми прыжок во время движения", ["Animations"] = "Анимации", ["Animation pack"] = "Пак анимаций",
			["Combat"] = "Бой", ["Auto grab gun"] = "Авто-подбор пушки", ["Teleports to the dropped gun and back"] = "Телепорт к выпавшей пушке и обратно",
			["Hit sound"] = "Звук попадания", ["Volume"] = "Громкость", ["Or paste a sound ID"] = "Или вставь ID звука", ["Test sound"] = "Проверить звук",
			["Auto emote"] = "Авто-эмоция", ["Plays the chosen emote when you stop moving"] = "Включает выбранную эмоцию, когда ты стоишь",
			["Any emote (ID)"] = "Любая эмоция (ID)", ["Paste the animation asset ID of any emote, including paid ones"] = "Вставь ID анимации любой эмоции, в том числе платной",
			["Play"] = "Играть", ["Stop"] = "Стоп",
			["Visual"] = "Визуал", ["Player"] = "Игрок", ["World"] = "Мир", ["Misc"] = "Разное", ["Config"] = "Конфиг",
			["Setting"] = "Настройки", ["Info"] = "Инфо",
			["esp & render"] = "есп и рендер", ["movement"] = "движение", ["world & shaders"] = "мир и шейдеры",
			["teleport & farm"] = "телепорт и фарм", ["configs"] = "конфиги", ["menu & language"] = "меню и язык", ["about"] = "о скрипте",
			-- Visual
			["General"] = "Основное", ["ESP master"] = "ESP включить", ["Role colors"] = "Цвета по ролям", ["Max distance"] = "Макс. дистанция",
			["ESP for..."] = "ESP для...", ["Show ESP only for"] = "Показывать ESP только для",
			["Pick a player / tap the circle to change his color"] = "Выбери игрока / нажми на круг, чтобы сменить цвет",
			["All"] = "Все", ["Murder"] = "Убийца", ["Sheriff"] = "Шериф",
			["Boxes"] = "Боксы", ["Esp box 2D"] = "ESP бокс 2D", ["Esp box 3D"] = "ESP бокс 3D", ["Corner box"] = "Углы бокса",
			["Filled box"] = "Заливка бокса", ["Length"] = "Длина", ["Transparency"] = "Прозрачность", ["Top color"] = "Верхний цвет",
			["Bottom color"] = "Нижний цвет",
			["Info"] = "Инфо", ["Show nickname"] = "Показать ник", ["Show distance"] = "Показать дистанцию", ["Show health"] = "Показать HP",
			["Show avatar"] = "Показать аватар", ["HUD"] = "HUD", ["Show FPS"] = "Показать FPS", ["Custom FPS"] = "Свой FPS",
			["Drag the badge across the screen"] = "Перетащи значок по экрану",
			["Render"] = "Рендер", ["Chams"] = "Чамсы", ["Fill transparency"] = "Прозрачность заливки", ["Outline"] = "Контур",
			["Wall check"] = "Проверка стены", ["Color behind a wall"] = "Цвет за стеной", ["Color when visible"] = "Цвет когда виден",
			["Glow"] = "Свечение", ["Range"] = "Радиус", ["Brightness"] = "Яркость", ["Custom FOV"] = "Свой FOV",
			["Field of view"] = "Поле зрения", ["Third person"] = "Третье лицо", ["Distance"] = "Дистанция",
			["Lines"] = "Линии", ["Line / Tracers"] = "Линии / трейсеры", ["Line origin"] = "Начало линии", ["Crosshair"] = "Прицел",
			["Bottom"] = "Снизу", ["Top"] = "Сверху", ["Skeleton"] = "Скелет", ["Show head"] = "Показать голову",
			["Enemy arrows"] = "Стрелки врагов", ["Radius"] = "Радиус", ["Size"] = "Размер",
			["Items"] = "Предметы", ["Gun ESP"] = "ESP пушки", ["Coin ESP"] = "ESP монет", ["Show text"] = "Показать текст", ["Tracers"] = "Трейсеры",
			["Extras"] = "Дополнительно", ["Hat"] = "Шляпа", ["Rainbow lines"] = "Радужные линии", ["Transparency "] = "Прозрачность",
			["Filled cone"] = "Залитый конус", ["Show for"] = "Показывать для", ["Everyone"] = "Все", ["Only me"] = "Только я",
			["Trails"] = "Трейлы", ["Width"] = "Ширина", ["Footsteps"] = "Следы", ["Fade time"] = "Время затухания", ["Shape"] = "Форма",
			["Circle"] = "Круг", ["Square"] = "Квадрат", ["Diamond"] = "Ромб", ["Foot"] = "Нога",
			-- Player
			["Walkspeed"] = "Скорость", ["Speed"] = "Скорость", ["Jump power"] = "Сила прыжка", ["Power"] = "Сила", ["Spin"] = "Вращение",
			["Spin speed"] = "Скорость вращения", ["Flight"] = "Полёт", ["Noclip"] = "Ноклип", ["Fly"] = "Полёт (Fly)", ["Fly speed"] = "Скорость полёта",
			-- World
			["Shaders"] = "Шейдеры", ["Time"] = "Время", ["Time of day"] = "Время суток", ["Xray"] = "Xray", ["Wall transparency"] = "Прозрачность стен",
			["Lighting"] = "Освещение", ["Amount"] = "Значение", ["Intensity"] = "Интенсивность", ["Threshold"] = "Порог",
			["Darkness"] = "Затемнение", ["Strength"] = "Сила", ["Color grading"] = "Цветокоррекция", ["Saturation"] = "Насыщенность",
			["Contrast"] = "Контраст", ["Motion blur"] = "Моушн блюр", ["Fog"] = "Туман", ["Density"] = "Плотность", ["Sun rays"] = "Лучи солнца",
			["Full bright"] = "Полная яркость", ["No shadows"] = "Без теней",
			-- Misc
			["Autofarm"] = "Автофарм", ["Autofarm coins"] = "Автофарм монет", ["Noclip turns on automatically"] = "Ноклип включается автоматически",
			["Farm delay"] = "Задержка фарма", ["Teleport"] = "Телепорт", ["Teleport to player"] = "Телепорт к игроку",
			["Teleport to spawn"] = "Телепорт на спавн", ["Teleport to map"] = "Телепорт на карту", ["Teleport to murder"] = "Телепорт к убийце",
			["Teleport to sheriff"] = "Телепорт к шерифу", ["Not found"] = "Не найдено",
			-- Config
			["New config"] = "Новый конфиг", ["Save your current settings under a name"] = "Сохрани текущие настройки под именем",
			["Config name..."] = "Имя конфига...", ["Save"] = "Сохранить", ["Slots:"] = "Слоты:", ["Saved"] = "Сохранённые",
			["— empty —"] = "— пусто —", ["No free slots"] = "Нет свободных слотов",
			-- Setting
			["Menu"] = "Меню", ["Menu scale"] = "Масштаб меню", ["Menu color"] = "Цвет меню", ["Language"] = "Язык",
			["The chosen language is saved automatically"] = "Выбранный язык сохраняется автоматически",
			-- Info
			["Telegram"] = "Телеграм", ["Copy link"] = "Копировать ссылку", ["Open Telegram"] = "Открыть Telegram", ["About"] = "О скрипте",
			["Unload script"] = "Выгрузить скрипт", ["News, updates and support"] = "Новости, обновления и поддержка",
			["ESP Editor"] = "Редактор ESP", ["live preview of your settings"] = "живой предпросмотр настроек",
		}

		local function applyLang()
			local ru = X.SET.lang == "ru"
			for _, d in ipairs(gui:GetDescendants()) do
				if d:IsA("TextLabel") or d:IsA("TextButton") then
					if d.RichText then
						local en = d:GetAttribute("en")
						if not en then
							en = d.Text
							d:SetAttribute("en", en)
						end
						local a, b = en:match('^(.-) <font color="rgb%(135,133,158%)">· (.-)</font>$')
						if a then
							local ta = ru and (X.DICT[a] or a) or a
							local tb2 = ru and (X.DICT[b] or b) or b
							d.Text = ta .. ' <font color="rgb(135,133,158)">· ' .. tb2 .. "</font>"
						end
					else
						local en = d:GetAttribute("en")
						if not en and X.DICT[d.Text] then
							en = d.Text
							d:SetAttribute("en", en)
						end
						if en then
							local ruT = X.DICT[en]
							if d.Text == en or d.Text == ruT then
								d.Text = ru and (ruT or en) or en
							end
						end
					end
				elseif d:IsA("TextBox") then
					local en = d:GetAttribute("en")
					if not en and X.DICT[d.PlaceholderText] then
						en = d.PlaceholderText
						d:SetAttribute("en", en)
					end
					if en then d.PlaceholderText = (ru and X.DICT[en]) or en end
				end
			end
			pcall(X.refreshAll)
		end

		function X.setLang(l)
			X.SET.lang = l
			applyLang()
			X.saveSettings()
		end

		-- цвет меню (акцент)
		local function applyAccent(n)
			local oldA, oldB = C.accent, C.accent2
			local h, s, v = n:ToHSV()
			local newB = Color3.fromHSV((h + .07) % 1, s * .9, math.clamp(v + .05, 0, 1))
			for _, d in ipairs(gui:GetDescendants()) do
				if d:IsA("UIGradient") then
					local out, ch = {}, false
					for i, k in ipairs(d.Color.Keypoints) do
						local val = k.Value
						if val == oldA then
							val = n
							ch = true
						elseif val == oldB then
							val = newB
							ch = true
						end
						out[i] = ColorSequenceKeypoint.new(k.Time, val)
					end
					if ch then d.Color = ColorSequence.new(out) end
				elseif d:IsA("GuiObject") then
					if d.BackgroundColor3 == oldA then d.BackgroundColor3 = n end
					if d:IsA("ScrollingFrame") and d.ScrollBarImageColor3 == oldA then d.ScrollBarImageColor3 = n end
				end
			end
			C.accent, C.accent2 = n, newB
		end

		-- следим за настройками меню и сохраняем их
		local last = { scale = X.SET.scale, trans = X.SET.trans }
		task.spawn(function()
			while alive do
				local s = X.SET
				local changed = false
				if s.accent ~= C.accent then
					applyAccent(s.accent)
					changed = true
				end
				if s.scale ~= last.scale then
					last.scale = s.scale
					fit()
					changed = true
				end
				if s.trans ~= last.trans then
					last.trans = s.trans
					X.applyTrans()
					changed = true
				end
				if changed then X.saveSettings() end
				task.wait(.25)
			end
		end)

		fit()
		applyLang()
	end
	run()
end

-- стартовое состояние вкладок
current = "Visual"
pages.Visual.Visible = true
pages.Visual.GroupTransparency = 0
for n in pairs(tabs) do paintTab(n, n == current, false) end

----------------------------------------------------------------
-- Кнопка NH (буквы двигаются) + клавиша
----------------------------------------------------------------
local OpenBtn = new("Frame", {
	Name = "NH_Button", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(0, 46, .5, 0),
	Size = UDim2.fromOffset(52, 52), BackgroundColor3 = Color3.fromRGB(14, 14, 20), BorderSizePixel = 0,
}, gui)
corner(OpenBtn, 16)
local btnScale = new("UIScale", { Scale = 1 }, OpenBtn)
local btnStroke = stroke(OpenBtn, WHITE, 2)
local btnGrad = new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.accent), ColorSequenceKeypoint.new(.5, WHITE), ColorSequenceKeypoint.new(1, C.accent2),
	}),
}, btnStroke)
local letterN = new("TextLabel", {
	BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(.5, 1, .5, 0),
	Size = UDim2.fromOffset(20, 24), Font = Enum.Font.GothamBlack, Text = "N", TextSize = 20, TextColor3 = WHITE,
}, OpenBtn)
local letterH = new("TextLabel", {
	BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(.5, -1, .5, 0),
	Size = UDim2.fromOffset(20, 24), Font = Enum.Font.GothamBlack, Text = "H", TextSize = 20, TextColor3 = WHITE,
}, OpenBtn)
local hitBtn = new("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1) }, OpenBtn)
makeDraggable(hitBtn, OpenBtn, function() setMenu(not menuOpen) end)
hitBtn.MouseEnter:Connect(function() tw(btnScale, .25, { Scale = 1.1 }, Enum.EasingStyle.Back) end)
hitBtn.MouseLeave:Connect(function() tw(btnScale, .25, { Scale = 1 }, Enum.EasingStyle.Back) end)
hitBtn.MouseButton1Down:Connect(function() tw(btnScale, .12, { Scale = .92 }) end)
hitBtn.MouseButton1Up:Connect(function() tw(btnScale, .2, { Scale = 1.1 }, Enum.EasingStyle.Back) end)

track(RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local off = math.sin(t * 2.4) * 4
	local sx = math.cos(t * 2.4) * 2
	letterN.Position = UDim2.new(.5, 1 + sx, .5, off)
	letterH.Position = UDim2.new(.5, -1 - sx, .5, -off)
	btnGrad.Rotation = (t * 120) % 360
	if bannerGrad then bannerGrad.Rotation = 35 + math.sin(t * .6) * 25 end
	if menuOpen and Preview.Visible then pvUpdate(t) end
end))

track(UIS.InputBegan:Connect(function(i, gp)
	if gp then return end
	if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == Enum.KeyCode.RightShift then
		setMenu(not menuOpen)
	end
end))

----------------------------------------------------------------
-- Выгрузка
----------------------------------------------------------------
function unload()
	alive = false
	if X.extraUnload then pcall(X.extraUnload) end
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	pcall(function() RunService:UnbindFromRenderStep("NH_FOV") end)
	pcall(function()
		local cam = Workspace.CurrentCamera
		if fovOn and cam then cam.FieldOfView = fovSaved or 70 end
	end)
	for _, d in pairs(S) do destroyData(d) end
	for _, h in pairs(hats) do pcall(function() h:Destroy() end) end
	for _, t in pairs(trails) do destroyTrail(t) end
	pcall(function() espGui:Destroy() end)
	pcall(function() gui:Destroy() end)
	ENV.NurHubMM2Unload = nil
end
ENV.NurHubMM2Unload = unload

----------------------------------------------------------------
-- Поиск по функциям + загрузочный экран + Welcome
----------------------------------------------------------------
do
	local function run()
		-- ПОИСК
		local sbox = new("TextBox", {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 8), Size = UDim2.fromOffset(190, 26),
			BackgroundColor3 = C.field, BorderSizePixel = 0, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.text,
			PlaceholderText = "Search...", PlaceholderColor3 = C.sub, Text = "", ClearTextOnFocus = false, ZIndex = 5,
		}, Main)
		corner(sbox, 9)
		stroke(sbox, C.line, 1)
		new("UIPadding", { PaddingLeft = UDim.new(0, 10) }, sbox)

		local results = new("Frame", {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 38), Size = UDim2.fromOffset(250, 0),
			BackgroundColor3 = C.card, BorderSizePixel = 0, ClipsDescendants = true, Visible = false, ZIndex = 20,
		}, Main)
		corner(results, 10)
		stroke(results, C.line, 1)
		new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, results)
		new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, results)

		local function flash(box)
			if not box or not box.Parent then return end
			local h = math.min(box.Size.Y.Offset, 40)
			local ov = new("Frame", {
				Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = Color3.fromRGB(255, 50, 60), BackgroundTransparency = 1,
				BorderSizePixel = 0, ZIndex = 10,
			}, box)
			corner(ov, 7)
			local s = stroke(ov, Color3.fromRGB(255, 70, 80), 2, 1)
			task.spawn(function()
				for _ = 1, 3 do
					tw(ov, .28, { BackgroundTransparency = .55 })
					tw(s, .28, { Transparency = 0 })
					task.wait(.3)
					tw(ov, .28, { BackgroundTransparency = .9 })
					tw(s, .28, { Transparency = .5 })
					task.wait(.3)
				end
				tw(ov, .3, { BackgroundTransparency = 1 })
				tw(s, .3, { Transparency = 1 })
				task.wait(.35)
				ov:Destroy()
			end)
		end

		local function jump(e)
			results.Visible = false
			results.Size = UDim2.fromOffset(250, 0)
			sbox.Text = ""
			switchTab(e.tab)
			task.delay(.55, function()
				local sf = X.pageSF[e.tab]
				if sf and e.box.Parent then
					local sc = math.max(fitScale.Scale * animScale.Scale, .01)
					local target = math.max(0, (e.box.AbsolutePosition.Y - sf.AbsolutePosition.Y) / sc + sf.CanvasPosition.Y - 24)
					tw(sf, .5, { CanvasPosition = Vector2.new(0, target) })
				end
				task.delay(.25, function() flash(e.box) end)
			end)
		end

		local rows = {}
		local function refreshResults()
			for _, r in ipairs(rows) do r:Destroy() end
			rows = {}
			local q = sbox.Text:lower()
			if q == "" then
				results.Visible = false
				return
			end
			local n = 0
			for _, e in ipairs(X.searchReg) do
				local en = e.name:lower()
				local ru = X.tr(e.name):lower()
				if en:find(q, 1, true) or ru:find(q, 1, true) then
					n += 1
					if n > 7 then break end
					local b = new("TextButton", {
						Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = C.accent, BackgroundTransparency = 1,
						BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = n, ZIndex = 21,
					}, results)
					corner(b, 7)
					new("TextLabel", {
						BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -90, 1, 0),
						Font = Enum.Font.GothamMedium, Text = X.tr(e.name), TextSize = 12, TextColor3 = C.text,
						TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 22,
					}, b)
					new("TextLabel", {
						BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0),
						Size = UDim2.fromOffset(78, 28), Font = Enum.Font.GothamMedium, Text = X.tr(e.tab), TextSize = 10,
						TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 22,
					}, b)
					b.MouseEnter:Connect(function() tw(b, .12, { BackgroundTransparency = .7 }) end)
					b.MouseLeave:Connect(function() tw(b, .12, { BackgroundTransparency = 1 }) end)
					b.MouseButton1Click:Connect(function() jump(e) end)
					rows[#rows + 1] = b
				end
			end
			if n == 0 then
				local l = new("TextLabel", {
					BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), Font = Enum.Font.GothamMedium, Text = "Nothing found",
					TextSize = 12, TextColor3 = C.sub, ZIndex = 21,
				}, results)
				rows[#rows + 1] = l
				n = 1
			end
			results.Visible = true
			tw(results, .25, { Size = UDim2.fromOffset(250, math.min(n, 7) * 30 + 8) })
		end
		sbox:GetPropertyChangedSignal("Text"):Connect(refreshResults)

		-- ЗАГРУЗКА + WELCOME
		function X.intro()
			OpenBtn.Visible = false
			local ig = new("ScreenGui", {
				Name = "NurHubMM2_Load", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 300,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			})
			mount(ig)
			local bgf = new("Frame", {
				Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(6, 6, 10), BackgroundTransparency = 1, BorderSizePixel = 0,
			}, ig)
			tw(bgf, .4, { BackgroundTransparency = .2 })
			local card = new("CanvasGroup", {
				AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(330, 176),
				BackgroundColor3 = C.bg, BorderSizePixel = 0, GroupTransparency = 1,
			}, bgf)
			corner(card, 18)
			local cs = new("UIScale", { Scale = .88 }, card)
			local frame = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, card)
			stroke(frame, C.line, 1)
			local logo = new("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 40),
				Font = Enum.Font.GothamBlack, Text = "NURHUB", TextSize = 34, TextColor3 = WHITE,
			}, card)
			local lg = new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2) }, logo)
			new("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 66), Size = UDim2.new(1, 0, 0, 16),
				Font = Enum.Font.GothamMedium, Text = "Murder Mystery 2", TextSize = 11, TextColor3 = C.sub,
			}, card)
			local status = new("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(35, 108), Size = UDim2.new(1, -70, 0, 14),
				Font = Enum.Font.GothamMedium, Text = "Loading modules...", TextSize = 11, TextColor3 = C.sub,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, card)
			local pctL = new("TextLabel", {
				BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -35, 0, 108),
				Size = UDim2.fromOffset(50, 14), Font = Enum.Font.GothamBold, Text = "0%", TextSize = 11, TextColor3 = C.text,
				TextXAlignment = Enum.TextXAlignment.Right,
			}, card)
			local bar = new("Frame", {
				Position = UDim2.fromOffset(35, 132), Size = UDim2.new(1, -70, 0, 6), BackgroundColor3 = C.track, BorderSizePixel = 0,
			}, card)
			corner(bar, 3)
			local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, bar)
			corner(fill, 3)
			new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2) }, fill)

			tw(card, .5, { GroupTransparency = 0 })
			tw(cs, .6, { Scale = 1 }, Enum.EasingStyle.Back)

			local texts = { "Loading modules...", "Preparing ESP...", "Building interface...", "Almost ready..." }
			task.spawn(function()
				local t0, dur = os.clock(), 2.8
				while alive do
					local a = math.clamp((os.clock() - t0) / dur, 0, 1)
					local p = a * a * (3 - 2 * a)
					fill.Size = UDim2.fromScale(p, 1)
					pctL.Text = math.floor(p * 100) .. "%"
					status.Text = texts[math.clamp(math.floor(p * 4) + 1, 1, 4)]
					lg.Rotation = (os.clock() * 90) % 360
					if a >= 1 then break end
					task.wait()
				end
				if not alive then
					ig:Destroy()
					return
				end
				tw(card, .35, { GroupTransparency = 1 })
				tw(cs, .35, { Scale = 1.08 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				task.wait(.4)

				-- Welcome
				local wl = new("TextLabel", {
					AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(520, 60),
					BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 36, TextColor3 = WHITE,
					Text = "Welcome, " .. LP.DisplayName, MaxVisibleGraphemes = 0,
				}, bgf)
				local wg = new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2) }, wl)
				local ws = new("UIScale", { Scale = .8 }, wl)
				tw(ws, .7, { Scale = 1 }, Enum.EasingStyle.Back)
				local total = utf8.len(wl.Text) or #wl.Text
				for i = 1, total do
					wl.MaxVisibleGraphemes = i
					task.wait(.045)
				end
				local t1 = os.clock()
				while os.clock() - t1 < 1.1 and alive do
					wg.Rotation = (os.clock() * 120) % 360
					task.wait()
				end
				tw(wl, .4, { TextTransparency = 1 })
				tw(bgf, .5, { BackgroundTransparency = 1 })
				task.wait(.5)
				ig:Destroy()
				if not alive then return end
				OpenBtn.Visible = true
				btnScale.Scale = .2
				tw(btnScale, .6, { Scale = 1 }, Enum.EasingStyle.Back)
				setMenu(true)
			end)
		end
	end
	run()
end

X.intro()
