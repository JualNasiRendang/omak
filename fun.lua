-- =========================================================================
-- RIDE GUARD SUBSYSTEM (STANDALONE MODULE)
-- Modularized from SAE Black UI New Method Upgrade
-- Compatible with Volt / Potassium / Standard Roblox Executors
-- =========================================================================

local ctx = ... or {}
local UI = ctx.UI or (getgenv and getgenv().__UI) or _G.__UI
local UIX = ctx.UIX or (getgenv and getgenv().__UIX) or _G.__UIX or {}
local ST = ctx.ST or (getgenv and getgenv().__STEALFIX) or _G.__STEALFIX or {}

local gg = getgenv and getgenv() or _G
local EPOCH = gg.__STEALFIX_EPOCH or 1
local function alive()
    if ctx.alive then return ctx.alive() end
    if UI and UI.isAlive then return UI.isAlive() end
    return true
end

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer or game:GetService("Players").LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HS = game:GetService("HttpService")

local Theme = ctx.Theme or (UI and UI.Theme) or {
    Background    = Color3.fromRGB(11, 14, 20),
    Window        = Color3.fromRGB(11, 14, 20),
    Card          = Color3.fromRGB(16, 20, 30),
    Control       = Color3.fromRGB(22, 28, 42),
    CardHover     = Color3.fromRGB(28, 36, 52),
    Border        = Color3.fromRGB(34, 44, 65),
    Text          = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(145, 165, 192),
}

local FONT = ctx.FONT or (UI and UI.FONT) or Enum.Font.GothamMedium
local FONT_BOLD = ctx.FONT_BOLD or (UI and UI.FONT_BOLD) or Enum.Font.GothamBold
local CTRL_T = (UI and UI.CTRL_T) or 0
local IS_PREMIUM = ctx.IS_PREMIUM ~= nil and ctx.IS_PREMIUM or true

local showToast = ctx.showToast or (UI and UI.showToast) or function(msg) print("[RideGuard]", msg) end
local saveConfig = ctx.saveConfig or function() end
local hrp = ctx.hrp or function()
    local c = LP.Character
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("RootPart"))
end

local function req(m)
    if not m then return nil end
    local ok, res = pcall(require, m)
    return ok and res or nil
end

local new = (UI and UI.new) or function(class, props, children)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then pcall(function() inst[k] = v end) end
        end
        if props.Parent then inst.Parent = props.Parent end
    end
    if children then
        for _, ch in ipairs(children) do ch.Parent = inst end
    end
    return inst
end

local corner = (UI and UI.corner) or function(r) return new("UICorner", { CornerRadius = UDim.new(0, r or 8) }) end
local stroke = (UI and UI.stroke) or function(col, th, tr) return new("UIStroke", { Color = col or Color3.fromRGB(50, 50, 50), Thickness = th or 1, Transparency = tr or 0 }) end
local sectionLabel = (UI and UI.sectionLabel)
local toggleRow = (UI and UI.toggleRow)
local dropdownSingle = (UI and UI.dropdownSingle)
local itemsOf = ctx.itemsOf or function(list)
    local t = {}
    for _, v in ipairs(list) do table.insert(t, { key = v, text = tostring(v) }) end
    return t
end
local trackConn = ctx.trackConn or (UI and UI.trackConn) or function(conn) return conn end
local makePage = (UI and UI.makePage)

-- If page already exists, return it
if UI and UI.Pages and UI.Pages["Ride Guard"] then
    return UI.Pages["Ride Guard"]
end

local rgPage = (makePage and makePage("Ride Guard"))
if not rgPage then
    warn("[RideGuard] Could not create page 'Ride Guard'")
    return nil
