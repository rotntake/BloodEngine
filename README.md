<div align="center">
	
<picture>
 <img alt="Logo" src="https://github.com/rotntake/BloodEngine/assets/126120456/eb3a43ec-579f-491d-a9f3-f32e3a75d9ff">
</picture>

</div>

<div align="center">


v1.1.2 • [Model](https://create.roblox.com/marketplace/asset/15420466379/) • [Devforum](https://devforum.roblox.com/t/blood-engine-a-droplet-emitter-system/2545682)

</div>

## What is Blood Engine?
Blood Engine is a versatile resource that can be utilized for various applications, including creating effects like paint, water, blood, and more. It offers numerous methods tailored to meet your specific needs.

One of its key features is the ability to emit "droplets" - these are meshes that can take on the appearance of "Decals" or "Spheres". These droplets can be emitted from any given origin point with a given velocity. Upon landing on a surface, such as a wall or floor, they transform into a pool.

This entire process is highly customizable, with 24 options at your disposal to tweak and adjust according to your requirements. This ensures that Blood Engine can adapt to a wide range of scenarios and use-cases, providing you with the flexibility to create the exact effect you're aiming for.

## Installation
You can install Blood Engine through the latest release of the repository, the [Model](https://create.roblox.com/marketplace/asset/15420466379/) published on Roblox, or by using Wally:
```toml
[dependencies]
BloodEngine = "rotntake/blood-engine@1.1.2"
```

## Usage
#### Initialization
Firstly, you'll need to initialize BloodEngine with your preferred settings. This can be done in either a client or server script. However, it's generally more advisable to do this on the client side, so we'll proceed with that approach. 

The settings provide you with control over various aspects of droplets and pools. These include the maximum number of droplets that can be created, the type of droplets to use, the velocity of droplets upon emission, and much more.
```lua
-- Import the BloodEngine module
local BloodEngine = require(PathToModule)

-- Initialize BloodEngine with desired settings
local Engine = BloodEngine.new({
    Limit = 100, -- Sets the maximum number of droplets that can be created.
    Type = "Default", -- Defines the droplet type. It can be either "Default" (Sphere) or "Decal",
    RandomOffset = false, -- Determines whether a droplet should spawn at a random offset from a given position.
    OffsetRange = {-20, 10}, -- Specifies the offset range for the position vectors.
    DropletVelocity = {1, 2}, -- Controls the velocity of the emitted droplet.
    DropletDelay = {0.05, 0.1}, -- Sets the delay between emitting droplets in a loop (for the EmitAmount method).
    StartingSize = Vector3.new(0.01, 0.7, 0.01), -- Sets the initial size of the droplets upon landing.
    Expansion = true, -- Determines whether a pool can expand when a droplet lands on it.
    MaximumSize = 1, -- Sets the maximum size a pool can reach.
})
```
#### Emitting Droplets
After initializing the module, you're all set to emit droplets. There are two key methods available for droplet emission: `EmitAmount` and `Emit`.
```lua
-- Emit a specific amount of droplets from a given origin in specific or nil direction
-- (Setting the Direction to nil will make droplets go in random directions)
Engine:EmitAmount(Origin, Direction, Amount)

-- Emit a single droplet from a given origin in a specific or nil direction
Engine:Emit(Origin, Direction)
```
In this instance, we’ll be utilizing the `EmitAmount` method. Typically, you’d use the `Emit` method when you want to create your own loop instead of relying on the built-in loop of `EmitAmount` . This gives you more control over the emission process.
