-- WorkClient | Blox Strike | v30.3 | by WorkSaturn17940
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local HttpService=game:GetService("HttpService")
local TweenService=game:GetService("TweenService")
local Stats=game:GetService("Stats")
local Lighting=game:GetService("Lighting")
local SoundService=game:GetService("SoundService")
local LocalPlayer=Players.LocalPlayer
local API_URL="https://bs-api.mihailkoshkin70.workers.dev"
local API_SECRET="bloxstrike_secret_2026_kotost_verylong777"
local FOLDER_ROOT="WorkClient"
local FOLDER_INFO=FOLDER_ROOT.."/info"
local FOLDER_CONFIGS=FOLDER_ROOT.."/configs"
local DATA_FILE=FOLDER_INFO.."/data.json"
local AUTOLOAD_FILE=FOLDER_CONFIGS.."/_autoload.txt"
local RAIN_SOUND_ID="rbxassetid://131961136"
local POLL_INTERVAL=5

local UI={bg=Color3.fromRGB(13,13,17),topbar=Color3.fromRGB(20,20,26),panel=Color3.fromRGB(17,17,22),panel2=Color3.fromRGB(24,24,30),panel3=Color3.fromRGB(30,30,38),border=Color3.fromRGB(42,42,52),borderHi=Color3.fromRGB(72,72,88),accent=Color3.fromRGB(80,190,255),text=Color3.fromRGB(230,232,240),textDim=Color3.fromRGB(140,144,158),textMute=Color3.fromRGB(100,104,118),good=Color3.fromRGB(70,210,130),bad=Color3.fromRGB(235,85,85),warn=Color3.fromRGB(235,190,80),yellow=Color3.fromRGB(255,220,60),freeze=Color3.fromRGB(140,200,255),input=Color3.fromRGB(22,22,28)}
local RANKS={player={level=0,color=Color3.fromRGB(180,180,190),access={}},beta={level=1,color=Color3.fromRGB(200,140,255),access={"beta"}},helper={level=2,color=Color3.fromRGB(255,215,0),access={"admin"}},moderator={level=3,color=Color3.fromRGB(80,160,255),access={"admin"}},admin={level=4,color=Color3.fromRGB(255,80,80),access={"beta","admin","adminpanel"}},owner={level=5,color=Color3.fromRGB(255,40,40),access={"beta","admin","adminpanel"}}}
local HEAD_SIZE=15
local HP_HIGH=Color3.fromRGB(0,220,100)
local HP_MID=Color3.fromRGB(240,200,60)
local HP_LOW=Color3.fromRGB(240,70,70)
local TEAM_COLORS={Color3.fromRGB(80,160,255),Color3.fromRGB(255,80,80),Color3.fromRGB(80,220,80),Color3.fromRGB(255,200,50),Color3.fromRGB(200,80,255),Color3.fromRGB(255,140,0),Color3.fromRGB(255,100,200),Color3.fromRGB(100,255,220)}

local function ensureFolders()
    if not makefolder or not isfolder then return end
    pcall(function()
        if not isfolder(FOLDER_ROOT) then makefolder(FOLDER_ROOT) end
        if not isfolder(FOLDER_INFO) then makefolder(FOLDER_INFO) end
        if not isfolder(FOLDER_CONFIGS) then makefolder(FOLDER_CONFIGS) end
    end)
end
ensureFolders()

local function httpPost(url,body)
    local okEnc,json=pcall(function() return HttpService:JSONEncode(body) end)
    if not okEnc or not json then return nil,"encode_failed" end
    local opts={Url=url,Method="POST",Headers={["Content-Type"]="application/json"},Body=json}
    if syn and syn.request then
        local ok,r=pcall(syn.request,opts)
        if ok and type(r)=="table" then return r.Body end
    end
    if request then
        local ok,r=pcall(request,opts)
        if ok and type(r)=="table" then return r.Body end
    end
    if http and http.request then
        local ok,r=pcall(http.request,opts)
        if ok and type(r)=="table" then return r.Body end
    end
    return nil,"no_request"
end
local function saveLocal(data) if writefile then pcall(function() writefile(DATA_FILE,HttpService:JSONEncode(data)) end) end end
local function loadLocal()
    if isfile and isfile(DATA_FILE) then
        local ok,data=pcall(function() return HttpService:JSONDecode(readfile(DATA_FILE)) end)
        if ok and type(data)=="table" then return data end
    end
    return nil
end
local function generateHWID()
    math.randomseed(os.time()+math.floor(tick()*1000))
    local s="" for i=1,10 do s=s..tostring(math.random(0,9)) end
    return s
end
local function copyToClipboard(txt)
    if setclipboard then pcall(setclipboard, txt); return true end
    if syn and syn.setclipboard then pcall(syn.setclipboard, txt); return true end
    if toclipboard then pcall(toclipboard, txt); return true end
    return false
end
local localData=loadLocal() or {}
if not localData.hwid then localData.hwid=generateHWID() end
saveLocal(localData)
local currentHWID=localData.hwid
local currentRank=localData.rank or "player"
local currentKey=localData.key
local isBanned=false
local banInfo={}

local function registerOnServer()
    local res=httpPost(API_URL.."/register",{secret=API_SECRET,hwid=currentHWID,nickname=LocalPlayer.Name,roblox_id=LocalPlayer.UserId})
    if not res then return false end
    local ok,data=pcall(function() return HttpService:JSONDecode(res) end)
    if not ok or not data then return false end
    currentRank=data.rank or "player"
    isBanned=data.banned==true
    banInfo={reason=data.ban_reason,expires=data.ban_expires}
    return true
end
local function hasAccess(tab)
    local r=RANKS[currentRank] or RANKS.player
    for _,t in ipairs(r.access) do if t==tab then return true end end
    return false
end
local function getGuiParent()
    if gethui then local ok,res=pcall(gethui) if ok and res then return res end end
    local ok,cg=pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then
        local ok2=pcall(function() local t=Instance.new("Folder") t.Parent=cg t:Destroy() end)
        if ok2 then return cg end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end
local parent=getGuiParent()
for _,name in ipairs({"_bs_root","_bs_key","_bs_wrong","_bs_ban","_bs_notif","_bs_reset_dialog","_bs_hud","_bs_season","_bs_tinfo","_bs_freeze","_bs_popups","_bs_loading"}) do
    local o=parent:FindFirstChild(name) if o then o:Destroy() end
end
local function addCorner(obj,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 4) c.Parent=obj end
local function addStroke(obj,col,th) local s=Instance.new("UIStroke") s.Color=col or UI.border s.Thickness=th or 1 s.Parent=obj return s end
local function setButtonState(btn,on,activeColor)
    local stroke=btn:FindFirstChildOfClass("UIStroke")
    local col=activeColor or UI.accent
    if on then btn.BackgroundColor3=UI.panel2 btn.TextColor3=col if stroke then stroke.Color=col stroke.Thickness=1.5 end
    else btn.BackgroundColor3=UI.panel2 btn.TextColor3=UI.text if stroke then stroke.Color=UI.border stroke.Thickness=1 end end
end
task.spawn(function() registerOnServer() end)

local function getRoot(char)
    if not char then return nil end
    if char:IsA("Model") and char.PrimaryPart then return char.PrimaryPart end
    local humanoid=char:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.RootPart then return humanoid.RootPart end
    for _,name in ipairs({"HumanoidRootPart","RootPart","Root","Body","Torso","UpperTorso","LowerTorso","Chest","Trunk","Head"}) do
        local p=char:FindFirstChild(name) if p and p:IsA("BasePart") then return p end
    end
    for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and p.Name:lower():find("root") then return p end end
    for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then return p end end
    return nil
end
local function getCharPos(char)
    if not char then return Vector3.zero end
    if char:IsA("Model") then local ok,pivot=pcall(function() return char:GetPivot() end) if ok and pivot then return pivot.Position end end
    local root=getRoot(char)
    return root and root.Position or Vector3.zero
end
local function moveChar(char,newCFrame)
    if not char then return end
    if char:IsA("Model") then local ok=pcall(function() char:PivotTo(newCFrame) end) if ok then return end end
    local root=getRoot(char) if root then root.CFrame=newCFrame end
end
local function unanchorChar(char)
    if not char then return end
    for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and p.Anchored then p.Anchored=false end end
end
local function findHeadPart(char)
    if not char then return nil end
    local direct=char:FindFirstChild("Head")
    if direct and direct:IsA("BasePart") then return direct end
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.Name:lower()=="head" then return p end
    end
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.Name:lower():find("head") then return p end
    end
    return nil
end

-- NOTIFICATIONS
local notifSg=Instance.new("ScreenGui")
notifSg.Name="_bs_notif" notifSg.ResetOnSpawn=false notifSg.DisplayOrder=2147483646 notifSg.IgnoreGuiInset=true notifSg.ZIndexBehavior=Enum.ZIndexBehavior.Global notifSg.Parent=parent
local notifHolder=Instance.new("Frame")
notifHolder.Size=UDim2.new(0,340,0,600) notifHolder.Position=UDim2.new(1,-360,0,60) notifHolder.BackgroundTransparency=1 notifHolder.Parent=notifSg notifHolder.ZIndex=5000
local notifLayout=Instance.new("UIListLayout")
notifLayout.Padding=UDim.new(0,6) notifLayout.SortOrder=Enum.SortOrder.LayoutOrder notifLayout.HorizontalAlignment=Enum.HorizontalAlignment.Right notifLayout.VerticalAlignment=Enum.VerticalAlignment.Top notifLayout.Parent=notifHolder
local notifCounter=0
local notificationsEnabled=false
local activeNotifs={}
local function notify(text,color)
    if not notificationsEnabled then return end
    notifCounter=notifCounter+1
    local n=Instance.new("Frame")
    n.Size=UDim2.new(1,0,0,40) n.BackgroundColor3=UI.panel2 n.BackgroundTransparency=0.05 n.BorderSizePixel=0 n.LayoutOrder=-notifCounter n.ZIndex=5001 n.Parent=notifHolder
    addCorner(n,4) addStroke(n,UI.border,1)
    local accentBar=Instance.new("Frame")
    accentBar.Size=UDim2.new(0,3,1,-10) accentBar.Position=UDim2.new(0,0,0,5) accentBar.BackgroundColor3=color or UI.accent accentBar.BorderSizePixel=0 accentBar.Parent=n addCorner(accentBar,2)
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-22,1,0) lbl.Position=UDim2.new(0,14,0,0) lbl.BackgroundTransparency=1 lbl.Text=text lbl.TextColor3=UI.text lbl.TextSize=13 lbl.Font=Enum.Font.GothamMedium lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.TextWrapped=true lbl.ZIndex=5002 lbl.Parent=n
    table.insert(activeNotifs,n)
    if #activeNotifs>8 then local old=table.remove(activeNotifs,1) if old and old.Parent then old:Destroy() end end
    n.BackgroundTransparency=1 lbl.TextTransparency=1 accentBar.BackgroundTransparency=1
    task.spawn(function()
        for i=0,8 do n.BackgroundTransparency=1-(i/8)*0.95 lbl.TextTransparency=1-(i/8) accentBar.BackgroundTransparency=1-(i/8) task.wait(0.02) end
        task.wait(3.2)
        for i=0,10 do n.BackgroundTransparency=0.05+(i/10)*0.95 lbl.TextTransparency=i/10 accentBar.BackgroundTransparency=i/10 task.wait(0.03) end
        n:Destroy()
        for idx,o in ipairs(activeNotifs) do if o==n then table.remove(activeNotifs,idx) break end end
    end)
end

-- HUD
local hudEnabled=false
local hudSg=Instance.new("ScreenGui")
hudSg.Name="_bs_hud" hudSg.ResetOnSpawn=false hudSg.DisplayOrder=2147483635 hudSg.IgnoreGuiInset=true hudSg.ZIndexBehavior=Enum.ZIndexBehavior.Global hudSg.Parent=parent
local hudMain=Instance.new("Frame")
hudMain.Size=UDim2.new(0,200,0,88) hudMain.Position=UDim2.new(0,16,0,16) hudMain.BackgroundColor3=UI.bg hudMain.BackgroundTransparency=0.15 hudMain.BorderSizePixel=0 hudMain.Visible=false hudMain.Parent=hudSg hudMain.ZIndex=4000
addCorner(hudMain,6) addStroke(hudMain,UI.border,1)
local hudAccent=Instance.new("Frame")
hudAccent.Size=UDim2.new(0,3,1,-16) hudAccent.Position=UDim2.new(0,0,0,8) hudAccent.BackgroundColor3=UI.accent hudAccent.BorderSizePixel=0 hudAccent.Parent=hudMain hudAccent.ZIndex=4001 addCorner(hudAccent,2)
local hudTitle=Instance.new("TextLabel")
hudTitle.Size=UDim2.new(1,-14,0,18) hudTitle.Position=UDim2.new(0,12,0,6) hudTitle.BackgroundTransparency=1 hudTitle.Text="WorkClient" hudTitle.TextColor3=UI.text hudTitle.TextSize=13 hudTitle.Font=Enum.Font.GothamBold hudTitle.TextXAlignment=Enum.TextXAlignment.Left hudTitle.Parent=hudMain hudTitle.ZIndex=4001
local hudSep=Instance.new("Frame")
hudSep.Size=UDim2.new(1,-20,0,1) hudSep.Position=UDim2.new(0,10,0,26) hudSep.BackgroundColor3=UI.border hudSep.BorderSizePixel=0 hudSep.Parent=hudMain hudSep.ZIndex=4001
local function hudMakeRow(labelText,yPos)
    local l=Instance.new("TextLabel") l.Size=UDim2.new(0.5,-12,0,16) l.Position=UDim2.new(0,12,0,yPos) l.BackgroundTransparency=1 l.Text=labelText l.TextColor3=UI.textDim l.TextSize=11 l.Font=Enum.Font.GothamBold l.TextXAlignment=Enum.TextXAlignment.Left l.Parent=hudMain l.ZIndex=4001
    local v=Instance.new("TextLabel") v.Size=UDim2.new(0.5,-8,0,16) v.Position=UDim2.new(0.5,4,0,yPos) v.BackgroundTransparency=1 v.Text="—" v.TextColor3=UI.text v.TextSize=11 v.Font=Enum.Font.Code v.TextXAlignment=Enum.TextXAlignment.Right v.Parent=hudMain v.ZIndex=4001
    return v
end
local hudFpsVal=hudMakeRow("FPS",32)
local hudPingVal=hudMakeRow("PING",48)
local hudRankVal=hudMakeRow("RANK",64)
local _hudFrames=0
local _hudTimer=0
RunService.RenderStepped:Connect(function(dt)
    if not hudEnabled then return end
    _hudFrames=_hudFrames+1 _hudTimer=_hudTimer+dt
    if _hudTimer>=0.5 then
        local fps=_hudFrames/_hudTimer
        _hudFrames=0 _hudTimer=0
        hudFpsVal.Text=tostring(math.floor(fps+0.5))
        local ping=0
        pcall(function() ping=math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()+0.5) end)
        hudPingVal.Text=tostring(ping).."ms"
        hudRankVal.Text=string.upper(currentRank)
        hudRankVal.TextColor3=(RANKS[currentRank] or RANKS.player).color
    end
end)
local function setHudVisible(v) hudEnabled=v hudMain.Visible=v end

-- TARGET INFO
local tinfoSg=Instance.new("ScreenGui")
tinfoSg.Name="_bs_tinfo" tinfoSg.ResetOnSpawn=false tinfoSg.DisplayOrder=2147483634 tinfoSg.IgnoreGuiInset=true tinfoSg.ZIndexBehavior=Enum.ZIndexBehavior.Global tinfoSg.Parent=parent
local tinfoCard=Instance.new("Frame")
tinfoCard.Size=UDim2.new(0,260,0,68) tinfoCard.Position=UDim2.new(0.5,-130,0.5,60) tinfoCard.BackgroundColor3=UI.bg tinfoCard.BackgroundTransparency=0.08 tinfoCard.BorderSizePixel=0 tinfoCard.Visible=false tinfoCard.Parent=tinfoSg tinfoCard.ZIndex=4500
addCorner(tinfoCard,6) addStroke(tinfoCard,UI.border,1)
local tinfoAvatar=Instance.new("ImageLabel")
tinfoAvatar.Size=UDim2.new(0,56,0,56) tinfoAvatar.Position=UDim2.new(0,6,0,6) tinfoAvatar.BackgroundColor3=UI.panel3 tinfoAvatar.BorderSizePixel=0 tinfoAvatar.Image="" tinfoAvatar.ZIndex=4501 tinfoAvatar.Parent=tinfoCard
addCorner(tinfoAvatar,6) addStroke(tinfoAvatar,UI.accent,1)
local tinfoName=Instance.new("TextLabel")
tinfoName.Size=UDim2.new(1,-74,0,18) tinfoName.Position=UDim2.new(0,68,0,6) tinfoName.BackgroundTransparency=1 tinfoName.Text="PlayerName" tinfoName.TextColor3=UI.text tinfoName.TextSize=13 tinfoName.Font=Enum.Font.GothamBold tinfoName.TextXAlignment=Enum.TextXAlignment.Left tinfoName.ZIndex=4501 tinfoName.Parent=tinfoCard
local tinfoHpBg=Instance.new("Frame")
tinfoHpBg.Size=UDim2.new(1,-74,0,8) tinfoHpBg.Position=UDim2.new(0,68,0,28) tinfoHpBg.BackgroundColor3=UI.panel3 tinfoHpBg.BorderSizePixel=0 tinfoHpBg.ZIndex=4501 tinfoHpBg.Parent=tinfoCard
addCorner(tinfoHpBg,3)
local tinfoHpFill=Instance.new("Frame")
tinfoHpFill.Size=UDim2.new(1,0,1,0) tinfoHpFill.BackgroundColor3=HP_HIGH tinfoHpFill.BorderSizePixel=0 tinfoHpFill.ZIndex=4502 tinfoHpFill.Parent=tinfoHpBg
addCorner(tinfoHpFill,3)
local tinfoHpText=Instance.new("TextLabel")
tinfoHpText.Size=UDim2.new(1,-74,0,12) tinfoHpText.Position=UDim2.new(0,68,0,38) tinfoHpText.BackgroundTransparency=1 tinfoHpText.Text="100 / 100" tinfoHpText.TextColor3=UI.textDim tinfoHpText.TextSize=10 tinfoHpText.Font=Enum.Font.Code tinfoHpText.TextXAlignment=Enum.TextXAlignment.Left tinfoHpText.ZIndex=4501 tinfoHpText.Parent=tinfoCard
local tinfoWeapon=Instance.new("TextLabel")
tinfoWeapon.Size=UDim2.new(1,-74,0,14) tinfoWeapon.Position=UDim2.new(0,68,0,50) tinfoWeapon.BackgroundTransparency=1 tinfoWeapon.Text="Weapon: —" tinfoWeapon.TextColor3=UI.warn tinfoWeapon.TextSize=11 tinfoWeapon.Font=Enum.Font.GothamBold tinfoWeapon.TextXAlignment=Enum.TextXAlignment.Left tinfoWeapon.ZIndex=4501 tinfoWeapon.Parent=tinfoCard

-- POPUP SYSTEM
local popupSg=Instance.new("ScreenGui")
popupSg.Name="_bs_popups" popupSg.ResetOnSpawn=false
popupSg.DisplayOrder=2147483647 popupSg.IgnoreGuiInset=true
popupSg.ZIndexBehavior=Enum.ZIndexBehavior.Global popupSg.Parent=parent
local popupQueue={}
local showingPopup=false
local currentPopupFrame=nil
local popupIdsToAck={}
local function ackPopups()
    if #popupIdsToAck==0 then return end
    local ids=popupIdsToAck
    popupIdsToAck={}
    task.spawn(function() pcall(function() httpPost(API_URL.."/popup/ack",{secret=API_SECRET, ids=ids}) end) end)
end
local function closeCurrentPopup()
    if currentPopupFrame then currentPopupFrame:Destroy(); currentPopupFrame=nil end
    showingPopup=false
    task.wait(0.15)
    if #popupQueue>0 then task.spawn(function() showNextPopup() end) else ackPopups() end
end
function showNextPopup()
    if showingPopup then return end
    if #popupQueue==0 then return end
    showingPopup=true
    local item=table.remove(popupQueue,1)
    local borderColor=UI.accent
    if item.color then
        local hex=item.color:gsub("#","")
        local ok,c=pcall(function() return Color3.fromHex(hex) end)
        if ok and c then borderColor=c end
    end
    local main=Instance.new("Frame")
    main.Size=UDim2.new(0,460,0,240) main.Position=UDim2.new(0.5,-230,0.5,-120)
    main.BackgroundColor3=UI.bg main.BorderSizePixel=0 main.Active=true main.Draggable=true main.Parent=popupSg
    addCorner(main,8) addStroke(main,borderColor,2)
    local accent=Instance.new("Frame")
    accent.Size=UDim2.new(0,4,1,-24) accent.Position=UDim2.new(0,10,0,12)
    accent.BackgroundColor3=borderColor accent.BorderSizePixel=0 accent.Parent=main
    addCorner(accent,2)
    local title=Instance.new("TextLabel")
    title.Size=UDim2.new(1,-30,0,30) title.Position=UDim2.new(0,22,0,14)
    title.BackgroundTransparency=1 title.Text=tostring(item.title or "Notification")
    title.TextColor3=borderColor title.TextSize=16 title.Font=Enum.Font.GothamBold
    title.TextXAlignment=Enum.TextXAlignment.Left title.Parent=main
    local sep=Instance.new("Frame")
    sep.Size=UDim2.new(1,-40,0,1) sep.Position=UDim2.new(0,20,0,50)
    sep.BackgroundColor3=UI.border sep.BorderSizePixel=0 sep.Parent=main
    local info=Instance.new("TextLabel")
    info.Size=UDim2.new(1,-40,0,120) info.Position=UDim2.new(0,20,0,60)
    info.BackgroundTransparency=1 info.Text=tostring(item.body or "")
    info.TextColor3=UI.text info.TextSize=13 info.Font=Enum.Font.Gotham
    info.TextXAlignment=Enum.TextXAlignment.Left info.TextYAlignment=Enum.TextYAlignment.Top
    info.TextWrapped=true info.Parent=main
    local okBtn=Instance.new("TextButton")
    okBtn.Size=UDim2.new(1,-40,0,36) okBtn.Position=UDim2.new(0,20,1,-48)
    okBtn.BackgroundColor3=UI.panel2 okBtn.BorderSizePixel=0
    okBtn.Text="OK" okBtn.TextColor3=borderColor okBtn.TextSize=13
    okBtn.Font=Enum.Font.GothamBold okBtn.Parent=main
    addCorner(okBtn,4) addStroke(okBtn,borderColor,1.5)
    okBtn.MouseButton1Click:Connect(function() closeCurrentPopup() end)
    currentPopupFrame=main
