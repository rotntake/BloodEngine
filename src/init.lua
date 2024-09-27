--[[
  @ Writer: @Smileeiles
  @ Version: v1.1.3
  @ Description:
     A droplet emitter system,
     used to emit droplets from a specified origin point.

     These droplets are then given a velocity,
     and upon landing on a surface, transform into pools.

     This process can be customized to suit various needs and genres.
]]

-- Essential definitions
local Operator = require(script.Operator)
local Settings = require(script.Settings)
local Functions = require(script.Functions)

-- Globals
local Unpack = table.unpack

-- Class definition
local BloodEngine = {}
BloodEngine.__index = BloodEngine

--[[
  Class constructor, constructs the class
  including other properties/variables.
]]
function BloodEngine.new(Data: Settings.Class)
	local self = setmetatable({}, BloodEngine)
	return self, self:Initialize(Data)
end

--[[
  Immediately called after the construction of the class,
  defines properties/variables for after-construction
]]
function BloodEngine:Initialize(Data: {})
	Functions.MultiInsert(self, {
		ActiveHandler = Settings.new(Data or {}),
		ActiveEngine = function()
			return Operator.new(self)
		end,
	})
end

--[[
  Emitter, emits droplets based on given amount,
  origin & direction.

  This is utilized when you prefer
  not to create a loop just for the
  purpose of emitting a few droplets.
]]
function BloodEngine:EmitAmount(Origin: Vector3 | BasePart, Direction: Vector3, Amount: number, Data: Settings.Class?)
	-- Class definitions
	local Handler: Settings.Class = self.ActiveHandler

	-- Variable definitions
	local DropletDelay = Handler.DropletDelay

	for _ = 1, Amount, 1 do
		-- Define variables for later use
		local DelayTime = Functions.NextNumber(Unpack(DropletDelay))

		-- Emit a droplet in the specified direction & origin
		self:Emit(Origin, Direction, Data)

		-- Delays the next droplet to be emitted
		task.wait(DelayTime)
	end
end

--[[
  EmitOnce, a variant of the Emit method; emits a single droplet.
  Unlike Emit, which uses a loop to emit multiple droplets,
  EmitOnce only emits one droplet per call.

  This is useful when you want to control the emission
  loop externally.
]]
function BloodEngine:Emit(Origin: Vector3 | BasePart, Direction: Vector3, Data: Settings.Class?)
	-- Class definitions
	local Engine: Operator.Class = self.ActiveEngine

	-- Variable definitions
	Origin = typeof(Origin) == "Instance" and Origin.Position or Origin
	Direction = Direction or Functions.GetVector({ -10, 10 }) / 10

	-- Emit a single droplet
	Engine:Emit(Origin, Direction, Data)
end

--[[
  GetSettings, returns all the settings of the
  current class instance.

  Use this function when you want to access
  the settings for external handling of the system.
]]
function BloodEngine:GetSettings(): Settings.Class
	-- Class definitions
	local Handler: Settings.Class = self.ActiveHandler

	-- Export settings
	return Handler
end

--[[
  UpdateSettings, updates the settings of the
  current class instance.

  It uses the `Handler:UpdateSettings()`, which
  uses the given `Data` array/table to update individual settings.
]]
function BloodEngine:UpdateSettings(Data: Settings.Class)
	-- Class definitions
	local Handler: Settings.Class = self.ActiveHandler

	-- Update the settings
	Handler:UpdateSettings(Data)
end

--[[
	Destroy, destroys anything associated 
	with the settings/handler and the operator/engine.
	
	Use this function when there is no longer a use
	for the created engine. (Like when a character dies, etc.)
]]
function BloodEngine:Destroy()
	-- Class definitions
	local Handler: Settings.Class = self.ActiveHandler
	local Engine: Operator.Class = self.ActiveEngine
	
	-- Destroy the handler & engine
	self.Handler = nil
	Engine:Destroy()
	self.Engine = nil
	
	-- Nullify/replace all the Engine methods
	self.UpdateSettings = Functions.Replacement
	self.GetSettings = Functions.Replacement
	
	self.EmitAmount = Functions.Replacement
	self.Emit = Functions.Replacement
end

-- Exports the class
return BloodEngine
