class GoatBook extends GGKActor
	placeable;

var GGAIControllerSlender slenderAI;
var Indicator ind;
var SoundCue bookFoundSound;
var bool destroyedCorrectly;

function vector FindGoatCenter()
{
	local GGPlayerControllerGame pc;
	local vector center;
	local float count;
	local bool first;

	first=true;
	count=0;
	foreach WorldInfo.AllControllers( class'GGPlayerControllerGame', pc )
	{
		if( pc.IsLocalPlayerController() && pc.Pawn != none )
		{
			count+=1.f;
			if(first)
			{
				center=pc.Pawn.Location;
				first=false;
			}
			else
			{
				center+=pc.Pawn.Location;
			}

		}
	}
	if(count > 0)
	{
		center/=count;
	}
	else
	{
		center=slenderAI.mMyPawn.Location;
	}

	return center;
}

function placeBook(GGAIControllerSlender sAI)
{
	local vector dest, center;
	local rotator rot;
	local float h, r, dist;
	local Actor hitActor;
	local vector hitLocation, hitNormal, traceEnd, traceStart;

	slenderAI=sAI;
	if(slenderAI == none)
	{
		DestroyCorrectly();
		return;
	}

	center=FindGoatCenter();

	rot=Rotator(vect(1, 0, 0));
	rot.Yaw+=RandRange(0.f, 65536.f);

	dist=slenderAI.maxTeleportDistance;
	dist=RandRange(dist/2.f, dist);

	//dest=center;
	dest=center+Normal(Vector(rot))*dist;
	traceStart=dest;
	traceEnd=dest;
	traceStart.Z=10000.f;
	traceEnd.Z=-3000;

	hitActor = Trace( hitLocation, hitNormal, traceEnd, traceStart, true);
	if( hitActor == none )
	{
		hitLocation = traceEnd;
	}

	GetBoundingCylinder( r, h );
	hitLocation.Z+=h;
	SetPhysics(PHYS_None);
	SetLocation(hitLocation);
	CollisionComponent.SetRBPosition(hitLocation);
	SetPhysics(PHYS_RigidBody);
}

event Tick( float deltaTime )
{
	Super.Tick( deltaTime );

	if(Location.Z < -3000)
	{
		Destroy();
	}

	if(ind == none)
	{
		ind=Spawn(class'Indicator');
		ind.SetBase(self);
	}
}

function DestroyCorrectly()
{
	destroyedCorrectly=true;
	Destroy();
}

simulated event Destroyed()
{
	ind.Destroy();

	if(!destroyedCorrectly && slenderAI != none)
	{
		slenderAI.ReplaceBook(self);
	}

	Super.Destroyed();
}

function OnGrabbed( Actor grabbedByActor )
{
	super.OnGrabbed(grabbedByActor);

	if(slenderAI != none)
	{
		PlaySound( bookFoundSound );
		slenderAI.slenderBookFound(self, grabbedByActor);
	}
}

function int GetScore()
{
	return 1000;
}

/**
 * Access to the in game name of this actor
 */
function string GetActorName()
{
	return "Slender Goat Book";
}

DefaultProperties
{
	Begin Object name=StaticMeshComponent0
		StaticMesh=StaticMesh'Living_Room_01.Mesh.Book_01'
	End Object

	bNoDelete=false
	bStatic=false

	bookFoundSound=SoundCue'Goat_Sounds.Cue.HolyGoat_Cue'
}