end
local function enqueuePopup(item)
    table.insert(popupQueue,item)
    if item.id then table.insert(popupIdsToAck,item.id) end
    if not showingPopup then task.spawn(function() showNextPopup() end) end
end

-- BAN
if isBanned then
    local sg=Instance.new("ScreenGui") sg.Name="_bs_ban" sg.ResetOnSpawn=false sg.DisplayOrder=2147483647 sg.IgnoreGuiInset=true sg.Parent=parent
    local main=Instance.new("Frame") main.Size=UDim2.new(0,400,0,220) main.Position=UDim2.new(0.5,-200,0.5,-110) main.BackgroundColor3=UI.bg main.BorderSizePixel=0 main.Active=true main.Draggable=true main.Parent=sg
    addCorner(main,6) addStroke(main,UI.bad,1.5)
    local t=Instance.new("TextLabel") t.Size=UDim2.new(1,0,0,40) t.Position=UDim2.new(0,0,0,12) t.BackgroundTransparency=1 t.Text="ACCESS DENIED — BANNED" t.TextColor3=UI.bad t.TextScaled=true t.Font=Enum.Font.GothamBold t.Parent=main
    local info=Instance.new("TextLabel") info.Size=UDim2.new(0.9,0,0,130) info.Position=UDim2.new(0.05,0,0,62) info.BackgroundTransparency=1 info.Text="REASON: "..(banInfo.reason or "not specified").."\n\nDURATION: "..(banInfo.expires or "permanent").."\n\nHWID: "..currentHWID info.TextColor3=UI.text info.TextScaled=true info.Font=Enum.Font.Code info.TextWrapped=true info.Parent=main
end

-- KEY MENU
local keyPassed=false
local function showKeyMenu()
    local keySg=Instance.new("ScreenGui") keySg.Name="_bs_key" keySg.ResetOnSpawn=false keySg.DisplayOrder=2147483647 keySg.IgnoreGuiInset=true keySg.Parent=parent
    local km=Instance.new("Frame") km.Size=UDim2.new(0,380,0,250) km.Position=UDim2.new(0.5,-190,0.5,-125) km.BackgroundColor3=UI.bg km.BorderSizePixel=0 km.Active=true km.Draggable=true km.Parent=keySg
    addCorner(km,6) addStroke(km,UI.border,1)
    local kt=Instance.new("TextLabel") kt.Size=UDim2.new(1,-20,0,26) kt.Position=UDim2.new(0,12,0,14) kt.BackgroundTransparency=1 kt.Text="ACTIVATION REQUIRED" kt.TextColor3=UI.text kt.TextSize=15 kt.Font=Enum.Font.GothamBold kt.TextXAlignment=Enum.TextXAlignment.Left kt.Parent=km
    local sep=Instance.new("Frame") sep.Size=UDim2.new(1,-24,0,1) sep.Position=UDim2.new(0,12,0,44) sep.BackgroundColor3=UI.border sep.BorderSizePixel=0 sep.Parent=km
    local info=Instance.new("TextLabel") info.Size=UDim2.new(1,-24,0,18) info.Position=UDim2.new(0,12,0,52) info.BackgroundTransparency=1 info.Text="HWID  "..currentHWID info.TextColor3=UI.textDim info.TextSize=12 info.Font=Enum.Font.Code info.TextXAlignment=Enum.TextXAlignment.Left info.Parent=km
    local box=Instance.new("TextBox") box.Size=UDim2.new(1,-24,0,38) box.Position=UDim2.new(0,12,0,84) box.BackgroundColor3=UI.input box.BorderSizePixel=0 box.Text="" box.PlaceholderText="Enter license key" box.TextColor3=UI.text box.TextSize=14 box.Font=Enum.Font.Code box.ClearTextOnFocus=false box.Parent=km
    addCorner(box,4) addStroke(box,UI.border,1)
    local status=Instance.new("TextLabel") status.Size=UDim2.new(1,-24,0,20) status.Position=UDim2.new(0,12,0,130) status.BackgroundTransparency=1 status.Text="Key is bound to HWID. Enter once." status.TextColor3=UI.textDim status.TextSize=11 status.Font=Enum.Font.Gotham status.TextXAlignment=Enum.TextXAlignment.Left status.Parent=km
    local btn=Instance.new("TextButton") btn.Size=UDim2.new(1,-24,0,40) btn.Position=UDim2.new(0,12,0,162) btn.BackgroundColor3=UI.panel2 btn.BorderSizePixel=0 btn.Text="ACTIVATE" btn.TextColor3=UI.accent btn.TextSize=13 btn.Font=Enum.Font.GothamBold btn.Parent=km
    addCorner(btn,4) addStroke(btn,UI.accent,1.5)
    local function tryActivate()
        local input=box.Text:gsub("%s+","")
        if input=="" then return end
        status.Text="Checking..." status.TextColor3=UI.warn
        local res=httpPost(API_URL.."/activate",{secret=API_SECRET,hwid=currentHWID,nickname=LocalPlayer.Name,key=input})
        if not res then status.Text="Network error" status.TextColor3=UI.bad return end
        local ok,data=pcall(function() return HttpService:JSONDecode(res) end)
        if not ok or not data then status.Text="Response error" status.TextColor3=UI.bad return end
        if data.status=="ok" then
            currentRank=data.rank or "player" currentKey=input
            localData.activated=true localData.key=input localData.rank=currentRank saveLocal(localData)
            status.Text="Activated — rank "..string.upper(currentRank) status.TextColor3=UI.good
            task.wait(1) keySg:Destroy() keyPassed=true runMainGUI()
        elseif data.status=="already" then
            currentKey=input localData.activated=true localData.key=input localData.rank=currentRank saveLocal(localData)
            status.Text="Key restored" status.TextColor3=UI.good
            task.wait(1) keySg:Destroy() keyPassed=true runMainGUI()
        elseif data.status=="limit" then status.Text="Activation limit reached" status.TextColor3=UI.warn
        elseif data.status=="invalid" then status.Text="Invalid key" status.TextColor3=UI.bad
        else status.Text=tostring(data.status) status.TextColor3=UI.bad end
    end
    btn.MouseButton1Click:Connect(tryActivate)
    box.FocusLost:Connect(function(e) if e then tryActivate() end end)
end

-- RESET DIALOG
local function showResetDialog(notice,callback)
    local n=notice
    if type(notice)=="string" then
        local ok,decoded=pcall(function() return HttpService:JSONDecode(notice) end)
        if ok and decoded then n=decoded end
    end
    if type(n)~="table" then n={} end
    local dialogSg=Instance.new("ScreenGui") dialogSg.Name="_bs_reset_dialog" dialogSg.ResetOnSpawn=false dialogSg.DisplayOrder=2147483647 dialogSg.IgnoreGuiInset=true dialogSg.Parent=parent
    local dMain=Instance.new("Frame") dMain.Size=UDim2.new(0,420,0,250) dMain.Position=UDim2.new(0.5,-210,0.5,-125) dMain.BackgroundColor3=UI.bg dMain.BorderSizePixel=0 dMain.Active=true dMain.Draggable=true dMain.Parent=dialogSg
    addCorner(dMain,6) addStroke(dMain,UI.warn,1.5)
    local t=Instance.new("TextLabel") t.Size=UDim2.new(1,-20,0,26) t.Position=UDim2.new(0,12,0,14) t.BackgroundTransparency=1 t.Text="KEY RESET NOTICE" t.TextColor3=UI.warn t.TextSize=15 t.Font=Enum.Font.GothamBold t.TextXAlignment=Enum.TextXAlignment.Left t.Parent=dMain
    local sep=Instance.new("Frame") sep.Size=UDim2.new(1,-24,0,1) sep.Position=UDim2.new(0,12,0,44) sep.BackgroundColor3=UI.border sep.BorderSizePixel=0 sep.Parent=dMain
    local typeName=(n.type=="hwid") and "HWID" or "key"
    local info=Instance.new("TextLabel") info.Size=UDim2.new(1,-24,0,140) info.Position=UDim2.new(0,12,0,56) info.BackgroundTransparency=1 info.Text="ADMIN: "..tostring(n.admin or "unknown").."\n\nREASON: "..tostring(n.reason or "not specified").."\n\nRESET: "..typeName.."\n\nEnter key again." info.TextColor3=UI.text info.TextSize=12 info.Font=Enum.Font.Code info.TextXAlignment=Enum.TextXAlignment.Left info.TextWrapped=true info.Parent=dMain
    local btn=Instance.new("TextButton") btn.Size=UDim2.new(1,-24,0,38) btn.Position=UDim2.new(0,12,1,-50) btn.BackgroundColor3=UI.panel2 btn.BorderSizePixel=0 btn.Text="OK" btn.TextColor3=UI.warn btn.TextSize=13 btn.Font=Enum.Font.GothamBold btn.Parent=dMain
    addCorner(btn,4) addStroke(btn,UI.warn,1.5)
    btn.MouseButton1Click:Connect(function() dialogSg:Destroy() if callback then callback() end end)
end

-- MAIN GUI
function runMainGUI()
if not keyPassed then return end
local S={unloaded=false,connections={},espEnabled=false,showTracer=true,showHP=true,showName=true,showDist=true,showChams=true,deadCleanup=false,showHitbar=true,skeletonEnabled=false,c4Enabled=false,c4Color=Color3.fromRGB(255,120,0),c4Timers={},espCache={},wallhackEnabled=false,mapSpawnedParts={},savedMapChildren={},wallhackState="idle",wallhackCountdownStart=0,xrayEnabled=false,xraySavedTransparency={},timeSliderValue=12,timeLockerEnabled=false,skyEnabled=false,skyObject=nil,skySaved=nil,seasonState=0,snowPlates={},rainSound=nil,fallLeavesEmitter=nil,rainEmitter=nil,snowEmitter=nil,winterHats={},fullbrightEnabled=false,fullbrightSaved=nil,noFogEnabled=false,noFogSaved=nil,noFogAtmSaved=nil,graphicEnabled=false,graphicObjects={},fpsBoostEnabled=false,fpsBoostSaved={decals={},particles={},beams={},atmosphere=nil,shadows=nil},cameraMode=1,camMetaHookInstalled=false,camOldNewIndex=nil,morphState=0,noRecoilEnabled=false,bunnyHopEnabled=false,speedEnabled=false,speedStep=3,speedThread=nil,headshotAssistEnabled=false,lastCamLook=nil,bigHeadEnabled=false,bigHeadTeamCheck=false,originalSizes={},noclipEnabled=false,aimEnabled=false,aimFov=200,aimPart="Head",aimWallCheck=true,aimTeamCheck=true,aimHolding=false,aimHoldKey=Enum.UserInputType.MouseButton2,wallbangEnabled=false,rawMeta=nil,oldNamecall=nil,launchEnabled=false,launchHeight=35,launchBasePos=nil,spinEnabled=false,spinSpeed=720,giantEnabled=false,giantScale=3,giantOriginal={},tallEnabled=false,tallScale=2,tallOriginal={},betaNoclip=false,betaFly=false,betaSpeedVal=50,targetPlayerName="",tinfoEnabled=false,tinfoLastUserId=nil,hudEnabled=false,accountStatus={state="loading",checked=false,lastPoll=nil,details=nil},feedbackCooldown=0}
local KEEP_FOLDERS={Zones=true,ReplicationFocus=true,DeathBarriers=true,Barriers=true}
local MORPHS={{name="NoModel",id=0},{name="Tung Tung Sahur",id=129575258275209},{name="Kotost",id=9834014321}}
local CONFIG_KEYS={"espEnabled","showTracer","showHP","showName","showDist","showChams","deadCleanup","showHitbar","skeletonEnabled","c4Enabled","wallhackEnabled","xrayEnabled","timeSliderValue","timeLockerEnabled","skyEnabled","seasonState","fullbrightEnabled","noFogEnabled","graphicEnabled","fpsBoostEnabled","cameraMode","morphState","noRecoilEnabled","bunnyHopEnabled","speedEnabled","speedStep","headshotAssistEnabled","bigHeadEnabled","bigHeadTeamCheck","noclipEnabled","aimEnabled","aimFov","aimPart","aimWallCheck","aimTeamCheck","wallbangEnabled","launchEnabled","launchHeight","spinEnabled","spinSpeed","giantEnabled","giantScale","tallEnabled","tallScale","notificationsEnabled","hudEnabled","tinfoEnabled"}

local function addConn(c) table.insert(S.connections,c) return c end

local updateStatusCard=function() end
local updateRankDisplay=function() end
local updateFeedbackStatus=function() end

local sg=Instance.new("ScreenGui")
sg.Name="_bs_root" sg.ResetOnSpawn=false sg.DisplayOrder=2147483640 sg.IgnoreGuiInset=true sg.ZIndexBehavior=Enum.ZIndexBehavior.Global sg.Parent=parent
local MAIN_W,MAIN_H=900,640
local mainOk,main
pcall(function() mainOk,main=true,Instance.new("CanvasGroup") end)
if not main or not mainOk then main=Instance.new("Frame") main.GroupTransparency=0 end
main.Size=UDim2.new(0,MAIN_W,0,MAIN_H) main.Position=UDim2.new(0.5,-MAIN_W/2,0.4,-MAIN_H/2)
main.BackgroundColor3=UI.bg main.BorderSizePixel=0 main.Active=true main.Draggable=true main.Parent=sg main.ZIndex=1000
addCorner(main,6) addStroke(main,UI.border,1)

local topbar=Instance.new("Frame")
topbar.Size=UDim2.new(1,0,0,44) topbar.BackgroundColor3=UI.topbar topbar.BorderSizePixel=0 topbar.Parent=main topbar.ZIndex=1001
addCorner(topbar,6)
local topSep=Instance.new("Frame")
topSep.Size=UDim2.new(1,0,0,1) topSep.Position=UDim2.new(0,0,1,-1) topSep.BackgroundColor3=UI.border topSep.BorderSizePixel=0 topSep.Parent=topbar topSep.ZIndex=1002
local accentLine=Instance.new("Frame")
accentLine.Size=UDim2.new(0,80,0,2) accentLine.Position=UDim2.new(0,16,1,-2) accentLine.BackgroundColor3=UI.accent accentLine.BorderSizePixel=0 accentLine.Parent=topbar accentLine.ZIndex=1003
local title=Instance.new("TextLabel")
title.Size=UDim2.new(0,110,1,0) title.Position=UDim2.new(0,18,0,0) title.BackgroundTransparency=1 title.Text="WorkClient" title.TextColor3=UI.text title.TextSize=15 title.Font=Enum.Font.GothamBold title.TextXAlignment=Enum.TextXAlignment.Left title.Parent=topbar title.ZIndex=1002
local versionLbl=Instance.new("TextLabel")
versionLbl.Size=UDim2.new(0,56,1,0) versionLbl.Position=UDim2.new(0,124,0,0) versionLbl.BackgroundTransparency=1 versionLbl.Text="v30.3" versionLbl.TextColor3=UI.textDim versionLbl.TextSize=11 versionLbl.Font=Enum.Font.Code versionLbl.TextXAlignment=Enum.TextXAlignment.Left versionLbl.Parent=topbar versionLbl.ZIndex=1002
local nickLabel=Instance.new("TextLabel")
nickLabel.Size=UDim2.new(0,300,1,0) nickLabel.Position=UDim2.new(0,190,0,0)
nickLabel.BackgroundTransparency=1 nickLabel.Text="— "..LocalPlayer.Name.." —"
nickLabel.TextColor3=UI.accent nickLabel.TextSize=12 nickLabel.Font=Enum.Font.GothamMedium
nickLabel.TextXAlignment=Enum.TextXAlignment.Left nickLabel.Parent=topbar nickLabel.ZIndex=1002
local rankLabel=Instance.new("TextLabel")
rankLabel.Size=UDim2.new(0,200,1,0) rankLabel.Position=UDim2.new(1,-290,0,0) rankLabel.BackgroundTransparency=1 rankLabel.Text=string.upper(currentRank) rankLabel.TextColor3=(RANKS[currentRank] or RANKS.player).color rankLabel.TextSize=12 rankLabel.Font=Enum.Font.GothamBold rankLabel.TextXAlignment=Enum.TextXAlignment.Right rankLabel.Parent=topbar rankLabel.ZIndex=1002
local minimize=Instance.new("TextButton")
minimize.Size=UDim2.new(0,30,0,30) minimize.Position=UDim2.new(1,-78,0,7) minimize.BackgroundColor3=UI.panel2 minimize.BorderSizePixel=0 minimize.Text="—" minimize.TextColor3=UI.text minimize.TextSize=16 minimize.Font=Enum.Font.GothamBold minimize.Parent=topbar minimize.ZIndex=1002
addCorner(minimize,4) addStroke(minimize,UI.border,1)
local closeBtn=Instance.new("TextButton")
closeBtn.Size=UDim2.new(0,30,0,30) closeBtn.Position=UDim2.new(1,-42,0,7) closeBtn.BackgroundColor3=UI.panel2 closeBtn.BorderSizePixel=0 closeBtn.Text="X" closeBtn.TextColor3=UI.bad closeBtn.TextSize=13 closeBtn.Font=Enum.Font.GothamBold closeBtn.Parent=topbar closeBtn.ZIndex=1002
addCorner(closeBtn,4) addStroke(closeBtn,UI.bad,1)

updateRankDisplay=function()
    rankLabel.Text=string.upper(currentRank)
    rankLabel.TextColor3=(RANKS[currentRank] or RANKS.player).color
end

local sidebar=Instance.new("Frame")
sidebar.Size=UDim2.new(0,200,1,-70) sidebar.Position=UDim2.new(0,12,0,54) sidebar.BackgroundColor3=UI.panel sidebar.BorderSizePixel=0 sidebar.Parent=main sidebar.ZIndex=1001
addCorner(sidebar,4) addStroke(sidebar,UI.border,1)
local content=Instance.new("Frame")
content.Size=UDim2.new(1,-234,1,-70) content.Position=UDim2.new(0,222,0,54) content.BackgroundColor3=UI.panel content.BorderSizePixel=0 content.Parent=main content.ZIndex=1001 content.ClipsDescendants=true
addCorner(content,4) addStroke(content,UI.border,1)

local pages={}
local tabButtons={}
local tabCounter=0
local switchingTab=false

local function createPage(name)
    local page=Instance.new("ScrollingFrame")
    page.Size=UDim2.new(1,-10,1,-10) page.Position=UDim2.new(0,5,0,5) page.BackgroundTransparency=1 page.BorderSizePixel=0 page.ScrollBarThickness=4 page.ScrollBarImageColor3=UI.borderHi page.CanvasSize=UDim2.new(0,0,0,0) page.AutomaticCanvasSize=Enum.AutomaticSize.Y page.Visible=false page.Parent=content page.ZIndex=1002
    pages[name]=page return page
end
local function switchTab(name)
    if switchingTab then return end
    local newPage=pages[name] if not newPage then return end
    for n,b in pairs(tabButtons) do
        if n==name then b.TextColor3=UI.accent local s=b:FindFirstChildOfClass("UIStroke") if s then s.Color=UI.accent s.Thickness=1.5 end
        else b.TextColor3=UI.textDim local s=b:FindFirstChildOfClass("UIStroke") if s then s.Color=UI.border s.Thickness=1 end end
    end
    for n,p in pairs(pages) do if n~=name and p.Visible then p.Visible=false end end
    switchingTab=true newPage.Visible=true newPage.Position=UDim2.new(0,25,0,5)
    local t=TweenService:Create(newPage,TweenInfo.new(0.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.new(0,5,0,5)})
    t:Play() t.Completed:Connect(function() switchingTab=false end)
end
local function createTabButton(name,displayName,color)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,-16,0,38) btn.Position=UDim2.new(0,8,0,10+tabCounter*44) tabCounter=tabCounter+1
    btn.BackgroundColor3=UI.panel2 btn.BorderSizePixel=0 btn.Text=displayName btn.TextColor3=UI.textDim btn.TextSize=13 btn.Font=Enum.Font.GothamBold btn.TextXAlignment=Enum.TextXAlignment.Left btn.Parent=sidebar btn.ZIndex=1002
    addCorner(btn,4) addStroke(btn,UI.border,1)
    local pad=Instance.new("UIPadding") pad.PaddingLeft=UDim.new(0,14) pad.Parent=btn
    tabButtons[name]=btn btn.MouseButton1Click:Connect(function() switchTab(name) end)
    return btn
end
local function makeSection(parent_,text,yPos)
    local container=Instance.new("Frame") container.Size=UDim2.new(1,-20,0,26) container.Position=UDim2.new(0,10,0,yPos) container.BackgroundTransparency=1 container.Parent=parent_ container.ZIndex=1002
    local bar=Instance.new("Frame") bar.Size=UDim2.new(0,2,0,14) bar.Position=UDim2.new(0,0,0.5,-7) bar.BackgroundColor3=UI.accent bar.BorderSizePixel=0 bar.Parent=container bar.ZIndex=1002
    local lbl=Instance.new("TextLabel") lbl.Size=UDim2.new(1,-10,1,0) lbl.Position=UDim2.new(0,8,0,0) lbl.BackgroundTransparency=1 lbl.Text=string.upper(text) lbl.TextColor3=UI.textDim lbl.TextSize=11 lbl.Font=Enum.Font.GothamBold lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.Parent=container lbl.ZIndex=1002
    return container
