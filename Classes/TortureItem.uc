class TortureItem extends GGRollerSkate;

var GGPawn gpawn;

function name FindFirstNXActorBone( name socketName )
{
	local name boneName;
	local RB_BodyInstance bodyInstance;

	boneName = gpawn.mesh.GetSocketBoneName( socketName );

	do
	{
		bodyInstance = gpawn.mesh.FindBodyInstanceNamed( boneName );

		if( bodyInstance != none )
		{
			return boneName;
		}

  		boneName = gpawn.mesh.GetParentBone( boneName );
	}until( boneName == 'none' );

	return boneName;
}

function AttachToPawn( GGPawn targetPawn, name socketName )
{
	local bool oldCollideActors, oldBlockActors;

	gpawn = targetPawn;
	
	mThruster = gpawn.Spawn( class'RB_Thruster' );
	mThruster.ThrustStrength = 1000;

	oldCollideActors = mThruster.bCollideActors;
	oldBlockActors = mThruster.bBlockActors;
	mThruster.SetCollision(false, false);

	// The thruster need to sit on a nxactor, so we traverse the parent bones untill we find a NX-actor
	mThruster.SetBase( gpawn,, gpawn.mesh, FindFirstNXActorBone( socketName ) );

	mThruster.SetCollision( oldCollideActors, oldBlockActors );

	mThrustParticle=none;
	mThrustSoundCue=none;
}

function Detach()
{
	mThruster.bThrustEnabled=false;
	mThruster.SetBase(none);
}