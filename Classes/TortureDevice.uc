class TortureDevice extends Actor;

var GGPawn gpawn;
var TortureComponent tc;
var float tortureDuration;
var float tortureMomentum;
var SoundCue baaScream1;
var SoundCue baaScream2;
var bool switchBaa;

function Torture(Pawn pawnToTorture)
{
	gpawn=GGPawn(pawnToTorture);
	tc=new class'TortureComponent';
	tc.AttachToPawn(gpawn);
	gpawn.SetRagdoll(true);
	if(GGGoat(gpawn) != none) GGGoat(gpawn).mLayStill=true;
	tc.SwitchOn();
	gpawn.mesh.AddForce(vect(0, 0, 1) * tortureMomentum * gpawn.GetMass());
	PlayBaaScream();

	SetTimer( 1.f, false, NameOf( StartTorture ));
}

function PlayBaaScream()
{
	switchBaa=!switchBaa;
	if(switchBaa)
	{
		gpawn.PlaySound( baaScream1 );
	}
	else
	{
		gpawn.PlaySound( baaScream2 );
	}
}

function StartTorture()
{
	SetTimer( tortureDuration, false, NameOf( StopTorture ));
	SetTimer( 2.f, false, NameOf( AddRandomForce ));
}

function AddRandomForce()
{
	local rotator rot;
	local vector dir;

	rot=Rotator(vect(1, 0, 0));
	rot.Yaw+=RandRange(0.f, 65536.f);
	dir=Normal(Vector(rot));
	dir.Z=1.f;
	gpawn.mesh.AddForce(dir * tortureMomentum * gpawn.GetMass());
	PlayBaaScream();

	SetTimer( 2.f, false, NameOf( AddRandomForce ));
}


event Tick( float deltaTime )
{
	Super.Tick( deltaTime );

	if(!gpawn.mIsRagdoll)
	{
		gpawn.SetRagdoll(true);
	}
}

function StopTorture()
{
	tc.SwitchOn(true);
	if(GGGoat(gpawn) != none) GGGoat(gpawn).mLayStill=GGGoat(gpawn).default.mLayStill;
	ClearTimer( NameOf( AddRandomForce ) );
	Destroy();
}

DefaultProperties
{
	tortureDuration=10.f
	tortureMomentum=1500.f
	baaScream1=SoundCue'Goat_Sounds.Cue.GoatSound_Bigge_CUe'
	baaScream2=SoundCue'Goat_Sounds.Cue.GoatSound_Armin_Cue'
}