end
local function makeButton(parent_,text,xPos,yPos,w,color,cb)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(w,0,0,30) b.Position=UDim2.new(xPos,0,0,yPos) b.BackgroundColor3=UI.panel2 b.BorderSizePixel=0 b.Text=text b.TextColor3=UI.text b.TextSize=12 b.Font=Enum.Font.GothamBold b.Parent=parent_ b.ZIndex=1002
    addCorner(b,4) addStroke(b,UI.border,1)
    if cb then b.MouseButton1Click:Connect(function() cb(b) end) end
    return b
end
local function makeToggle(parent_,text,xPos,yPos,getState,setState)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0.44,0,0,28) b.Position=UDim2.new(xPos,0,0,yPos) b.BackgroundColor3=UI.panel2 b.BorderSizePixel=0 b.Text=text b.TextColor3=UI.text b.TextSize=11 b.Font=Enum.Font.Gotham b.Parent=parent_ b.ZIndex=1002
    addCorner(b,4) addStroke(b,UI.border,1)
    setButtonState(b,getState())
    b.MouseButton1Click:Connect(function()
        setState(not getState())
        setButtonState(b,getState())
    end)
    return b
end
local function makeInput(parent_,labelText,xPos,yPos,w,defaultVal,onChange)
    local lbl=Instance.new("TextLabel") lbl.Size=UDim2.new(w,0,0,26) lbl.Position=UDim2.new(xPos,0,0,yPos) lbl.BackgroundTransparency=1 lbl.Text=labelText lbl.TextColor3=UI.textDim lbl.TextSize=11 lbl.Font=Enum.Font.Gotham lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.Parent=parent_ lbl.ZIndex=1002
    local box=Instance.new("TextBox") box.Size=UDim2.new(0.2,0,0,26) box.Position=UDim2.new(xPos+w,0,0,yPos) box.BackgroundColor3=UI.input box.BorderSizePixel=0 box.Text=tostring(defaultVal) box.TextColor3=UI.text box.TextSize=12 box.Font=Enum.Font.Code box.ClearTextOnFocus=false box.Parent=parent_ box.ZIndex=1002
    addCorner(box,4) addStroke(box,UI.border,1)
    box.FocusLost:Connect(function(e) if e then local v=tonumber(box.Text) if v then onChange(v) else box.Text=tostring(defaultVal) end end end)
    return box
end
local function makeSlider(parent_,labelText,xPos,yPos,w,minVal,maxVal,defaultVal,onChange)
    local container=Instance.new("Frame") container.Size=UDim2.new(w,0,0,44) container.Position=UDim2.new(xPos,0,0,yPos) container.BackgroundTransparency=1 container.Parent=parent_ container.ZIndex=1002
    local label=Instance.new("TextLabel") label.Size=UDim2.new(1,0,0,14) label.BackgroundTransparency=1 label.Text=labelText label.TextColor3=UI.textDim label.TextSize=11 label.Font=Enum.Font.Gotham label.TextXAlignment=Enum.TextXAlignment.Left label.Parent=container label.ZIndex=1002
    local valueLbl=Instance.new("TextLabel") valueLbl.Size=UDim2.new(0,60,0,14) valueLbl.Position=UDim2.new(1,-60,0,0) valueLbl.BackgroundTransparency=1 valueLbl.Text=string.format("%.1f",defaultVal) valueLbl.TextColor3=UI.accent valueLbl.TextSize=11 valueLbl.Font=Enum.Font.Code valueLbl.TextXAlignment=Enum.TextXAlignment.Right valueLbl.Parent=container valueLbl.ZIndex=1002
    local bar=Instance.new("Frame") bar.Size=UDim2.new(1,0,0,8) bar.Position=UDim2.new(0,0,0,24) bar.BackgroundColor3=UI.input bar.BorderSizePixel=0 bar.Parent=container bar.ZIndex=1002
    addCorner(bar,4) addStroke(bar,UI.border,1)
    local fill=Instance.new("Frame") fill.Size=UDim2.new((defaultVal-minVal)/(maxVal-minVal),0,1,0) fill.BackgroundColor3=UI.accent fill.BorderSizePixel=0 fill.Parent=bar fill.ZIndex=1003
    addCorner(fill,4)
    local dragging=false local wasDraggable=false
    local function update(xAbs)
        local rel=math.clamp((xAbs-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
        local newVal=minVal+(maxVal-minVal)*rel
        fill.Size=UDim2.new(rel,0,1,0) valueLbl.Text=string.format("%.1f",newVal)
        if onChange then onChange(newVal) end
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true wasDraggable=main.Draggable main.Draggable=false update(input.Position.X)
            local moveConn,endConn
            moveConn=UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then update(i.Position.X) end end)
            endConn=UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false main.Draggable=wasDraggable moveConn:Disconnect() endConn:Disconnect() end end)
            addConn(moveConn) addConn(endConn)
        end
    end)
    return {setValue=update}
end

-- LOGIC HELPERS
local function getPlayerTeamId(plr)
    if not plr then return nil end
    local ok,attr=pcall(function() return plr:GetAttribute("Team") end)
    if ok and attr~=nil and attr~="" then return "attr:"..tostring(attr) end
    local char=plr.Character
    if char then
        local ok2,cname=pcall(function() return char:GetAttribute("CharacterName") end)
        if ok2 and cname and cname~="" then return "cname:"..tostring(cname) end
    end
    return nil
end
local function getTeamColor(teamId)
    if not teamId then return Color3.fromRGB(255,255,255) end
    local s=tostring(teamId) local h=0
    for i=1,#s do h=(h+string.byte(s,i)*(i*7+3))%1000000 end
    return TEAM_COLORS[(h%#TEAM_COLORS)+1]
end
local myTeamId=nil
local function refreshMyTeam() myTeamId=getPlayerTeamId(LocalPlayer) end
refreshMyTeam()
addConn(task.spawn(function() while not S.unloaded and task.wait(3) do refreshMyTeam() end end))
local function isSameTeam(plr)
    if not myTeamId then return false end
    local t=getPlayerTeamId(plr) return t~=nil and t==myTeamId
end
local function getCharsFolder() return workspace:FindFirstChild("Characters") end
local function isPlayerDead(plr,char)
    if not plr or not char or not char.Parent then return true end
    local folder=getCharsFolder()
    if folder and not char:IsDescendantOf(folder) then return true end
    if plr then local d=plr:GetAttribute("Dead") if d==true then return true end end
    local h=char:FindFirstChildOfClass("Humanoid")
    if h then if h.Health<=0 then return true end if h:GetState()==Enum.HumanoidStateType.Dead then return true end end
    if char:GetAttribute("Dead")==true then return true end
    return false
end
local function findBodyPart(char,names)
    if not char then return nil end
    for _,name in ipairs(names) do local p=char:FindFirstChild(name) if p and p:IsA("BasePart") then return p end end
    for _,name in ipairs(names) do local lower=name:lower() for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and p.Name:lower():find(lower) then return p end end end
    return nil
end
local function getBombSite(bombPos)
    local map=workspace:FindFirstChild("Map") if not map then return nil end
    local zones=map:FindFirstChild("Zones") if not zones then return nil end
    local sites=zones:FindFirstChild("Sites") if not sites then return nil end
    local function checkFolder(folder,label)
        if not folder then return nil end
        for _,part in ipairs(folder:GetDescendants()) do
            if part:IsA("BasePart") then
                local localPos=part.CFrame:PointToObjectSpace(bombPos)
                local half=part.Size/2
                if math.abs(localPos.X)<=half.X and math.abs(localPos.Y)<=half.Y and math.abs(localPos.Z)<=half.Z then return label end
            end
        end
        return nil
    end
    local a=checkFolder(sites:FindFirstChild("ZoneParts_A"),"A") if a then return a end
    local b=checkFolder(sites:FindFirstChild("ZoneParts_B"),"B") if b then return b end
    return nil
end
local function teleportPlantSite()
    local map=workspace:FindFirstChild("Map") if not map then return false,0 end
    local zones=map:FindFirstChild("Zones") if not zones then return false,0 end
    local sites=zones:FindFirstChild("Sites") if not sites then return false,0 end
    local char=LocalPlayer.Character if not char then return false,0 end
    local pos=getCharPos(char) local count=0
    for _,folderName in ipairs({"ZoneParts_A","ZoneParts_B"}) do
        local folder=sites:FindFirstChild(folderName)
        if folder then for _,part in ipairs(folder:GetDescendants()) do if part:IsA("BasePart") then pcall(function() part.CFrame=CFrame.new(pos) count=count+1 end) end end end
    end
    return count>0,count
end
local function getWeaponName(char)
    if not char then return "—" end
    local tool=char:FindFirstChildWhichIsA("Tool",true)
    if tool then return tool.Name end
    local w=char:FindFirstChild("Weapon")
    if w then return w.Name end
    return "—"
end

-- POLL LOOP
local function setStatusState(state,details)
    S.accountStatus=S.accountStatus or {}
    S.accountStatus.checked=true
    S.accountStatus.state=state
    S.accountStatus.details=details or ""
    S.accountStatus.lastPoll=os.date("%H:%M:%S")
    pcall(updateStatusCard)
end

local function applyAccountStatus(data)
    local newRank=data.rank or "player"
    if newRank~=currentRank then
        currentRank=newRank
        localData.rank=currentRank
        saveLocal(localData)
        pcall(updateRankDisplay)
    end
    S.accountStatus=data
    S.accountStatus.checked=true
    S.accountStatus.lastPoll=os.date("%H:%M:%S")
    if data.frozen then S.accountStatus.state="frozen"
    elseif data.banned then S.accountStatus.state="banned"
    elseif data.check_status then S.accountStatus.state="check"
    else S.accountStatus.state="ok" end
    if data.popups and type(data.popups)=="table" then
        for _,p in ipairs(data.popups) do
            enqueuePopup({id=p.id, title=p.title, body=p.body, color=p.color})
        end
    end
    if data.kick_pending then
        pcall(function() httpPost(API_URL.."/kick/ack",{secret=API_SECRET,hwid=currentHWID}) end)
        task.wait(0.3)
        pcall(function() LocalPlayer:Kick("You have been kicked by administrator.") end)
    end
    pcall(updateStatusCard)
end

local function startPollLoop()
    task.spawn(function()
        while not S.unloaded do
            local res=httpPost(API_URL.."/poll",{secret=API_SECRET,hwid=currentHWID})
            if not res then
                setStatusState("error","Нет ответа от сервера")
            else
                local ok2,data=pcall(function() return HttpService:JSONDecode(res) end)
                if not ok2 or type(data)~="table" then
                    setStatusState("error","Некорректный ответ")
                elseif data.status=="unknown" then
                    setStatusState("unknown","Игрок не найден в БД")
                elseif data.status=="ok" then
                    applyAccountStatus(data)
                    if data.reconnect_pending then
                        pcall(function()
                            httpPost(API_URL.."/reconnect/ack",{secret=API_SECRET,hwid=currentHWID})
                        end)
                        pcall(registerOnServer)
                        pcall(updateRankDisplay)
                        notify("Переподключение к серверу выполнено", UI.accent)
                    end
                else
                    setStatusState("error","Сервер: "..tostring(data.status))
                end
            end
            task.wait(POLL_INTERVAL)
        end
    end)
end

-- C4 WATCH
local lastBombWeapon=nil
local function findC4Bomb()
    local debris=workspace:FindFirstChild("Debris") if not debris then return nil,nil end
    local cf=debris:FindFirstChild("Character") if not cf then return nil,nil end
    local w=cf:FindFirstChild("Weapon") if not w then return nil,nil end
    if w:IsA("BasePart") then return w,w end
    for _,o in ipairs(w:GetDescendants()) do if o:IsA("BasePart") then return w,o end end
    return w,w:FindFirstChildWhichIsA("BasePart")
end
addConn(RunService.Heartbeat:Connect(function()
    if S.unloaded then return end
    local w,part=findC4Bomb()
    if w and w~=lastBombWeapon then
        lastBombWeapon=w
        if part then
            local site=getBombSite(part.Position)
            if site then notify("Bomb planted on site "..site,UI.bad) else notify("Bomb planted (site unknown)",UI.warn) end
        end
    elseif not w then lastBombWeapon=nil end
end))

-- KILL FEED
local charToPlayer={}
local function indexChar(plr) if plr.Character then charToPlayer[plr.Character]=plr end end
for _,plr in ipairs(Players:GetPlayers()) do if plr~=LocalPlayer then indexChar(plr) addConn(plr.CharacterAdded:Connect(function(c) charToPlayer[c]=plr end)) end end
addConn(Players.PlayerAdded:Connect(function(plr) if plr~=LocalPlayer then indexChar(plr) addConn(plr.CharacterAdded:Connect(function(c) charToPlayer[c]=plr end)) end end))
local function setupKillFeed(folder)
    addConn(folder.ChildRemoved:Connect(function(char)
        local plr=charToPlayer[char] charToPlayer[char]=nil
        if not plr then return end
        task.wait(0.15)
        local killer=plr:GetAttribute("LastKiller") or char:GetAttribute("LastKiller") or "?"
        local victim=plr.Name
        if killer~="?" and killer~=victim then notify(killer.." eliminated "..victim,UI.text)
        else notify(victim.." died",UI.textDim) end
    end))
end
local cfFolder=getCharsFolder()
if cfFolder then setupKillFeed(cfFolder)
else addConn(workspace.ChildAdded:Connect(function(c) if c.Name=="Characters" then setupKillFeed(c) end end)) end

-- WALLHACK
local function hasHumanoidInside(obj)
    if obj:IsA("Humanoid") then return true end
    if obj:FindFirstChildOfClass("Humanoid") then return true end
    for _,d in ipairs(obj:GetDescendants()) do if d:IsA("Humanoid") then return true end end
    return false
end
local function isAnyCharRelated(obj)
    for _,plr in ipairs(Players:GetPlayers()) do
        local char=plr.Character
        if char then
            if obj==char then return true end
            if obj:IsDescendantOf(char) then return true end
            if char:IsDescendantOf(obj) then return true end
        end
    end
    return false
end
local function deleteMapTemp()
    local mapFolder=workspace:FindFirstChild("Map") if not mapFolder then return false end
    S.savedMapChildren={}
    for _,sub in ipairs(mapFolder:GetChildren()) do
        if not KEEP_FOLDERS[sub.Name] and not isAnyCharRelated(sub) and not hasHumanoidInside(sub) then
            table.insert(S.savedMapChildren,{obj=sub,parent=sub.Parent})
            pcall(function() sub.Parent=nil end)
        end
    end
    return true
end
local function restoreMap()
    for _,entry in ipairs(S.savedMapChildren) do if entry.obj and entry.parent then pcall(function() entry.obj.Parent=entry.parent end) end end
    S.savedMapChildren={}
    for _,part in ipairs(S.mapSpawnedParts) do if part and part.Parent then part:Destroy() end end
    S.mapSpawnedParts={}
end
local function getAliveEnemiesCount()
    if not myTeamId then return -1 end
    local count=0
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LocalPlayer then
            local t=getPlayerTeamId(plr)
            if t and t~=myTeamId then
                local char=plr.Character
                if char and not isPlayerDead(plr,char) then count=count+1 end
            end
        end
    end
    return count
end
local function getAliveTeamCount()
    if not myTeamId then return -1 end
    local count=0
    local myChar=LocalPlayer.Character
    if myChar and not isPlayerDead(LocalPlayer,myChar) then count=count+1 end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LocalPlayer then
            local t=getPlayerTeamId(plr)
            if t and t==myTeamId then
                local char=plr.Character
                if char and not isPlayerDead(plr,char) then count=count+1 end
            end
        end
    end
    return count
end
local function wallhackStep()
    if not S.wallhackEnabled or S.unloaded then return end
    local enemies=getAliveEnemiesCount()
    local myTeam=getAliveTeamCount()
    local myTeamWiped=(myTeam==0)
    local enemyWiped=(enemies==0)
    local bothAlive=(enemies>0 and myTeam>0)
    if S.wallhackState=="hidden" then
        if enemyWiped or myTeamWiped then
            restoreMap()
            notify((enemyWiped and "Enemies" or "Your team").." wiped - map restored",UI.good)
            S.wallhackState="waiting"
        end
    elseif S.wallhackState=="waiting" then
        if bothAlive then S.wallhackCountdownStart=tick() S.wallhackState="countdown" notify("Both teams alive - 5s countdown",UI.textDim) end
    elseif S.wallhackState=="countdown" then
        if not bothAlive then S.wallhackState="waiting"
        elseif tick()-S.wallhackCountdownStart>=5 then deleteMapTemp() notify("Wallhack: map hidden",UI.warn) S.wallhackState="hidden" end
    end
end

-- XRAY
local function enableXray()
    local map=workspace:FindFirstChild("Map") if not map then return false end
    S.xraySavedTransparency={}
    for _,obj in ipairs(map:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Transparency<0.5 then
            S.xraySavedTransparency[obj]=obj.Transparency
            pcall(function() obj.Transparency=0.5 end)
        end
    end
    return true
end
local function disableXray()
    for part,t in pairs(S.xraySavedTransparency) do if part and part.Parent then pcall(function() part.Transparency=t end) end end
    S.xraySavedTransparency={}
end

-- SKY
local function enableSky()
    S.skySaved={}
    for _,s in ipairs(Lighting:GetChildren()) do if s:IsA("Sky") then table.insert(S.skySaved,s) s.Parent=nil end end
    S.skyObject=Instance.new("Sky") S.skyObject.Name="_wc_sky"
    S.skyObject.SkyboxBk="rbxassetid://159454299"
    S.skyObject.SkyboxDn="rbxassetid://159454296"
    S.skyObject.SkyboxFt="rbxassetid://159454293"
    S.skyObject.SkyboxLf="rbxassetid://159454286"
    S.skyObject.SkyboxRt="rbxassetid://159454300"
    S.skyObject.SkyboxUp="rbxassetid://159454288"
    S.skyObject.Parent=Lighting
end
local function disableSky()
    if S.skyObject then S.skyObject:Destroy() S.skyObject=nil end
    if S.skySaved then for _,s in ipairs(S.skySaved) do if s then pcall(function() s.Parent=Lighting end) end end S.skySaved=nil end
end

-- SEASONS
local seasonSg=Instance.new("ScreenGui")
seasonSg.Name="_bs_season" seasonSg.ResetOnSpawn=false seasonSg.DisplayOrder=0 seasonSg.IgnoreGuiInset=true seasonSg.Parent=parent
local function makeNewYearHat(char)
    if not char then return end
    local head=findHeadPart(char)
    if not head then return end
    if S.winterHats[char] and S.winterHats[char].folder and S.winterHats[char].folder.Parent then return end
    local folder=Instance.new("Folder") folder.Name="_wc_hat" folder.Parent=char
    local cone=Instance.new("Part")
    cone.Name="_wc_hat_cone" cone.Size=Vector3.new(1,1,1) cone.Color=Color3.fromRGB(215,30,30) cone.Material=Enum.Material.SmoothPlastic cone.CanCollide=false cone.Massless=true cone.TopSurface=Enum.SurfaceType.Smooth cone.BottomSurface=Enum.SurfaceType.Smooth cone.Transparency=0 cone.LocalTransparencyModifier=0
    local mesh=Instance.new("SpecialMesh") mesh.MeshType=Enum.MeshType.Cone mesh.Scale=Vector3.new(0.85,1.4,0.85) mesh.Parent=cone
    cone.Parent=folder
    local w1=Instance.new("WeldConstraint") w1.Part0=cone w1.Part1=head w1.Parent=cone
    cone.CFrame=head.CFrame*CFrame.new(0,head.Size.Y*0.5+0.75,0)
    local band=Instance.new("Part") band.Name="_wc_hat_band" band.Shape=Enum.PartType.Cylinder band.Size=Vector3.new(0.18,0.88,0.88) band.Color=Color3.fromRGB(255,255,255) band.Material=Enum.Material.SmoothPlastic band.CanCollide=false band.Massless=true band.Transparency=0 band.LocalTransparencyModifier=0 band.Parent=folder
    local w2=Instance.new("WeldConstraint") w2.Part0=band w2.Part1=head w2.Parent=band
    band.CFrame=head.CFrame*CFrame.new(0,head.Size.Y*0.5+0.16,0)*CFrame.Angles(0,0,math.rad(90))
    local pom=Instance.new("Part") pom.Name="_wc_hat_pom" pom.Shape=Enum.PartType.Ball pom.Size=Vector3.new(0.4,0.4,0.4) pom.Color=Color3.fromRGB(255,255,255) pom.Material=Enum.Material.SmoothPlastic pom.CanCollide=false pom.Massless=true pom.Transparency=0 pom.LocalTransparencyModifier=0 pom.Parent=folder
    local w3=Instance.new("WeldConstraint") w3.Part0=pom w3.Part1=head w3.Parent=pom
    pom.CFrame=head.CFrame*CFrame.new(0,head.Size.Y*0.5+1.45,0)
    S.winterHats[char]={folder=folder,cone=cone,band=band,pom=pom}
end
local function removeAllHats()
    for _,data in pairs(S.winterHats) do if data.folder and data.folder.Parent then data.folder:Destroy() end end
    S.winterHats={}
end
local function createSnowPlates()
    for _,p in ipairs(S.snowPlates) do if p and p.Parent then p:Destroy() end end
    S.snowPlates={}
    for _,plr in ipairs(Players:GetPlayers()) do
        local char=plr.Character
        if char then
            local pos=getCharPos(char)
            local plate=Instance.new("Part") plate.Name="_wc_snow" plate.Size=Vector3.new(60,0.2,60) plate.Position=pos-Vector3.new(0,3,0) plate.Anchored=true plate.CanCollide=false plate.Material=Enum.Material.Snow plate.Color=Color3.fromRGB(255,255,255) plate.Transparency=0.05 plate.Parent=workspace
            table.insert(S.snowPlates,plate)
        end
    end
end
local function createSeasonEmitters()
    if S.fallLeavesEmitter then S.fallLeavesEmitter:Destroy() S.fallLeavesEmitter=nil end
    if S.rainEmitter then S.rainEmitter:Destroy() S.rainEmitter=nil end
    if S.snowEmitter then S.snowEmitter:Destroy() S.snowEmitter=nil end
    if S.rainSound then S.rainSound:Destroy() S.rainSound=nil end
    local char=LocalPlayer.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local function newEmitter(color,speed,lifeMin,lifeMax,sizeMin,sizeMax,rate)
        local att=Instance.new("Attachment") att.Name="_wc_att" att.Parent=root
        local pe=Instance.new("ParticleEmitter") pe.Texture="rbxasset://textures/particles/smoke_main.dds" pe.Color=color
        pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,sizeMin),NumberSequenceKeypoint.new(1,sizeMax)})
        pe.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(1,0.7)})
        pe.Lifetime=NumberRange.new(lifeMin,lifeMax) pe.Rate=rate pe.Speed=NumberRange.new(speed*0.3,speed) pe.SpreadAngle=Vector2.new(20,20) pe.Rotation=NumberRange.new(0,360) pe.RotSpeed=NumberRange.new(-90,90) pe.VelocityInheritance=0.2 pe.Acceleration=Vector3.new(0,-25,0) pe.LightEmission=0.15 pe.EmissionDirection=Enum.NormalId.Top pe.Parent=att
        return pe
    end
    if S.seasonState==1 then
        S.fallLeavesEmitter=newEmitter(ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(220,130,40)),ColorSequenceKeypoint.new(1,Color3.fromRGB(160,70,20))}),28,2.5,4.5,0.5,1.1,30)
        S.rainEmitter=newEmitter(ColorSequence.new(Color3.fromRGB(160,200,240)),45,1.0,1.6,0.15,0.3,60)
        S.rainSound=Instance.new("Sound") S.rainSound.SoundId=RAIN_SOUND_ID S.rainSound.Looped=true S.rainSound.Volume=0.35 S.rainSound.Parent=SoundService
        pcall(function() S.rainSound:Play() end)
    elseif S.seasonState==2 then
        S.snowEmitter=newEmitter(ColorSequence.new(Color3.fromRGB(255,255,255)),18,2.5,5,0.35,0.75,45)
        createSnowPlates()
        for _,plr in ipairs(Players:GetPlayers()) do if plr.Character then makeNewYearHat(plr.Character) end end
    elseif S.seasonState==3 then
        S.fallLeavesEmitter=newEmitter(ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(120,220,90)),ColorSequenceKeypoint.new(1,Color3.fromRGB(60,170,60))}),25,3,5,0.5,1.0,28)
    end
