-- Script Bay (Fly) hỗ trợ Mobile & PC
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local FlyEnabled = false
local FlySpeed = 60 -- Chỉnh tốc độ mặc định tại đây (nên để 50-80 để tránh bị giật lại)

local BodyGyro, BodyVelocity
local FlyConnection

-- Hàm bật bay
local function StartFly()
	local character = LocalPlayer.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not rootPart or not humanoid then return end

	if FlyConnection then FlyConnection:Disconnect() end
	if BodyGyro then BodyGyro:Destroy() end
	if BodyVelocity then BodyVelocity:Destroy() end

	FlyEnabled = true
	humanoid.PlatformStand = true

	BodyGyro = Instance.new("BodyGyro")
	BodyGyro.P = 9e4
	BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	BodyGyro.CFrame = rootPart.CFrame
	BodyGyro.Parent = rootPart

	BodyVelocity = Instance.new("BodyVelocity")
	BodyVelocity.Velocity = Vector3.zero
	BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	BodyVelocity.Parent = rootPart

	FlyConnection = RunService.RenderStepped:Connect(function()
		if not FlyEnabled or not character or not rootPart.Parent then
			return
		end

		local camCF = Camera.CFrame
		BodyGyro.CFrame = camCF

		local moveDir = humanoid.MoveDirection
		local vertical = 0

		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			vertical = 1
		elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			vertical = -1
		end

		if moveDir.Magnitude > 0 then
			local flatForward = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
			if flatForward.Magnitude > 0.001 then
				flatForward = flatForward.Unit
			else
				flatForward = Vector3.new(camCF.UpVector.X, 0, camCF.UpVector.Z).Unit
			end

			local flatRight = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
			if flatRight.Magnitude > 0.001 then
				flatRight = flatRight.Unit
			end

			local forwardAmount = moveDir:Dot(flatForward)
			local rightAmount = moveDir:Dot(flatRight)

			local flyDirection = (camCF.LookVector * forwardAmount) + (camCF.RightVector * rightAmount) + Vector3.new(0, vertical, 0)
			if flyDirection.Magnitude > 0 then
				BodyVelocity.Velocity = flyDirection.Unit * FlySpeed
			else
				BodyVelocity.Velocity = Vector3.zero
			end
		else
			BodyVelocity.Velocity = Vector3.new(0, vertical * FlySpeed, 0)
		end
	end)
end

-- Hàm tắt bay
local function StopFly()
	FlyEnabled = false
	if FlyConnection then
		FlyConnection:Disconnect()
		FlyConnection = nil
	end
	if BodyGyro then
		BodyGyro:Destroy()
		BodyGyro = nil
	end
	if BodyVelocity then
		BodyVelocity:Destroy()
		BodyVelocity = nil
	end
	local character = LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.PlatformStand = false
		end
	end
end

-- Tự động reset trạng thái bay khi nhân vật hồi sinh
LocalPlayer.CharacterAdded:Connect(function()
	if FlyEnabled then
		task.wait(0.5)
		StartFly()
	end
end)

-- Tạo giao diện nút điều khiển nhỏ gọn (kéo thả được trên màn hình)
-- ĐÃ SỬA: gắn menu vào PlayerGui (không dùng CoreGui nữa) để luôn hiện trên mobile
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Xoá menu cũ nếu chạy script nhiều lần (tránh bị trùng)
local oldGui = PlayerGui:FindFirstChild("EggFlyUI")
if oldGui then
	oldGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EggFlyUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 150, 0, 76)
MainFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -12, 0, 32)
ToggleBtn.Position = UDim2.new(0, 6, 0, 6)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Text = "Bay: TẮT"
ToggleBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = ToggleBtn

local MinusBtn = Instance.new("TextButton")
MinusBtn.Size = UDim2.new(0, 32, 0, 26)
MinusBtn.Position = UDim2.new(0, 6, 0, 44)
MinusBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
MinusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinusBtn.Font = Enum.Font.GothamBold
MinusBtn.TextSize = 14
MinusBtn.Text = "-"
MinusBtn.Parent = MainFrame
Instance.new("UICorner", MinusBtn).CornerRadius = UDim.new(0, 6)

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, -84, 0, 26)
SpeedLabel.Position = UDim2.new(0, 42, 0, 44)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
SpeedLabel.Font = Enum.Font.Gotham
SpeedLabel.TextSize = 12
SpeedLabel.Text = "Tốc độ: " .. FlySpeed
SpeedLabel.Parent = MainFrame

local PlusBtn = Instance.new("TextButton")
PlusBtn.Size = UDim2.new(0, 32, 0, 26)
PlusBtn.Position = UDim2.new(1, -38, 0, 44)
PlusBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
PlusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlusBtn.Font = Enum.Font.GothamBold
PlusBtn.TextSize = 14
PlusBtn.Text = "+"
PlusBtn.Parent = MainFrame
Instance.new("UICorner", PlusBtn).CornerRadius = UDim.new(0, 6)

-- Sự kiện bấm nút
ToggleBtn.MouseButton1Click:Connect(function()
	if FlyEnabled then
		StopFly()
		ToggleBtn.Text = "Bay: TẮT"
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	else
		StartFly()
		ToggleBtn.Text = "Bay: BẬT"
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 90)
	end
end)

MinusBtn.MouseButton1Click:Connect(function()
	FlySpeed = math.max(10, FlySpeed - 10)
	SpeedLabel.Text = "Tốc độ: " .. FlySpeed
end)

PlusBtn.MouseButton1Click:Connect(function()
	FlySpeed = math.min(300, FlySpeed + 10)
	SpeedLabel.Text = "Tốc độ: " .. FlySpeed
end)

-- Hỗ trợ kéo thả bảng điều khiển bằng cảm ứng hoặc chuột
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
	end
end)
MainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
