do
    local auth = "VQMPJAYZ_KEYV3_OFFICIAL_2025"
    task.spawn(function()
        task.wait(3)
        assert(loadstring("return '" .. auth .. "'")() == auth, "Unauthorized modification detected")
    end)
end

local AntiHTTPSpy = {}
AntiHTTPSpy.ProtectedURLs = {}
AntiHTTPSpy.Active = false

function AntiHTTPSpy:Protect(url)
    if not url or #url < 10 then return end
    self.ProtectedURLs[url] = true

    if not self.Active then
        self.Active = true
        self:HookClipboard()
    end
end

function AntiHTTPSpy:HookClipboard()
    local clipboardFuncs = {"setclipboard", "toclipboard", "set_clipboard", "writeclipboard"}

    for _, funcName in ipairs(clipboardFuncs) do
        pcall(function()
            local env = getgenv and getgenv() or _G
            if env[funcName] then
                local original = env[funcName]
                env[funcName] = function(content)
                    if type(content) == "string" then
                        for url in pairs(AntiHTTPSpy.ProtectedURLs) do
                            if content:find(url, 1, true) or content == url then
                                game.Players.LocalPlayer:Kick("HTTP Logger Detected")
                                while true do task.wait() end
                            end
                        end
                    end
                    return original(content)
                end
            end
        end)
    end
end

local KeySystem = {}

local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local HttpService = game:GetService('HttpService')
local Players = game:GetService('Players')
local CoreGui = game:GetService('CoreGui')
local RunService = game:GetService('RunService')
local LocalPlayer = Players.LocalPlayer

local AllClipboards = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set)

local KeyUI = game:GetObjects('rbxassetid://82003485513802')[1]
KeyUI.Enabled = true

local actionExecuting = false
local activeTweens = {}

if game:GetService('RunService'):IsStudio() then
    function gethui() return KeyUI end
    function writefile() end
    function isfolder() return false end
    function makefolder() end
    function isfile() return false end
    function readfile() return '' end
    function setclipboard(text) print("Clipboard set to: " .. tostring(text)) end
end

local function ParentGUI(Gui)
    local success = pcall(function()
        if get_hidden_gui or gethui then
            local hiddenUI = get_hidden_gui or gethui
            Gui.Parent = hiddenUI()
        elseif syn and syn.protect_gui then
            syn.protect_gui(Gui)
            Gui.Parent = CoreGui
        else
            Gui.Parent = CoreGui
        end
    end)

    if not success then
        Gui.Parent = LocalPlayer:FindFirstChildWhichIsA('PlayerGui')
    end
end

local ArrayFieldFolder = 'ArrayField'
local ConfigurationExtension = '.rfld'

local function GetCustomHWID(salt)
    salt = salt or "default"
    local baseId = game:GetService("RbxAnalyticsService"):GetClientId()
    local result = ""

    local saltModifier = 0
    for i = 1, #salt do
        saltModifier = saltModifier + string.byte(salt:sub(i, i)) * i
    end

    for i = 1, #baseId do
        local char = baseId:sub(i, i)
        local saltOffset = (saltModifier + i) % 10

        if char:match("%d") then
            local digit = tonumber(char)
            local newDigit = (digit + saltOffset) % 10
            result = result .. tostring(newDigit)
        else
            local ascii = string.byte(char)
            if char:match("%a") then
                local shiftAmount = (i * 3 + saltModifier) % 26
                local base = char:match("%u") and 65 or 97
                local shifted = ((ascii - base + shiftAmount) % 26) + base
                result = result .. string.char(shifted)
            else
                result = result .. char
            end
        end
    end

    return result
end

local function GetIPAddress()
    local success, ip = pcall(function()
        return game:HttpGet("https://api.ipify.org")
    end)

    if success and ip and #ip > 0 then
        return ip
    end

    return nil
end

