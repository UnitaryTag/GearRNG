-- MenuUIBuilder.client.lua
-- React-based main menu UI — declarative components with hooks.
-- Replaces native Instance.new() spaghetti with a component tree.
--
-- Components:
--   App → Overlay + LeftColumn → TitleSection + MenuButton[] + OverlayPanel[]
-- State:  activePanel (nil / "Inventory" / "Settings" / "Shop")
-- Audio:  MenuAudio shared module for hover/click SFX

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local MenuAudio = require(ReplicatedStorage.Modules.MenuAudio)

local MenuUIBuilder = {}

-- ── Constants ────────────────────────────────────────────────
local TITLE_TEXT = "GEAR RNG"
local SUBTITLE_TEXT = "Roll. Enhance. Dominate."
local VERSION_TEXT = "v0.1.0-alpha"

local COLORS = {
	Gold = Color3.fromRGB(212, 175, 55),
	GoldDark = Color3.fromRGB(150, 120, 30),
	Silver = Color3.fromRGB(180, 170, 160),
	BgOverlay = Color3.fromRGB(0, 0, 0),
	TextLight = Color3.fromRGB(230, 220, 200),
	TextDim = Color3.fromRGB(160, 150, 140),
	Green = Color3.fromRGB(50, 160, 50),
	GreenHover = Color3.fromRGB(80, 200, 80),
	Blue = Color3.fromRGB(40, 80, 180),
	BlueHover = Color3.fromRGB(65, 110, 220),
	Grey = Color3.fromRGB(80, 80, 85),
	GreyHover = Color3.fromRGB(120, 120, 125),
}

local BUTTON_DEFS = {
	{ id = "Play",       text = "PLAY",       color = COLORS.Green, colorHover = COLORS.GreenHover, primary = true },
	{ id = "Inventory",  text = "INVENTORY",   color = COLORS.Blue,  colorHover = COLORS.BlueHover },
	{ id = "Settings",   text = "SETTINGS",    color = COLORS.Grey,  colorHover = COLORS.GreyHover },
	{ id = "Shop",       text = "SHOP",        color = COLORS.Gold,  colorHover = COLORS.GoldDark },
}

local PANEL_DATA = {
	Inventory = { title = "INVENTORY", body = "Your collected gear will appear here." },
	Settings  = { title = "SETTINGS",  body = "Settings will be available soon." },
	Shop      = { title = "SHOP",      body = "The premium shop is coming soon." },
}

-- Global audio instance — set before render
local audio = nil

-- ── Reusable: Decorative Line ────────────────────────────────
local function DecorativeLine(_props)
	return React.createElement("Frame", {
		Size = UDim2.new(0.6, 0, 0, 2),
		BackgroundColor3 = COLORS.Gold,
		BorderSizePixel = 0,
	}, {
		UIGradient = React.createElement("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.8),
				NumberSequenceKeypoint.new(0.1, 0),
				NumberSequenceKeypoint.new(0.8, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})
end

-- ── Reusable: Title Section ──────────────────────────────────
local function TitleSection(_props)
	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 0.28, 0),
		BackgroundTransparency = 1,
	}, {
		Title = React.createElement("TextLabel", {
			Text = TITLE_TEXT,
			Font = Enum.Font.Fantasy,
			TextSize = 64,
			TextColor3 = COLORS.Gold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextStrokeTransparency = 0.6,
			TextStrokeColor3 = COLORS.GoldDark,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0.55, 0),
		}, {
			TitleGradient = React.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, COLORS.Gold),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 100)),
					ColorSequenceKeypoint.new(1, COLORS.GoldDark),
				}),
			}),
		}),
		Subtitle = React.createElement("TextLabel", {
			Text = SUBTITLE_TEXT,
			Font = Enum.Font.Gotham,
			TextSize = 16,
			TextColor3 = COLORS.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0.3, 0),
			Position = UDim2.new(0, 0, 0.6, 0),
		}),
	})
end

