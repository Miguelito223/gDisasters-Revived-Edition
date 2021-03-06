AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.Spawnable		            	 = false        
ENT.AdminSpawnable		             = false 

ENT.PrintName		                 =  "Lava Flood"
ENT.Author			                 =  "Hmm"
ENT.Contact		                     =  "Hmm"
ENT.Category                         =  "Hmm"
ENT.MaxFloodLevel                    =  600

function ENT:Initialize()	

	
	if (SERVER) then
		
		self:SetModel("models/props_junk/PopCan01a.mdl")

		self:SetSolid( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_NONE  )
		self:SetUseType( ONOFF_USE )
		self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
				
		self.FloodHeight = 0
		self:SetNWFloat("FloodHeight", self.FloodHeight)
		
		if IsMapRegistered()==false then self:Remove() end 

			
		
	end
end

function ENT:EFire(pointer, arg) 
	
	if pointer == "EnableFHGain" then self.shouldFloodGainHeight = arg or true 
	elseif pointer == "Enable" then 
	elseif pointer == "MaxHeight" then self.MaxFloodLevel = arg or 600 
	elseif pointer == "Parent" then self.Parent = arg 
	elseif pointer == "Height" then self.FloodHeight = arg or 100 
	end
end

function createLava(maxheight, parent)

	if IsMapRegistered() == true then
	
	for k, v in pairs(ents.FindByClass("env_dynamiclava")) do
		v:Remove()
	end
	
	local flood = ents.Create("env_dynamiclava")
	flood:SetPos(getMapCenterFloorPos())
	flood:Spawn()
	flood:Activate()

	flood:EFire("Parent", parent)
	flood:EFire("MaxHeight", maxheight)
	flood:EFire("Enable", true)
	
	return flood
	
	end
end

function floodExists()

	return #ents.FindByClass("env_dynamiclava")>0
end


function ENT:SpawnFunction( ply, tr )
	if ( !tr.Hit ) then return end
	
	self.OWNER = ply
	local ent = ents.Create( self.ClassName )
	ent:SetPhysicsAttacker(ply)
	ent:SetPos( getMapCenterFloorPos() )
	ent:Spawn()
	ent:Activate()
	

	return ent
end


function ENT:LavaFloodHeightIncrement(scalar, t)


	local sim_quality     = GetConVar( "gdisasters_envdynamicwater_candamageconstraints" ):GetFloat() --  original lava simulation is based on a value of 0.01 ( which is alright but not for big servers ) 
	local sim_quality_mod = sim_quality / 0.01
	local overall_mod     = sim_quality_mod * scalar
	
	
	self.FloodHeight = math.Clamp(self.FloodHeight + ( (1/6) * overall_mod), 0, self.MaxFloodLevel) 
	self:SetNWFloat("FloodHeight", self.FloodHeight)
end


function ENT:PlayerIgnite(v)	
	if v.IsInlava then
		v:Ignite()
		v:TakeDamage(10, self, self)
	end
end

local ignore_ents ={
["phys_constraintsystem"]=true,
["phys_constraint"]=true,
["logic_collision_pair"]=true,
["entityflame"]=true,
["worldspawn"]=true
}

function IsValidPhysicsEnt(ent)
	return !ignore_ents[ent:GetClass()]
end