local function CheckVIPStatus(Settings)
    if not Settings.VIP or not Settings.VIP.Enabled then
        return false
    end

    local currentHWID = GetCustomHWID(Settings.HWIDSalt or "default")

    if Settings.VIP.PastebinURL then
        AntiHTTPSpy:Protect(Settings.VIP.PastebinURL)

        local success, vipList = pcall(function()
            return game:HttpGet(Settings.VIP.PastebinURL)
        end)

        if success and vipList then
            local jsonSuccess, decodedList = pcall(function()
                return HttpService:JSONDecode(vipList)
            end)

            if jsonSuccess and type(decodedList) == "table" then
                for _, hwid in ipairs(decodedList) do
                    if tostring(hwid) == currentHWID then
                        return true
                    end
                end
            else
                for hwid in vipList:gmatch("[^\r\n]+") do
                    hwid = hwid:gsub("^%s*(.-)%s*$", "%1")
                    if hwid == currentHWID then
                        return true
                    end
                end
            end
        end
    end

    if Settings.VIP.LocalList then
        for _, hwid in ipairs(Settings.VIP.LocalList) do
            if hwid == currentHWID then
                return true
            end
        end
    end

    return false
end

local function cleanupTweens()
    for i = #activeTweens, 1, -1 do
        local tween = activeTweens[i]
        if tween then
            tween:Cancel()
        end
        table.remove(activeTweens, i)
    end
end

local function createTween(object, tweenInfo, properties)
    local tween = TweenService:Create(object, tweenInfo, properties)
    table.insert(activeTweens, tween)
    return tween
end

local function IsKeyStillValid(savedData, durationHours)
    if not durationHours or durationHours <= 0 then
        return true, savedData
    end

    local success, keyData = pcall(function()
        return HttpService:JSONDecode(savedData)
    end)

    if success and type(keyData) == "table" and keyData.key and keyData.savedAt then
        local currentTime = os.time()
        local elapsedSeconds = currentTime - keyData.savedAt
        local elapsedHours = elapsedSeconds / 3600

        if elapsedHours < durationHours then
            local remainingHours = durationHours - elapsedHours
            return true, keyData.key, remainingHours
        else
            return false, keyData.key, 0
        end
    else
        if durationHours and durationHours > 0 then
            return false, savedData, 0
        end
        return true, savedData
    end
end

local function SaveKeyWithTimestamp(filePath, key, useDuration)
    if useDuration then
        local keyData = {
            key = key,
            savedAt = os.time()
        }
        writefile(filePath, HttpService:JSONEncode(keyData))
    else
        writefile(filePath, key)
    end
end

local function ValidateKeyWithServer(key, validateURL)
    local encodedKey = HttpService:UrlEncode(key)
    local url = validateURL .. "?key=" .. encodedKey

    local success, result = pcall(function()
        return game:HttpGet(url)
    end)

    if success and result then
        return result:lower():gsub("%s+", "") == "true"
    end

    return false
end

local function ParseTrialDuration(value)
    if type(value) == "number" then
        if value <= 0 then return 0 end
        return math.floor(value * 3600)
    end
    local s = tostring(value or ""):lower():gsub("%s+", "")
    if s == "" or s == "0" or s == "off" or s == "none" then
        return 0
    end
    if s:match("^%d+$") then
        return tonumber(s) * 3600
    end
    local total = 0
    for num, unit in s:gmatch("(%d+)([smhdw])") do
        num = tonumber(num)
        if unit == "s" then
            total = total + num
        elseif unit == "m" then
            total = total + num * 60
        elseif unit == "h" then
            total = total + num * 3600
        elseif unit == "d" then
            total = total + num * 86400
        elseif unit == "w" then
            total = total + num * 604800
        end
    end
    return total
end