-- ── Reusable: Menu Button ────────────────────────────────────
local function MenuButton(props)
	local isHovered, setHovered = React.useState(false)
	local ref = React.useRef(nil)

	local btnW, btnH
	if props.primary then
		btnW, btnH = (isHovered and 0.3 or 0.28), (isHovered and 0.095 or 0.09)
	else
		btnW, btnH = (isHovered and 0.22 or 0.21), (isHovered and 0.07 or 0.065)
	end

	return React.createElement("TextButton", {
		Name = props.id .. "Button",
		Text = "",
		BackgroundColor3 = isHovered and props.colorHover or props.color,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Size = UDim2.new(btnW, 0, btnH, 0),
		Position = props.position,
		[React.Event.MouseEnter] = function()
			setHovered(true)
			if audio then audio:playUIHover() end
		end,
		[React.Event.MouseLeave] = function()
			setHovered(false)
		end,
		[React.Event.MouseButton1Click] = function()
			if audio then audio:playUIClick() end
			if props.onClick then props.onClick() end
		end,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, 10),
		}),
		Label = React.createElement("TextLabel", {
			Text = props.text,
			Font = Enum.Font.Fantasy,
			TextSize = props.primary and 32 or 22,
			TextColor3 = COLORS.TextLight,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
		}),
	})
end

-- ── Reusable: Overlay Panel ──────────────────────────────────
local function OverlayPanel(props)
	if not props.visible then return nil end

	local backdropTransparency, setBackdropTransparency = React.useState(1)

	React.useEffect(function()
		setBackdropTransparency(0.7)
	end, {})

	local function handleClose()
		setBackdropTransparency(1)
		task.delay(0.2, function()
			if props.onClose then props.onClose() end
		end)
	end

	return React.createElement("Frame", {
		Name = props.panelKey .. "Panel",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = COLORS.BgOverlay,
		BackgroundTransparency = backdropTransparency,
		BorderSizePixel = 0,
		ZIndex = 10,
	}, {
		Content = React.createElement("Frame", {
			Name = "Content",
			Size = UDim2.new(0.4, 0, 0.5, 0),
			Position = UDim2.new(0.3, 0, 0.25, 0),
			BackgroundColor3 = COLORS.BgOverlay,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
		}, {
			ContentCorner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 12),
			}),
			Border = React.createElement("UIStroke", {
				Thickness = 2,
				Color = COLORS.Gold,
				Transparency = 0.4,
			}),
			PanelTitle = React.createElement("TextLabel", {
				Text = props.title,
				Font = Enum.Font.Fantasy,
				TextSize = 36,
				TextColor3 = COLORS.Gold,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0.2, 0),
				Position = UDim2.new(0, 0, 0.05, 0),
			}),
			Line = React.createElement("Frame", {
				Size = UDim2.new(0.5, 0, 0, 2),
				Position = UDim2.new(0.25, 0, 0.28, 0),
				BackgroundColor3 = COLORS.Gold,
				BorderSizePixel = 0,
			}),
			Body = React.createElement("TextLabel", {
				Text = props.body,
				Font = Enum.Font.Gotham,
				TextSize = 18,
				TextColor3 = COLORS.TextDim,
				BackgroundTransparency = 1,
				Size = UDim2.new(0.8, 0, 0.3, 0),
				Position = UDim2.new(0.1, 0, 0.35, 0),
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Center,
			}),
			CloseButton = React.createElement("TextButton", {
				Text = "✕",
				Font = Enum.Font.GothamBold,
				TextSize = 20,
				TextColor3 = COLORS.TextDim,
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				BorderSizePixel = 0,
				Size = UDim2.new(0, 36, 0, 36),
				Position = UDim2.new(1, -44, 0, 8),
				ZIndex = 11,
				[React.Event.MouseButton1Click] = handleClose,
			}, {
				CloseCorner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}),
		}),
	})
end