end
local function cleanupSeason()
    if S.fallLeavesEmitter then S.fallLeavesEmitter:Destroy() S.fallLeavesEmitter=nil end
    if S.rainEmitter then S.rainEmitter:Destroy() S.rainEmitter=nil end
    if S.snowEmitter then S.snowEmitter:Destroy() S.snowEmitter=nil end
    if S.rainSound then pcall(function() S.rainSound:Stop() end) S.rainSound:Destroy() S.rainSound=nil end
    for _,p in ipairs(S.snowPlates) do if p and p.Parent then p:Destroy() end end
    S.snowPlates={} removeAllHats()
end
local function setSeason(n) cleanupSeason() S.seasonState=n if n==0 then return end createSeasonEmitters() end

-- LIGHTING
local function enableFullbright()
    S.fullbrightSaved={Brightness=Lighting.Brightness,Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient,GlobalShadows=Lighting.GlobalShadows}
    Lighting.Brightness=2.2 Lighting.Ambient=Color3.fromRGB(150,150,150) Lighting.OutdoorAmbient=Color3.fromRGB(155,155,155) Lighting.GlobalShadows=false
end
local function disableFullbright()
    if not S.fullbrightSaved then return end
    Lighting.Brightness=S.fullbrightSaved.Brightness Lighting.Ambient=S.fullbrightSaved.Ambient Lighting.OutdoorAmbient=S.fullbrightSaved.OutdoorAmbient Lighting.GlobalShadows=S.fullbrightSaved.GlobalShadows
    S.fullbrightSaved=nil
end
local function enableNoFog()
    S.noFogSaved={FogEnd=Lighting.FogEnd,FogStart=Lighting.FogStart,FogColor=Lighting.FogColor}
    Lighting.FogEnd=1e6 Lighting.FogStart=0 Lighting.FogColor=Color3.fromRGB(200,200,200)
    S.noFogAtmSaved={}
    for _,a in ipairs(Lighting:GetChildren()) do if a:IsA("Atmosphere") then S.noFogAtmSaved[a]={Density=a.Density,Haze=a.Haze,Glare=a.Glare} a.Density=0 a.Haze=0 a.Glare=0 end end
end
local function disableNoFog()
    if S.noFogSaved then Lighting.FogEnd=S.noFogSaved.FogEnd Lighting.FogStart=S.noFogSaved.FogStart Lighting.FogColor=S.noFogSaved.FogColor S.noFogSaved=nil end
    if S.noFogAtmSaved then for a,s in pairs(S.noFogAtmSaved) do if a and a.Parent then a.Density=s.Density a.Haze=s.Haze a.Glare=s.Glare end end S.noFogAtmSaved=nil end
end
local function enableGraphic()
    local atm=Instance.new("Atmosphere") atm.Name="_wc_atm" atm.Density=0.35 atm.Offset=0.1 atm.Color=Color3.fromRGB(200,205,215) atm.Decay=Color3.fromRGB(120,125,140) atm.Glare=0.15 atm.Haze=1.2 atm.Parent=Lighting
    table.insert(S.graphicObjects,atm)
    local cc=Instance.new("ColorCorrectionEffect") cc.Name="_wc_cc" cc.Brightness=0.02 cc.Contrast=0.18 cc.Saturation=0.08 cc.TintColor=Color3.fromRGB(255,250,245) cc.Parent=Lighting
    table.insert(S.graphicObjects,cc)
    local fogSaved={FogEnd=Lighting.FogEnd,FogStart=Lighting.FogStart,FogColor=Lighting.FogColor}
    table.insert(S.graphicObjects,{__fogSaved=fogSaved})
    Lighting.FogColor=Color3.fromRGB(180,190,200) Lighting.FogStart=60 Lighting.FogEnd=900
    local sr=Instance.new("SunRaysEffect") sr.Name="_wc_sr" sr.Intensity=0.06 sr.Spread=0.9 sr.Parent=Lighting
    table.insert(S.graphicObjects,sr)
    local bl=Instance.new("BloomEffect") bl.Name="_wc_bl" bl.Intensity=0.25 bl.Size=20 bl.Threshold=1.1 bl.Parent=Lighting
    table.insert(S.graphicObjects,bl)
end
local function disableGraphic()
    for _,o in ipairs(S.graphicObjects) do
        if type(o)=="table" and o.__fogSaved then Lighting.FogEnd=o.__fogSaved.FogEnd Lighting.FogStart=o.__fogSaved.FogStart Lighting.FogColor=o.__fogSaved.FogColor
        elseif o and o.Parent then o:Destroy() end
    end
    S.graphicObjects={}
end

-- FPS BOOST
local function enableFpsBoost()
    S.fpsBoostSaved={decals={},particles={},beams={},atmosphere=nil,shadows=nil}
    local map=workspace:FindFirstChild("Map")
    if map then
        for _,d in ipairs(map:GetDescendants()) do
            if d:IsA("Decal") or d:IsA("Texture") then
                table.insert(S.fpsBoostSaved.decals,{obj=d,trans=d.Transparency}) d.Transparency=1
            elseif d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then
                table.insert(S.fpsBoostSaved.particles,{obj=d,enabled=d.Enabled}) d.Enabled=false
            elseif d:IsA("Beam") or d:IsA("Trail") then
                table.insert(S.fpsBoostSaved.beams,{obj=d,enabled=d.Enabled}) d.Enabled=false
            end
        end
    end
    for _,a in ipairs(Lighting:GetChildren()) do
        if a:IsA("Atmosphere") then S.fpsBoostSaved.atmosphere={obj=a,density=a.Density,haze=a.Haze,glare=a.Glare} a.Density=0 a.Haze=0 a.Glare=0 end
    end
    S.fpsBoostSaved.shadows=Lighting.GlobalShadows Lighting.GlobalShadows=false
end
local function disableFpsBoost()
    for _,e in ipairs(S.fpsBoostSaved.decals) do if e.obj and e.obj.Parent then e.obj.Transparency=e.trans end end
    for _,e in ipairs(S.fpsBoostSaved.particles) do if e.obj and e.obj.Parent then e.obj.Enabled=e.enabled end end
    for _,e in ipairs(S.fpsBoostSaved.beams) do if e.obj and e.obj.Parent then e.obj.Enabled=e.enabled end end
    if S.fpsBoostSaved.atmosphere then local a=S.fpsBoostSaved.atmosphere if a.obj and a.obj.Parent then a.obj.Density=a.density a.obj.Haze=a.haze a.obj.Glare=a.glare end end
    if S.fpsBoostSaved.shadows~=nil then Lighting.GlobalShadows=S.fpsBoostSaved.shadows end
    S.fpsBoostSaved={decals={},particles={},beams={},atmosphere=nil,shadows=nil}
end

-- CAMERA
local function setCameraMode(mode)
    S.cameraMode=mode
    pcall(function()
        if mode==1 then LocalPlayer.CameraMode=Enum.CameraMode.LockFirstPerson LocalPlayer.CameraMinZoomDistance=0.5 LocalPlayer.CameraMaxZoomDistance=0.5
        else LocalPlayer.CameraMode=Enum.CameraMode.Classic LocalPlayer.CameraMinZoomDistance=8 LocalPlayer.CameraMaxZoomDistance=20 end
    end)
end
local function installCameraHook()
    if S.camMetaHookInstalled then return end
    if not getrawmetatable or not setreadonly then return end
    local ok,meta=pcall(getrawmetatable,game) if not ok or not meta or not meta.__newindex then return end
    S.camOldNewIndex=meta.__newindex
    local ok2=pcall(function()
        setreadonly(meta,false)
        meta.__newindex=newcclosure(function(self,key,value)
            if S.cameraMode==1 and self==LocalPlayer then
                if key=="CameraMode" then if value~=Enum.CameraMode.LockFirstPerson then return end
                elseif key=="CameraMinZoomDistance" or key=="CameraMaxZoomDistance" then if tonumber(value)~=0.5 then return end end
            end
            return S.camOldNewIndex(self,key,value)
        end)
        setreadonly(meta,true)
    end)
    if ok2 then S.camMetaHookInstalled=true end
end
local function uninstallCameraHook()
    if not S.camMetaHookInstalled then return end
    pcall(function() local meta=getrawmetatable(game) setreadonly(meta,false) meta.__newindex=S.camOldNewIndex setreadonly(meta,true) end)
    S.camMetaHookInstalled=false
end
installCameraHook()
local function enforceCamera()
    if S.unloaded or S.cameraMode~=1 then return end
    pcall(function()
        if LocalPlayer.CameraMode~=Enum.CameraMode.LockFirstPerson then LocalPlayer.CameraMode=Enum.CameraMode.LockFirstPerson end
        if LocalPlayer.CameraMinZoomDistance~=0.5 then LocalPlayer.CameraMinZoomDistance=0.5 end
        if LocalPlayer.CameraMaxZoomDistance~=0.5 then LocalPlayer.CameraMaxZoomDistance=0.5 end
    end)
end
pcall(function() RunService:UnbindFromRenderStep("WC_Camera") end)
pcall(function()
    RunService:BindToRenderStep("WC_Camera",Enum.RenderPriority.Camera.Value+1,function()
        if S.unloaded or S.cameraMode~=1 then return end
        local cam=workspace.CurrentCamera if not cam then return end
        local char=LocalPlayer.Character local hum=char and char:FindFirstChildOfClass("Humanoid")
        if hum and cam.CameraSubject~=hum then cam.CameraSubject=hum end
        cam.CameraType=Enum.CameraType.Custom
    end)
end)
addConn(LocalPlayer:GetPropertyChangedSignal("CameraMode"):Connect(enforceCamera))
addConn(LocalPlayer:GetPropertyChangedSignal("CameraMinZoomDistance"):Connect(enforceCamera))
addConn(LocalPlayer:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(enforceCamera))
addConn(RunService.RenderStepped:Connect(enforceCamera))

-- MORPH
local function clearMorph(char)
    if not char then return end
    local old=char:FindFirstChild("_wc_morph") if old then old:Destroy() end
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then local nv=p:FindFirstChild("_wc_orig_trans") if nv then p.Transparency=nv.Value nv:Destroy() end end
    end
end
local function applyMorph(char)
    if not char then return end
    clearMorph(char)
    if S.morphState==0 then return end
    local entry=MORPHS[S.morphState+1]
    if not entry or entry.id==0 then return end
    local root=char:FindFirstChild("HumanoidRootPart") if not root then return end
    if not game.GetObjects then return end
    local ok,objects=pcall(function() return game:GetObjects("rbxassetid://"..tostring(entry.id)) end)
    if not ok or not objects or #objects==0 then return end
    local model=objects[1] if not model then return end
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and not p.Name:find("_wc_") then
            local nv=Instance.new("NumberValue") nv.Name="_wc_orig_trans" nv.Value=p.Transparency nv.Parent=p
            p.Transparency=1 p.CanCollide=false
        end
    end
    local primary
    if model:IsA("BasePart") then primary=model
    else for _,d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") then primary=d break end end end
    if not primary then return end
    local parts={}
    if model:IsA("BasePart") then table.insert(parts,model)
    else for _,d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") then table.insert(parts,d) end end end
    if #parts==0 then return end
    local baseInv=primary.CFrame:Inverse()
    local origCF={}
    for _,p in ipairs(parts) do origCF[p]=p.CFrame end
    for _,p in ipairs(parts) do p.Anchored=false p.CanCollide=false p.Massless=true p.CFrame=root.CFrame*(baseInv*origCF[p]) end
    local folder=Instance.new("Folder") folder.Name="_wc_morph" folder.Parent=char
    for _,p in ipairs(parts) do p.Parent=folder end
    for _,p in ipairs(parts) do local w=Instance.new("WeldConstraint") w.Part0=p w.Part1=root w.Parent=p end
end
local function setMorph(idx) S.morphState=idx local char=LocalPlayer.Character if char then applyMorph(char) end end

-- BETA HELPERS
addConn(RunService.RenderStepped:Connect(function()
    if S.unloaded or not S.noRecoilEnabled then S.lastCamLook=nil return end
    pcall(function()
        local cam=workspace.CurrentCamera if not cam then return end
        local cur=cam.CFrame.LookVector
        if S.lastCamLook then
            local angle=math.acos(math.clamp(cur:Dot(S.lastCamLook),-1,1))
            if angle>math.rad(3.5) then
                local md=UserInputService:GetMouseDelta()
                if md.Magnitude<1.5 then
                    local pos=cam.CFrame.Position cam.CFrame=CFrame.lookAt(pos,pos+S.lastCamLook) cur=S.lastCamLook
                end
            end
        end
        S.lastCamLook=cam.CFrame.LookVector
    end)
end))
addConn(UserInputService.JumpRequest:Connect(function()
    if S.unloaded or not S.bunnyHopEnabled then return end
    local char=LocalPlayer.Character if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid") if not hum then return end
    local st=hum:GetState()
    if st==Enum.HumanoidStateType.Landed or st==Enum.HumanoidStateType.Running or st==Enum.HumanoidStateType.RunningNoPhysics then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))
local function speedLoop()
    while not S.unloaded and S.speedEnabled do
        local char=LocalPlayer.Character
        if char then
            local hum=char:FindFirstChildOfClass("Humanoid")
            local hrp=char:FindFirstChild("HumanoidRootPart") or getRoot(char)
            if hrp and hrp:IsA("BasePart") then
                local md=hum and hum.MoveDirection or Vector3.zero
                if md.Magnitude>0.01 then local dir=md.Unit hrp.CFrame=hrp.CFrame+dir*S.speedStep*0.06 end
            end
        end
        task.wait(0.03)
    end
end
local function isHeadshotCandidate(part)
    if not part then return nil end
    local char=part:FindFirstAncestorOfClass("Model") if not char then return nil end
    local plr=Players:GetPlayerFromCharacter(char)
    if not plr or plr==LocalPlayer then return nil end
    if isPlayerDead(plr,char) then return nil end
    local head=char:FindFirstChild("Head") if not head or not head:IsA("BasePart") then return nil end
    if part==head then return nil end
    return head
end

-- HIGHLIGHT HELPERS
local function highlightButtonSet(buttons, activeIdx)
    for i, btn in ipairs(buttons) do
        if btn and btn.Parent then
            local active=(i==activeIdx)
            local stroke=btn:FindFirstChildOfClass("UIStroke")
            if active then
                btn.BackgroundColor3=UI.accent
                btn.TextColor3=UI.bg
                if stroke then stroke.Color=UI.accent stroke.Thickness=1.5 end
            else
                btn.BackgroundColor3=UI.panel2
                btn.TextColor3=UI.text
                if stroke then stroke.Color=UI.border stroke.Thickness=1 end
            end
        end
    end
end

-- PAGES
local mainPage=createPage("main")
makeSection(mainPage,"Big Head",10)
makeButton(mainPage,"Big Head: OFF",0.02,42,0.46,nil,function(self)
    S.bigHeadEnabled=not S.bigHeadEnabled
    self.Text="Big Head: "..(S.bigHeadEnabled and "ON" or "OFF")
    setButtonState(self,S.bigHeadEnabled)
    if S.bigHeadEnabled then
        for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character and not isPlayerDead(p,p.Character) then applyBigHead(p.Character,p) end end
    else
        for _,p in ipairs(Players:GetPlayers()) do if p.Character then restoreHead(p.Character) end end
    end
end)
makeButton(mainPage,"Team Check: OFF",0.52,42,0.46,nil,function(self)
    S.bigHeadTeamCheck=not S.bigHeadTeamCheck
    self.Text="Team Check: "..(S.bigHeadTeamCheck and "ON" or "OFF")
    setButtonState(self,S.bigHeadTeamCheck)
end)
makeInput(mainPage,"Head size:",0.02,83,0.5,HEAD_SIZE,function(v)
    if v>0 and v<60 then
        HEAD_SIZE=v
        if S.bigHeadEnabled then for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character and not isPlayerDead(p,p.Character) then applyBigHead(p.Character,p) end end end
    end
end)
findHeads=function(char)
    local heads={}
    if not char then return heads end
    local head=char:FindFirstChild("Head") if head and head:IsA("BasePart") then table.insert(heads,head) end
    for _,part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            local n=part.Name:lower()
            if (n=="head" or n:find("head")) and not table.find(heads,part) then table.insert(heads,part) end
        end
    end
    if #heads==0 then
        local best,bestY=nil,-math.huge
        for _,part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Position.Y>bestY and part.Size.Magnitude<10 then bestY=part.Position.Y best=part end
        end
        if best then table.insert(heads,best) end
    end
    return heads
end
applyBigHead=function(char,plr)
    if not S.bigHeadEnabled or not char then return end
    if S.bigHeadTeamCheck and plr and isSameTeam(plr) then return end
    if isPlayerDead(plr,char) then return end
    local size=Vector3.new(HEAD_SIZE,HEAD_SIZE,HEAD_SIZE)
    local cs=S.originalSizes[char] or {} S.originalSizes[char]=cs
    for _,head in ipairs(findHeads(char)) do if not cs[head] then cs[head]=head.Size end head.Size=size head.CanCollide=false head.Massless=true end
end
restoreHead=function(char)
    if not char then return end
    local cs=S.originalSizes[char] if not cs then return end
    for part,sz in pairs(cs) do if part and part.Parent then part.Size=sz end end
    S.originalSizes[char]=nil
end

makeSection(mainPage,"Camera",130)
makeButton(mainPage,"Camera: First Person",0.02,162,0.96,nil,function(self)
    if S.cameraMode==1 then setCameraMode(2) else setCameraMode(1) end
    self.Text="Camera: "..(S.cameraMode==1 and "First Person" or "Third Person")
    setButtonState(self,S.cameraMode==2)
end)
setCameraMode(1)

makeSection(mainPage,"Aimbot",202)
makeButton(mainPage,"Aimbot: OFF",0.02,234,0.46,nil,function(self)
    S.aimEnabled=not S.aimEnabled
    self.Text="Aimbot: "..(S.aimEnabled and "ON" or "OFF")
    setButtonState(self,S.aimEnabled)
end)
makeToggle(mainPage,"Wall Check",0.52,234,function() return S.aimWallCheck end,function(v) S.aimWallCheck=v end)
makeToggle(mainPage,"Team Check",0.02,272,function() return S.aimTeamCheck end,function(v) S.aimTeamCheck=v end)
makeInput(mainPage,"FOV:",0.52,272,0.4,200,function(v) if v>0 then S.aimFov=v end end)
makeButton(mainPage,"Target: Head",0.02,310,0.46,nil,function(self)
    if S.aimPart=="Head" then S.aimPart="Torso"
    elseif S.aimPart=="Torso" then S.aimPart="Nearest"
    else S.aimPart="Head" end
    self.Text="Target: "..S.aimPart
end)

