--[[
  @ Description:
    This is the operator of the base system/class,
    it manages the functionality of the droplets,
    the events of the casts, the limit and such.
]]

-- Variable definitions
local ParentClass = script.Parent
local Assets = ParentClass.Assets

-- Asset definitions
local Sounds = Assets.Sounds
local Essentials = Assets.Essentials
local Meshes = Assets.Meshes

-- Sound definitions
local EndFolder = Sounds.End:GetChildren()
local StartFolder = Sounds.Start:GetChildren()

-- Essential definitions
local Functions = require(ParentClass.Functions)
local PartCache = require(Essentials.PartCache)
local Settings = require(ParentClass.Settings)
local FastCast = require(Essentials.FastCast)

-- Globals
local Unpack = table.unpack

-- Constants definition
local TypeAttribute = "Type"
local DecayAttribute = "Decaying"
local ExpandAttribute = "Expanding"
local MeshMap = {
	Default = Meshes.Droplet,
	Decal = Meshes.Decal,
}

-- Type definitions
type Connections = { RBXScriptConnection }

-- Class definition
local Operator = {}
Operator.__index = Operator

--[[
  Class constructor, constructs the class
  including other properties/variables.
]]
function Operator.new(Class)
	local self = setmetatable({
		Handler = Class.ActiveHandler,
	}, Operator)

	return self, self:Initialize(), self:InitializeCast()
end

--[[
  Immediately called after the construction of the class,
  defines properties/variables for after-construction
]]
function Operator:Initialize()
	-- Variable definitions
	local Handler: Settings.Class = self.Handler
	local FolderName: string = Handler.FolderName

	-- Essential definitions
	local Type = Handler.Type
	local Limit = Handler.Limit
	local CastParams = Handler.RaycastParams

	local Folder = Functions.GetFolder(FolderName)
	local Object = Functions.GetDroplet(Handler.SplashName)

	-- Class definitions
	local Cache = PartCache.new(Object, Limit, Folder)
	
	-- Insert variables
	Functions.MultiInsert(self, {
		Registry = {},
		Connections = {},
		
		Droplet = Object,
		Cache = Cache,
		Container = Folder,
		Caster = FastCast.new(),
		Behavior = function()
			return Functions.SetupBehavior(Cache, CastParams)
		end,
	})
end

--[[
  The Cast-Setup, which is executed immediately
  following the Initialization of the class.

  It efficiently manages events
  associated with the Caster.
]]
function Operator:InitializeCast()
	-- Self definitions
	local Connections: Connections = self.Connections
	local Caster: FastCast.Class = self.Caster
	local Handler: Settings.Class = self.Handler
	local Container: Folder = self.Container

	-- Event definitions
	local LengthChanged = Caster.LengthChanged
	local RayHit = Caster.RayHit

	-- Caster Listeners
	Functions.Connect(LengthChanged:Connect(function(_, Origin, Direction, Length, _, Object: BasePart)
		if not Object then
			return
		end

		-- 3D Definition
		local ObjectSize = Object.Size
		local ObjectLength = ObjectSize.Z / 2

		local Offset = CFrame.new(0, 0, -(Length - ObjectLength))

		local GoalCFrame = CFrame.new(Origin, Origin + Direction):ToWorldSpace(Offset)

		-- Update properties
		Object.CFrame = GoalCFrame
	end), Connections)
	
	Functions.Connect(RayHit:Connect(function(_, RaycastResult: RaycastResult, Velocity, Object: BasePart?)
		if not Object then
			return nil
		end

		-- Options definitions
		local RegistryData = self.Registry[Object] or Handler
		local Size = RegistryData.StartingSize
		local SizeRange = RegistryData.DefaultSize
		local YRange = RegistryData.YSize
		local Distance = RegistryData.Distance
		local Expansion = RegistryData.Expansion
		local IsDecal = RegistryData.Type == "Decal"

		-- Variable definitions
		local CastInstance = RaycastResult.Instance
		local Position = RaycastResult.Position
		local Normal = RaycastResult.Normal

		local VectorSize, SizeY = Functions.GetVector(SizeRange), Functions.NextNumber(table.unpack(YRange))
		local GoalSize = Functions.RefineVectors(IsDecal, Vector3.new(VectorSize.X, VectorSize.Y / 4, VectorSize.X))

		local GoalAngles = Functions.GetAngles(IsDecal, IsDecal)
		local GoalCFrame = Functions.GetCFrame(Position, Normal, IsDecal) * GoalAngles

		local ClosestPart = Functions.GetClosest(Object, Distance, Container)

		local ExpansionLogic = (
			Expansion
				and ClosestPart
				and not ClosestPart:GetAttribute(DecayAttribute)
				and not ClosestPart:GetAttribute(ExpandAttribute)
				and ClosestPart:GetAttribute(TypeAttribute) == RegistryData.Type
		)

		-- Clear the registry entry
		self.Registry[Object] = nil

		-- Evaluates if the droplet is close to another pool, if so, expand.
		if ExpansionLogic then
			self:Expanse(Object, ClosestPart, Velocity, GoalSize, RegistryData)
			return nil
		end

		-- Update properties
		Object.Anchored = true
		Object.Size = Size
		Object.CFrame = GoalCFrame
		Object.Transparency = Functions.NextNumber(Unpack(RegistryData.DefaultTransparency))

		--[[
     		Transitions the droplet into a pool,
      		then handles its later functionality.
        	(Decay, Sounds, etc...)
    	]]
		Functions.CreateTween(Object, RegistryData.Tweens.Landed, { Size = GoalSize }):Play()

		self:HandleDroplet(Object, RegistryData)
		self:HitEffects(Object, Velocity, RegistryData)
		Functions.Weld(CastInstance, Object)

		return nil
	end), Connections)