-- ── App Component ────────────────────────────────────────────
local function App(_props)
	local activePanel, setActivePanel = React.useState(nil)

	-- Button click callbacks
	local function onPlayClicked()
		local remotes = ReplicatedStorage:FindFirstChild("MenuRemotes")
		if remotes then
			local playEvent = remotes:FindFirstChild("PlayRequest")
			if playEvent then
				playEvent:FireServer()
			end
		end
	end

	local function onPanelButton(id)
		setActivePanel(id)
	end

	local function onPanelClose()
		setActivePanel(nil)
	end

	local buttonSpacing = 0.24
	local buttonElements = {}
	for i, btn in ipairs(BUTTON_DEFS) do
		local clickHandler
		if btn.id == "Play" then
			clickHandler = onPlayClicked
		else
			clickHandler = function() onPanelButton(btn.id) end
		end
		buttonElements["Btn_" .. btn.id] = React.createElement(MenuButton, {
			id = btn.id,
			text = btn.text,
			color = btn.color,
			colorHover = btn.colorHover,
			primary = btn.primary,
			position = UDim2.new(0, 0, (i - 1) * buttonSpacing, 0),
			onClick = clickHandler,
		})
	end

	return React.createElement("Frame", {
		-- This outer frame is the "virtual" parent for the UI tree.
		-- Children are parented to the ScreenGui by the reconciler.
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	}, {
		-- ── Dark Overlay ────────────────────────────────────
		Overlay = React.createElement("Frame", {
			Name = "Overlay",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = COLORS.BgOverlay,
			BackgroundTransparency = 0.85,
			BorderSizePixel = 0,
		}, {
			Vignette = React.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
					ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0, 0, 0)),
					ColorSequenceKeypoint.new(0.7, Color3.fromRGB(20, 15, 10)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 20, 15)),
				}),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.2),
					NumberSequenceKeypoint.new(0.5, 0.5),
					NumberSequenceKeypoint.new(1, 0.8),
				}),
			}),
		}),

		-- ── Left Column ────────────────────────────────────
		LeftColumn = React.createElement("Frame", {
			Name = "LeftColumn",
			Size = UDim2.new(0.35, 0, 0.6, 0),
			Position = UDim2.new(0.06, 0, 0.2, 0),
			BackgroundTransparency = 1,
		}, {
			TitleSection = React.createElement(TitleSection),
			Line = React.createElement(DecorativeLine, {
				Position = UDim2.new(0, 0, 0.38, 0),
			}),
			ButtonContainer = React.createElement("Frame", {
				Name = "ButtonContainer",
				Size = UDim2.new(1, 0, 0.55, 0),
				Position = UDim2.new(0, 0, 0.44, 0),
				BackgroundTransparency = 1,
			}, buttonElements),
		}),

		-- ── Overlay Panels ─────────────────────────────────
		InventoryPanel = React.createElement(OverlayPanel, {
			panelKey = "Inventory",
			title = PANEL_DATA.Inventory.title,
			body = PANEL_DATA.Inventory.body,
			visible = activePanel == "Inventory",
			onClose = onPanelClose,
		}),
		SettingsPanel = React.createElement(OverlayPanel, {
			panelKey = "Settings",
			title = PANEL_DATA.Settings.title,
			body = PANEL_DATA.Settings.body,
			visible = activePanel == "Settings",
			onClose = onPanelClose,
		}),
		ShopPanel = React.createElement(OverlayPanel, {
			panelKey = "Shop",
			title = PANEL_DATA.Shop.title,
			body = PANEL_DATA.Shop.body,
			visible = activePanel == "Shop",
			onClose = onPanelClose,
		}),

		-- ── Version ────────────────────────────────────────
		Version = React.createElement("TextLabel", {
			Text = VERSION_TEXT,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = COLORS.TextDim,
			TextXAlignment = Enum.TextXAlignment.Right,
			BackgroundTransparency = 1,
			Size = UDim2.new(0.1, 0, 0.03, 0),
			Position = UDim2.new(0.9, 0, 0.96, 0),
		}),
	})
end

-- ── Build (Public API) ───────────────────────────────────────
function MenuUIBuilder:build()
	audio = MenuAudio.new()

	local gui = Instance.new("ScreenGui")
	gui.Name = "MenuUI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Fade-in
	gui.Enabled = false
	task.wait(0.3)
	gui.Enabled = true

	local root = ReactRoblox.createRoot(gui)
	root:render(React.createElement(App, {}))

	print("[MenuUIBuilder] React menu mounted.")
	return gui
end

return MenuUIBuilder