makeSection(mainPage,"Wallhack",352)
makeButton(mainPage,"Wallhack: OFF",0.02,384,0.96,nil,function(self)
    S.wallhackEnabled=not S.wallhackEnabled
    self.Text="Wallhack: "..(S.wallhackEnabled and "ON" or "OFF")
    setButtonState(self,S.wallhackEnabled,UI.warn)
    if S.wallhackEnabled then
        if not myTeamId then notify("Team unknown - cannot track enemies",UI.bad) end
        if deleteMapTemp() then notify("Wallhack: map hidden",UI.warn) S.wallhackState="hidden"
        else notify("Map folder not found",UI.bad) S.wallhackEnabled=false self.Text="Wallhack: OFF" setButtonState(self,false,UI.warn) end
    else restoreMap() S.wallhackState="idle" notify("Wallhack disabled - map restored",UI.textDim) end
end)

makeSection(mainPage,"Notifications",426)
makeButton(mainPage,"Notifications: OFF",0.02,458,0.96,nil,function(self)
    notificationsEnabled=not notificationsEnabled
    self.Text="Notifications: "..(notificationsEnabled and "ON" or "OFF")
    setButtonState(self,notificationsEnabled)
    if notificationsEnabled then task.wait(0.3) notify("Notifications enabled",UI.good) end
end)

S.rawMeta=getrawmetatable and getrawmetatable(game) or nil
if S.rawMeta then
    pcall(function()
        S.oldNamecall=S.rawMeta.__namecall
        setreadonly(S.rawMeta,false)
        S.rawMeta.__namecall=newcclosure(function(self,...)
            if S.unloaded then return S.oldNamecall(self,...) end
            local method=getnamecallmethod()
            if S.wallbangEnabled and (method=="Raycast" or method=="FindPartOnRay" or method=="FindPartOnRayWithIgnoreList") and self==workspace then
                local args={...} local chars={}
                for _,p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(chars,p.Character) end end
                if method=="Raycast" then
                    local np=RaycastParams.new() np.FilterType=Enum.RaycastFilterType.Include np.FilterDescendantsInstances=chars
                    return S.oldNamecall(self,args[1],args[2],np)
                else return S.oldNamecall(self,args[1],chars,true,false) end
            end
            if S.headshotAssistEnabled and method=="Raycast" and self==workspace then
                local args={...}
                local origin=args[1] local direction=args[2] local params=args[3]
                local result=S.oldNamecall(self,origin,direction,params)
                if result and result.Instance then
                    local head=isHeadshotCandidate(result.Instance)
                    if head then
                        local newDir=head.Position-origin local mag=direction.Magnitude
                        if newDir.Magnitude>0.01 then
                            newDir=newDir.Unit*mag
                            local newResult=S.oldNamecall(self,origin,newDir,params)
                            if newResult and newResult.Instance then return newResult end
                        end
                    end
                end
                return result
            end
            return S.oldNamecall(self,...)
        end)
        setreadonly(S.rawMeta,true)
    end)
end

-- VISUALS
local visualsPage=createPage("visuals")
makeSection(visualsPage,"ESP",10)
makeButton(visualsPage,"ESP: OFF",0.02,42,0.46,nil,function(self)
    S.espEnabled=not S.espEnabled
    self.Text="ESP: "..(S.espEnabled and "ON" or "OFF")
    setButtonState(self,S.espEnabled)
end)
makeButton(visualsPage,"C4 ESP: OFF",0.52,42,0.46,nil,function(self)
    S.c4Enabled=not S.c4Enabled
    self.Text="C4 ESP: "..(S.c4Enabled and "ON" or "OFF")
    setButtonState(self,S.c4Enabled,UI.warn)
end)
makeButton(visualsPage,"Skeleton: OFF",0.02,82,0.46,nil,function(self)
    S.skeletonEnabled=not S.skeletonEnabled
    self.Text="Skeleton: "..(S.skeletonEnabled and "ON" or "OFF")
    setButtonState(self,S.skeletonEnabled)
end)
makeToggle(visualsPage,"Tracer",0.52,82,function() return S.showTracer end,function(v) S.showTracer=v end)
makeToggle(visualsPage,"HP Bar",0.02,120,function() return S.showHP end,function(v) S.showHP=v end)
makeToggle(visualsPage,"Name",0.52,120,function() return S.showName end,function(v) S.showName=v end)
makeToggle(visualsPage,"Distance",0.02,158,function() return S.showDist end,function(v) S.showDist=v end)
makeToggle(visualsPage,"Chams",0.52,158,function() return S.showChams end,function(v) S.showChams=v end)
makeToggle(visualsPage,"Hit Bar",0.02,196,function() return S.showHitbar end,function(v) S.showHitbar=v end)
makeToggle(visualsPage,"Dead Cleanup",0.52,196,function() return S.deadCleanup end,function(v) S.deadCleanup=v end)
makeSection(visualsPage,"HUD",238)
makeButton(visualsPage,"HUD Overlay: OFF",0.02,270,0.46,nil,function(self)
    setHudVisible(not hudEnabled)
    self.Text="HUD Overlay: "..(hudEnabled and "ON" or "OFF")
    setButtonState(self,hudEnabled)
end)
makeButton(visualsPage,"Target Info: OFF",0.52,270,0.46,nil,function(self)
    S.tinfoEnabled=not S.tinfoEnabled
    self.Text="Target Info: "..(S.tinfoEnabled and "ON" or "OFF")
    setButtonState(self,S.tinfoEnabled)
    if not S.tinfoEnabled then tinfoCard.Visible=false end
end)
makeSection(visualsPage,"X-Ray",312)
makeButton(visualsPage,"X-Ray: OFF",0.02,344,0.96,nil,function(self)
    S.xrayEnabled=not S.xrayEnabled
    self.Text="X-Ray: "..(S.xrayEnabled and "ON" or "OFF")
    setButtonState(self,S.xrayEnabled)
    if S.xrayEnabled then
        if not enableXray() then notify("Map folder not found",UI.bad) S.xrayEnabled=false self.Text="X-Ray: OFF" setButtonState(self,false) else notify("X-Ray enabled",UI.accent) end
    else disableXray() notify("X-Ray disabled",UI.textDim) end
end)
makeSection(visualsPage,"Sky",386)
makeButton(visualsPage,"Beautiful Sky: OFF",0.02,418,0.96,nil,function(self)
    S.skyEnabled=not S.skyEnabled
    self.Text="Beautiful Sky: "..(S.skyEnabled and "ON" or "OFF")
    setButtonState(self,S.skyEnabled)
    if S.skyEnabled then enableSky() notify("Sky enabled",UI.accent) else disableSky() notify("Sky disabled",UI.textDim) end
end)
makeSection(visualsPage,"Time Control",460)
makeSlider(visualsPage,"Time of day (hours)",0.02,492,0.96,0,24,12,function(v) S.timeSliderValue=v pcall(function() Lighting.ClockTime=v end) end)
makeToggle(visualsPage,"Time Locker",0.02,548,function() return S.timeLockerEnabled end,function(v) S.timeLockerEnabled=v end)
makeSection(visualsPage,"Season",590)
local seasonBtns={}
local seasonNames={"Summer","Autumn","Winter","Spring"}
local function refreshSeasonBtns() highlightButtonSet(seasonBtns, S.seasonState+1) end
for i,name in ipairs(seasonNames) do
    local col=(i-1)%2 local row=math.floor((i-1)/2)
    local b=makeButton(visualsPage,name,0.02+col*0.5,622+row*38,0.46,nil,function()
        setSeason(i-1); refreshSeasonBtns(); notify("Season: "..name,UI.accent)
    end)
    table.insert(seasonBtns,b)
end
refreshSeasonBtns()
makeSection(visualsPage,"Lighting",710)
makeButton(visualsPage,"Fullbright: OFF",0.02,742,0.46,nil,function(self)
    S.fullbrightEnabled=not S.fullbrightEnabled
    self.Text="Fullbright: "..(S.fullbrightEnabled and "ON" or "OFF")
    setButtonState(self,S.fullbrightEnabled,UI.warn)
    if S.fullbrightEnabled then enableFullbright() else disableFullbright() end
end)
makeButton(visualsPage,"No Fog: OFF",0.52,742,0.46,nil,function(self)
    S.noFogEnabled=not S.noFogEnabled
    self.Text="No Fog: "..(S.noFogEnabled and "ON" or "OFF")
    setButtonState(self,S.noFogEnabled,UI.warn)
    if S.noFogEnabled then enableNoFog() else disableNoFog() end
end)
makeButton(visualsPage,"Graphic: OFF",0.02,780,0.96,nil,function(self)
    S.graphicEnabled=not S.graphicEnabled
    self.Text="Graphic: "..(S.graphicEnabled and "ON" or "OFF")
    setButtonState(self,S.graphicEnabled,UI.warn)
    if S.graphicEnabled then enableGraphic() else disableGraphic() end
end)
makeSection(visualsPage,"Performance",820)
makeButton(visualsPage,"FPS Boost: OFF",0.02,852,0.96,nil,function(self)
    S.fpsBoostEnabled=not S.fpsBoostEnabled
    self.Text="FPS Boost: "..(S.fpsBoostEnabled and "ON" or "OFF")
    setButtonState(self,S.fpsBoostEnabled,UI.warn)
    if S.fpsBoostEnabled then enableFpsBoost() else disableFpsBoost() end
end)
makeSection(visualsPage,"Character Model",898)
local morphBtns={}
local function refreshMorphBtns() highlightButtonSet(morphBtns, S.morphState+1) end
for i,m in ipairs(MORPHS) do
    local col=(i-1)%2 local row=math.floor((i-1)/2)
    local b=makeButton(visualsPage,m.name,0.02+col*0.5,930+row*38,0.46,nil,function()
        setMorph(i-1); refreshMorphBtns(); notify("Model: "..m.name,UI.accent)
    end)
    table.insert(morphBtns,b)
end
refreshMorphBtns()

-- SKIN CHANGER
local scPage=createPage("skinchanger")
local soonLabel=Instance.new("TextLabel")
soonLabel.Size=UDim2.new(1,-20,0,80) soonLabel.Position=UDim2.new(0,10,0.4,-40) soonLabel.BackgroundTransparency=1 soonLabel.Text="COMING SOON" soonLabel.TextColor3=UI.yellow soonLabel.TextScaled=true soonLabel.Font=Enum.Font.GothamBold soonLabel.Parent=scPage soonLabel.ZIndex=1002

-- BETA
local betaPage=createPage("beta")
makeSection(betaPage,"Combat",10)
makeButton(betaPage,"No Recoil: OFF",0.02,42,0.46,nil,function(self)
    S.noRecoilEnabled=not S.noRecoilEnabled
    self.Text="No Recoil: "..(S.noRecoilEnabled and "ON" or "OFF")
    setButtonState(self,S.noRecoilEnabled,UI.warn)
    S.lastCamLook=nil
end)
makeButton(betaPage,"Bunny Hop: OFF",0.52,42,0.46,nil,function(self)
    S.bunnyHopEnabled=not S.bunnyHopEnabled
    self.Text="Bunny Hop: "..(S.bunnyHopEnabled and "ON" or "OFF")
    setButtonState(self,S.bunnyHopEnabled,UI.warn)
end)
makeSection(betaPage,"Headshot Assist",82)
makeButton(betaPage,"Headshot Assist: OFF",0.02,114,0.96,nil,function(self)
    S.headshotAssistEnabled=not S.headshotAssistEnabled
    self.Text="Headshot Assist: "..(S.headshotAssistEnabled and "ON" or "OFF")
    setButtonState(self,S.headshotAssistEnabled,UI.warn)
end)
makeSection(betaPage,"Speed Hack",154)
makeButton(betaPage,"Speed: OFF",0.02,186,0.96,nil,function(self)
    S.speedEnabled=not S.speedEnabled
    self.Text="Speed: "..(S.speedEnabled and "ON" or "OFF")
    setButtonState(self,S.speedEnabled)
    if S.speedEnabled and not S.speedThread then S.speedThread=task.spawn(function() speedLoop() S.speedThread=nil end) end
end)
makeInput(betaPage,"Speed value:",0.02,226,0.55,3,function(v) if v>0 then S.speedStep=v end end)
makeSection(betaPage,"Launch",266)
makeButton(betaPage,"Launch: OFF",0.02,298,0.96,nil,function(self)
    S.launchEnabled=not S.launchEnabled
    self.Text="Launch: "..(S.launchEnabled and "ON" or "OFF")
    setButtonState(self,S.launchEnabled)
    if S.launchEnabled then local char=LocalPlayer.Character if char then unanchorChar(char) S.launchBasePos=getCharPos(char) end else S.launchBasePos=nil end
end)
addConn(RunService.Heartbeat:Connect(function()
    if S.unloaded or not S.launchEnabled then return end
    local char=LocalPlayer.Character if not char or not S.launchBasePos then return end
    unanchorChar(char)
    local targetPos=Vector3.new(S.launchBasePos.X,S.launchBasePos.Y+S.launchHeight,S.launchBasePos.Z)
    local curPivot=char:GetPivot()
    moveChar(char,CFrame.new(targetPos)*(curPivot-curPivot.Position))
end))
makeSection(betaPage,"Spin",338)
makeButton(betaPage,"Spin: OFF",0.02,370,0.96,nil,function(self)
    S.spinEnabled=not S.spinEnabled
    self.Text="Spin: "..(S.spinEnabled and "ON" or "OFF")
    setButtonState(self,S.spinEnabled)
end)
makeInput(betaPage,"Deg/sec:",0.02,412,0.55,720,function(v) if v>0 then S.spinSpeed=v end end)
addConn(RunService.Heartbeat:Connect(function(dt)
    if S.unloaded or not S.spinEnabled then return end
    local char=LocalPlayer.Character if not char then return end
    unanchorChar(char)
    local cam=workspace.CurrentCamera
    local sLook,sRight=nil,nil
    if cam then sLook,sRight=cam.CFrame.LookVector,cam.CFrame.RightVector end
    local curPivot=char:GetPivot()
    moveChar(char,curPivot*CFrame.Angles(0,math.rad(S.spinSpeed*dt),0))
    if cam and sLook and sRight then cam.CFrame=CFrame.fromMatrix(cam.CFrame.Position,sRight,Vector3.new(0,1,0),-sLook) end
end))
makeSection(betaPage,"Giant Character",452)
local function applyGiant(char,scale)
    if not char then return end
    local sizes=S.giantOriginal[char]
    if not sizes then sizes={} for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then sizes[part]=part.Size end end S.giantOriginal[char]=sizes end
    for part,origSize in pairs(sizes) do if part and part.Parent then part.Size=origSize*scale end end
end
local function restoreGiant(char)
    local sizes=S.giantOriginal[char] if not sizes then return end
    for part,origSize in pairs(sizes) do if part and part.Parent then part.Size=origSize end end
    S.giantOriginal[char]=nil
end
makeButton(betaPage,"Giant: OFF",0.02,484,0.96,nil,function(self)
    S.giantEnabled=not S.giantEnabled
    self.Text="Giant: "..(S.giantEnabled and "ON" or "OFF")
    setButtonState(self,S.giantEnabled)
    local char=LocalPlayer.Character
    if char then if S.giantEnabled then unanchorChar(char) applyGiant(char,S.giantScale) else restoreGiant(char) end end
end)
makeInput(betaPage,"Giant scale:",0.02,526,0.55,3,function(v) if v>1 and v<=20 then S.giantScale=v end end)
addConn(task.spawn(function()
    while not S.unloaded do
        if S.giantEnabled then local char=LocalPlayer.Character if char then unanchorChar(char) applyGiant(char,S.giantScale) end end
        task.wait(0.5)
    end
end))
makeSection(betaPage,"Tall Character",568)
local function applyTall(char,scaleY)
    if not char then return end
    local sizes=S.tallOriginal[char]
    if not sizes then sizes={} for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then sizes[part]=part.Size end end S.tallOriginal[char]=sizes end
    for part,origSize in pairs(sizes) do if part and part.Parent then part.Size=Vector3.new(origSize.X,origSize.Y*scaleY,origSize.Z) end end
end
local function restoreTall(char)
    local sizes=S.tallOriginal[char] if not sizes then return end
    for part,origSize in pairs(sizes) do if part and part.Parent then part.Size=origSize end end
    S.tallOriginal[char]=nil
end
makeButton(betaPage,"Tall: OFF",0.02,600,0.96,nil,function(self)
    S.tallEnabled=not S.tallEnabled
    self.Text="Tall: "..(S.tallEnabled and "ON" or "OFF")
    setButtonState(self,S.tallEnabled)
    local char=LocalPlayer.Character
    if char then if S.tallEnabled then unanchorChar(char) applyTall(char,S.tallScale) else restoreTall(char) end end
end)
makeInput(betaPage,"Tall scale:",0.02,642,0.55,2,function(v) if v>1 and v<=10 then S.tallScale=v end end)
addConn(task.spawn(function()
    while not S.unloaded do
        if S.tallEnabled then local char=LocalPlayer.Character if char then unanchorChar(char) applyTall(char,S.tallScale) end end
        task.wait(0.5)
    end
end))
makeSection(betaPage,"Teleport Plant Site",684)
makeButton(betaPage,"Teleport plant to me",0.02,716,0.96,nil,function(self)
    local ok,count=teleportPlantSite()
    if ok then self.Text="Moved: "..tostring(count) notify("Plant teleported ("..tostring(count).." parts)",UI.warn) task.wait(1.5) self.Text="Teleport plant to me"
    else self.Text="Not found" task.wait(1.5) self.Text="Teleport plant to me" end
end)
makeSection(betaPage,"Fly",758)
makeToggle(betaPage,"Noclip",0.02,790,function() return S.betaNoclip end,function(v) S.betaNoclip=v end)
makeToggle(betaPage,"Fly",0.52,790,function() return S.betaFly end,function(v) S.betaFly=v end)
addConn(RunService.Stepped:Connect(function()
    if S.unloaded or not S.betaNoclip then return end
    local char=LocalPlayer.Character if not char then return end
    for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide=false end end
end))
addConn(RunService.Heartbeat:Connect(function(dt)
    if S.unloaded or not S.betaFly then return end
    local char=LocalPlayer.Character if not char then return end
    unanchorChar(char)
    local cam=workspace.CurrentCamera if not cam then return end
    local move=Vector3.zero
    local humanoid=char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local md=humanoid.MoveDirection
        if md.Magnitude>0.01 then local flat=Vector3.new(md.X,0,md.Z) if flat.Magnitude>0.01 then move=move+flat.Unit*S.betaSpeedVal end end
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.E) then move=move+Vector3.new(0,S.betaSpeedVal,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then move=move-Vector3.new(0,S.betaSpeedVal,0) end
    local curPivot=char:GetPivot()
    local newPos=curPivot.Position+move*dt
    moveChar(char,CFrame.new(newPos)*(curPivot-curPivot.Position))
end))

-- ADMIN
local adminPage=createPage("admin")
makeSection(adminPage,"Moderation",10)
local targetPlayerBox=Instance.new("TextBox")
targetPlayerBox.Size=UDim2.new(0.6,0,0,30) targetPlayerBox.Position=UDim2.new(0.02,0,0,42) targetPlayerBox.BackgroundColor3=UI.input targetPlayerBox.BorderSizePixel=0 targetPlayerBox.Text="" targetPlayerBox.PlaceholderText="Player name..." targetPlayerBox.TextColor3=UI.text targetPlayerBox.TextSize=12 targetPlayerBox.Font=Enum.Font.Code targetPlayerBox.Parent=adminPage targetPlayerBox.ZIndex=1002 targetPlayerBox.TextXAlignment=Enum.TextXAlignment.Left
addCorner(targetPlayerBox,4) addStroke(targetPlayerBox,UI.border,1)
local boxPad=Instance.new("UIPadding") boxPad.PaddingLeft=UDim.new(0,10) boxPad.Parent=targetPlayerBox
targetPlayerBox.FocusLost:Connect(function() S.targetPlayerName=targetPlayerBox.Text end)
makeButton(adminPage,"Teleport to player",0.02,82,0.46,nil,function()
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(S.targetPlayerName:lower()) and p~=LocalPlayer then
            local char=p.Character if char then
                local myChar=LocalPlayer.Character
                if myChar then local tPos=getCharPos(char) local myPivot=myChar:GetPivot() moveChar(myChar,CFrame.new(tPos+Vector3.new(5,3,0))*(myPivot-myPivot.Position)) end
            end
            return
        end
    end
end)
makeButton(adminPage,"Spectate player",0.52,82,0.46,nil,function()
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(S.targetPlayerName:lower()) and p~=LocalPlayer then
            local char=p.Character if char then local h=char:FindFirstChildOfClass("Humanoid") if h then workspace.CurrentCamera.CameraSubject=h end end
            return
        end
    end
end)
makeButton(adminPage,"Restore camera",0.02,122,0.96,nil,function()
    local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if h then workspace.CurrentCamera.CameraSubject=h end
end)

