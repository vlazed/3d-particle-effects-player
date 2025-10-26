AddCSLuaFile()

---@class particle_player: ENT
---@field GetTargetEntity fun(self: particle_player): targetEntity: Entity
---@field SetTargetEntity fun(self: particle_player, targetEntity: Entity)
---@field GetNumpadState fun(self: particle_player): numpadState: string
---@field SetNumpadState fun(self: particle_player, numpadState: string)
---@field GetFilePath fun(self: particle_player): filePath: string
---@field SetFilePath fun(self: particle_player, filePath: string)
---@field GetGamePath fun(self: particle_player): gamePath: string
---@field SetGamePath fun(self: particle_player, gamePath: string)
---@field GetNumpadKey fun(self: particle_player): numpadKey: integer
---@field SetNumpadKey fun(self: particle_player, numpadKey: integer)
---@field GetPoolSize fun(self: particle_player): poolSize: integer
---@field SetPoolSize fun(self: particle_player, poolSize: integer)
---@field GetRate fun(self: particle_player): rate: number
---@field SetRate fun(self: particle_player, rate: number)
---@field GetActive fun(self: particle_player): active: boolean
---@field SetActive fun(self: particle_player, active: boolean)
---@field GetToggle fun(self: particle_player): toggle: boolean
---@field SetToggle fun(self: particle_player, toggle: boolean)
local ENT = ENT

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "3D Particle System Player"
ENT.Author = ""

ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "TargetEntity")

	self:NetworkVar("String", 0, "NumpadState")
	self:NetworkVar("String", 1, "FilePath")
	self:NetworkVar("String", 2, "GamePath")

	self:NetworkVar("Int", 0, "NumpadKey")
	self:NetworkVar("Int", 1, "PoolSize")
	self:NetworkVar("Float", 0, "Rate")

	self:NetworkVar("Bool", 0, "Active")
	self:NetworkVar("Bool", 1, "Toggle")
end

function ENT:Initialize()
	self:SetModel("models/hunter/plates/plate.mdl")
	self:SetNoDraw(true)

	if CLIENT then
		self.emitterPool = {}
		self:GenerateConfig()

		if self:GetRate() > 0 then
			self.NextRepeat = 0
		else
			if self:GetActive() then
				self:AttachParticle()
			end
		end
	end
end

local function removeEmitters(self)
	for _, emitter in ipairs(self.emitterPool or {}) do
		emitter:Destroy()
		emitter:Remove()
	end
	self.emitterPool = {}
end

function ENT:RemoveParticle()
	if CLIENT then
		if self.maxLifeTime then
			timer.Simple(self.maxLifeTime, function()
				if (IsValid(self) and not self:GetActive()) or not IsValid(self) then
					removeEmitters(self)
				end
			end)
		else
			removeEmitters(self)
		end
	end
end

function ENT:GenerateConfig()
	self.config = file.Read(self:GetFilePath(), self:GetGamePath())

	self.particles = GLOBALS_3D_PARTICLE_PARSER:ParseConfiguration(self.config)

	self.maxLifeTime = -1
	for _, particle in pairs(self.particles) do
		if particle.LifeTime > self.maxLifeTime then
			self.maxLifeTime = particle.LifeTime
		end
	end
end

function ENT:AttachParticle()
	if CLIENT then
		local emitter = ents.CreateClientside("3d_particle_system_base")
		emitter:SetPos(Vector(0, 0, 0))
		emitter:Spawn()
		emitter:SetPos(self:GetPos())
		emitter:SetAngles(self:GetAngles())
		emitter:SetLifeTime(1e9)

		emitter:InitializeParticles(self.particles)
		table.insert(self.emitterPool, emitter)
		if #self.emitterPool > self:GetPoolSize() then
			self.emitterPool[1]:Destroy()
			self.emitterPool[1]:Remove()
			table.remove(self.emitterPool, 1)
		end
	end
end

function ENT:Think()
	if SERVER then
		return
	end

	if not self.config then
		return
	end

	if self:GetNumpadState() == "on" then
		self:SetNumpadState("")
		if self:GetRate() > 0 then
			self.NextRepeat = 0
		else
			if self:GetActive() then
				self:AttachParticle()
			end
		end
	end

	if self:GetActive() and self:GetRate() > 0 then
		self.removed = false
		if self.NextRepeat <= CurTime() then
			self:AttachParticle()
			self.NextRepeat = CurTime() + self:GetRate()
		end
	end

	if not self:GetActive() and not self.removed then
		self:RemoveParticle()
		self.removed = true
	end

	self:NextThink(CurTime())
	return true
end

if SERVER then
	-- The press and release code come from the Advanced Particle Controller
	-- They've been edited to make StyLua formatting work
	-- Gonna simplify things by reusing implementations that almost everyone is used to
	local function press(pl, ent)
		if not ent or not IsValid(ent) then
			return
		end

		if ent:GetToggle() then
			if ent:GetActive() == false then
				ent:SetActive(true)
				ent:SetNumpadState("on")
			else
				ent:SetActive(false)
				ent:SetNumpadState("off")
			end
		else
			ent:SetActive(true)
			ent:SetNumpadState("on")
		end
	end

	local function release(pl, ent)
		if not ent or not IsValid(ent) then
			return
		end

		if ent:GetToggle() then
			return
		end

		ent:SetActive(false)
		ent:SetNumpadState("off")
	end

	numpad.Register("3d_particle_system_player_press", press)
	numpad.Register("3d_particle_system_player_release", release)
end

function ENT:OnRemove()
	removeEmitters(self)
end

duplicator.RegisterEntityClass("particle_player", function(ply, data) end, "Data")