local function CheckLocalTrial(Settings)
    local trial = Settings.Trial
    if type(trial) ~= "table" or not trial.Enabled then
        return false
    end

    local duration = ParseTrialDuration(trial.Duration)
    if duration <= 0 then
        return false
    end

    local hwid = GetCustomHWID(Settings.HWIDSalt or "default")
    local path = ArrayFieldFolder .. '/Key System' .. '/' .. (Settings.FileName or "DefaultKey") .. "_trial" .. ConfigurationExtension

    if not isfolder(ArrayFieldFolder) then
        makefolder(ArrayFieldFolder)
    end
    if not isfolder(ArrayFieldFolder .. '/Key System') then
        makefolder(ArrayFieldFolder .. '/Key System')
    end

    if isfile(path) then
        local raw = readfile(path)
        local ok, data = pcall(function()
            return HttpService:JSONDecode(raw)
        end)
        if ok and type(data) == "table" and data.startedAt and data.duration then
            if data.hwid and data.hwid ~= hwid then
                return false
            end
            return os.time() < (data.startedAt + data.duration)
        end
    end

    pcall(function()
        writefile(path, HttpService:JSONEncode({
            hwid = hwid,
            startedAt = os.time(),
            duration = duration,
        }))
    end)
    return true
end

function ValidateKeyWithDiscord(key, settings)
    local hwid = GetCustomHWID(settings.HWIDSalt or "default")
    local url = settings.DiscordValidation.ValidateURL

    AntiHTTPSpy:Protect(url)
    AntiHTTPSpy:Protect(settings.DiscordValidation.APISecret or "")

    local httpRequest = (syn and syn.request) or (http and http.request) or request or http_request or (fluxus and fluxus.request)

    if not httpRequest then
        return false, "Executor does not support HTTP requests"
    end

    local payload = HttpService:JSONEncode({
        key = key,
        hwid = hwid,
        secret = settings.DiscordValidation.APISecret
    })

    local success, result = pcall(function()
        return httpRequest({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = payload
        })
    end)

    if not success then
        return false, "HTTP request failed"
    end

    if not result then
        return false, "No response from server"
    end

    local body = result.Body or result.body
    if not body then
        return false, "Empty response from server"
    end

    local decodeSuccess, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if not decodeSuccess or type(data) ~= "table" then
        return false, "Invalid response from server"
    end
    print("Validation response:", body)
    return data.valid == true, data.message or "Unknown error"
end