-- ADMIN PANEL
local adminPanelPage=createPage("adminpanel")
makeSection(adminPanelPage,"Command Line",10)
local cmdLog=Instance.new("ScrollingFrame")
cmdLog.Size=UDim2.new(0.96,0,0,280) cmdLog.Position=UDim2.new(0.02,0,0,45) cmdLog.BackgroundColor3=UI.bg cmdLog.BorderSizePixel=0 cmdLog.ScrollBarThickness=5 cmdLog.ScrollBarImageColor3=UI.borderHi cmdLog.CanvasSize=UDim2.new(0,0,0,0) cmdLog.AutomaticCanvasSize=Enum.AutomaticSize.Y cmdLog.ScrollingDirection=Enum.ScrollingDirection.Y cmdLog.ClipsDescendants=true cmdLog.Parent=adminPanelPage cmdLog.ZIndex=1005
addCorner(cmdLog,4) addStroke(cmdLog,UI.border,1)
local logLayout=Instance.new("UIListLayout") logLayout.Padding=UDim.new(0,4) logLayout.SortOrder=Enum.SortOrder.LayoutOrder logLayout.Parent=cmdLog
local logPadding=Instance.new("UIPadding") logPadding.PaddingTop=UDim.new(0,6) logPadding.PaddingLeft=UDim.new(0,8) logPadding.PaddingRight=UDim.new(0,8) logPadding.Parent=cmdLog
local cmdInput=Instance.new("TextBox")
cmdInput.Size=UDim2.new(0.96,0,0,34) cmdInput.Position=UDim2.new(0.02,0,0,340) cmdInput.BackgroundColor3=UI.input cmdInput.BorderSizePixel=0 cmdInput.Text="" cmdInput.PlaceholderText="Enter command" cmdInput.TextColor3=UI.text cmdInput.TextSize=12 cmdInput.Font=Enum.Font.Code cmdInput.Parent=adminPanelPage cmdInput.ZIndex=1005 cmdInput.TextXAlignment=Enum.TextXAlignment.Left
addCorner(cmdInput,4) addStroke(cmdInput,UI.border,1)
local ciPad=Instance.new("UIPadding") ciPad.PaddingLeft=UDim.new(0,10) ciPad.Parent=cmdInput
local sendBtn=Instance.new("TextButton")
sendBtn.Size=UDim2.new(0.96,0,0,34) sendBtn.Position=UDim2.new(0.02,0,0,386) sendBtn.BackgroundColor3=UI.panel2 sendBtn.BorderSizePixel=0 sendBtn.Text="Execute" sendBtn.TextColor3=UI.accent sendBtn.TextSize=12 sendBtn.Font=Enum.Font.GothamBold sendBtn.Parent=adminPanelPage sendBtn.ZIndex=1005
addCorner(sendBtn,4) addStroke(sendBtn,UI.accent,1.5)
local lineCounter=0
local function logLine(text,color)
    lineCounter=lineCounter+1
    local lbl=Instance.new("TextLabel") lbl.Size=UDim2.new(1,0,0,20) lbl.BackgroundTransparency=1 lbl.Text=text lbl.TextColor3=color or UI.text lbl.TextSize=12 lbl.Font=Enum.Font.Code lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.LayoutOrder=lineCounter lbl.ZIndex=1006 lbl.Parent=cmdLog
end
logLine("API connected. Type /help.",UI.textDim)
local function apiAdmin(action,target,reason,extra)
    local res=httpPost(API_URL.."/admin/action",{secret=API_SECRET,admin_hwid=currentHWID,action=action,target=target,reason=reason or "",extra=extra or ""})
    if not res then return nil end
    local ok,data=pcall(function() return HttpService:JSONDecode(res) end)
    if ok then return data end
    return nil
end
local function processCommand(cmdLine)
    if not cmdLine or cmdLine=="" then return end
    logLine("> "..cmdLine,UI.accent)
    local args={} for word in cmdLine:gmatch("%S+") do table.insert(args,word) end
    local cmd=args[1] if not cmd then return end
    if cmd=="/help" then logLine("/help - list",UI.textDim) logLine("/resethwid /resetkey /resetrank",UI.textDim) logLine("/setrank /ban /unban /admlist",UI.textDim) logLine("/freeze /unfreeze /kick",UI.textDim) logLine("/setcheck /unsetcheck",UI.textDim)
    elseif cmd=="/resethwid" then local r=apiAdmin("resethwid",args[2],args[3]) if r and r.status=="ok" then logLine("New HWID: "..(r.new_hwid or "?"),UI.good) else logLine(tostring((r and r.status) or "network error"),UI.bad) end
    elseif cmd=="/resetkey" then local r=apiAdmin("resetkey",args[2],args[3]) if r and r.status=="ok" then logLine("Key reset",UI.good) else logLine(tostring((r and r.status) or "network error"),UI.bad) end
    elseif cmd=="/resetrank" then local r=apiAdmin("resetrank",args[2],args[3]) if r and r.status=="ok" then logLine("Rank reset",UI.good) else logLine(tostring((r and r.status) or "network error"),UI.bad) end
    elseif cmd=="/setrank" then local r=apiAdmin("setrank",args[2],args[4],args[3]) if r and r.status=="ok" then logLine("Rank set: "..(args[3] or "?"),UI.good) else logLine(tostring((r and r.status) or "network error"),UI.bad) end
    elseif cmd=="/ban" then local r=apiAdmin("ban",args[2],args[3],args[4]) if r and r.status=="ok" then logLine("Banned",UI.bad) else logLine(tostring((r and r.status) or "network error"),UI.bad) end
    elseif cmd=="/unban" then local r=apiAdmin("unban",args[2],args[3]) if r and r.status=="ok" then logLine("Unbanned",UI.good) else logLine(tostring((r and r.status) or "network error"),UI.bad) end
    elseif cmd=="/freeze" then local r=apiAdmin("freeze",args[2],args[3],args[4]) if r and r.status=="ok" then logLine("Frozen",UI.freeze) else logLine(tostring((r and r.status) or "network error"),UI.bad) end
    elseif cmd=="/unfreeze" then local r=apiAdmin("unfreeze",args[2],args[3]) if r and r.status=="ok" then logLine("Unfrozen",UI.good) else logLine(tostring((r and r.status) or "network error"),UI.bad) end
    elseif cmd=="/kick" then local r=apiAdmin("kick",args[2],args[3]) if r and r.status=="ok" then logLine("Kick queued",UI.warn) else logLine(tostring((r and r.status) or "network error"),UI.bad) end
    elseif cmd=="/setcheck" then local r=apiAdmin("setcheck",args[2],args[3]) if r and r.status=="ok" then logLine("Check status ON",UI.warn) else logLine(tostring((r and r.status) or "network error"),UI.bad) end
    elseif cmd=="/unsetcheck" then local r=apiAdmin("unsetcheck",args[2],args[3]) if r and r.status=="ok" then logLine("Check status OFF",UI.good) else logLine(tostring((r and r.status) or "network error"),UI.bad) end
    elseif cmd=="/admlist" then local r=apiAdmin("admlist","x","x") if r and r.status=="ok" and r.list then for _,row in ipairs(r.list) do logLine("- "..(row.nickname or "?").." | "..(row.hwid or "?").." | "..(row.rank or "?"),UI.textDim) end else logLine("Error",UI.bad) end
    else logLine("Unknown command. /help",UI.bad) end
end
sendBtn.MouseButton1Click:Connect(function() processCommand(cmdInput.Text) cmdInput.Text="" end)
cmdInput.FocusLost:Connect(function(e) if e then processCommand(cmdInput.Text) cmdInput.Text="" end end)

-- SETTINGS
local settingsPage=createPage("settings")
makeSection(settingsPage,"Information (click to copy)",10)
local function clickableInfoRow(parent_,label,value,yPos,valColor,copyValue)
    local l=Instance.new("TextLabel") l.Size=UDim2.new(0.4,0,0,30) l.Position=UDim2.new(0.02,0,0,yPos) l.BackgroundTransparency=1 l.Text=label l.TextColor3=UI.textDim l.TextSize=12 l.Font=Enum.Font.GothamBold l.TextXAlignment=Enum.TextXAlignment.Left l.Parent=parent_ l.ZIndex=1002
    local v=Instance.new("TextButton") v.Size=UDim2.new(0.5,0,0,30) v.Position=UDim2.new(0.44,0,0,yPos) v.BackgroundColor3=UI.input v.BorderSizePixel=0 v.Text=value v.TextColor3=valColor or UI.text v.TextSize=12 v.Font=Enum.Font.Code v.TextXAlignment=Enum.TextXAlignment.Left v.AutoButtonColor=true v.Parent=parent_ v.ZIndex=1002
    addCorner(v,4) addStroke(v,UI.border,1)
    local vp=Instance.new("UIPadding") vp.PaddingLeft=UDim.new(0,10) vp.Parent=v
    local originalText=value
    local originalColor=valColor or UI.text
    v.MouseButton1Click:Connect(function()
        local ok=copyToClipboard(tostring(copyValue or value))
        if ok then
            v.Text="Copied!"
            v.TextColor3=UI.good
            task.wait(0.8)
            v.Text=originalText
            v.TextColor3=originalColor
        else
            v.Text="Copy failed"
            v.TextColor3=UI.bad
            task.wait(0.8)
            v.Text=originalText
            v.TextColor3=originalColor
        end
    end)
    return v
end
clickableInfoRow(settingsPage,"Nickname",LocalPlayer.Name,42,UI.text,LocalPlayer.Name)
clickableInfoRow(settingsPage,"HWID",currentHWID,78,UI.accent,currentHWID)
clickableInfoRow(settingsPage,"Rank",string.upper(currentRank),114,(RANKS[currentRank] or RANKS.player).color,currentRank)
clickableInfoRow(settingsPage,"Key",currentKey or "not activated",150,UI.textDim,currentKey or "")

-- ACCOUNT STATUS
makeSection(settingsPage,"Account Status",195)
local statusCard=Instance.new("Frame")
statusCard.Size=UDim2.new(0.96,0,0,90) statusCard.Position=UDim2.new(0.02,0,0,228)
statusCard.BackgroundColor3=UI.input
statusCard.BorderSizePixel=0
statusCard.Parent=settingsPage
statusCard.ZIndex=1002
addCorner(statusCard,6) addStroke(statusCard,UI.border,1)

local statusIcon=Instance.new("TextLabel")
statusIcon.Size=UDim2.new(0,50,1,0) statusIcon.Position=UDim2.new(0,6,0,0)
statusIcon.BackgroundTransparency=1
statusIcon.Text="🟢"
statusIcon.TextSize=34
statusIcon.Font=Enum.Font.GothamBold
statusIcon.TextXAlignment=Enum.TextXAlignment.Center
statusIcon.TextYAlignment=Enum.TextYAlignment.Center
statusIcon.Parent=statusCard
statusIcon.ZIndex=1003

local statusTitle=Instance.new("TextLabel")
statusTitle.Size=UDim2.new(1,-70,0,22) statusTitle.Position=UDim2.new(0,62,0,12)
statusTitle.BackgroundTransparency=1
statusTitle.Text="Всё в порядке"
statusTitle.TextColor3=UI.good
statusTitle.TextSize=14
statusTitle.Font=Enum.Font.GothamBold
statusTitle.TextXAlignment=Enum.TextXAlignment.Left
statusTitle.Parent=statusCard
statusTitle.ZIndex=1003

local statusDetails=Instance.new("TextLabel")
statusDetails.Size=UDim2.new(1,-70,0,46) statusDetails.Position=UDim2.new(0,62,0,36)
statusDetails.BackgroundTransparency=1
statusDetails.Text="Аккаунт в норме."
statusDetails.TextColor3=UI.textDim
statusDetails.TextSize=11
statusDetails.Font=Enum.Font.Gotham
statusDetails.TextXAlignment=Enum.TextXAlignment.Left
statusDetails.TextYAlignment=Enum.TextYAlignment.Top
statusDetails.TextWrapped=true
statusDetails.Parent=statusCard
statusDetails.ZIndex=1003

updateStatusCard=function()
    local st=S.accountStatus or {}
    local lastPoll=st.lastPoll and ("Обновлено: "..st.lastPoll) or "Ещё не проверялось"
    if not st.checked then
        statusIcon.Text="⚪"
        statusTitle.Text="Проверка..."
        statusTitle.TextColor3=UI.textDim
        statusDetails.Text="Ожидание ответа от сервера...\n"..lastPoll
        return
    end
    local state=st.state
    if state=="banned" or st.banned then
        statusIcon.Text="🔴"
        statusTitle.Text="Аккаунт заблокирован"
        statusTitle.TextColor3=UI.bad
        statusDetails.Text="Причина: "..(st.ban_reason or "—").."\nРазблокировка: "..(st.ban_expires_str or "навсегда")
    elseif state=="frozen" or st.frozen then
        statusIcon.Text="❄️"
        statusTitle.Text="Аккаунт заморожен"
        statusTitle.TextColor3=UI.freeze
        local fzTxt=st.frozen_to_str or "не указано"
        statusDetails.Text="Причина: "..(st.frozen_reason or "—").."\nРазморозка: "..fzTxt
    elseif state=="check" or st.check_status then
        statusIcon.Text="🟠"
        statusTitle.Text="На проверке"
        statusTitle.TextColor3=UI.warn
        statusDetails.Text="Усиленное внимание администрации.\n"..lastPoll
    elseif state=="unknown" then
        statusIcon.Text="⚪"
        statusTitle.Text="Не зарегистрирован"
        statusTitle.TextColor3=UI.textDim
        statusDetails.Text=tostring(st.details or "—").."\n"..lastPoll
    elseif state=="error" then
        statusIcon.Text="🔴"
        statusTitle.Text="Ошибка проверки"
        statusTitle.TextColor3=UI.bad
        statusDetails.Text=tostring(st.details or "—").."\n"..lastPoll
    else
        statusIcon.Text="🟢"
        statusTitle.Text="Всё в порядке"
        statusTitle.TextColor3=UI.good
        statusDetails.Text="Аккаунт в норме.\n"..lastPoll
    end
end
updateStatusCard()

makeButton(settingsPage,"Force check status",0.02,362,0.46,nil,function(self)
    self.Text="Checking..."
    task.spawn(function()
        local res=httpPost(API_URL.."/poll",{secret=API_SECRET,hwid=currentHWID})
        if not res then setStatusState("error","Нет ответа от сервера")
        else
            local ok2,data=pcall(function() return HttpService:JSONDecode(res) end)
            if not ok2 or type(data)~="table" then setStatusState("error","Некорректный ответ")
            elseif data.status=="unknown" then setStatusState("unknown","Игрок не найден в БД")
            elseif data.status=="ok" then applyAccountStatus(data) updateStatusCard()
            else setStatusState("error","Сервер: "..tostring(data.status)) end
        end
        self.Text="Force check status"
    end)
end)

makeSection(settingsPage,"Server",410)
makeButton(settingsPage,"Refresh from server",0.02,442,0.96,nil,function(self)
    self.Text="Refreshing..."
    registerOnServer()
    localData.rank=currentRank saveLocal(localData)
    updateRankDisplay()
    for _,btn in pairs(tabButtons) do if btn and btn.Parent then btn:Destroy() end end
    tabButtons={} tabCounter=0
    createTabButton("main","Main",UI.text)
    createTabButton("visuals","Visuals",UI.accent)
    createTabButton("skinchanger","Skin Changer",UI.yellow)
    if hasAccess("beta") then createTabButton("beta","Beta",Color3.fromRGB(200,140,255)) end
    if hasAccess("admin") then createTabButton("admin","Admin",UI.warn) end
    if hasAccess("adminpanel") then createTabButton("adminpanel","Admin Panel",UI.bad) end
    createTabButton("configs","Configs",UI.good)
    createTabButton("feedback","Feedback",UI.accent)
    createTabButton("settings","Settings",UI.accent)
    switchTab("main")
    self.Text="Done" task.wait(1.2) self.Text="Refresh from server"
end)

-- FEEDBACK PAGE
local feedbackPage=createPage("feedback")
makeSection(feedbackPage,"Обратная связь / Feedback",10)
local fbIntro=Instance.new("TextLabel")
fbIntro.Size=UDim2.new(0.96,0,0,60) fbIntro.Position=UDim2.new(0.02,0,0,42)
fbIntro.BackgroundTransparency=1
fbIntro.Text="Здесь вы можете оставить обратную связь:\n• оспорить наказание\n• сообщить о баге\n• предложить идею\n\nВсе сообщения будут отправлены администрации."
fbIntro.TextColor3=UI.textDim
fbIntro.TextSize=12
fbIntro.Font=Enum.Font.Gotham
fbIntro.TextXAlignment=Enum.TextXAlignment.Left
fbIntro.TextYAlignment=Enum.TextYAlignment.Top
fbIntro.TextWrapped=true
fbIntro.Parent=feedbackPage
fbIntro.ZIndex=1002

local fbInput=Instance.new("TextBox")
fbInput.Size=UDim2.new(0.96,0,0,140) fbInput.Position=UDim2.new(0.02,0,0,110)
fbInput.BackgroundColor3=UI.input
fbInput.BorderSizePixel=0
fbInput.Text=""
fbInput.PlaceholderText="Напишите ваше сообщение здесь..."
fbInput.TextColor3=UI.text
fbInput.TextSize=12
fbInput.Font=Enum.Font.Gotham
fbInput.TextXAlignment=Enum.TextXAlignment.Left
fbInput.TextYAlignment=Enum.TextYAlignment.Top
fbInput.TextWrapped=true
fbInput.ClearTextOnFocus=false
fbInput.MultiLine=true
fbInput.Parent=feedbackPage
fbInput.ZIndex=1002
addCorner(fbInput,6)
addStroke(fbInput,UI.border,1)
local fbPad=Instance.new("UIPadding")
fbPad.PaddingLeft=UDim.new(0,10) fbPad.PaddingTop=UDim.new(0,8) fbPad.PaddingRight=UDim.new(0,10)
fbPad.Parent=fbInput

local fbSendBtn=Instance.new("TextButton")
fbSendBtn.Size=UDim2.new(0,140,0,44) fbSendBtn.Position=UDim2.new(1,-150,0,262)
fbSendBtn.BackgroundColor3=UI.good
fbSendBtn.BorderSizePixel=0
fbSendBtn.Text="✈ Send"
fbSendBtn.TextColor3=Color3.fromRGB(255,255,255)
fbSendBtn.TextSize=15
fbSendBtn.Font=Enum.Font.GothamBold
fbSendBtn.Parent=feedbackPage
fbSendBtn.ZIndex=1002
addCorner(fbSendBtn,6)
addStroke(fbSendBtn,UI.good,1)

local fbStatus=Instance.new("TextLabel")
fbStatus.Size=UDim2.new(1,-170,0,44) fbStatus.Position=UDim2.new(0.02,0,0,262)
fbStatus.BackgroundTransparency=1
fbStatus.Text=""
fbStatus.TextColor3=UI.textDim
fbStatus.TextSize=12
fbStatus.Font=Enum.Font.Gotham
fbStatus.TextXAlignment=Enum.TextXAlignment.Left
fbStatus.TextYAlignment=Enum.TextYAlignment.Center
fbStatus.TextWrapped=true
fbStatus.Parent=feedbackPage
fbStatus.ZIndex=1002

local fbSending=false
local fbWatchdogId=0
local fbSentNoticeUntil=0

local function formatCooldown(sec)
    sec=math.max(0,math.floor(sec))
    local h=math.floor(sec/3600)
    local m=math.floor((sec%3600)/60)
    local s=sec%60
    if h>0 then
        return string.format("%d:%02d:%02d", h, m, s)
    else
        return string.format("%d:%02d", m, s)
    end
end

updateFeedbackStatus=function()
    if tick()<fbSentNoticeUntil then return end
    if not S.feedbackCooldown or S.feedbackCooldown <= 0 then
        if fbStatus.Text~="" then fbStatus.Text="" end
        return
    end
    fbStatus.Text="Cooldown: "..formatCooldown(S.feedbackCooldown)
    fbStatus.TextColor3=UI.warn
end

local function fbResetButton()
    fbSending=false
    fbSendBtn.Text="✈ Send"
    fbSendBtn.BackgroundColor3=UI.good
end

fbSendBtn.MouseButton1Click:Connect(function()
    if fbSending then return end
    if S.feedbackCooldown and S.feedbackCooldown>0 then
        fbSentNoticeUntil=0
        updateFeedbackStatus()
        return
    end
    local msg=fbInput.Text:gsub("^%s+",""):gsub("%s+$","")
    if msg=="" then
        fbStatus.Text="Напишите сообщение перед отправкой"
        fbStatus.TextColor3=UI.bad
        return
    end

    fbSending=true
    fbWatchdogId=fbWatchdogId+1
    local myWatchdog=fbWatchdogId

    fbSendBtn.Text="..."
    fbSendBtn.BackgroundColor3=UI.panel2
    fbStatus.Text="Отправка..."
    fbStatus.TextColor3=UI.warn

    task.delay(25,function()
        if myWatchdog==fbWatchdogId and fbSending then
            fbStatus.Text="Превышено время ожидания. Попробуйте снова."
            fbStatus.TextColor3=UI.bad
            fbResetButton()
        end
    end)

    task.spawn(function()
        local okRun,errRun=pcall(function()
            local res,errCode=httpPost(API_URL.."/feedback/submit",{
                secret=API_SECRET,
                hwid=currentHWID,
                nickname=LocalPlayer.Name,
                rank=currentRank,
                message=msg
            })

            if not res then
                fbStatus.Text="Network error ("..tostring(errCode or "no response")..")"
                fbStatus.TextColor3=UI.bad
                return
            end

            local okDec,data=pcall(function() return HttpService:JSONDecode(res) end)
            if not okDec or type(data)~="table" then
                fbStatus.Text="Response error (неверный формат)"
                fbStatus.TextColor3=UI.bad
                return
            end

            local status=tostring(data.status or "unknown")

            if status=="ok" then
                fbStatus.Text="✓ Отправлено! Спасибо за фидбек."
                fbStatus.TextColor3=UI.good
                fbInput.Text=""
                S.feedbackCooldown=3600
                fbSentNoticeUntil=tick()+3
            elseif status=="cooldown" then
                local w=tonumber(data.wait) or 3600
                S.feedbackCooldown=math.min(w,3600)
                fbSentNoticeUntil=0
                updateFeedbackStatus()
            elseif status=="muted" then
                fbStatus.Text="Вам запрещено отправлять фидбек до "..tostring(data["until"] or "?")
                fbStatus.TextColor3=UI.bad
            elseif status=="unknown" then
                fbStatus.Text="Игрок не найден"
                fbStatus.TextColor3=UI.bad
            else
                fbStatus.Text="Сервер: "..status
                fbStatus.TextColor3=UI.bad
            end
        end)

        if not okRun then
            fbStatus.Text="Ошибка: "..tostring(errRun)
            fbStatus.TextColor3=UI.bad
        end

        if myWatchdog==fbWatchdogId and fbSending then
            fbResetButton()
        end
    end)
end)

