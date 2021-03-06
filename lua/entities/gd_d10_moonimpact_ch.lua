AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )

ENT.Spawnable		            	 = false        
ENT.AdminSpawnable		             = false 

ENT.PrintName		                 =  "Moon"
ENT.Author			                 =  "Hmm"
ENT.Contact		                     =  "Hmm"
ENT.Category                         =  "Hmm"

ENT.Model                            = "models/ramses/models/nature/moon.mdl"


function ENT:Initialize()	

    game.AddParticles( "particles/chicxulub.pcf" )
	if (SERVER) then
		
		self:SetModel(self.Model)
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS  )
		self:SetUseType( ONOFF_USE )

		
		local phys = self:GetPhysicsObject()
		phys:Wake()
		
		if (phys:IsValid()) then
			phys:SetMass(700)
		end 		
		
		phys:EnableDrag( false )	
		
		timer.Simple(14, function()
			if !self:IsValid() then return end
			self:Remove()
		end)

	end
end


function ENT:SpawnFunction( ply, tr )
	if ( !tr.Hit ) then return end

	self.OWNER = ply
	local ent = ents.Create( self.ClassName )
	ent:SetPhysicsAttacker(ply)
	ent:SetPos( tr.HitPos + tr.HitNormal * -1.00  ) 
	ent:Spawn()
	ent:Activate()
	return ent
	
end


function ENT:PhysicsCollide( data, physobj )

	local tr,trace = {},{}
	tr.start = self:GetPos() + self:GetForward() * -200
	tr.endpos = tr.start + self:GetForward() * 500
	tr.filter = { self, physobj }
	trace = util.TraceLine( tr )
	
	if( trace.HitSky ) then
	
		self:Remove()
		
		return
		
	end
	
	if (data.Speed > 200 ) then 
	
		
		self:Explode()
						 

	end

	
end

function ENT:Explode()

	if( !IsValid( self.Owner ) ) then
		
		self.Owner = self
		
	end
	
	local pos = self:GetPos()
	local mat = self.Material
	local mat = self.Material
	local vel = self.Move_vector 
	
	local metsound = "disasters/space/chucxulub/chucxulub.wav"
	
	ParticleEffect("chicxuclub_explosion_main", self:GetPos(), Angle(0,0,0), nil)
	
	CreateSoundWave(metsound, self:GetPos(), "stereo" ,340.29, {100,110}, 5)
	
	for k,v in pairs(ents.FindInSphere(self:GetPos(), 5000000)) do
		
	local dist = ( v:GetPos() - self:GetPos() ):Length() 	
		
	if (  v != self && IsValid( v ) && IsValid( v:GetPhysicsObject() ) ) and (v:GetClass()!= "phys_constraintsystem" and v:GetClass()!= "phys_constraint"  and v:GetClass()!= "logic_collision_pair") then 
	
	if dist < 5000000 then 
	
	if( !v.Destroy ) then
						
			constraint.RemoveAll( v )
			v:GetPhysicsObject():EnableMotion(true)
			v:GetPhysicsObject():Wake()
			v.Destroy = true
			
						end
						
					end
						
			  end
				  
		end
	
	local pe = ents.Create( "env_physexplosion" );
	pe:SetPos( self:GetPos() );
	pe:SetKeyValue( "Magnitude", 5000000 );
	pe:SetKeyValue( "radius", 5000000 );
	pe:SetKeyValue( "spawnflags", 19 );
	pe:Spawn();
	pe:Activate();
	pe:Fire( "Explode", "", 0 );
	pe:Fire( "Kill", "", 0.5 );
	
	util.BlastDamage( self, self, self:GetPos()+Vector(0,0,12), 5000000, math.random( 100000, 400000 ) )
	
	timer.Simple(5, function()
		if GetConVar("gdisasters_atmosphere"):GetInt() <= 0 then return end
		if #ents.FindByClass("gd_w*") >= 1 then return end
		
		local ent = ents.Create("gd_w3_heavyashstorm")
		local ent2 = ents.Create("gd_d10_meteorshower")
		local ent3 = ents.Create("gd_d10_meteoriteshower")
		ent:Spawn()
		ent:Activate()
		
		ent2:Spawn()
		ent2:Activate()
		
		ent3:Spawn()
		ent3:Activate()
	
	end)
	timer.Simple(45, function()
		if GetConVar("gdisasters_atmosphere"):GetInt() <= 0 then return end
		if #ents.FindByClass("gd_w*") >= 1 then return end
		local ent4 = ents.Create("gd_w4_heavyacidrain")
		ent4:Spawn()
		ent4:Activate()
	end)

	self:Remove()

		
end

function ENT:Think()
		if (CLIENT) then
		
	
		end
	
		local t =  ( (1 / (engine.TickInterval())) ) / 66.666 * 0.1	
		
		if (SERVER) then
		
		
		if self:WaterLevel() >= 2 then self:Remove() end
	
		self:NextThink(CurTime() + t)
		return true
	
	end
			
end


function ENT:OnRemove()
end

function ENT:Draw()



	self:DrawModel()
	
end