end

--[[
	Destroys PartCache, FastCast, 
	and all the droplets associated with this engine/operator.
]]
function Operator:Destroy()
	-- Self definitions
	local Connections: Connections = self.Connections
	local Cache: PartCache.Class = self.Cache
	local Caster: FastCast.Class = self.Caster
	local Container: Folder = self.Container
	
	-- Destroy classes
	Cache:Dispose()
	table.clear(Caster)
	
	Functions.DisconnectAll(Connections)
	table.clone(Connections)
	
	-- Destroy main container
	if Container then
		Container:Destroy()
	end
	
	-- Null everything, making the operator unusable
	self.Connections = nil
	self.Container = nil
	self.Cache = nil
	self.Caster = nil
end

--[[
  Emitter, emits a certain amount of droplets,
  at a certain point of origin, with a certain given direction.
]]
function Operator:Emit(Origin: Vector3, Direction: Vector3, Data: Settings.Class?)
	-- Class definitions
	local Caster: FastCast.Class = self.Caster
	local Behavior: FastCast.Behavior = self.Behavior
	local Cache: PartCache.Class = self.Cache
	local Handler: Settings.Class = self.Handler
	
	-- Create a clone of the default settings, and apply specific settings if provided
	local Clone = table.clone(Handler)
	Clone:UpdateSettings(Data or {})
	Data = Clone

	-- Variable definitions
	local IsDecal = Data.Type == "Decal"
	local DropletVelocity = Data.DropletVelocity
	local Velocity = Functions.NextNumber(Unpack(DropletVelocity)) * 10

	local RandomOffset = Data.RandomOffset
	local OffsetRange = Data.OffsetRange
	local Position = Functions.GetVector(OffsetRange) / 10

	-- Final definitions
	local FinalPosition = Origin + Vector3.new(Position.X, 0, Position.Z)
	local FinalStart = (RandomOffset and FinalPosition or Origin)

	if #Cache.Open <= 0 then
		return
	end

	-- Caster definitions, fire the caster with given arguments
	local ActiveDroplet = Caster:Fire(FinalStart, Direction, Velocity, Behavior)

	local RayInfo = ActiveDroplet.RayInfo
	local Droplet: MeshPart = RayInfo.CosmeticBulletObject
	
	-- Update the mesh's look and color
	Droplet:ApplyMesh(MeshMap[Data.Type])
	Droplet.Color = Data.DropletColor
	
	-- Assign the registry entry and update the attributes
	self.Registry[Droplet] = Data
	Droplet:SetAttribute(TypeAttribute, Data.Type)
	Droplet:SetAttribute(DecayAttribute, false)
	Droplet:SetAttribute(ExpandAttribute, false)
	
	-- Execute essential functions
	self:UpdateDroplet(Droplet, Data)
	Functions.PlaySound(Functions.GetRandom(StartFolder), Droplet)
end

--[[
  A small function, designed to update the properties
  of a recently emitted droplet.
]]
function Operator:UpdateDroplet(Object: BasePart, Data: Settings.Class)
	-- Variable definitions
	local DropletTrail = Data.Trail
	local DropletVisible = Data.DropletVisible
	local IsDecal = Data.Type == "Decal"

	-- Object definitions
	local Trail = Object:FindFirstChildOfClass("Trail")

	-- Update Object properties
	Object.Transparency = DropletVisible and 0 or 1
	Trail.Enabled = DropletTrail

	-- Execute essential functions
	Functions.ApplyDecal(Object, IsDecal)