task.spawn(function()
    while not S.unloaded do
        task.wait(1)
        if S.feedbackCooldown and S.feedbackCooldown > 0 then
            S.feedbackCooldown = math.max(0, S.feedbackCooldown - 1)
            updateFeedbackStatus()
        end
    end
end)

-- CONFIGS
local configsPage=createPage("configs")
makeSection(configsPage,"Config Manager",10)
local configNameBox=Instance.new("TextBox")
configNameBox.Size=UDim2.new(0.96,0,0,32) configNameBox.Position=UDim2.new(0.02,0,0,42) configNameBox.BackgroundColor3=UI.input configNameBox.BorderSizePixel=0 configNameBox.Text="" configNameBox.PlaceholderText="Config name..." configNameBox.TextColor3=UI.text configNameBox.TextSize=12 configNameBox.Font=Enum.Font.Code configNameBox.Parent=configsPage configNameBox.ZIndex=1002 configNameBox.TextXAlignment=Enum.TextXAlignment.Left
addCorner(configNameBox,4) addStroke(configNameBox,UI.border,1)
local cnbPad=Instance.new("UIPadding") cnbPad.PaddingLeft=UDim.new(0,10) cnbPad.Parent=configNameBox
makeButton(configsPage,"Create Config",0.02,84,0.46,nil,function(self)
    local name=configNameBox.Text:gsub("^%s+",""):gsub("%s+$","")
    if name=="" then self.Text="Enter name first!" setButtonState(self,false,UI.bad) task.wait(1.5) self.Text="Create Config" setButtonState(self,false) return end
    if not writefile then self.Text="File API not available" setButtonState(self,false,UI.bad) task.wait(1.5) self.Text="Create Config" setButtonState(self,false) return end
    local data={}
    for _,k in ipairs(CONFIG_KEYS) do data[k]=S[k] end
    local path=FOLDER_CONFIGS.."/"..name..".json"
    local ok=pcall(function() writefile(path,HttpService:JSONEncode(data)) end)
    if ok then self.Text="Created: "..name setButtonState(self,true,UI.good) notify("Config created: "..name,UI.good) task.wait(1.5) self.Text="Create Config" setButtonState(self,false)
    if _G._wc_refresh_config_list then _G._wc_refresh_config_list() end
    else self.Text="Write failed" setButtonState(self,false,UI.bad) task.wait(1.5) self.Text="Create Config" setButtonState(self,false) end
end)
makeButton(configsPage,"Load Config",0.52,84,0.46,nil,function(self)
    local name=configNameBox.Text:gsub("^%s+",""):gsub("%s+$","")
    if name=="" then self.Text="Enter name first!" setButtonState(self,false,UI.bad) task.wait(1.5) self.Text="Load Config" setButtonState(self,false) return end
    if not readfile then self.Text="File API not available" setButtonState(self,false,UI.bad) task.wait(1.5) self.Text="Load Config" setButtonState(self,false) return end
    local path=FOLDER_CONFIGS.."/"..name..".json"
    local ok,raw=pcall(function() return readfile(path) end)
    if not ok or not raw then self.Text="Not found" setButtonState(self,false,UI.bad) task.wait(1.5) self.Text="Load Config" setButtonState(self,false) return end
    local ok2,data=pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(data)~="table" then self.Text="Corrupted" setButtonState(self,false,UI.bad) task.wait(1.5) self.Text="Load Config" setButtonState(self,false) return end
    for _,k in ipairs(CONFIG_KEYS) do if data[k]~=nil then S[k]=data[k] end end
    if S.fullbrightEnabled then enableFullbright() else disableFullbright() end
    if S.noFogEnabled then enableNoFog() else disableNoFog() end
    if S.graphicEnabled then enableGraphic() else disableGraphic() end
    if S.fpsBoostEnabled then enableFpsBoost() else disableFpsBoost() end
    if S.skyEnabled then enableSky() else disableSky() end
    if S.xrayEnabled then enableXray() else disableXray() end
    setSeason(S.seasonState or 0) refreshSeasonBtns()
    setCameraMode(S.cameraMode or 1)
    setMorph(S.morphState or 0) refreshMorphBtns()
    setHudVisible(S.hudEnabled and true or false)
    if S.timeSliderValue then pcall(function() Lighting.ClockTime=S.timeSliderValue end) end
    if not S.wallhackEnabled then restoreMap() end
    notificationsEnabled=S.notificationsEnabled and true or false
    self.Text="Loaded!" setButtonState(self,true,UI.good) notify("Config loaded: "..name,UI.good)
    task.wait(1.5) self.Text="Load Config" setButtonState(self,false)
end)
makeButton(configsPage,"Delete Config",0.02,124,0.46,nil,function(self)
    local name=configNameBox.Text:gsub("^%s+",""):gsub("%s+$","")
    if name=="" then self.Text="Enter name first!" setButtonState(self,false,UI.bad) task.wait(1.5) self.Text="Delete Config" setButtonState(self,false) return end
    if not delfile then self.Text="File API not available" setButtonState(self,false,UI.bad) task.wait(1.5) self.Text="Delete Config" setButtonState(self,false) return end
    local path=FOLDER_CONFIGS.."/"..name..".json"
    local ok=pcall(function() delfile(path) end)
    if ok then self.Text="Deleted: "..name setButtonState(self,true,UI.bad) notify("Config deleted: "..name,UI.bad) task.wait(1.5) self.Text="Delete Config" setButtonState(self,false)
    if _G._wc_refresh_config_list then _G._wc_refresh_config_list() end
    else self.Text="Delete failed" setButtonState(self,false,UI.bad) task.wait(1.5) self.Text="Delete Config" setButtonState(self,false) end
end)
makeButton(configsPage,"Auto-load: OFF",0.52,124,0.46,nil,function(self)
    if _G._wc_autoload then
        _G._wc_autoload=false
        pcall(function() if delfile and isfile and isfile(AUTOLOAD_FILE) then delfile(AUTOLOAD_FILE) end end)
        self.Text="Auto-load: OFF" setButtonState(self,false) notify("Auto-load disabled",UI.textDim)
    else
        local name=configNameBox.Text:gsub("^%s+",""):gsub("%s+$","")
        if name=="" then self.Text="Enter name first!" setButtonState(self,false,UI.bad) task.wait(1.5) self.Text="Auto-load: OFF" setButtonState(self,false) return end
        if not writefile then self.Text="File API not available" setButtonState(self,false,UI.bad) task.wait(1.5) self.Text="Auto-load: OFF" setButtonState(self,false) return end
        local ok=pcall(function() writefile(AUTOLOAD_FILE,name) end)
        if ok then _G._wc_autoload=true self.Text="Auto-load: "..name setButtonState(self,true,UI.good) notify("Auto-load enabled: "..name,UI.good)
        else self.Text="Write failed" setButtonState(self,false,UI.bad) task.wait(1.5) self.Text="Auto-load: OFF" setButtonState(self,false) end
    end
end)
makeSection(configsPage,"Available Configs",170)
local configListFrame=Instance.new("Frame")
configListFrame.Size=UDim2.new(0.96,0,0,220) configListFrame.Position=UDim2.new(0.02,0,0,202) configListFrame.BackgroundColor3=UI.bg configListFrame.BorderSizePixel=0 configListFrame.Parent=configsPage configListFrame.ZIndex=1002
addCorner(configListFrame,4) addStroke(configListFrame,UI.border,1)
local clfScroll=Instance.new("ScrollingFrame")
clfScroll.Size=UDim2.new(1,-8,1,-8) clfScroll.Position=UDim2.new(0,4,0,4) clfScroll.BackgroundTransparency=1 clfScroll.BorderSizePixel=0 clfScroll.ScrollBarThickness=4 clfScroll.ScrollBarImageColor3=UI.borderHi clfScroll.CanvasSize=UDim2.new(0,0,0,0) clfScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y clfScroll.Parent=configListFrame clfScroll.ZIndex=1003
local clfLayout=Instance.new("UIListLayout") clfLayout.Padding=UDim.new(0,4) clfLayout.SortOrder=Enum.SortOrder.LayoutOrder clfLayout.Parent=clfScroll
local clfEmpty=Instance.new("TextLabel")
clfEmpty.Size=UDim2.new(1,0,0,40) clfEmpty.BackgroundTransparency=1 clfEmpty.Text="No configs yet." clfEmpty.TextColor3=UI.textMute clfEmpty.TextSize=12 clfEmpty.Font=Enum.Font.Gotham clfEmpty.Parent=clfScroll clfEmpty.ZIndex=1004
_G._wc_refresh_config_list=function()
    for _,ch in ipairs(clfScroll:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
    if not listfiles then clfEmpty.Visible=true clfEmpty.Text="listfiles not available" return end
    local ok,files=pcall(function() return listfiles(FOLDER_CONFIGS) end)
    if not ok or not files then clfEmpty.Visible=true clfEmpty.Text="Cannot read configs folder" return end
    local any=false
    for _,fpath in ipairs(files) do
        local fname=fpath:match("([^/\\]+)%.json$")
        if fname and fname~="_autoload" then
            any=true
            local btn=Instance.new("TextButton")
            btn.Size=UDim2.new(1,-8,0,28) btn.BackgroundColor3=UI.panel2 btn.BorderSizePixel=0 btn.Text=fname btn.TextColor3=UI.text btn.TextSize=12 btn.Font=Enum.Font.Code btn.TextXAlignment=Enum.TextXAlignment.Left btn.Parent=clfScroll btn.ZIndex=1004
            addCorner(btn,4) addStroke(btn,UI.border,1)
            local p=Instance.new("UIPadding") p.PaddingLeft=UDim.new(0,10) p.Parent=btn
            btn.MouseButton1Click:Connect(function() configNameBox.Text=fname end)
        end
    end
    clfEmpty.Visible=not any clfEmpty.Text="No configs yet."
end
task.spawn(function() task.wait(0.2) if _G._wc_refresh_config_list then _G._wc_refresh_config_list() end end)
makeButton(configsPage,"Refresh List",0.02,440,0.96,nil,function(self)
    if _G._wc_refresh_config_list then _G._wc_refresh_config_list() end
    self.Text="Refreshed" task.wait(1) self.Text="Refresh List"
end)

-- LOOPS
addConn(RunService.Stepped:Connect(function()
    if S.unloaded or not S.noclipEnabled then return end
    local char=LocalPlayer.Character
    if char then for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide=false end end end
end))
addConn(UserInputService.InputBegan:Connect(function(input,gp)
    if S.unloaded or gp then return end
    if input.UserInputType==S.aimHoldKey then S.aimHolding=true end
end))
addConn(UserInputService.InputEnded:Connect(function(input,gp)
    if S.unloaded or gp then return end
    if input.UserInputType==S.aimHoldKey then S.aimHolding=false end
end))
local function getAimTarget()
    local cam=workspace.CurrentCamera if not cam then return nil end
    local best,bestDist=nil,math.huge
    local camPos=cam.CFrame.Position
    local mousePos=UserInputService:GetMouseLocation()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LocalPlayer then
            local char=plr.Character
            if char and not isPlayerDead(plr,char) then
                local humanoid=char:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health>0 then
                    if not (S.aimTeamCheck and isSameTeam(plr)) then
                        local targetPart
                        if S.aimPart=="Head" then targetPart=findBodyPart(char,{"Head"})
                        elseif S.aimPart=="Torso" then targetPart=findBodyPart(char,{"UpperTorso","Torso","Chest","Trunk"})
                        else targetPart=findBodyPart(char,{"Head","UpperTorso","Torso"}) end
                        if targetPart then
                            local sp=cam:WorldToViewportPoint(targetPart.Position)
                            if sp.Z>0 then
                                local dx,dy=sp.X-mousePos.X,sp.Y-mousePos.Y
                                local dist=math.sqrt(dx*dx+dy*dy)
                                if dist<S.aimFov and dist<bestDist then
                                    if S.aimWallCheck then
                                        local rp=RaycastParams.new() rp.FilterDescendantsInstances={LocalPlayer.Character,targetPart.Parent} rp.FilterType=Enum.RaycastFilterType.Exclude
                                        local r=workspace:Raycast(camPos,targetPart.Position-camPos,rp)
                                        if not r then best=targetPart bestDist=dist end
                                    else best=targetPart bestDist=dist end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end
addConn(RunService.RenderStepped:Connect(function()
    if S.unloaded or not S.aimEnabled or not S.aimHolding then return end
    local t=getAimTarget()
    if t then local cam=workspace.CurrentCamera if cam then cam.CFrame=CFrame.lookAt(cam.CFrame.Position,t.Position) end end
end))
addConn(RunService.RenderStepped:Connect(function()
    if S.unloaded or not S.c4Enabled then return end
    local cam=workspace.CurrentCamera if not cam then return end
    local w,part=findC4Bomb()
    if not w or not part then for _,d in pairs(S.c4Timers) do if d.box and d.box.Parent then d.box.Visible=false end if d.timer and d.timer.Parent then d.timer.Visible=false end end return end
    local data=S.c4Timers[w]
    if not data then
        local hl=Instance.new("Highlight") hl.Adornee=part hl.FillColor=S.c4Color hl.OutlineColor=S.c4Color hl.FillTransparency=0.5 hl.OutlineTransparency=0 hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop hl.Parent=part
        local box=Instance.new("Frame") box.BackgroundTransparency=1 box.Visible=false box.Parent=sg box.ZIndex=55
        local bo=Instance.new("UIStroke") bo.Color=S.c4Color bo.Thickness=2 bo.Parent=box
        local timer=Instance.new("TextLabel") timer.BackgroundTransparency=1 timer.TextColor3=UI.warn timer.TextScaled=true timer.Font=Enum.Font.Code timer.TextStrokeTransparency=0 timer.TextStrokeColor3=Color3.fromRGB(0,0,0) timer.Visible=false timer.Parent=sg timer.ZIndex=65
        local siteLabel=Instance.new("TextLabel") siteLabel.BackgroundTransparency=1 siteLabel.TextColor3=UI.accent siteLabel.TextScaled=true siteLabel.Font=Enum.Font.GothamBold siteLabel.TextStrokeTransparency=0 siteLabel.TextStrokeColor3=Color3.fromRGB(0,0,0) siteLabel.Visible=false siteLabel.Parent=sg siteLabel.ZIndex=65
        data={highlight=hl,box=box,boxOutline=bo,timer=timer,siteLabel=siteLabel,startTime=tick()}
        S.c4Timers[w]=data
    end
    local bp,on=cam:WorldToViewportPoint(part.Position)
    if not on or bp.Z<0 then data.box.Visible=false data.timer.Visible=false if data.siteLabel then data.siteLabel.Visible=false end if data.highlight and data.highlight.Parent then data.highlight.Enabled=false end return end
    if data.highlight and data.highlight.Parent then data.highlight.Enabled=true end
    local dist=(part.Position-cam.CFrame.Position).Magnitude
    if dist>1500 then data.box.Visible=false data.timer.Visible=false if data.siteLabel then data.siteLabel.Visible=false end return end
    local bH=math.clamp(5000/dist,30,200) local bW=bH*0.55
    local bs=Vector2.new(bp.X,bp.Y)
    local left=bs.X-bW/2 local top=bs.Y-bH/2
    data.box.Visible=true data.box.Position=UDim2.new(0,left,0,top) data.box.Size=UDim2.new(0,bW,0,bH)
    local site=getBombSite(part.Position)
    if site and data.siteLabel then data.siteLabel.Visible=true data.siteLabel.Text="PLANT "..site data.siteLabel.Position=UDim2.new(0,left,0,top-38) data.siteLabel.Size=UDim2.new(0,bW,0,18)
    elseif data.siteLabel then data.siteLabel.Visible=false end
    local rem=math.max(0,40-(tick()-data.startTime))
    local sec,ms=math.floor(rem),math.floor((rem-math.floor(rem))*100)
    data.timer.Visible=true data.timer.Text=string.format("%d.%02d",sec,ms)
    data.timer.TextColor3=(rem<10) and UI.bad or UI.warn
    data.timer.Position=UDim2.new(0,left,0,top-18) data.timer.Size=UDim2.new(0,bW,0,16)
end))
addConn(RunService.RenderStepped:Connect(function()
    if S.unloaded or not S.tinfoEnabled then if tinfoCard.Visible then tinfoCard.Visible=false end return end
    local cam=workspace.CurrentCamera if not cam then tinfoCard.Visible=false return end
    local origin=cam.CFrame.Position
    local dir=cam.CFrame.LookVector*2000
    local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude
    local filterList={}
    if LocalPlayer.Character then table.insert(filterList,LocalPlayer.Character) end
    for _,obj in ipairs(cam:GetChildren()) do table.insert(filterList,obj) end
    params.FilterDescendantsInstances=filterList
    local result=workspace:Raycast(origin,dir,params)
    if not result or not result.Instance then tinfoCard.Visible=false return end
    local char=result.Instance:FindFirstAncestorOfClass("Model")
    local plr=char and Players:GetPlayerFromCharacter(char)
    if not plr or plr==LocalPlayer then tinfoCard.Visible=false return end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health<=0 then tinfoCard.Visible=false return end
    tinfoCard.Visible=true
    tinfoName.Text=plr.Name tinfoName.TextColor3=getTeamColor(getPlayerTeamId(plr))
    local hp=math.floor(hum.Health) local mx=math.max(math.floor(hum.MaxHealth),1)
    local ratio=math.clamp(hp/mx,0,1)
    tinfoHpFill.Size=UDim2.new(ratio,0,1,0)
    if ratio>0.5 then tinfoHpFill.BackgroundColor3=HP_HIGH elseif ratio>0.25 then tinfoHpFill.BackgroundColor3=HP_MID else tinfoHpFill.BackgroundColor3=HP_LOW end
    tinfoHpText.Text=hp.." / "..mx
    tinfoWeapon.Text="Weapon: "..getWeaponName(char)
    if S.tinfoLastUserId~=plr.UserId then
        S.tinfoLastUserId=plr.UserId
        task.spawn(function()
            local ok,img=pcall(function() return Players:GetUserThumbnailAsync(plr.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end)
            if ok and img and tinfoAvatar and tinfoAvatar.Parent then tinfoAvatar.Image=img end
        end)
    end
end))
createESP=function(plr)
    if plr==LocalPlayer then return nil end
    if S.espCache[plr] then return S.espCache[plr] end
    local box=Instance.new("Frame") box.BackgroundTransparency=1 box.Visible=false box.Parent=sg box.ZIndex=50
    local bo=Instance.new("UIStroke") bo.Color=Color3.fromRGB(255,255,255) bo.Thickness=1.5 bo.Parent=box
    local tracer=Instance.new("Frame") tracer.BackgroundColor3=Color3.fromRGB(255,60,60) tracer.BorderSizePixel=0 tracer.AnchorPoint=Vector2.new(0.5,0) tracer.Visible=false tracer.Parent=sg tracer.ZIndex=40
    local nameText=Instance.new("TextLabel") nameText.BackgroundTransparency=1 nameText.TextColor3=Color3.fromRGB(255,255,255) nameText.TextScaled=true nameText.Font=Enum.Font.GothamBold nameText.TextStrokeTransparency=0.3 nameText.Visible=false nameText.Parent=sg nameText.ZIndex=60
    local hpBg=Instance.new("Frame") hpBg.BackgroundColor3=Color3.fromRGB(20,20,25) hpBg.BorderSizePixel=0 hpBg.Visible=false hpBg.Parent=sg hpBg.ZIndex=65
    addCorner(hpBg,2) addStroke(hpBg,UI.border,1)
    local hpFill=Instance.new("Frame") hpFill.BackgroundColor3=HP_HIGH hpFill.BorderSizePixel=0 hpFill.Size=UDim2.new(1,0,1,0) hpFill.Parent=hpBg hpFill.ZIndex=66
    addCorner(hpFill,2)
    local hpText=Instance.new("TextLabel") hpText.BackgroundTransparency=1 hpText.TextColor3=Color3.fromRGB(255,255,255) hpText.TextScaled=true hpText.Font=Enum.Font.GothamBold hpText.TextStrokeTransparency=0.3 hpText.Visible=false hpText.Parent=sg hpText.ZIndex=62
    local distText=Instance.new("TextLabel") distText.BackgroundTransparency=1 distText.TextColor3=Color3.fromRGB(220,220,220) distText.TextScaled=true distText.Font=Enum.Font.Gotham distText.TextStrokeTransparency=0.3 distText.Visible=false distText.Parent=sg distText.ZIndex=60
    local hitbarBg=Instance.new("Frame") hitbarBg.BackgroundColor3=Color3.fromRGB(20,20,25) hitbarBg.BorderSizePixel=0 hitbarBg.Visible=false hitbarBg.Parent=sg hitbarBg.ZIndex=65
    addCorner(hitbarBg,2) addStroke(hitbarBg,UI.border,1)
    local hitbarFill=Instance.new("Frame") hitbarFill.BackgroundColor3=HP_LOW hitbarFill.BorderSizePixel=0 hitbarFill.AnchorPoint=Vector2.new(0,1) hitbarFill.Position=UDim2.new(0,0,1,0) hitbarFill.Size=UDim2.new(1,0,1,0) hitbarFill.Parent=hitbarBg hitbarFill.ZIndex=66
    addCorner(hitbarFill,2)
    local bones={}
    for i=1,11 do
        local l=Instance.new("Frame") l.BackgroundColor3=Color3.fromRGB(255,255,255) l.BorderSizePixel=0 l.AnchorPoint=Vector2.new(0.5,0) l.Visible=false l.Parent=sg l.ZIndex=45
        table.insert(bones,l)
    end
    local data={box=box,boxOutline=bo,tracer=tracer,nameText=nameText,hpBg=hpBg,hpFill=hpFill,hpText=hpText,distText=distText,highlight=nil,bones=bones,hitbarBg=hitbarBg,hitbarFill=hitbarFill}
    S.espCache[plr]=data
    return data
end
removeESP=function(plr)
    local d=S.espCache[plr] if not d then return end
    for _,o in pairs(d) do
        if typeof(o)=="Instance" and o.Parent then o:Destroy()
        elseif typeof(o)=="table" then for _,s in ipairs(o) do if s and s.Parent then s:Destroy() end end end
    end
    S.espCache[plr]=nil
end
hideAll=function(data)
    if not data then return end
    for k,o in pairs(data) do
        if k=="bones" then for _,b in ipairs(o) do b.Visible=false end
        elseif k=="highlight" then if o and o.Parent then o.Enabled=false end
        elseif typeof(o)=="Instance" and o.Parent then if o:IsA("GuiObject") then o.Visible=false end end
    end
end
local function updateBoneLine(line,a,b)
    if not line or not a or not b then if line then line.Visible=false end return end
    local dx,dy=b.X-a.X,b.Y-a.Y
    local len=math.sqrt(dx*dx+dy*dy)
    if len<1 then line.Visible=false return end
    line.Position=UDim2.new(0,a.X,0,a.Y) line.Size=UDim2.new(0,1.5,0,len) line.Rotation=math.deg(math.atan2(dy,dx))-90 line.Visible=true
end
addConn(RunService.RenderStepped:Connect(function()
    if S.unloaded then return end
    pcall(function()
        if not S.espEnabled and not S.skeletonEnabled then for _,d in pairs(S.espCache) do hideAll(d) end return end
        local cam=workspace.CurrentCamera if not cam then return end
        local vp=cam.ViewportSize
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=LocalPlayer then
                local char=plr.Character
                if not char or not char.Parent or isPlayerDead(plr,char) then
                    if S.espCache[plr] then hideAll(S.espCache[plr]) end
                    if S.deadCleanup and char and char.Parent then
                        restoreHead(char)
                        for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.LocalTransparencyModifier=1 part.CanCollide=false end end
                    end
                else
                    local teamColor=getTeamColor(getPlayerTeamId(plr))
                    local root=getRoot(char)
                    local head=findBodyPart(char,{"Head"}) or root
                    local hum=char:FindFirstChildOfClass("Humanoid")
                    if root and head then
                        local data=S.espCache[plr] or createESP(plr)
                        if data then
                            if S.espEnabled and S.showChams then
                                if not data.highlight or not data.highlight.Parent then
                                    local hl=Instance.new("Highlight") hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop hl.OutlineTransparency=0 hl.FillTransparency=0.75 hl.Parent=char
                                    data.highlight=hl
                                end
                                data.highlight.FillColor=teamColor data.highlight.OutlineColor=teamColor data.highlight.Enabled=true
                            else if data.highlight and data.highlight.Parent then data.highlight.Enabled=false end end
                            if S.skeletonEnabled then
                                local hPart=findBodyPart(char,{"Head"})
                                local ut=findBodyPart(char,{"UpperTorso","Torso","Chest","Trunk"})
                                local lt=findBodyPart(char,{"LowerTorso","Torso","Trunk"})
                                local la=findBodyPart(char,{"LeftUpperArm","Left Arm","LeftArm"})
                                local ra=findBodyPart(char,{"RightUpperArm","Right Arm","RightArm"})
                                local lh=findBodyPart(char,{"LeftHand","Left Hand","LeftHand"})
                                local rh=findBodyPart(char,{"RightHand","Right Hand","RightHand"})
                                local ll=findBodyPart(char,{"LeftUpperLeg","Left Leg","LeftLeg"})
                                local rl=findBodyPart(char,{"RightUpperLeg","Right Leg","RightLeg"})
                                local lf=findBodyPart(char,{"LeftFoot","Left Foot","LeftFoot"})
                                local rf=findBodyPart(char,{"RightFoot","Right Foot","RightFoot"})
                                local function s(p) if not p then return nil end local v=cam:WorldToViewportPoint(p.Position) if v.Z<0 then return nil end return Vector2.new(v.X,v.Y) end
                                local pieces={{s(hPart),s(ut)},{s(ut),s(lt)},{s(ut),s(la)},{s(la),s(lh)},{s(ut),s(ra)},{s(ra),s(rh)},{s(lt),s(ll)},{s(ll),s(lf)},{s(lt),s(rl)},{s(rl),s(rf)},{s(hPart),s(ut)}}
                                for i,bone in ipairs(data.bones) do
                                    local pc=pieces[i]
                                    if pc and pc[1] and pc[2] then updateBoneLine(bone,pc[1],pc[2]) bone.BackgroundColor3=teamColor else bone.Visible=false end
                                end
                            else for _,b in ipairs(data.bones) do b.Visible=false end end
                            if S.espEnabled then
                                local hp3=cam:WorldToViewportPoint(head.Position)
                                local rp3=cam:WorldToViewportPoint(root.Position)
                                local vis=(hp3.Z>0) and (math.abs(hp3.X)<vp.X*2) and (math.abs(hp3.Y)<vp.Y*2)
                                if vis then
                                    local dist=(root.Position-cam.CFrame.Position).Magnitude
                                    if dist<1500 then
                                        local bh=math.clamp(5000/dist,25,300) local bw=bh*0.55
                                        local hs=Vector2.new(hp3.X,hp3.Y) local rs=Vector2.new(rp3.X,rp3.Y)
                                        local top=hs.Y-bh*0.6 local bot=rs.Y+bh*0.3
                                        local left=hs.X-bw/2 local right=hs.X+bw/2
                                        data.box.Visible=true data.box.Position=UDim2.new(0,left,0,top) data.box.Size=UDim2.new(0,right-left,0,bot-top)
                                        data.boxOutline.Color=teamColor
                                        if S.showTracer then
                                            data.tracer.Visible=true data.tracer.BackgroundColor3=teamColor
                                            local ox,oy=vp.X/2,vp.Y
                                            local dx,dy=hs.X-ox,bot-oy
                                            local len=math.sqrt(dx*dx+dy*dy)
                                            data.tracer.Position=UDim2.new(0,ox,0,oy) data.tracer.Size=UDim2.new(0,1.5,0,len) data.tracer.Rotation=math.deg(math.atan2(dy,dx))-90
                                        else data.tracer.Visible=false end
                                        if S.showName then
                                            data.nameText.Visible=true data.nameText.Text=plr.Name data.nameText.TextColor3=teamColor
                                            data.nameText.Position=UDim2.new(0,left,0,top-15) data.nameText.Size=UDim2.new(0,right-left,0,13)
                                        else data.nameText.Visible=false end
                                        if S.showHP and hum then
                                            local hp=hum.Health local mx=math.max(hum.MaxHealth,1)
                                            local p=math.clamp(hp/mx,0,1)
                                            data.hpBg.Visible=true data.hpBg.Position=UDim2.new(0,left,0,bot+2) data.hpBg.Size=UDim2.new(0,right-left,0,6)
                                            data.hpFill.Size=UDim2.new(p,0,1,0)
                                            if p>0.5 then data.hpFill.BackgroundColor3=HP_HIGH elseif p>0.25 then data.hpFill.BackgroundColor3=HP_MID else data.hpFill.BackgroundColor3=HP_LOW end
                                            data.hpText.Visible=true data.hpText.Text=math.floor(hp).." / "..math.floor(mx)
                                            data.hpText.Position=UDim2.new(0,left,0,bot+10) data.hpText.Size=UDim2.new(0,right-left,0,11)
                                        else data.hpBg.Visible=false data.hpText.Visible=false end
                                        if S.showDist then
                                            data.distText.Visible=true data.distText.Text=math.floor(dist).."m"
                                            data.distText.Position=UDim2.new(0,left,0,bot+22) data.distText.Size=UDim2.new(0,right-left,0,11)
                                        else data.distText.Visible=false end
                                        if S.showHitbar and hum then
                                            local hp=hum.Health local mx=math.max(hum.MaxHealth,1)
                                            local p=math.clamp(hp/mx,0,1)
                                            data.hitbarBg.Visible=true data.hitbarBg.Position=UDim2.new(0,right+4,0,top) data.hitbarBg.Size=UDim2.new(0,5,0,bot-top)
                                            data.hitbarFill.Size=UDim2.new(1,0,p,0)
                                            if p>0.5 then data.hitbarFill.BackgroundColor3=HP_HIGH elseif p>0.25 then data.hitbarFill.BackgroundColor3=HP_MID else data.hitbarFill.BackgroundColor3=HP_LOW end
                                        else data.hitbarBg.Visible=false end
                                    else hideAll(data) end
                                else hideAll(data) end
                            end
                        end
                    end
                end
            end
        end
    end)
end))
addConn(RunService.Heartbeat:Connect(function()
    if S.unloaded then return end
    if S.wallhackEnabled then wallhackStep() end
    if S.wallhackEnabled and #S.savedMapChildren>0 then
        local char=LocalPlayer.Character if not char then return end
        local pos=getCharPos(char)
        local params=RaycastParams.new() params.FilterDescendantsInstances={char} params.FilterType=Enum.RaycastFilterType.Exclude
        local result=workspace:Raycast(pos,Vector3.new(0,-10,0),params)
        if not result or result.Distance>5 then
            local plat=Instance.new("Part") plat.Size=Vector3.new(15,1,15) plat.Position=pos-Vector3.new(0,4,0) plat.Anchored=true plat.Transparency=0.5 plat.BrickColor=BrickColor.new("Dark stone grey") plat.Parent=workspace
            table.insert(S.mapSpawnedParts,plat)
        end
    end
end))
addConn(RunService.Heartbeat:Connect(function()
    if S.unloaded or not S.timeLockerEnabled then return end
    pcall(function() Lighting.ClockTime=S.timeSliderValue end)
end))
addConn(RunService.Heartbeat:Connect(function()
    if S.unloaded or S.seasonState~=2 then return end
    local char=LocalPlayer.Character
    if char then
        local pos=getCharPos(char)
        if S.snowPlates[1] and S.snowPlates[1].Parent then S.snowPlates[1].Position=pos-Vector3.new(0,3.2,0) end
    end
    for _,plr in ipairs(Players:GetPlayers()) do
        local c=plr.Character
        if c and findHeadPart(c) then
            if not S.winterHats[c] or not S.winterHats[c].folder or not S.winterHats[c].folder.Parent then makeNewYearHat(c) end
        end
    end
end))
for _,plr in ipairs(Players:GetPlayers()) do
    if plr~=LocalPlayer then
        addConn(plr.CharacterAdded:Connect(function(c)
            task.wait(0.5)
            if S.bigHeadEnabled and not isPlayerDead(plr,c) then applyBigHead(c,plr) end
            if S.seasonState==2 then makeNewYearHat(c) end
        end))
        addConn(plr.CharacterRemoving:Connect(function() if S.espCache[plr] then hideAll(S.espCache[plr]) end end))
        if plr.Character then task.spawn(function() task.wait(0.5) if S.bigHeadEnabled then applyBigHead(plr.Character,plr) end end) end
    end
end
addConn(Players.PlayerAdded:Connect(function(plr)
    if plr~=LocalPlayer then
        addConn(plr.CharacterAdded:Connect(function(c)
            task.wait(0.5)
            if S.bigHeadEnabled then applyBigHead(c,plr) end
            if S.seasonState==2 then makeNewYearHat(c) end
        end))
        addConn(plr.CharacterRemoving:Connect(function() if S.espCache[plr] then hideAll(S.espCache[plr]) end end))
    end
end))
addConn(Players.PlayerRemoving:Connect(function(plr) removeESP(plr) end))
addConn(LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(0.7)
    if S.morphState~=0 then applyMorph(c) end
    if S.seasonState~=0 then createSeasonEmitters() end
    enforceCamera()
end))

task.spawn(function()
    task.wait(1)
    if readfile and isfile and isfile(AUTOLOAD_FILE) then
        local ok,name=pcall(function() return readfile(AUTOLOAD_FILE) end)
        if ok and name and name~="" then
            local path=FOLDER_CONFIGS.."/"..name..".json"
            if isfile(path) then
                local ok2,raw=pcall(function() return readfile(path) end)
                if ok2 and raw then
                    local ok3,data=pcall(function() return HttpService:JSONDecode(raw) end)
                    if ok3 and type(data)=="table" then
                        for _,k in ipairs(CONFIG_KEYS) do if data[k]~=nil then S[k]=data[k] end end
                        if S.fullbrightEnabled then enableFullbright() end
                        if S.noFogEnabled then enableNoFog() end
                        if S.graphicEnabled then enableGraphic() end
                        if S.fpsBoostEnabled then enableFpsBoost() end
                        if S.skyEnabled then enableSky() end
                        if S.xrayEnabled then enableXray() end
                        setSeason(S.seasonState or 0) refreshSeasonBtns()
                        setCameraMode(S.cameraMode or 1)
                        setMorph(S.morphState or 0) refreshMorphBtns()
                        setHudVisible(S.hudEnabled and true or false)
                        if S.timeSliderValue then pcall(function() Lighting.ClockTime=S.timeSliderValue end) end
                        notificationsEnabled=S.notificationsEnabled and true or false
                        _G._wc_autoload=true
                        notify("Auto-loaded: "..name,UI.good)
                        if configNameBox and configNameBox.Parent then configNameBox.Text=name end
                    end
                end
            end
        end
    end
end)

startPollLoop()

-- MINI BTN
local miniBtn=Instance.new("TextButton")
miniBtn.Size=UDim2.new(0,50,0,50) miniBtn.Position=UDim2.new(0,20,0.5,-25) miniBtn.BackgroundColor3=UI.panel2 miniBtn.BorderSizePixel=0 miniBtn.Text="WC" miniBtn.TextColor3=UI.accent miniBtn.TextSize=14 miniBtn.Font=Enum.Font.GothamBold miniBtn.Visible=false miniBtn.Parent=sg miniBtn.ZIndex=2000 miniBtn.Active=true
addCorner(miniBtn,25) addStroke(miniBtn,UI.accent,1.5)
local miniDragging=false local miniDragStart=nil local miniStartPos=nil local miniMoved=false
miniBtn.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        miniDragging=true miniMoved=false miniDragStart=input.Position miniStartPos=miniBtn.Position
        input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then miniDragging=false end end)
    end