function ENT:ProcesslavaFlood(scalar, t)
	local zmax = self:GetPos().z + self.FloodHeight 
	local pos  = self:GetPos() - Vector(0,0,50)
	local wr   = 0.999               -- lava friction
	local sim_quality     = GetConVar( "gdisasters_envdynamicwater_candamageconstraints" ):GetFloat() --  original lava simulation is based on a value of 0.01 ( which is alright but not for big servers ) 
	local sim_quality_mod = sim_quality / 0.01
	
	local overall_mod     = sim_quality_mod * scalar 

	for k, v in pairs(ents.GetAll()) do
	
		local phys = v:GetPhysicsObject()
		
		if phys:IsValid()  and  IsValidPhysicsEnt(v) then 
			local vpos = v:GetPos()
	
			local diff = zmax-vpos.z 
			
			if v:IsPlayer() then
			
				local eye = v:EyePos()	
				
				if eye.z >= pos.z and eye.z <= zmax then
					v:SetNWBool("IsUnderlava", true)		
					
					self:PlayerIgnite(v)
					v:SetNWInt("ZlavaDepth", diff)
					
					
					
				else
					if v:GetNWBool("IsUnderlava")==true then
						net.Start("gd_screen_particles")
						net.WriteString("hud/warp_ripple3")
						net.WriteFloat(math.random(10,58))
						net.WriteFloat(math.random(10,50)/10)
						net.WriteFloat(math.random(0,10))
						net.WriteVector(Vector(0,math.random(0,200)/100,0))
						net.Send(v)
						
					
						
					end
					
					v:SetNWBool("IsUnderlava", false)
				end
			end
	
	
	
			if (vpos.z >= pos.z and vpos.z <= zmax) and v.IsInlava!=true then
				v.IsInlava = true 
				
				if math.random(1,2)==1 then
					ParticleEffect( "lava_splash_main", Vector(vpos.x, vpos.y, zmax), Angle(0,0,0), nil)
					v:EmitSound(table.Random({"ambient/water/water_splash1.wav","ambient/water/water_splash2.wav","ambient/water/water_splash3.wav"}), 80, 100)
				end
				
			end
			
			if (v:GetPos().z < pos.z or v:GetPos().z > zmax) and v.IsInlava==true then
				v.IsInlava = false
			end
			
			if v.IsInlava and v:IsPlayer() then
				
				v:SetVelocity( v:GetVelocity() * -0.5 + Vector(0,0,20) )
				v:Ignite()
				v:TakeDamage(10, self, self)
			
			elseif v.IsInlava and v:IsNPC() or v:IsNextBot() then
				v:SetVelocity( ((Vector(0,0,math.Clamp(diff,-100,50)/4) * 0.99)  * overall_mod) - (v:GetVelocity() * 0.05))
				v:TakeDamage(1, self, self)
				v:Ignite()
				v:TakeDamage(10, self, self)
			else
				if v.IsInlava then
					
					local massmod       = math.Clamp((phys:GetMass()/25000),0,1)
					local buoyancy_mod  = GetBuoyancyMod(v)
					
					if v:GetModel()=="models/airboat.mdl" then 
						buoyancy_mod = 5 
						
					end 
					
					local buoyancy      = massmod + (buoyancy_mod*(1 + massmod))
					
					local friction      = (1-math.Clamp( (phys:GetVelocity():Length()*overall_mod)/50000,0,1)) 
					
					if buoyancy_mod <= 1 then 
						friction  = (1-math.Clamp( (phys:GetVelocity():Length()*overall_mod)/10000,0,1)) 
					end
			
					local add_vel       = Vector(0,0, (math.Clamp(diff,-20,20)/8 * buoyancy)  * overall_mod)
					phys:AddVelocity( add_vel )
					
					local resultant_vel = v:GetVelocity() * friction
					local final_vel     = Vector(resultant_vel.x * wr,resultant_vel.y * wr, resultant_vel.z * friction)
		
					
					phys:SetVelocity( final_vel)
					v:Ignite()
					
					if v:IsVehicle() and v:GetClass()!="prop_vehicle_airboat" then 
						v:Fire("TurnOff", 0.1, 0)
					end 
					
					if (v.isWacAircraft) then
						v:setEngine(false)
						v.engineDead = true							 
					end
				end
			end

		end
	
	end
end

