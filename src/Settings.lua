--[[
  @ Description:
    A class that handles settings,
    a group of keys that have an assigned value.
]]

-- Class definition
local Settings = {}
Settings.__index = Settings

--[[
  Class constructor, constructs the class
  including other properties/variables.
]]
function Settings.new(Data: {})
	local self = setmetatable({
		FolderName = "Droplets", -- Specifies the name of the folder containing the droplets.
		Type = "Default", -- Defines the droplet type. It can be either "Default" (Sphere) or "Decal".
		Limit = 500, -- Sets the maximum number of droplets that can be created.
		Filter = {}, -- An array/table of instances that should be ignored during droplet collision.
		
		YSize = { 0.1, 0.175 }, -- Specifices the range of the thickness/flatness/depth of the pool. Lesser is flatter.
		DefaultSize = { 0.4, 0.7 }, -- Specifies the default size range of a pool.
		DefaultTransparency = { 0.3, 0.4 }, -- Specifies the default transparency range of a pool.
		StartingSize = Vector3.new(0.1, 0.3, 0.1), -- Sets the initial size of the droplets upon landing.
		ScaleDown = true, -- Determines whether the pool should scale down when decaying.

		DropletDelay = { 0.01, 0.03 }, -- Sets the delay between emitting droplets in a loop (for the EmitAmount method).
		DropletVelocity = { 1, 2 }, -- Controls the velocity of the emitted droplet.
		DropletVisible = false, -- Determines if the droplet is visible upon emission.
		DropletColor = Color3.fromRGB(103, 0, 0), -- Determines the color of the emitted droplet.

		RandomOffset = true, -- Determines whether a droplet should spawn at a random offset from a given position.
		OffsetRange = { -5, 5 }, -- Specifies the offset range for the position vectors.

		SplashName = "Impact", -- The name of the attachment that releases particles on surface contact.
		SplashAmount = { 5, 10 }, -- Sets the number of particles to emit upon impact.
		SplashByVelocity = true, -- If true, sets the number of particles based on the velocity of the droplet.
		VelocityDivider = 8, -- Controls how much the velocity can affect the splash amount, Higher values reduce the effect.

		Expansion = true, -- Determines whether a pool can expand when a droplet lands on it.
		Distance = 0.2, -- Sets the distance (in studs) within which the droplet should check for nearby pools
		ExpanseDivider = 3, -- Controls how much a pool's size can increase. Higher values reduce the increase.
		MaximumSize = 0.7, -- Sets the maximum size a pool can reach.

		Trail = true, -- Controls the visibility of the trail during droplet emission.
		DecayDelay = { 10, 15 }, -- Sets the delay before the droplet decays and recycles

		-- Contains all the tweens used by the module
		Tweens = {
			Landed = TweenInfo.new(0.5, Enum.EasingStyle.Cubic), -- Used for when a droplet has landed on a surface.
			Decay = TweenInfo.new(1, Enum.EasingStyle.Cubic), -- Used for when a droplet is decaying.
			Expand = TweenInfo.new(0.5, Enum.EasingStyle.Cubic), -- Used for when a droplet is expanding (Pool Expansion).
		},
	}, Settings)

	-- Fill the default settings with values from the Data array
	for Setting, Value in Data do
		if Setting == "Tweens" then
			for Tween, Info in Value do
				self.Tweens[Tween] = Info
			end

			continue
		end

		self[Setting] = Value
	end

	return self, self:CreateParams()
end

--[[
  Updates settings with values from the provided array.
]]
function Settings:UpdateSettings(Data: {})
	-- Variable definitions
	local Filter = self.Filter
	local Params = self.RaycastParams

	for Setting, Value in Data do
		self[Setting] = Value
	end

	-- Update Param properties
	Params.FilterDescendantsInstances = Filter
end

--[[
	Manages the instantiation of the RaycastParams
	aswell as the configuration of the filter.
]]
function Settings:CreateParams()
	-- Variable definitions
	local Filter = self.Filter
	local Params = RaycastParams.new()

	-- Update Params properties
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = Filter

	-- Assign Params as a self value
	self.RaycastParams = Params
end

-- Exports the class and its type
export type Class = typeof(Settings.new(...))

return Settings