function KeySystem:CreateKeyUI(Settings)
    if not Settings then
        error('KeySystem: Settings table required')
    end

    if CheckVIPStatus(Settings) then
        Settings.Callback()
        return
    end

    if CheckLocalTrial(Settings) then
        Settings.Callback()
        return
    end

    local useDiscordValidation = type(Settings.DiscordValidation) == "table" and Settings.DiscordValidation.Enabled
    local useServerValidation = type(Settings.ValidateKeyFromServer) == "table" and Settings.ValidateKeyFromServer.Enabled

    if not Settings.Keys and not useServerValidation and not useDiscordValidation then
        error('KeySystem: Keys array required (unless ValidateKeyFromServer or DiscordValidation is enabled)')
    end

    Settings.Keys = Settings.Keys or {}

    if not Settings.Callback then
        error('KeySystem: Callback function required')
    end

    Settings.Title = Settings.Title or 'Key System'
    Settings.Subtitle = Settings.Subtitle or 'Enter Key'
    Settings.Note = Settings.Note or 'No instructions provided'
    Settings.SaveKey = Settings.SaveKey or false
    Settings.SaveKeyDuration = Settings.SaveKeyDuration or 0
    Settings.FileName = Settings.FileName or 'DefaultKey'

    if type(Settings.ValidateKeyFromServer) == "table" then
        Settings.ValidateKeyFromServer.Enabled = Settings.ValidateKeyFromServer.Enabled ~= false
        Settings.ValidateKeyFromServer.ValidateURL = Settings.ValidateKeyFromServer.ValidateURL or ""
    else
        Settings.ValidateKeyFromServer = {
            Enabled = Settings.ValidateKeyFromServer == true,
            ValidateURL = ""
        }
    end

    if type(Settings.DiscordValidation) ~= "table" then
        Settings.DiscordValidation = {
            Enabled = false,
            ValidateURL = "",
            APISecret = ""
        }
    end

    if Settings.SaveKey then
        if not isfolder(ArrayFieldFolder) then
            makefolder(ArrayFieldFolder)
        end
        if not isfolder(ArrayFieldFolder .. '/Key System') then
            makefolder(ArrayFieldFolder .. '/Key System')
        end
    end

    if Settings.SaveKey then
        local keyFilePath = ArrayFieldFolder .. '/Key System' .. '/' .. Settings.FileName .. ConfigurationExtension
        if isfile(keyFilePath) then
            local savedData = readfile(keyFilePath)
            if savedData and #savedData > 0 then
                local isValid, savedKey, remainingHours = IsKeyStillValid(savedData, Settings.SaveKeyDuration)

                if isValid and savedKey and #savedKey > 0 then
                    if useDiscordValidation then
                        local discordValid, discordMsg = ValidateKeyWithDiscord(savedKey, Settings)
                        if discordValid then
                            Settings.Callback()
                            return
                        else
                            pcall(function()
                                delfile(keyFilePath)
                            end)
                        end
                    else
                        Settings.Callback()
                        return
                    end
                else
                    pcall(function()
                        delfile(keyFilePath)
                    end)
                end
            end
        end
    end

    ParentGUI(KeyUI)

    local KeyMain = KeyUI.Main
    KeyMain.Title.Text = Settings.Title
    KeyMain.Subtitle.Text = Settings.Subtitle
    KeyMain.NoteMessage.Text = Settings.Note

    local originalEyeImage = KeyMain.HideP.Image
    local originalEyeRectSize = KeyMain.HideP.ImageRectSize
    local originalEyeRectOffset = KeyMain.HideP.ImageRectOffset

    KeyMain.Size = UDim2.new(0, 467, 0, 175)
    KeyMain.BackgroundTransparency = 1
    KeyMain.EShadow.ImageTransparency = 1
    KeyMain.Title.TextTransparency = 1
    KeyMain.Subtitle.TextTransparency = 1
    KeyMain.KeyNote.TextTransparency = 1
    KeyMain.Input.BackgroundTransparency = 1
    KeyMain.Input.UIStroke.Transparency = 1
    KeyMain.Input.InputBox.TextTransparency = 1
    KeyMain.Input.HidenInput.TextTransparency = 1
    KeyMain.Input.HidenInput.Position = UDim2.new(0.517499566, 0, 0.5, 0)
    KeyMain.NoteTitle.TextTransparency = 1
    KeyMain.NoteMessage.TextTransparency = 1
    KeyMain.Hide.ImageTransparency = 1
    KeyMain.HideP.ImageTransparency = 1
    KeyMain.Actions.Template.Visible = false
    KeyMain.Input.Reset.ImageTransparency = 1

    KeyMain.Input.InputBox.PlaceholderText = "Enter Key Here"
    KeyMain.Input.InputBox.TextYAlignment = Enum.TextYAlignment.Center
    KeyMain.Input.InputBox.Size = UDim2.new(1, -40, 1, 0)
    KeyMain.Input.InputBox.Position = UDim2.new(0.450499594, 0, 0.5, 0)
    KeyMain.Input.InputBox.TextScaled = false
    KeyMain.Input.InputBox.TextSize = 14
    KeyMain.Input.HidenInput.Size = UDim2.new(1, -40, 1, 0)
    KeyMain.Input.HidenInput.Position = UDim2.new(0.450499594, 0, 0.5, 0)
    KeyMain.Input.HidenInput.TextScaled = false
    KeyMain.Input.HidenInput.TextSize = 14

    local CaretLabel = Instance.new("TextLabel")
    CaretLabel.Name = "Caret"
    CaretLabel.Parent = KeyMain.Input
    CaretLabel.AnchorPoint = Vector2.new(0, 0.5)
    CaretLabel.BackgroundTransparency = 1
    CaretLabel.Position = UDim2.new(0, 5, 0.48, 0)
    CaretLabel.Size = UDim2.new(0, 20, 1, 0)
    CaretLabel.Font = Enum.Font.Gotham
    CaretLabel.Text = "|"
    CaretLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    CaretLabel.TextScaled = false
    CaretLabel.TextSize = 18
    CaretLabel.TextTransparency = 1
    CaretLabel.TextXAlignment = Enum.TextXAlignment.Left
    CaretLabel.Visible = false
    CaretLabel.ZIndex = 10

    local ResetButtonWrapper = Instance.new("TextButton")
    ResetButtonWrapper.Name = "ResetWrapper"
    ResetButtonWrapper.Parent = KeyMain.Input
    ResetButtonWrapper.BackgroundTransparency = 1
    ResetButtonWrapper.AnchorPoint = KeyMain.Input.Reset.AnchorPoint
    ResetButtonWrapper.Position = KeyMain.Input.Reset.Position
    ResetButtonWrapper.Size = UDim2.new(0, 30, 0, 30)
    ResetButtonWrapper.Text = ""
    ResetButtonWrapper.ZIndex = 15
    ResetButtonWrapper.Visible = false
    ResetButtonWrapper.AutoButtonColor = false

    KeyMain.Input.Reset.ZIndex = 14

    local VisibilityNotification = Instance.new("TextLabel")
    VisibilityNotification.Name = "VisibilityNotification"
    VisibilityNotification.Parent = KeyMain.Input
    VisibilityNotification.AnchorPoint = Vector2.new(0, 0)
    VisibilityNotification.Position = UDim2.new(0, 50, 0, -23)
    VisibilityNotification.Size = UDim2.new(0, 120, 0, 20)
    VisibilityNotification.BackgroundTransparency = 1
    VisibilityNotification.Font = Enum.Font.Gotham
    VisibilityNotification.Text = ""
    VisibilityNotification.TextColor3 = Color3.fromRGB(160, 160, 160)
    VisibilityNotification.TextScaled = false
    VisibilityNotification.TextSize = 10
    VisibilityNotification.TextTransparency = 1
    VisibilityNotification.TextXAlignment = Enum.TextXAlignment.Left
    VisibilityNotification.Visible = false

    if Settings.Action then
        local Action = KeyMain.Actions.Template
        Action.Text = 'Click here to copy key link'
        Action.Visible = true
        Action.Parent = KeyMain.Actions
        Action.TextStrokeTransparency = 0.5
        Action.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        Action.ZIndex = 15
        Action.Font = Enum.Font.GothamBold
        Action.TextScaled = true
        Action.BackgroundTransparency = 1

        local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
        local hoverTimer = nil

        Action.MouseButton1Click:Connect(function()
            if actionExecuting then
                return
            end
            actionExecuting = true

            if AllClipboards and Settings.Action.Link then
                AllClipboards(Settings.Action.Link)
            end

            local originalText = Action.Text
            Action.Text = 'Copied!'

            task.spawn(function()
                task.wait(0.45)
                Action.Text = originalText
                actionExecuting = false
            end)
        end)

        Action.MouseEnter:Connect(function()
            if actionExecuting then
                return
            end
            createTween(Action, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(185, 185, 185)}):Play()

            if isMobile then
                hoverTimer = task.delay(0.1, function()
                    if actionExecuting then
                        return
                    end
                    actionExecuting = true

                    if AllClipboards and Settings.Action.Link then
                        AllClipboards(Settings.Action.Link)
                    end

                    local originalText = Action.Text
                    Action.Text = 'Copied!'

                    task.spawn(function()
                        task.wait(0.45)
                        Action.Text = originalText
                        actionExecuting = false
                    end)
                end)
            end
        end)

        Action.MouseLeave:Connect(function()
            if actionExecuting then
                return
            end
            createTween(Action, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(105, 105, 105)}):Play()

            if hoverTimer then
                task.cancel(hoverTimer)
                hoverTimer = nil
            end
        end)
    end

    self:AnimateIn(KeyMain, Settings, originalEyeImage, originalEyeRectSize, originalEyeRectOffset)
    self:SetupInputHandlers(KeyMain, Settings, originalEyeImage, originalEyeRectSize, originalEyeRectOffset, ResetButtonWrapper)
