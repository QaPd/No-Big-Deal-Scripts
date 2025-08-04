-- Settings
local toggleKey = Enum.KeyCode.P
local minESPsize = 2

local plr = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local library = loadstring(game:HttpGet('https://raw.githubusercontent.com/Eri-Yoshimi/Eri-s-Modular-Gui/refs/heads/main/v2.lua'))()

local Style = {
	name = "Cash ESP",
	size = UDim2.new(0, 500, 0, 300),
	primaryColor = Color3.fromRGB(40, 130, 40), -- softer green
	backgroundColor = Color3.fromRGB(20, 20, 20), -- dark gray
	draggable = true,
	toggleBind = toggleKey,
}

local window = library:Initialize(Style)
local espModule = window:createNewModule("ESP")

-- Globals
local ESPCache = {}
local borderThickness = 1
local espTextVisible = false
local cash = {}
local markers = {}
local showGroups = false

-- ESP Function
local function CreateESP(basepart, color)
	local newEspGui = Instance.new("BillboardGui", window.GUI)
	newEspGui.Adornee = basepart
	newEspGui.AlwaysOnTop = true
	newEspGui.Size = UDim2.new(1, 0, 1, 0)
	newEspGui.ResetOnSpawn = false
	task.delay(5, function()
		newEspGui.ResetOnSpawn = true
	end)

	local softenedColor = (color or basepart.Color):Lerp(Color3.new(0, 0, 0), 0.4)

	local espFrame = Instance.new("TextLabel", newEspGui)
	espFrame.Text = string.upper(string.sub(basepart.Parent.Name, 1, 1))
	espFrame.TextTransparency = espTextVisible and 0.2 or 1
	espFrame.TextScaled = true
	espFrame.Size = UDim2.new(1, 0, 1, 0)
	espFrame.BackgroundTransparency = 1
	espFrame.TextColor3 = softenedColor

	local stroke = Instance.new("UIStroke", espFrame)
	stroke.Color = softenedColor
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = borderThickness
	stroke.Transparency = espTextVisible and 0.8 or 1

	table.insert(ESPCache, newEspGui)
	return newEspGui
end

-- Distance Helper
local function getDistance(a, b)
	return (a.Position - b.Position).Magnitude
end

-- Group Averaging
local function getAveragePosition(group)
	local sum = Vector3.zero
	for _, part in ipairs(group) do
		sum += part.Position
	end
	return sum / #group
end

-- Update Group Markers
local function updateGroupMarkers(groups)
	while #markers > #groups do
		local m = table.remove(markers)
		if m.marker then m.marker:Destroy() end
	end

	for i, group in ipairs(groups) do
		if #group > 0 then
			local pos = getAveragePosition(group) + Vector3.new(0, 100, 0)
			if markers[i] then
				markers[i].marker.StudsOffsetWorldSpace = pos
				markers[i].text.Text = "$" .. #group
			else
				local gui = Instance.new("BillboardGui", window.GUI)
				gui.AlwaysOnTop = true
				gui.Size = UDim2.new(0, 50, 0, 50)
				gui.StudsOffsetWorldSpace = pos

				local text = Instance.new("TextLabel", gui)
				text.Text = "$" .. #group
				text.Size = UDim2.new(1, 0, 1, 0)
				text.BackgroundTransparency = 1
				text.TextColor3 = Color3.fromRGB(60, 180, 60)
				text.TextScaled = true
				text.TextTransparency = showGroups and 0 or 1

				markers[i] = {marker = gui, text = text}
			end
		end
	end
end

-- Group Logic
local function groupCashObjects()
	local groups = {}
	local visited = {}

	for _, c in ipairs(cash) do
		if c and c:IsDescendantOf(workspace) and not visited[c] then
			local group = {c}
			visited[c] = true
			for _, other in ipairs(cash) do
				if not visited[other] and getDistance(c, other) <= 25 then
					table.insert(group, other)
					visited[other] = true
				end
			end
			table.insert(groups, group)
		end
	end

	updateGroupMarkers(groups)
end

-- Scan Cash
local function scanCash(name)
	for _, obj in ipairs(workspace:GetDescendants()) do
		if string.lower(obj.Name) == name and obj:IsA("Model") then
			local part = obj:FindFirstChild("Root") or obj:FindFirstChildWhichIsA("BasePart")
			if part then table.insert(cash, part) end
		end
	end

	workspace.DescendantAdded:Connect(function(d)
		task.wait(1)
		if string.lower(d.Name) == name and d:IsA("Model") then
			local part = d:FindFirstChild("Root") or d:FindFirstChildWhichIsA("BasePart")
			if part then table.insert(cash, part) end
		end
	end)
end

-- Create ESP Toggle
local function createESPButton(label, nameMatch, partName, color)
	local createdESPs = {}
	local toggle, state = espModule:AddToggle(label)
	toggle.Activated:Connect(function()
		if not state:GetState() then
			for _, esp in createdESPs do esp:Destroy() end
			table.clear(createdESPs)
			return
		end

		for _, obj in ipairs(workspace:GetDescendants()) do
			if string.lower(obj.Name) == nameMatch and obj:IsA("Model") then
				local part = obj:FindFirstChild(partName)
				if part and part:IsA("BasePart") then
					local esp = CreateESP(part, color)
					table.insert(createdESPs, esp)
				end
			end
		end
	end)

	workspace.DescendantAdded:Connect(function(obj)
		if not state:GetState() then return end
		if string.lower(obj.Name) == nameMatch and obj:IsA("Model") then
			local part = obj:FindFirstChild(partName)
			if part and part:IsA("BasePart") then
				local esp = CreateESP(part, color)
				table.insert(createdESPs, esp)
			end
		end
	end)
end

-- UI Controls
local espTextToggle, espTextToggled = espModule:AddToggle("Show ESP Text")
espTextToggle.Activated:Connect(function()
	espTextVisible = espTextToggled:GetState()
	for _, gui in ipairs(ESPCache) do
		local text = gui:FindFirstChildOfClass("TextLabel")
		if text then
			text.TextTransparency = espTextVisible and 0 or 1
			local stroke = text:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Transparency = espTextVisible and 1 or 0 end
		end
	end
end)

local thicknessSlider = espModule:AddSlider("Border Thickness", 1, 5)
thicknessSlider.OnValueChanged:Connect(function(value)
	borderThickness = value
	for _, gui in ipairs(ESPCache) do
		local stroke = gui:FindFirstChildOfClass("TextLabel"):FindFirstChildOfClass("UIStroke")
		if stroke then stroke.Thickness = value end
	end
end)

local groupedCash, groupedCashToggled = espModule:AddToggle("Group Cash ESP")
groupedCash.Activated:Connect(function()
	showGroups = groupedCashToggled:GetState()
	for _, m in pairs(markers) do
		m.text.TextTransparency = showGroups and 0 or 1
	end
end)

-- Enable cash tracking
scanCash("cash")
scanCash("fakecash")
scanCash("disk")
scanCash("grenade")
scanCash("bottle")

createESPButton("Cash ESP", "cash", "Root", Color3.new(0, 1, 0))
createESPButton("Fake Cash ESP", "fakecash", "Root", Color3.new(1, 0.666667, 0))
createESPButton("Disk ESP", "disk", "Color", Color3.new(1, 0, 0))
createESPButton("Grenade ESP", "grenade", "Root", Color3.new(1, 0, 0))
createESPButton("Seltzer ESP", "bottle", "Fluid", Color3.new(0.666, 0, 0.498))

-- Continuously update grouped markers
RunService.Heartbeat:Connect(groupCashObjects)