end)
miniBtn.InputChanged:Connect(function(input)
    if not miniDragging then return end
    if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
        local delta=input.Position-miniDragStart
        if math.abs(delta.X)>3 or math.abs(delta.Y)>3 then miniMoved=true end
        miniBtn.Position=UDim2.new(miniStartPos.X.Scale,miniStartPos.X.Offset+delta.X,miniStartPos.Y.Scale,miniStartPos.Y.Offset+delta.Y)
    end
end)
miniBtn.MouseButton1Click:Connect(function()
    if miniMoved then return end
    main.Visible=true
    if main.GroupTransparency~=nil then main.GroupTransparency=1 TweenService:Create(main,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{GroupTransparency=0}):Play() end
    miniBtn.Visible=false
end)
minimize.MouseButton1Click:Connect(function()
    if main.GroupTransparency~=nil then
        local t=TweenService:Create(main,TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{GroupTransparency=1})
        t:Play() t.Completed:Connect(function() main.Visible=false miniBtn.Visible=true end)
    else main.Visible=false miniBtn.Visible=true end
end)
if main.GroupTransparency~=nil then
    main.GroupTransparency=1
    main.Position=UDim2.new(0.5,-MAIN_W/2,0.4,-MAIN_H/2+24)
    task.spawn(function()
        TweenService:Create(main,TweenInfo.new(0.28,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{GroupTransparency=0,Position=UDim2.new(0.5,-MAIN_W/2,0.4,-MAIN_H/2)}):Play()
    end)
end

closeBtn.MouseButton1Click:Connect(function()
    if main.GroupTransparency~=nil and main.Visible then
        local t=TweenService:Create(main,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{GroupTransparency=1})
        t:Play() t.Completed:Wait()
    end
    S.unloaded=true
    for _,c in ipairs(S.connections) do pcall(function() c:Disconnect() end) end
    S.connections={}
    pcall(function() RunService:UnbindFromRenderStep("WC_Camera") end)
    uninstallCameraHook()
    if S.rawMeta and S.oldNamecall then pcall(function() setreadonly(S.rawMeta,false) S.rawMeta.__namecall=S.oldNamecall setreadonly(S.rawMeta,true) end) end
    pcall(function() for _,p in ipairs(Players:GetPlayers()) do if p.Character then restoreHead(p.Character) end end end)
    pcall(function() local char=LocalPlayer.Character if char then restoreGiant(char) restoreTall(char) clearMorph(char) end end)
    pcall(function() restoreMap() end)
    pcall(function() disableXray() end)
    pcall(function() cleanupSeason() end)
    pcall(function() disableFullbright() end)
    pcall(function() disableNoFog() end)
    pcall(function() disableGraphic() end)
    pcall(function() disableFpsBoost() end)
    pcall(function() disableSky() end)
    pcall(function() LocalPlayer.CameraMode=Enum.CameraMode.Classic LocalPlayer.CameraMinZoomDistance=0.5 LocalPlayer.CameraMaxZoomDistance=128 end)
    S.wallhackEnabled=false S.xrayEnabled=false S.timeLockerEnabled=false
    S.speedEnabled=false S.noRecoilEnabled=false S.bunnyHopEnabled=false S.headshotAssistEnabled=false
    pcall(function() sg:Destroy() end)
    pcall(function() notifSg:Destroy() end)
    pcall(function() hudSg:Destroy() end)
    pcall(function() seasonSg:Destroy() end)
    pcall(function() tinfoSg:Destroy() end)
    pcall(function() popupSg:Destroy() end)
end)

createTabButton("main","Main",UI.text)
createTabButton("visuals","Visuals",UI.accent)
createTabButton("skinchanger","Skin Changer",UI.yellow)
if hasAccess("beta") then createTabButton("beta","Beta",Color3.fromRGB(200,140,255)) end
if hasAccess("admin") then createTabButton("admin","Admin",UI.warn) end
if hasAccess("adminpanel") then createTabButton("adminpanel","Admin Panel",UI.bad) end
createTabButton("configs","Configs",UI.good)
createTabButton("feedback","Feedback",UI.accent)
createTabButton("settings","Settings",UI.accent)
switchTab("main")
end

-- ============ ЗАПУСК (без print) ============
local function clearServerNotice()
    pcall(function() httpPost(API_URL.."/clear_notice",{secret=API_SECRET,hwid=currentHWID}) end)
end

local function showLoadingHint(text)
    if not _G._wc_loadingSg or not _G._wc_loadingSg.Parent then
        local sg=Instance.new("ScreenGui")
        sg.Name="_bs_loading" sg.ResetOnSpawn=false sg.DisplayOrder=2147483647
        sg.IgnoreGuiInset=true sg.Parent=parent
        local fr=Instance.new("Frame")
        fr.Size=UDim2.new(0,340,0,42) fr.Position=UDim2.new(0.5,-170,0,20)
        fr.BackgroundColor3=UI.bg fr.BorderSizePixel=0 fr.Parent=sg
        addCorner(fr,6) addStroke(fr,UI.accent,1.5)
        local lbl=Instance.new("TextLabel")
        lbl.Name="Lbl"
        lbl.Size=UDim2.new(1,-20,1,0) lbl.Position=UDim2.new(0,10,0,0)
        lbl.BackgroundTransparency=1 lbl.Text="WorkClient: запуск…"
        lbl.TextColor3=UI.text lbl.TextSize=12 lbl.Font=Enum.Font.Gotham
        lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.Parent=fr
        _G._wc_loadingSg=sg
        _G._wc_loadingLbl=lbl
    end
    if _G._wc_loadingLbl then
        _G._wc_loadingLbl.Text="WorkClient: "..tostring(text)
    end
end

local function hideLoadingHint()
    if _G._wc_loadingSg then
        pcall(function() _G._wc_loadingSg:Destroy() end)
        _G._wc_loadingSg=nil
        _G._wc_loadingLbl=nil
    end
end

local function startFlow()
    showLoadingHint("проверяю связь с сервером…")

    local done=false
    local res,errCode=nil,nil
    task.spawn(function()
        res,errCode=httpPost(API_URL.."/register",{
            secret=API_SECRET, hwid=currentHWID,
            nickname=LocalPlayer.Name, roblox_id=LocalPlayer.UserId
        })
        done=true
    end)

    local waited=0
    while not done and waited<15 do
        task.wait(0.25)
        waited=waited+0.25
    end

    if not done then
        showLoadingHint("сервер не отвечает (timeout)")
        task.wait(1.5)
        hideLoadingHint()
        if localData.key and localData.key~="" then
            keyPassed=true
            currentKey=localData.key
            currentRank=localData.rank or "player"
            runMainGUI()
        else
            showKeyMenu()
        end
        return
    end

    showLoadingHint("обрабатываю ответ…")

    if res then
        local ok,data=pcall(function() return HttpService:JSONDecode(res) end)
        if ok and type(data)=="table" then
            if data.reset_notice and data.reset_notice~="" then
                hideLoadingHint()
                showResetDialog(data.reset_notice,function()
                    clearServerNotice()
                    localData.key=nil localData.rank=nil localData.activated=nil
                    saveLocal(localData)
                    showKeyMenu()
                end)
                return
            end
            if data.activated_key and data.activated_key~="" then
                localData.key=data.activated_key
                localData.rank=data.rank or "player"
                saveLocal(localData)
                currentKey=data.activated_key
                currentRank=localData.rank
                keyPassed=true
                hideLoadingHint()
                runMainGUI()
                return
            end
        end
    end

    hideLoadingHint()
    if localData.key and localData.key~="" then
        keyPassed=true
        currentKey=localData.key
        currentRank=localData.rank or "player"
        runMainGUI()
    else
        showKeyMenu()
    end
end

task.spawn(function()
    local ok,err=pcall(startFlow)
    if not ok then
        hideLoadingHint()
        pcall(function() showKeyMenu() end)
    end
end)