end

function KeySystem:AnimateIn(KeyMain, Settings, originalEyeImage, originalEyeRectSize, originalEyeRectOffset)
    local visibilityPrefPath = ArrayFieldFolder .. '/Key System' .. '/visibility_pref' .. ConfigurationExtension
    local savedVisibility = true

    if isfile(visibilityPrefPath) then
        local savedPref = readfile(visibilityPrefPath)
        savedVisibility = savedPref == "true"
    end

    if savedVisibility then
        KeyMain.HideP.Image = "rbxassetid://16898613353"
        KeyMain.HideP.ImageRectSize = Vector2.new(48, 48)
        KeyMain.HideP.ImageRectOffset = Vector2.new(820, 514)
    else
        KeyMain.HideP.Image = originalEyeImage
        KeyMain.HideP.ImageRectSize = originalEyeRectSize
        KeyMain.HideP.ImageRectOffset = originalEyeRectOffset
    end

    task.spawn(function()
        createTween(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {BackgroundTransparency = 0,Size = UDim2.new(0, 500, 0, 187)}):Play()
        createTween(KeyMain.EShadow, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {ImageTransparency = 0.5}):Play()
        task.wait(0.05)
        createTween(KeyMain.Title, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
        createTween(KeyMain.Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
        task.wait(0.05)
        createTween(KeyMain.KeyNote, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
        createTween(KeyMain.Input, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 0}):Play()
        createTween(KeyMain.Input.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quint),{Transparency = 0}):Play()

        if savedVisibility then
            createTween(KeyMain.Input.HidenInput, TweenInfo.new(0.5, Enum.EasingStyle.Quint),{TextTransparency = 0}):Play()
        else
            createTween(KeyMain.Input.InputBox, TweenInfo.new(0.5, Enum.EasingStyle.Quint),{TextTransparency = 0}):Play()
        end

        task.wait(0.05)
        createTween(KeyMain.NoteTitle, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
        createTween(KeyMain.NoteMessage, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
        createTween(KeyMain.Actions.Template, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
        task.wait(0.15)
        createTween(KeyMain.Hide, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency = 0.3}):Play()
        createTween(KeyMain.HideP, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency = 0.3}):Play()
        KeyMain.Input.Reset.Visible = false
        KeyMain.Input.ResetWrapper.Visible = false
    end)
end

function KeySystem:AnimateOut(KeyMain, Settings, callback)
    task.spawn(function()
        createTween(KeyMain.Actions.Template, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
        createTween(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {BackgroundTransparency = 1, Size = UDim2.new(0, 467, 0, 175)}):Play()
        createTween(KeyMain.EShadow, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
        createTween(KeyMain.Title, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
        createTween(KeyMain.Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
        createTween(KeyMain.KeyNote, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
        createTween(KeyMain.Input, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
        createTween(KeyMain.Input.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quint),{Transparency = 1}):Play()
        createTween(KeyMain.Input.InputBox, TweenInfo.new(0.5, Enum.EasingStyle.Quint),{TextTransparency = 1}):Play()
        createTween(KeyMain.Input.HidenInput, TweenInfo.new(0.5, Enum.EasingStyle.Quint),{TextTransparency = 1}):Play()
        createTween(KeyMain.NoteTitle, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
        createTween(KeyMain.NoteMessage, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
        createTween(KeyMain.Hide, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
        createTween(KeyMain.HideP, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
        createTween(KeyMain.Input.Reset, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
        createTween(KeyMain.Input.Caret, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
        task.wait(0.51)
        if callback then
            callback()
        end
        KeyMain.Hide.Visible = false
        cleanupTweens()
        KeyUI:Destroy()
    end)
end

function KeySystem:SetupInputHandlers(KeyMain, Settings, originalEyeImage, originalEyeRectSize, originalEyeRectOffset, ResetButtonWrapper)
    local Hidden = true

    local visibilityPrefPath = ArrayFieldFolder .. '/Key System' .. '/visibility_pref' .. ConfigurationExtension
    if isfile(visibilityPrefPath) then
        local savedPref = readfile(visibilityPrefPath)
        Hidden = savedPref == "true"
    end

    local resetVisible = false
    local caretConnection = nil

    local function createCaret()
        if not Hidden or #KeyMain.Input.InputBox.Text > 0 then return end

        KeyMain.Input.Caret.Visible = true
        createTween(KeyMain.Input.Caret, TweenInfo.new(0.2), {TextTransparency = 0.2}):Play()

        caretConnection = RunService.Heartbeat:Connect(function()
            if math.floor(tick() * 2) % 2 == 0 then
                KeyMain.Input.Caret.TextTransparency = 0.2
            else
                KeyMain.Input.Caret.TextTransparency = 1
            end
        end)
    end

    local function removeCaret()
        if caretConnection then
            caretConnection:Disconnect()
            caretConnection = nil
        end
        createTween(KeyMain.Input.Caret, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        task.wait(0.2)
        KeyMain.Input.Caret.Visible = false
    end

    local function animateResetButton(show)
        if show and not resetVisible then
            resetVisible = true
            KeyMain.Input.Reset.Visible = true
            ResetButtonWrapper.Visible = true
            createTween(KeyMain.Input.Reset, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {
                ImageTransparency = 0.5
            }):Play()
        elseif not show and resetVisible then
            resetVisible = false
            createTween(KeyMain.Input.Reset, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {
                ImageTransparency = 1
            }):Play()
            task.wait(0.6)
            KeyMain.Input.Reset.Visible = false
            ResetButtonWrapper.Visible = false
        end
    end

    KeyMain.Input.InputBox:GetPropertyChangedSignal('Text'):Connect(function()
        KeyMain.Input.HidenInput.Text = string.rep('•', #KeyMain.Input.InputBox.Text)
        animateResetButton(#KeyMain.Input.InputBox.Text > 0)

        if #KeyMain.Input.InputBox.Text > 0 then
            removeCaret()
        elseif KeyMain.Input.InputBox:IsFocused() and Hidden then
            createCaret()
        end
    end)

    KeyMain.Input.InputBox.Focused:Connect(function()
        if Hidden and #KeyMain.Input.InputBox.Text == 0 then
            createCaret()
        end
    end)

    KeyMain.Input.InputBox.FocusLost:Connect(function()
        removeCaret()
    end)

    ResetButtonWrapper.MouseButton1Click:Connect(function()
        KeyMain.Input.InputBox.Text = ''
        KeyMain.Input.HidenInput.Text = ''
        animateResetButton(false)
        removeCaret()
    end)

    ResetButtonWrapper.MouseEnter:Connect(function()
        if resetVisible then
            createTween(KeyMain.Input.Reset, TweenInfo.new(0.25), {
                ImageTransparency = 0.3
            }):Play()
        end
    end)

    ResetButtonWrapper.MouseLeave:Connect(function()
        if resetVisible then
            createTween(KeyMain.Input.Reset, TweenInfo.new(0.25), {
                ImageTransparency = 0.5
            }):Play()
        end
    end)

    KeyMain.Input.InputBox.FocusLost:Connect(function(EnterPressed)
        if not EnterPressed or #KeyMain.Input.InputBox.Text == 0 then
            return
        end

        local KeyFound = false
        local EnteredKey = KeyMain.Input.InputBox.Text
        local FailMessage = nil

        if Settings.DiscordValidation and Settings.DiscordValidation.Enabled then
            KeyFound, FailMessage = ValidateKeyWithDiscord(EnteredKey, Settings)
        elseif Settings.ValidateKeyFromServer and Settings.ValidateKeyFromServer.Enabled then
            KeyFound = ValidateKeyWithServer(EnteredKey, Settings.ValidateKeyFromServer.ValidateURL)
        else
            for _, ValidKey in ipairs(Settings.Keys) do
                if EnteredKey == ValidKey then
                    KeyFound = true
                    break
                end
            end
        end

        if KeyFound then
            self:AnimateOut(KeyMain, Settings, function()
                if Settings.SaveKey then
                    task.spawn(function()
                        local keyFilePath = ArrayFieldFolder .. '/Key System' .. '/' .. Settings.FileName .. ConfigurationExtension
                        local useDuration = Settings.SaveKeyDuration and Settings.SaveKeyDuration > 0
                        SaveKeyWithTimestamp(keyFilePath, EnteredKey, useDuration)
                    end)
                end

                Settings.Callback()
            end)
        else
            KeyMain.Input.InputBox.Text = ''

            local originalPos = KeyMain.Position
            local shakeDistance = 10

            task.spawn(function()
                local shakeSequence = {
                    {pos = UDim2.new(originalPos.X.Scale, originalPos.X.Offset - shakeDistance, originalPos.Y.Scale,originalPos.Y.Offset), time = 0.05},
                    {pos = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + shakeDistance, originalPos.Y.Scale, originalPos.Y.Offset), time = 0.05},
                    {pos = UDim2.new(originalPos.X.Scale, originalPos.X.Offset - shakeDistance / 2, originalPos.Y.Scale, originalPos.Y.Offset), time = 0.05},
                    {pos = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + shakeDistance / 2, originalPos.Y.Scale, originalPos.Y.Offset),time = 0.05},
                    {pos = originalPos, time = 0.1},
                }

                for _, shake in ipairs(shakeSequence) do
                    createTween(KeyMain, TweenInfo.new(shake.time, Enum.EasingStyle.Quad),{Position = shake.pos}):Play()
                    task.wait(shake.time)
                end
            end)
        end
    end)

    KeyMain.HideP.MouseButton1Click:Connect(function()
        removeCaret()

        if Hidden then
            createTween(KeyMain.HideP, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
            task.wait(0.15)

            KeyMain.HideP.Image = originalEyeImage
            KeyMain.HideP.ImageRectSize = originalEyeRectSize
            KeyMain.HideP.ImageRectOffset = originalEyeRectOffset

            createTween(KeyMain.HideP, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageTransparency = 0.3}):Play()

            createTween(KeyMain.Input.HidenInput, TweenInfo.new(0.5, Enum.EasingStyle.Quint),{TextTransparency = 1}):Play()
            createTween(KeyMain.Input.InputBox, TweenInfo.new(0.5, Enum.EasingStyle.Quint),{TextTransparency = 0}):Play()
            Hidden = false

            KeyMain.Input.VisibilityNotification.Text = "(key visibility: on)"
        else
            createTween(KeyMain.HideP, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
            task.wait(0.15)

            KeyMain.HideP.Image = "rbxassetid://16898613353"
            KeyMain.HideP.ImageRectSize = Vector2.new(48, 48)
            KeyMain.HideP.ImageRectOffset = Vector2.new(820, 514)

            createTween(KeyMain.HideP, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageTransparency = 0.3}):Play()

            createTween(KeyMain.Input.HidenInput, TweenInfo.new(0.5, Enum.EasingStyle.Quint),{TextTransparency = 0}):Play()
            createTween(KeyMain.Input.InputBox, TweenInfo.new(0.5, Enum.EasingStyle.Quint),{TextTransparency = 1}):Play()
            Hidden = true

            if KeyMain.Input.InputBox:IsFocused() and #KeyMain.Input.InputBox.Text == 0 then
                createCaret()
            end

            KeyMain.Input.VisibilityNotification.Text = "(key visibility: hidden)"
        end

        KeyMain.Input.VisibilityNotification.Visible = true
        createTween(KeyMain.Input.VisibilityNotification, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()

        task.spawn(function()
            task.wait(1.5)
            createTween(KeyMain.Input.VisibilityNotification, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
            task.wait(0.3)
            KeyMain.Input.VisibilityNotification.Visible = false
        end)

        task.spawn(function()
            local visibilityPrefPath = ArrayFieldFolder .. '/Key System' .. '/visibility_pref' .. ConfigurationExtension
            writefile(visibilityPrefPath, tostring(Hidden))
        end)
    end)

    KeyMain.Hide.MouseButton1Click:Connect(function()
        removeCaret()
        self:AnimateOut(KeyMain, Settings)
    end)
end

return KeySystem
