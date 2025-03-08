class Indicator extends Actor;

var ParticleSystemComponent lightRayPSC;
var ParticleSystem lightRayPSTemplate;

event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	SetPhysics(PHYS_None);
	CollisionComponent=none;
	lightRayPSC=WorldInfo.MyEmitterPool.SpawnEmitter(lightRayPSTemplate, Location, Rotation, self);
	lightRayPSC.SetScale3D(vect(0.05f, 0.05f, 4.f));
	lightRayPSC.CustomTimeDilation=0.1f;
}

simulated event Destroyed()
{
	lightRayPSC.DeactivateSystem();
	lightRayPSC.KillParticlesForced();
	
	Super.Destroyed();
}

DefaultProperties
{
	bNoDelete=false
	bStatic=false
	bIgnoreBaseRotation=true
	lightRayPSTemplate=ParticleSystem'Whale.Effects.Water'
}