hook.Add( "Tick", "gDisasters_EnvlavaMovement", function(  )
	if !SERVER then return end 
	
	for k, ply in pairs(player.GetAll()) do 
	
		if ply.IsInlava then
	
			if ply:KeyDown( IN_JUMP) then 
				if ply:GetVelocity():Dot(Vector(0,0,30)) < 500 then 
				

				ply:SetVelocity(  Vector( 0, 0, 30 ) )
				
				end
			elseif ply:KeyDown( IN_FORWARD) then
				if ply:GetVelocity():Dot(ply:GetAimVector() * 100) < 10000 then 
					ply:SetVelocity(  ply:GetAimVector() * 100 )
				end
			end
		end
	end
	
end )

function ENT:IsParentValid()

	if self.Parent:IsValid()==false or self.Parent==nil then self:Remove() end
	
end

function ENT:Think()
	if (SERVER) then
		local t = ( (1 / (engine.TickInterval())) ) / 66.666 * 0.1-- tick dependant function that allows for constant think loop regardless of server tickrate
		
		local scalar = (66/ ( 1/engine.TickInterval()))
		self:ProcesslavaFlood(scalar, t)
		self:LavaFloodHeightIncrement(scalar, t)
		self:IsParentValid()
		
		self:NextThink(CurTime() + t)
		return true
	end
	
end
function ENT:OnRemove()
	if (SERVER) then
		for k, v in pairs(player.GetAll()) do
		
			v:SetNWBool("IsUnderlava", false)
			v.IsInlava = false
		end
	end
	self:StopParticles()
end
	
function ENT:Draw()
			
end


function env_dynamiclava_Drawlava()

	local flood = ents.FindByClass("env_dynamiclava")[1]
	if !flood then return end
	

	local model = ClientsideModel("models/props_junk/PopCan01a.mdl", RENDERGROUP_OPAQUE)
	model:SetNoDraw(true)	
	
	local height =  flood:GetNWFloat("FloodHeight")
	local map_bounds = getMapBounds()
	local vmin, vmax =  Vector(map_bounds[1].x,map_bounds[1].y,0),  Vector(map_bounds[2].x,map_bounds[2].y,height)

	local function RenderFix()
	
	
		cam.Start3D()
		
			local mat = Matrix()
			mat:Scale(Vector(0, 0, 0))
			model:EnableMatrix("RenderMultiply", mat)
			model:SetPos(flood:GetPos())
			model:DrawModel()
		
			render.SuppressEngineLighting( true ) 
		
			
			render.SuppressEngineLighting( false ) 
		cam.End3D()
	
	end
	local function EasyVert( position, normal, u, v )

		mesh.Position( position );
		mesh.Normal( normal );
		mesh.TexCoord( 0, u, v );

		mesh.AdvanceVertex( );
	 
	end

	local function Drawlava()
	
		render.SetMaterial( Material("nature/env_dynamiclava/base_lava") )
		render.SetBlend( 1 )
		
		local matrix = Matrix( );
		matrix:Translate( getMapCenterFloorPos() );
		matrix:Rotate( flood:GetAngles( ) );
		matrix:Scale( Vector(1,1,1) )
		
		local hmod = height -1 
		
		cam.PushModelMatrix( matrix );

			mesh.Begin( MATERIAL_QUADS, 2 );

			EasyVert( Vector(map_bounds[1].x,map_bounds[1].y,hmod), vector_up, 0,0 );
			EasyVert( Vector(map_bounds[1].x,map_bounds[2].y,hmod), vector_up, 0,25 );
			EasyVert( Vector(map_bounds[2].x,map_bounds[2].y,hmod), vector_up, 25,25 );
			EasyVert( Vector(map_bounds[2].x,map_bounds[1].y,hmod), vector_up, 25,0 );
		
			mesh.End( );
			 
		cam.PopModelMatrix( );	
				
	
	end
	
	
	RenderFix()
	Drawlava()	
	
	model:Remove()
end


if (CLIENT) then
	function DrawFlood()
	
		
		if IsMapRegistered() then
		
			env_dynamiclava_Drawlava()
			
			
		end
		
	end
	hook.Add("PreDrawTranslucentRenderables", "DRAWFLOOD", DrawFlood)
	
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end