end

--[[
  Handles the given droplet/object after
  it landed on a surface.
]]
function Operator:HandleDroplet(Object: BasePart, Data: Settings.Class)
	-- Object definitions
	local Trail = Object:FindFirstChildOfClass("Trail")

	-- Variable definitions
	local Tweens = Data.Tweens
	local DecayDelay = Data.DecayDelay

	local DecayInfo = Tweens.Decay
	local DecayTime = Functions.NextNumber(Unpack(DecayDelay))

	local ScaleDown = Data.ScaleDown
	local FinalSize = ScaleDown and Vector3.new(0.01, 0.01, 0.01) or Object.Size

	-- Tween definitions
	local DecayTween = Functions.CreateTween(Object, DecayInfo, { Transparency = 1, Size = FinalSize })

	-- Update Droplet properties
	Trail.Enabled = false

	-- Listeners
	DecayTween.Completed:Connect(function()
		DecayTween:Destroy()
		Object:SetAttribute("Decaying", nil)
		self:ReturnDroplet(Object)
	end)

	-- Reset the droplet after the given DecayDelay has passed
	task.delay(DecayTime, function()
		DecayTween:Play()
		Object:SetAttribute("Decaying", true)
	end)
end

--[[
  HitEffects, a sequence of effects to enhance
  the visuals of the droplet->pool
]]
function Operator:HitEffects(Object, Velocity: Vector3, Data: Settings.Class)
	-- Variable definitions
	local SplashName = Data.SplashName
	local SplashAmount = Data.SplashAmount
	local SplashByVelocity = Data.SplashByVelocity
	local Divider = Data.VelocityDivider
	local IsDecal = Data.Type == "Decal"

	local Magnitude = Velocity.Magnitude
	local FinalVelocity = Magnitude / Divider
	local FinalAmount = (SplashByVelocity and FinalVelocity or Functions.NextNumber(Unpack(SplashAmount)))
	local Splash: Attachment = Object:FindFirstChild(SplashName)

	-- Execute essential functions
	Splash.Orientation = Vector3.new(0, 0, IsDecal and 0 or 180)
	Functions.PlaySound(Functions.GetRandom(EndFolder), Object)
	Functions.EmitParticles(Splash, FinalAmount)
end

--[[
	Simulates the pool expansion
	effect when a droplet is near
	a pool.

	It checks the distance between
	a threshold, then triggers changes
	on the droplet & pool.
]]
function Operator:Expanse(
	Object: BasePart,
	ClosestPart: BasePart,
	Velocity: Vector3, 
	Size: Vector3, 
	Data: Settings.Class
)
	-- Variable definitions
	local Divider = Data.ExpanseDivider
	local MaximumSize = Data.MaximumSize
	local IsDecal = Data.Type == "Decal"

	-- Info definitions
	local Tweens = Data.Tweens
	local Expand = Tweens.Expand

	-- Value definitions
	local PoolSize = ClosestPart.Size
	local FinalVelocity = Velocity / 20
	local GoalSize = Vector3.new(Size.X, Size.Y / Divider, Size.Z) / Divider

	local FirstSize = Functions.RefineVectors(
		IsDecal,
		Vector3.new(PoolSize.X - FinalVelocity.Z, PoolSize.Y + FinalVelocity.Y, PoolSize.Z - FinalVelocity.Z)
	)

	local LastSize = Vector3.new(PoolSize.X, PoolSize.Y, PoolSize.Z) + GoalSize

	local FinalSize = (LastSize.X < MaximumSize and LastSize or PoolSize)

	-- Update properties
	ClosestPart:SetAttribute("Expanding", true)
	ClosestPart.Size = FirstSize

	-- Transition to Expanded size
	local Tween = Functions.CreateTween(ClosestPart, Expand, { Size = FinalSize })

	Tween:Play()
	Tween.Completed:Connect(function()
		ClosestPart:SetAttribute("Expanding", nil)
		Tween:Destroy()
	end)

	-- Execute essential functions
	Functions.PlaySound(Functions.GetRandom(EndFolder), ClosestPart)
	self:ReturnDroplet(Object)
end

--[[
  Resets the given droplet/pool,
  then returns it to the Cache.
]]
function Operator:ReturnDroplet(Object: Instance)
	-- Self definitions
	local Cache: PartCache.Class = self.Cache
	local Template: Instance = self.Droplet

	-- Execute essential functions
	Functions.ResetDroplet(Object, Template)
	Cache:ReturnPart(Object) -- Ignore, ReturnPart exists
end

-- Exports the class
export type Class = typeof(Operator.new(...))

return Operator
