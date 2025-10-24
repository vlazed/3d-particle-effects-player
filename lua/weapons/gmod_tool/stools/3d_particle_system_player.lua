TOOL.Category = "Effects"
TOOL.Name = "#tool.3d_particle_system_player.name"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["filepath"] = ""
TOOL.ClientConVar["gamepath"] = ""
TOOL.ClientConVar["key"] = 0
TOOL.ClientConVar["toggle"] = 0
TOOL.ClientConVar["rate"] = 1
TOOL.ClientConVar["model"] = ""
TOOL.ClientConVar["starton"] = 1
TOOL.ClientConVar["filepath"] = 1
TOOL.ClientConVar["gamepath"] = 1
TOOL.ClientConVar["poolsize"] = 20

---@param cvarName string
---@return string
local function toolCVar(cvarName)
	return "3d_particle_system_player_" .. cvarName
end

local firstReload = true
function TOOL:Think()
	if CLIENT and firstReload then
		self:RebuildControlPanel()
		firstReload = false
	end
end

---Remove all 3D particle system from the entity
---@param tr table|TraceResult
---@return boolean
function TOOL:Reload(tr)
	local entity = tr.Entity
	if not IsValid(entity) or entity:IsPlayer() then
		return false
	end

	return true
end

function TOOL:Holster()
	self:ClearObjects()
end

if SERVER then
	function SpawnParticlePlayer(ply, ent, dataTable)
		print(ply, ent, dataTable)
		PrintTable(dataTable)
		if
			dataTable == nil
			or dataTable == {}
			or dataTable.FilePath == nil
			or dataTable.GamePath == nil
			or ent == nil
			or not IsValid(ent)
		then
			return
		end

		print("Spawn particle player")
		local particlePlayer = ents.Create("particle_player")
		if not IsValid(particlePlayer) then
			return
		end

		---@cast particlePlayer particle_player
		particlePlayer:SetPos(ent:GetPos())
		particlePlayer:SetAngles(ent:GetAngles())
		particlePlayer:SetParent(ent)
		ent:DeleteOnRemove(particlePlayer)

		particlePlayer:SetTargetEntity(ent)
		particlePlayer:SetRate(dataTable.Rate)
		particlePlayer:SetActive(dataTable.StartOn == 1 or dataTable.StartOn == true)
		particlePlayer:SetToggle(dataTable.Toggle == 1 or dataTable.Toggle == true)
		particlePlayer:SetNumpadKey(dataTable.NumpadKey)
		particlePlayer:SetFilePath(dataTable.FilePath)
		particlePlayer:SetGamePath(dataTable.GamePath)
		particlePlayer:SetPoolSize(dataTable.PoolSize)

		numpad.OnDown(ply, dataTable.NumpadKey, "3d_particle_system_player_press", particlePlayer)
		numpad.OnUp(ply, dataTable.NumpadKey, "3d_particle_system_player_release", particlePlayer)
		particlePlayer:SetNumpadState("")

		particlePlayer:Spawn()
		particlePlayer:Activate()
	end

	function AttachParticlePlayer(ply, ent, Data)
		if Data.NewTable then
			SpawnParticlePlayer(ply, ent, Data.NewTable)

			local dupetable = {}
			if ent.EntityMods and ent.EntityMods.Dupe3DParticlePlayer then
				dupetable = ent.EntityMods.Dupe3DParticlePlayer
			end
			table.insert(dupetable, Data.NewTable)
			duplicator.StoreEntityModifier(ent, "Dupe3DParticlePlayer", dupetable)
			return
		end
	end

	function Dupe3DParticlePlayer(ply, ent, Data)
		-- due to a problem with the easy bonemerge tool that causes entity modifiers to be applied TWICE, we need to remove the effects that were added the first time
		for _, asdf in ipairs(ents:GetAll()) do
			if asdf:GetClass() == "particle_player" and asdf:GetParent() == ent then
				asdf:Remove()
			end
		end

		for _, DataTable in pairs(Data) do
			SpawnParticlePlayer(ply, ent, DataTable)
		end
	end
	duplicator.RegisterEntityModifier("Dupe3DParticlePlayer", Dupe3DParticlePlayer)
end

---Attach a 3D particle system to an entity
---@param tr table|TraceResult
---@return boolean
function TOOL:LeftClick(tr)
	local entity = tr.Entity
	if not IsValid(entity) or entity:IsPlayer() then
		return false
	end

	local filepath = self:GetClientInfo("filepath")
	local gamepath = self:GetClientInfo("gamepath")
	local rate = self:GetClientNumber("rate", 0)
	local key = self:GetClientNumber("numpad", 0)
	local toggle = self:GetClientNumber("toggle", 0)
	local starton = self:GetClientNumber("starton", 0)
	local poolsize = self:GetClientNumber("poolsize", 0)

	local ply = self:GetOwner()

	if CLIENT then
		return true
	end

	-- TODO: Add attachment point support
	AttachParticlePlayer(ply, entity, {
		NewTable = {
			Rate = rate,
			Toggle = toggle,
			StartOn = starton,
			NumpadKey = key,
			FilePath = filepath,
			GamePath = gamepath,
			PoolSize = poolsize,
		},
	})

	return true
