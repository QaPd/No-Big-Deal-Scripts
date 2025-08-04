local plr = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera

local lazerWidth = 0.05
local raylazertype = true

-- Function to add a laser beam from an attachment
local function addLaser(attachment: Attachment)
	if not attachment or not attachment:IsA("Attachment") then return end

	local laserPart = Instance.new("Part")
	laserPart.Anchored = true
	laserPart.CanCollide = false
	laserPart.CastShadow = false
	laserPart.Material = Enum.Material.Neon
	laserPart.Color = Color3.fromRGB(255, 0, 0)
	laserPart.Size = Vector3.new(lazerWidth, lazerWidth, 1000)
	laserPart.Parent = workspace

	local function updateLaser()
		if not attachment or not attachment.Parent then
			laserPart:Destroy()
			return
		end

		local startPos = attachment.WorldCFrame.Position
		local direction = attachment.WorldCFrame.LookVector * 5000

		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {
			attachment.Parent.Parent, laserPart, workspace:FindFirstChild(plr.Name)
		}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.IgnoreWater = true

		local raycastResult = workspace:Raycast(startPos, direction, raycastParams)
		local hitPoint = raycastResult and raycastResult.Position or (startPos + direction)
		local laserLength = (hitPoint - startPos).Magnitude

		laserPart.Size = Vector3.new(lazerWidth, lazerWidth, laserLength)
		laserPart.CFrame = CFrame.new(startPos, hitPoint) * CFrame.new(0, 0, -laserLength / 2)
	end

	if raylazertype then
		RunService.Heartbeat:Connect(updateLaser)
	else
		RunService.Heartbeat:Connect(function()
			laserPart.CFrame = attachment.WorldCFrame + (attachment.WorldCFrame.LookVector * laserPart.Size.Z / 2)
		end)
	end
end

-- GUI Setup for Lasers
local library = loadstring(game:HttpGet('https://raw.githubusercontent.com/Eri-Yoshimi/Eri-s-Modular-Gui/refs/heads/main/v2.lua'))()
local lazerModule = library:Initialize({
	name = "Laser GUI",
	size = UDim2.new(0, 400, 0, 250),
	primaryColor = Color3.fromRGB(255, 0, 0),
	secondaryColor = Color3.fromRGB(80, 80, 80),
	backgroundColor = Color3.new(0, 0, 0),
	toggleBind = Enum.KeyCode.L
}):createNewModule("Lazers")

-- Toggle between ray type styles
local toggleRayType, toggled = lazerModule:AddToggle("Use Raycast Lasers")
toggleRayType.Activated:Connect(function()
	raylazertype = toggled:GetState()
end)

-- Example buttons for specific guns
local function setupGunLaser(name)
	lazerModule:AddButton(name .. " Laser").Activated:Connect(function()
		for _, g in workspace:GetChildren() do
			if g.Name == name and g:FindFirstChild("Root") and g.Root:FindFirstChild("Muzzle") then
				addLaser(g.Root.Muzzle)
			end
		end
	end)
end

setupGunLaser("Pistol")
setupGunLaser("Snub")
setupGunLaser("MAGNUM")
setupGunLaser("AceCarbine")
setupGunLaser("ToolboxMAC10")
setupGunLaser("Sniper")
setupGunLaser("DB")
setupGunLaser("AK47")

lazerModule:AddButton("All Lasers").Activated:Connect(function()
	for _, g in workspace:GetChildren() do
		if g:FindFirstChild("Root") and g.Root:FindFirstChild("Muzzle") then
			addLaser(g.Root.Muzzle)
		end
	end
end)