end
UIX.rgPage = rgPage

    -- Nunggangin model Guard tiap area. MURNI VISUAL DI KLIEN: model-nya hasil Clone
    -- yang di-parent ke workspace lokal, jadi gak ke-replikasi ke server dan gak
    -- ngirim remote apa pun. Ini juga alasan gak ada risiko anticheat di sini.
    --
    -- SEMUA temuan di bawah hasil ukur live waktu prototipe, bukan asumsi:
    --
    -- 1. RIG-nya BUKAN di Humanoid luar. Struktur guard: Guard(Model, punya Humanoid)
    --    -> Guard.Model (rig asli) yang punya AnimationController + Animator sendiri.
    --    Nempelin animasi ke Humanoid luar bikin track jalan tapi rig DIAM.
    --
    -- 2. Rig-nya SKINNED MESH (40 Bone). Deformasi terjadi di GPU lewat bone, jadi
    --    posisi BasePart memang TIDAK berubah walau animasi jalan normal. Jangan
    --    pernah pakai posisi part buat ngecek animasi hidup — pakai Bone.Transform.
    --
    -- 3. Tinggi punggung HARUS diukur dari mesh badan saja. Ada part penanda "CENTER"
    --    setebal 0.0 di atas kepala; kalau ikut kehitung, bounding box ketarik ~8 stud
    --    dan guard-nya jadi kependem di tanah.
    --
    -- 4. Badan guard ~25 stud. Kalau punggung ditaruh pas di kaki player sementara
    --    player tetap di tanah, kaki guard otomatis 25 stud DI BAWAH tanah. Jadi
    --    player-nya yang dinaikin, bukan guard-nya yang diturunin.
    -- Halaman ditaruh di UIX.rgPage, BUKAN `local`: blok utama pas di 208 lokal dan
    -- batas Luau 200 lokal aktif udah kebukti kepicu di angka segini
    -- ("Out of local registers ... exceeded limit 200").
    -- UIX.rgPage created in header
    do local o = 0; local function n() o = o + 1; return o end
        UIX.rgGuards = workspace:FindFirstChild("__OBJECTS")
            and Workspace.__OBJECTS:FindFirstChild("Areas")
            and Workspace.__OBJECTS.Areas:FindFirstChild("GuardAreas")

        -- Daftar area guard lengkap di game
        function UIX.rgFullList()
            local t = {}
            for _, a in ipairs((UIX.rgGuards and UIX.rgGuards:GetChildren()) or {}) do
                if a:FindFirstChild("Guard") then t[#t + 1] = a.Name end
            end
            table.sort(t)
            return t
        end

        function UIX.rgList()
            return UIX.rgFullList()
        end

        function UIX.rgSource(id)
            local holder = UIX.rgGuards and UIX.rgGuards:FindFirstChild(id or "")
            return holder and holder:FindFirstChild("Guard")
        end

        -- Seberapa dalam player "duduk" ke punggung (stud). 0 = telapak kaki pas nempel
        -- di garis punggung — itu bikin player kelihatan ngambang dikit karena punggung
        -- guard melengkung, bukan datar. Positif = guard dinaikin, jadi player amblas
        -- sedikit ke badan dan nempel meyakinkan.
        -- Guard dipakai UKURAN ASLI (tanpa penyeragaman skala) sesuai permintaan.
        UIX.RIDE_SINK = 2.0

        -- dasar & punggung relatif pivot (Prioritaskan BONE untuk Skinned Mesh agar akurat 100%)
        function UIX.rgSpan(model)
            local pivotY = model:GetPivot().Position.Y
            local bones = {}
            for _, d in ipairs(model:GetDescendants()) do
                if d:IsA("Bone") then
                    table.insert(bones, d.WorldPosition.Y)
                end
            end
            if #bones > 0 then
                table.sort(bones)
                local boneMin = bones[1]
                local boneMax = bones[#bones]
                return boneMin - pivotY, boneMax - pivotY
            end

            -- Fallback untuk unskinned parts
            local inner = model:FindFirstChild("Model") or model
            local lo, hi = math.huge, -math.huge
            for _, d in ipairs(inner:GetDescendants()) do
                if d:IsA("BasePart") and d.Size.Magnitude > 0.1 then
                    local nm = d.Name
                    -- Abaikan part helper, collider, head proxy, dan efek api (Fire)
                    if not nm:find("Root") and not nm:find("Point") and not nm:find("Proxy") and not nm:find("Collider") and nm ~= "CENTER" and nm ~= "Head" and not nm:find("Fire") then
                        lo = math.min(lo, d.Position.Y - d.Size.Y / 2)
                        hi = math.max(hi, d.Position.Y + d.Size.Y / 2)
                    end
                end
            end
            if lo == math.huge then return -8, 8 end
            return lo - pivotY, hi - pivotY
        end

        function UIX.rgDespawn()
            if UIX.rgConn then UIX.rgConn:Disconnect(); UIX.rgConn = nil end
            if UIX.rgTrack then pcall(function() UIX.rgTrack:Stop() end); UIX.rgTrack = nil end
            if UIX.rgIdleTrack then pcall(function() UIX.rgIdleTrack:Stop() end); UIX.rgIdleTrack = nil end
            if UIX.rgMount then pcall(function() UIX.rgMount:Destroy() end); UIX.rgMount = nil end
            if UIX.rgSaddle then pcall(function() UIX.rgSaddle:Destroy() end); UIX.rgSaddle = nil end
            if UIX.rgShadow then pcall(function() UIX.rgShadow:Destroy() end); UIX.rgShadow = nil end
            UIX.rideLift = 0
            UIX.rgFootOff = 0
            UIX.rgBackOff = 0
        end

        -- SATU sumber kebenaran buat sink offset. Dipakai rgSpawn (mount sendiri) DAN
        -- rgPeerBuild (mount pemain lain), supaya guard yang dilihat orang lain duduk di
        -- ketinggian yang SAMA PERSIS dengan yang dirasakan penunggangnya. Kalau angkanya
        -- dibiarkan dobel di dua tempat, cepat atau lambat pasti drift.
        -- Ditaruh SEBELUM rgSpawn biar gak ada ketergantungan urutan.
        function UIX.rgSink(areaId, guardHeight)
            if areaId == "Titan Temple" then return 8.5 end
            if areaId == "Volcano" then return 4.8 end
            if areaId == "Prehistoric" then return 1.5 end
            if guardHeight < 10 then return 1.0 end
            if guardHeight < 18 then return 2.0 end
            return 4.5
        end

        function UIX.rgSpawn(areaId)
            UIX.rgDespawn()
            local src = UIX.rgSource(areaId)
            if not src then return false end

            local c = src:Clone()
            c.Name = "SAE_GuardRide"
            local ohrp = c:FindFirstChild("HumanoidRootPart")
            for _, d in ipairs(c:GetDescendants()) do
                if d:IsA("BasePart") then
                    d.Anchored = (d == ohrp)
                    d.CanCollide = false
                    d.CastShadow = true
                end
            end
            local hum = c:FindFirstChildOfClass("Humanoid")
            if hum then hum.EvaluateStateMachine = false end
            c.Parent = Workspace

            local inner = c:FindFirstChild("Model")
            local ac = inner and inner:FindFirstChildOfClass("AnimationController")
            local animator = ac and ac:FindFirstChildOfClass("Animator")
            local gdir = req(RS:FindFirstChild("Data") and RS.Data:FindFirstChild("Guards"))
            local gd = gdir and (gdir.Directory or gdir)[areaId]
            if animator and gd then
                for _, t in ipairs(animator:GetPlayingAnimationTracks()) do pcall(function() t:Stop() end) end
                local wId = tostring(gd.WalkAnimation):match("(%d+)")
                local iId = tostring(gd.IdleAnimation):match("(%d+)")

                if wId then
                    local aW = Instance.new("Animation")
                    aW.AnimationId = "rbxassetid://" .. wId
                    local okW, trW = pcall(function() return animator:LoadAnimation(aW) end)
                    if okW and trW then
                        trW.Looped = true
                        trW.Priority = Enum.AnimationPriority.Movement
                        trW:Play()
                        UIX.rgTrack = trW
                    end
                end

                if iId then
                    local aI = Instance.new("Animation")
                    aI.AnimationId = "rbxassetid://" .. iId
                    local okI, trI = pcall(function() return animator:LoadAnimation(aI) end)
                    if okI and trI then
                        trI.Looped = true
                        trI.Priority = Enum.AnimationPriority.Idle
                        trI:Play()
                        UIX.rgIdleTrack = trI
                    end
                end
            end

            local footOff, backOff = UIX.rgSpan(c)
            local guardHeight = math.max(1, backOff - footOff)
            -- Angkanya dipindah ke UIX.rgSink supaya jadi SATU sumber kebenaran:
            -- mount pemain lain (rgPeerBuild) pakai fungsi yang sama. Kalau dibiarkan
            -- dobel, guard yang dilihat orang lain bakal duduk di ketinggian berbeda
            -- dari yang dirasakan penunggangnya.
            local SINK_OFFSET = UIX.rgSink(areaId, guardHeight)

            UIX.rgFootOff = footOff
            UIX.rgBackOff = backOff
            UIX.rideLift = math.max(0, (backOff - footOff) - SINK_OFFSET)

            -- Invisible Saddle Platform untuk tumpuan kaki player
            local saddle = Instance.new("Part")
            saddle.Name = "SAE_RideSaddle"
            saddle.Size = Vector3.new(20, 1, 20)
            saddle.Transparency = 1
            saddle.CanCollide = true
            saddle.Anchored = true
            saddle.Parent = Workspace
            UIX.rgSaddle = saddle

            UIX.rgMount = c
            local lastLook = Vector3.new(0, 0, -1)
            local lastPos = (hrp() and hrp().Position) or Vector3.zero

            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude

            local pHum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if pHum then
                pHum.PlatformStand = false
                pHum.Sit = false
                pcall(function()
                    pHum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
                    pHum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                    pHum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                end)
            end

            -- Posisi awal angkat player ke atas punggung
            local rInit = hrp()
            if rInit then
                rayParams.FilterDescendantsInstances = { LP.Character, c, saddle }
                local hit0 = Workspace:Raycast(rInit.Position, Vector3.new(0, -90, 0), rayParams)
                local gY0 = hit0 and hit0.Position.Y or (rInit.Position.Y - 3)
                local sY0 = (gY0 - footOff) + backOff - SINK_OFFSET
                saddle.Position = Vector3.new(rInit.Position.X, sY0, rInit.Position.Z)
                rInit.CFrame = CFrame.new(rInit.Position.X, sY0 + 3.0, rInit.Position.Z)
                rInit.AssemblyLinearVelocity = Vector3.zero
            end

            UIX.rgConn = RunService.RenderStepped:Connect(function(dt)
                local r = hrp()
                if not r or not c.Parent or not saddle.Parent then return end
                local fly = ST.flyMode and true or false

                local d = r.Position - lastPos
                lastPos = r.Position
                local flat = Vector3.new(d.X, 0, d.Z)
                local moveSpeed = flat.Magnitude / math.max(dt, 1 / 240)

                local curHum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                local moveDir = (curHum and curHum.MoveDirection) or Vector3.zero

                local targetLook = lastLook
                if moveDir.Magnitude > 0.05 then
                    targetLook = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
                elseif flat.Magnitude > 0.05 then
                    targetLook = flat.Unit
                else
                    local look = r.CFrame.LookVector
                    local flatLook = Vector3.new(look.X, 0, look.Z)
                    if flatLook.Magnitude > 0.01 then targetLook = flatLook.Unit end
                end

                -- Smooth Tween Rotasi Guard
                if targetLook.Magnitude > 0.1 and lastLook.Magnitude > 0.1 then
                    local blended = lastLook:Lerp(targetLook, math.clamp(dt * 12.0, 0.05, 1.0))
                    if blended.Magnitude > 0.01 then
                        lastLook = blended.Unit
                    end
                end

                -- Suppress player running/walking animations (biar karakter diem/idle di punggung guard)
                local pAnimator = curHum and curHum:FindFirstChildOfClass("Animator")
                if pAnimator then
                    for _, tr in ipairs(pAnimator:GetPlayingAnimationTracks()) do
                        local name = tr.Name:lower()
                        local anim = tr.Animation
                        local animId = (anim and anim.AnimationId) or ""
                        if name:find("run") or name:find("walk") or name:find("jump") or name:find("fall") or name:find("swim") or animId:find("run") or animId:find("walk") then
                            pcall(function() tr:Stop(0.1) end)
                        end
                    end
                end

                -- Animation State Blending pada Guard: Idle vs Walk
                if UIX.rgTrack and UIX.rgIdleTrack then
                    if moveSpeed > 1.5 then
                        UIX.rgTrack:AdjustWeight(1.0, 0.1)
                        UIX.rgIdleTrack:AdjustWeight(0.0, 0.1)
                        UIX.rgTrack:AdjustSpeed(math.clamp(moveSpeed / 28, 0.5, 2.5))
                    else
                        UIX.rgTrack:AdjustWeight(0.0, 0.15)
                        UIX.rgIdleTrack:AdjustWeight(1.0, 0.15)
                    end
                elseif UIX.rgTrack then
                    UIX.rgTrack:AdjustSpeed(moveSpeed > 1.5 and math.clamp(moveSpeed / 28, 0.5, 2.5) or 0.6)
                end

                -- Cek ketinggian tanah aktual di bawah player
                rayParams.FilterDescendantsInstances = { LP.Character, c, saddle }
                local startY = r.Position.Y + 4.0
                local hit = Workspace:Raycast(Vector3.new(r.Position.X, startY, r.Position.Z), Vector3.new(0, -(UIX.rideLift + 35), 0), rayParams)
                if not hit or (hit and hit.Position.Y > (r.Position.Y + 2.0)) then
                    -- Fallback jika ada atap/skybox: raycast tepat ke bawah dari kaki
                    hit = Workspace:Raycast(Vector3.new(r.Position.X, r.Position.Y - (UIX.rideLift or 0) + 2, r.Position.Z), Vector3.new(0, -30, 0), rayParams)
                end
                local groundY = (hit and hit.Position.Y < (r.Position.Y + 2.0)) and hit.Position.Y or 67.57

                local curGuardPivotY
                local curGuardBackY
                local curSaddleY

                -- Jika player berada di dekat tanah (di Safe Zone / mendarat)
                local inAir = (r.Position.Y - groundY) > (UIX.rideLift + 12)

                if not inAir then
                    -- Mode Darat / Di Safe Zone: Kaki guard menapak pas di tanah
                    curGuardPivotY = groundY - footOff
                    curGuardBackY = curGuardPivotY + backOff
                    curSaddleY = curGuardBackY - SINK_OFFSET

                    saddle.Position = Vector3.new(r.Position.X, curSaddleY, r.Position.Z)
                    saddle.CanCollide = true
                    if not ST.on then
                        if r.Position.Y < (curSaddleY + 2.0) then
                            r.CFrame = CFrame.new(r.Position.X, curSaddleY + 3.0, r.Position.Z)
                            r.AssemblyLinearVelocity = Vector3.zero
                        end
                    end
                else
                    -- Mode Terbang di Udara: Punggung guard tepat di bawah kaki player
                    saddle.CanCollide = false
                    curGuardPivotY = r.Position.Y - 3 - backOff + SINK_OFFSET
                end

                local base = Vector3.new(r.Position.X, curGuardPivotY, r.Position.Z)
                local cf = CFrame.lookAt(base, base + lastLook)
                if inAir then cf = cf * CFrame.Angles(math.rad(-15), 0, 0) end
                c:PivotTo(cf)
            end)
            return true
        end

        sectionLabel(UIX.rgPage, "Ride Guard", n())
        dropdownSingle(UIX.rgPage, "Guard", n(), function() return itemsOf(UIX.rgList()) end,
            function(it)
                if it.clear then return end
                ST.rideGuardId = it.key
                saveConfig()
                if UIX.rgPreview then UIX.rgPreview(it.key) end
                if ST.rideGuard then UIX.rgSpawn(it.key) end   -- ganti guard langsung
            end, ST.rideGuardId or (IS_PREMIUM and "Cherry Blossom" or "Forest"), false)

        toggleRow(UIX.rgPage, "Ride Guard", n(), function(on)
            ST.rideGuard = on
            saveConfig()
            if on then
                local defaultGuard = IS_PREMIUM and "Cherry Blossom" or "Forest"
                local targetGuard = ST.rideGuardId or defaultGuard
                if not IS_PREMIUM and targetGuard ~= "Lake" and targetGuard ~= "Forest" then
                    targetGuard = "Forest"
                    ST.rideGuardId = "Forest"
                end
                if not UIX.rgSpawn(targetGuard) then
                    showToast("Guard model not found")
                    ST.rideGuard = false
                end
            else
                UIX.rgDespawn()
            end
        end, ST.rideGuard)

        -- ---------- PREVIEW ----------
        UIX.rgCard = new("Frame", { Parent = UIX.rgPage, Size = UDim2.new(1, 0, 0, 190),
            LayoutOrder = n(), BackgroundColor3 = Theme.Control, BackgroundTransparency = CTRL_T,
            BorderSizePixel = 0 }, { corner(10), stroke(Theme.Border, 1, 0.5) })
        UIX.rgVp = new("ViewportFrame", { Parent = UIX.rgCard, Size = UDim2.new(1, -12, 1, -26),
            Position = UDim2.new(0, 6, 0, 6), BackgroundTransparency = 1,
            Ambient = Color3.fromRGB(190, 190, 200), LightColor = Color3.fromRGB(255, 255, 255),
            LightDirection = Vector3.new(-0.4, -1, -0.6) })
        UIX.rgName = new("TextLabel", { Parent = UIX.rgCard, Size = UDim2.new(1, 0, 0, 18),
            Position = UDim2.new(0, 0, 1, -21), BackgroundTransparency = 1, Font = FONT_BOLD,
            Text = "", TextColor3 = Theme.Text, TextSize = 14 })

        function UIX.rgPreview(areaId)
            local vp = UIX.rgVp
            if not vp then return end
            for _, ch in ipairs(vp:GetChildren()) do pcall(function() ch:Destroy() end) end
            UIX.rgName.Text = tostring(areaId or "-")
            local src = UIX.rgSource(areaId)
            if not src then UIX.rgName.Text = tostring(areaId) .. " (model not found)" return end

            local m = src:Clone()
            m:PivotTo(CFrame.new())
            for _, nm in ipairs({ "Collider", "CENTER", "HeadProxy", "EggPoint", "HumanoidRootPart" }) do
                local p = m:FindFirstChild(nm); if p then p:Destroy() end
            end
            local h = m:FindFirstChildOfClass("Humanoid"); if h then h:Destroy() end
            for _, d in ipairs(m:GetDescendants()) do
                if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end
            end
            m.Parent = vp

            local cf, size = m:GetBoundingBox()
            local cam = Instance.new("Camera")
            cam.FieldOfView = 45
            local dist = (size.Magnitude * 0.5) / math.tan(math.rad(22.5)) * 1.05
            cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0.7, 0.28, -0.9).Unit * dist, cf.Position)
            cam.Parent = vp
            vp.CurrentCamera = cam
        end

        -- Banner upgrade info untuk Free users
        if not IS_PREMIUM then
            local info = new("TextButton", { Parent = UIX.rgPage, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = n(),
                BackgroundColor3 = Color3.fromRGB(30, 33, 46), BackgroundTransparency = 0.1, AutoButtonColor = false,
                Text = "" }, { corner(8), stroke(Color3.fromRGB(88, 101, 242), 1) })
            new("Frame", { Parent = info, Size = UDim2.new(0, 4, 1, -12), Position = UDim2.new(0, 8, 0.5, -16),
                BackgroundColor3 = Color3.fromRGB(255, 216, 92), BorderSizePixel = 0 }, { corner(2) })
            new("TextLabel", { Parent = info, Size = UDim2.new(1, -28, 1, 0), Position = UDim2.new(0, 18, 0, 0),
                BackgroundTransparency = 1, Font = FONT, TextColor3 = Theme.Text, TextSize = 11,
                Text = "🔒 Upgrade to Gold/Lifetime to unlock all 11+ Guard Mounts! Join: " .. DISCORD_INVITE .. " (tap to copy)",
                TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true })
            info.MouseButton1Click:Connect(function()
                local ok = pcall(setclipboard, "https://" .. DISCORD_INVITE)
                showToast(ok and "Discord invite copied to clipboard!" or ("Join: " .. DISCORD_INVITE))
            end)
        end

        task.spawn(function()
            task.wait(0.5)
            local defaultGuard = IS_PREMIUM and "Cherry Blossom" or "Forest"
            local initialGuard = ST.rideGuardId or defaultGuard
            if not IS_PREMIUM and initialGuard ~= "Lake" and initialGuard ~= "Forest" then
                initialGuard = "Forest"
                ST.rideGuardId = "Forest"
            end
            pcall(function() UIX.rgPreview(initialGuard) end)
            if ST.rideGuard then pcall(function() UIX.rgSpawn(initialGuard) end) end
        end)

        trackConn(LP.CharacterAdded:Connect(function()
            task.wait(1.5)
            local defaultGuard = IS_PREMIUM and "Cherry Blossom" or "Forest"
            local initialGuard = ST.rideGuardId or defaultGuard
            if not IS_PREMIUM and initialGuard ~= "Lake" and initialGuard ~= "Forest" then
                initialGuard = "Forest"
            end
            if ST.rideGuard then pcall(function() UIX.rgSpawn(initialGuard) end) end
        end))

        -- ============ SINKRON ANTAR-PEMAKAI SCRIPT ============
        -- Model guard itu clone LOKAL. Dibuktikan live: dari klien lain, penunggang
        -- keliatan MELAYANG TANPA guard sama sekali. Jadi mustahil klien lain melihatnya
        -- lewat Roblox, dan satu-satunya jalur in-game (nembak remote game) ditolak
        -- karena AC-nya galak + bakal ngirim sampah ke pemain non-script.
        --
        -- YANG BIKIN INI MURAH: kita GAK PERLU sinkron posisi sama sekali. Posisi
        -- karakter udah direplikasi Roblox gratis — itu sebabnya penunggang keliatan
        -- melayang. Yang ditukar cuma SATU STRING: guard mana yang dipakai. Penempatan
        -- tetap dihitung lokal per-frame, jadi tetap mulus walau polling 15 detik.
        --
        -- Blok ini SENGAJA di luar gerbang IS_PREMIUM: yang non-premium tetap bisa
        -- MELIHAT penunggang lain, cuma gak bisa ride sendiri. Mereka juga gak ngirim
        -- apa-apa, karena ST.rideGuard-nya gak akan pernah nyala.
        UIX.RIDE_ENDPOINT = "https://www.nrlscript.com/api/ride"
        UIX.RIDE_POLL     = 1
        UIX.rgPeers       = {}    -- userId -> areaId
        UIX.rgPeerMounts  = {}    -- userId -> { model=, walk=, idle=, foot=, back=, sink=, area=, look=, lastPos= }

        function UIX.rgPeerBuild(areaId, uid)
            local src = UIX.rgSource(areaId)
            if not src then return nil end
            local c = src:Clone()
            c.Name = "SAE_GuardRidePeer_" .. tostring(uid)
            local ohrp = c:FindFirstChild("HumanoidRootPart")
            for _, d in ipairs(c:GetDescendants()) do
                if d:IsA("BasePart") then
                    d.Anchored = (d == ohrp); d.CanCollide = false; d.CastShadow = true
                end
            end
            local hum = c:FindFirstChildOfClass("Humanoid")
            if hum then hum.EvaluateStateMachine = false end
            c.Parent = Workspace

            local walk, idle
            local inner = c:FindFirstChild("Model")
            local ac = inner and inner:FindFirstChildOfClass("AnimationController")
            local animator = ac and ac:FindFirstChildOfClass("Animator")
            local gdir = req(RS:FindFirstChild("Data") and RS.Data:FindFirstChild("Guards"))
            local gd = gdir and (gdir.Directory or gdir)[areaId]
            if animator and gd then
                for _, t in ipairs(animator:GetPlayingAnimationTracks()) do pcall(function() t:Stop() end) end
                local wId = tostring(gd.WalkAnimation):match("(%d+)")
                local iId = tostring(gd.IdleAnimation):match("(%d+)")
                if wId then
                    local a = Instance.new("Animation"); a.AnimationId = "rbxassetid://" .. wId
                    local ok, tr = pcall(function() return animator:LoadAnimation(a) end)
                    if ok and tr then tr.Looped = true; tr.Priority = Enum.AnimationPriority.Movement; tr:Play(); walk = tr end
                end
                if iId then
                    local a = Instance.new("Animation"); a.AnimationId = "rbxassetid://" .. iId
                    local ok, tr = pcall(function() return animator:LoadAnimation(a) end)
                    if ok and tr then tr.Looped = true; tr.Priority = Enum.AnimationPriority.Idle; tr:Play(); idle = tr end
                end
            end

            local foot, back = UIX.rgSpan(c)
            return { model = c, walk = walk, idle = idle, foot = foot, back = back,
                     sink = UIX.rgSink(areaId, math.max(1, back - foot)), area = areaId,
                     look = Vector3.new(0, 0, -1), lastPos = Vector3.zero }
        end

        function UIX.rgPeerDrop(m)
            if not m then return end
            if m.walk then pcall(function() m.walk:Stop() end) end
            if m.idle then pcall(function() m.idle:Stop() end) end
            pcall(function() m.model:Destroy() end)
        end

        -- Penempatan mount pemain lain. Logikanya cerminan dari loop punya sendiri —
        -- BEDA-nya: kita gak boleh (dan gak bisa) menggeser karakter mereka. Posisi
        -- mereka sudah termasuk lift, karena klien mereka yang mengangkat dan Roblox
        -- mereplikasikannya ke kita.
        function UIX.rgPeerStep(m, r, dt, rayParams)
            if not (m and m.model and m.model.Parent and r) then return end
            local d = r.Position - m.lastPos
            m.lastPos = r.Position
            local flat = Vector3.new(d.X, 0, d.Z)
            local moveSpeed = flat.Magnitude / math.max(dt, 1 / 240)

            if flat.Magnitude > 0.05 then
                local blended = m.look:Lerp(flat.Unit, math.clamp(dt * 12.0, 0.05, 1.0))
                if blended.Magnitude > 0.01 then m.look = blended.Unit end
            end

            if m.walk and m.idle then
                if moveSpeed > 1.5 then
                    m.walk:AdjustWeight(1.0, 0.1); m.idle:AdjustWeight(0.0, 0.1)
                    m.walk:AdjustSpeed(math.clamp(moveSpeed / 28, 0.5, 2.5))
                else
                    m.walk:AdjustWeight(0.0, 0.15); m.idle:AdjustWeight(1.0, 0.15)
                end
            elseif m.walk then
                m.walk:AdjustSpeed(moveSpeed > 1.5 and math.clamp(moveSpeed / 28, 0.5, 2.5) or 0.6)
            end

            local lift = math.max(0, (m.back - m.foot) - m.sink)
            rayParams.FilterDescendantsInstances = { r.Parent, m.model }
            local hit = Workspace:Raycast(Vector3.new(r.Position.X, r.Position.Y + 4, r.Position.Z),
                                          Vector3.new(0, -(lift + 35), 0), rayParams)
            if not hit or hit.Position.Y > (r.Position.Y + 2) then
                hit = Workspace:Raycast(Vector3.new(r.Position.X, r.Position.Y - lift + 2, r.Position.Z),
                                        Vector3.new(0, -30, 0), rayParams)
            end
            local groundY = (hit and hit.Position.Y < (r.Position.Y + 2)) and hit.Position.Y or 67.57
            local inAir = (r.Position.Y - groundY) > (lift + 12)

            local pivotY = inAir and (r.Position.Y - 3 - m.back + m.sink) or (groundY - m.foot)
            local base = Vector3.new(r.Position.X, pivotY, r.Position.Z)
            local cf = CFrame.lookAt(base, base + m.look)
            if inAir then cf = cf * CFrame.Angles(math.rad(-15), 0, 0) end
            m.model:PivotTo(cf)
        end

        task.spawn(function()
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            while alive() do
                local dt = RunService.RenderStepped:Wait()
                local peers, mounts = UIX.rgPeers or {}, UIX.rgPeerMounts
                for uid, areaId in pairs(peers) do
                    local plr = Players:GetPlayerByUserId(uid)
                    local r = plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    if r then
                        local m = mounts[uid]
                        if not m or m.area ~= areaId or not (m.model and m.model.Parent) then
                            UIX.rgPeerDrop(m)
                            mounts[uid] = UIX.rgPeerBuild(areaId, uid)
                            m = mounts[uid]
                        end
                        UIX.rgPeerStep(m, r, dt, rayParams)
                    elseif mounts[uid] then
                        UIX.rgPeerDrop(mounts[uid]); mounts[uid] = nil
                    end
                end
                for uid, m in pairs(mounts) do
                    if not peers[uid] then UIX.rgPeerDrop(m); mounts[uid] = nil end
                end
            end
        end)

        -- Satu request = kirim status kita SEKALIGUS terima daftar penunggang lain.
        function UIX.rgSync(active)
            local hr = (syn and syn.request) or (http and http.request) or http_request or request
            if type(hr) ~= "function" then return end
            local key
            pcall(function()
                if type(isfile) == "function" and isfile("nr_loader_key.txt") and type(readfile) == "function" then
                    local raw = readfile("nr_loader_key.txt")
                    if raw and raw ~= "" then key = (raw:match("^([^|\r\n]+)") or raw):gsub("%s+", "") end
                end
            end)
            if not key then return end

            local body
            if not pcall(function()
                body = HS:JSONEncode({ key = key, job = tostring(game.JobId), uid = LP.UserId,
                                       guard = active and (ST.rideGuardId or "Cherry Blossom") or nil })
            end) then return end

            local res
            if not pcall(function()
                res = hr({ Url = UIX.RIDE_ENDPOINT, Method = "POST",
                           Headers = { ["Content-Type"] = "application/json" }, Body = body })
            end) then return end
            if not (res and res.Body) then return end

            local data
            if not pcall(function() data = HS:JSONDecode(res.Body) end) then return end
            local fresh = {}
            for _, e in ipairs((type(data) == "table" and data.riders) or {}) do
                local uid = tonumber(e.uid)
                if uid and uid ~= LP.UserId and e.guard then fresh[uid] = tostring(e.guard) end
            end
            UIX.rgPeers = fresh
        end

        task.spawn(function()
            task.wait(6)   -- kasih waktu key & karakter kebaca dulu
            local wasActive = nil
            while alive() do
                local active = ST.rideGuard and true or false
                -- Dikirim tiap putaran; Worker yang mutusin perlu nulis ke KV atau engga
                -- (nulis cuma kalau guard-nya berubah). Jadi polling biasa = nol write.
                pcall(UIX.rgSync, active)
                if wasActive and not active then
                    for uid, m in pairs(UIX.rgPeerMounts) do UIX.rgPeerDrop(m); UIX.rgPeerMounts[uid] = nil end
                    UIX.rgPeers = {}
                end
                wasActive = active
                task.wait(UIX.RIDE_POLL)
            end
        end)
    end


return UIX.rgPage