end

---Add a prop that holds a 3D particle system
---@param tr table|TraceResult
---@return boolean
function TOOL:RightClick(tr)
	local filepath = self:GetClientInfo("filepath")
	local gamepath = self:GetClientInfo("gamepath")
	local rate = self:GetClientNumber("rate", 0)
	local key = self:GetClientNumber("key", 0)
	local toggle = self:GetClientNumber("toggle", 0)
	local starton = self:GetClientNumber("starton", 0)
	local poolsize = self:GetClientNumber("poolsize", 0)

	local ply = self:GetOwner()

	local model = self:GetClientInfo("model")

	if not util.IsValidModel(model) then
		return false
	end
	if not util.IsValidProp(model) then
		return false
	end
	if CLIENT then
		return true
	end

	local prop = ents.Create("prop_physics")
	prop:SetModel(model)
	prop:SetPos(tr.HitPos - tr.HitNormal * prop:OBBMins().z)
	prop:SetCollisionGroup(20)
	prop:Spawn()

	prop:GetPhysicsObject():EnableMotion(false)

	undo.Create("prop")
	undo.AddEntity(prop)
	undo.SetPlayer(ply)
	undo.Finish("Prop (" .. tostring(model) .. ")")

	AttachParticlePlayer(ply, prop, {
		NewTable = {
			Rate = rate,
			Toggle = toggle,
			StartOn = starton,
			NumpadKey = key,
			FilePath = filepath,
			GamePath = gamepath,
			PoolSize = poolsize,
		},
	})

	return true
end

if SERVER then
	return
end

TOOL:BuildConVarList()

---@param suffix string
---@return string
local function localization(suffix)
	return language.GetPhrase("tool.3d_particle_system_player." .. suffix)
end

---@param parent DTree_Node
---@param particleConfig string
---@return unknown
local function addNode(parent, particleConfig, filePath, gamePath)
	local node = parent:AddNode(particleConfig, "icon16/script.png")

	function node:DoClick()
		GetConVar(toolCVar("filepath")):SetString(filePath)
		GetConVar(toolCVar("gamepath")):SetString(gamePath)

		return true
	end

	return node
end

---@param tree DTree
local function fillFileTree(tree)
	local workshopNode = tree:AddNode("Workshop", "icon16/wrench.png")
	---@cast workshopNode DTree_Node
	for _, addon in ipairs(engine.GetAddons()) do
		local particleConfigs = file.Find("lua/particles/*", addon.title)
		for _, particleConfig in ipairs(particleConfigs or {}) do
			addNode(workshopNode, particleConfig, "lua/particles/" .. particleConfig, addon.title)
		end
	end

	local localNode = tree:AddNode("Local", "icon16/folder_table.png")
	---@cast localNode DTree_Node
	local _, addonFolders = file.Find("addons/*", "MOD")
	for _, folder in ipairs(addonFolders or {}) do
		local particleConfigs = file.Find("addons/" .. folder .. "/lua/particles/*", "MOD")
		for _, particleConfig in ipairs(particleConfigs or {}) do
			addNode(localNode, particleConfig, "addons/" .. folder .. "/lua/particles/" .. particleConfig, "MOD")
		end
	end

	local dataNode = tree:AddNode("Data", "icon16/cog.png")
	---@cast dataNode DTree_Node
	local particleConfigs = file.Find("3d_particle_system_editor/*", "DATA")
	for _, particleConfig in ipairs(particleConfigs or {}) do
		addNode(dataNode, particleConfig, "3d_particle_system_editor/" .. particleConfig, "DATA")
	end
end

---@param cPanel ControlPanel|DForm
function TOOL.BuildCPanel(cPanel)
	local tree = vgui.Create("DTree", cPanel)
	tree:SizeTo(-1, 300, 0.1)
	cPanel:AddItem(tree)

	fillFileTree(tree)

	cPanel:KeyBinder(localization("key"), toolCVar("key"))
	cPanel:CheckBox(localization("starton"), toolCVar("starton"))
	cPanel:CheckBox(localization("toggle"), toolCVar("toggle"))
	cPanel:NumSlider(localization("rate"), toolCVar("rate"), 0, 10, 4)
	cPanel:NumSlider(localization("poolsize"), toolCVar("poolsize"), 1, 100, 0)

	local convar = { toolCVar("model") }
	-- From Advanced Particle Controller
	local modellist = {
		["models/hunter/plates/plate025x025.mdl"] = convar,
		["models/hunter/plates/plate.mdl"] = convar,
		["models/weapons/w_smg1.mdl"] = convar,
		["models/props_junk/popcan01a.mdl"] = convar,
	}
	cPanel:PropSelect(localization("model"), toolCVar("model"), modellist)
end

TOOL.Information = {
	{ name = "left", stage = 0 },
	{ name = "right", stage = 0 },
	{ name = "reload" },
}
