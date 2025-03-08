class SlenderGoatComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;

var SkeletalMesh mSpaceGoatMesh;
var AnimSet mSpaceGoatAnimSet;
var AnimTree mSpaceGoatAnimTree;
var PhysicsAsset mSpaceGoatPhysAsset;

var float mNewCollisionRadius;
var float mNewCollisionHeight;

var float mSightRadius;
var ParticleSystem mTeleportParticleTemplate;
var ParticleSystemComponent mTeleportParticle;
var AudioComponent ac;
var SoundCue teleportSound;
var GGPawn lastTarget;

var SoundCue slenderBaaSoundCue;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	local GGRippedGoatInfo rippedGoatinfo;

	super.AttachToPlayer( goat, owningMutator );

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;

		if(!class'SlenderGoat'.default.isSlenderGoatUnlocked)
		{
			DisplayLockMessage();
			return;
		}

		gMe.mNeckBoneName = 'Spine_02';

        gMe.mesh.SetSkeletalMesh( mSpaceGoatMesh );
        gMe.mesh.SetPhysicsAsset( mSpaceGoatPhysAsset );
        gMe.mesh.SetAnimTreeTemplate( mSpaceGoatAnimTree );
        gMe.mesh.AnimSets[ 0 ] = mSpaceGoatAnimSet;

        gMe.mCameraLookAtOffset = vect( 0.0f, 0.0f, 100.0f );

        gMe.mRagdollCollisionSpeed = gMe.mWalkSpeed + ( gMe.mSprintSpeed - gMe.mWalkSpeed ) * 0.5f;
        gMe.mRagdollLandSpeed = 1780.0f;

        gMe.mAbilities[ EAT_Horn ].mRange = 60.0f;
        gMe.mAbilities[ EAT_Horn ].mDamage = 400.0f;
        gMe.mAbilities[ EAT_Kick ].mRange = 70.0f;
        gMe.mAbilities[ EAT_Kick ].mDamage = 800.0f;
        gMe.mAbilities[ EAT_Bite ].mRange = 170.0f;

        gMe.ClearBoneScaleInfos();
        gMe.AddBoneScaleInfo( 'Head', 1.5f, 2.0f );
        gMe.AddBoneScaleInfo( 'Eye_Base_L', 1.5f, 2.0f );
        gMe.AddBoneScaleInfo( 'Eye_Base_R', 1.5f, 2.0f );

		rippedGoatinfo = new class'GGRippedGoatInfo';
		rippedGoatinfo.AttachToPlayer( gMe, myMut );

		gMe.SetLocation( gMe.Location + vect( 0.0f, 0.0f, 1.0f ) * ( mNewCollisionHeight - gMe.GetCollisionHeight() ) );
        gMe.SetCollisionSize( mNewCollisionRadius, mNewCollisionHeight );

		gMe.mBaaSoundCue=slenderBaaSoundCue;

		gMe.FetchTongueControl();//Useless, the Space Goat don't have tongue...
	}
}

function ModifyCameraZoom( GGGoat goat )
{
    local GGCameraModeOrbital orbitalCamera;

	orbitalCamera = GGCameraModeOrbital( GGCamera( PlayerController( goat.Controller ).PlayerCamera ).mCameraModes[ CM_ORBIT ] );

	orbitalCamera.mMaxZoomDistance = 1500;
	orbitalCamera.mMinZoomDistance = 250;
	orbitalCamera.mDesiredZoomDistance = 1000;
	orbitalCamera.mCurrentZoomDistance = 1000;
}

simulated event TickMutatorComponent( float delta )
{
	local GGNPc npc;
	local GGAIController aic;

	if(!class'SlenderGoat'.default.isSlenderGoatUnlocked)
	{
		return;
	}

	foreach gMe.CollidingActors( class'GGNPc', npc, mSightRadius, gMe.Location )
	{
		aic = GGAIController(npc.Controller);
		if(!aic.IsInState('StartPanic'))
		{
			//Force panic on NPC you see
			aic.mLastSeenGoat=gMe;
			aic.Panic();
		}
	}

	if(ac == none || ac.IsPendingKill())
	{
		ac=gMe.CreateAudioComponent(teleportSound, false);
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	if(PCOwner != gMe.Controller)
		return;

	if( keyState == KS_Down )
	{
		if(newKey == 'X' || newKey == 'XboxTypeS_LeftThumbStick')
		{
			gMe.SetTimer(1.f, false, NameOf(DelayedTeleport), self);
		}
	}
	else if( keyState == KS_Up )
	{
		if(newKey == 'X' || newKey == 'XboxTypeS_LeftThumbStick')
		{
			gMe.ClearTimer(NameOf(DelayedTeleport), self);
		}
	}
}

function DelayedTeleport()
{
	Teleport();
}

function Teleport()
{
	local vector dest, dir;
	local rotator rot;
	local float h, r;
	local Actor hitActor;
	local vector hitLocation, hitNormal, traceEnd, traceStart;
	local float teleportDistance;

	//WorldInfo.Game.Broadcast(self, "Teleport");

	if(gMe.mIsRagdoll)
	{
		return;
	}

	if( gMe.IsTimerActive( NameOf( StopTeleportEffect ), self ) )
	{
		gMe.ClearTimer( NameOf( StopTeleportEffect ), self );
		StopTeleportEffect();
	}
	ac.Play();
	mTeleportParticle=gMe.WorldInfo.MyEmitterPool.SpawnEmitter(mTeleportParticleTemplate, gMe.Location);
	gMe.SetTimer( 2.f, false, NameOf( StopTeleportEffect ), self );

	FindClosestEnemy();
	if(lastTarget == none)
	{
		return;
	}

	dir=lastTarget.Location-gMe.Location;
	dir.Z=0.f;
	rot=Rotator(dir);
	rot.Yaw+=RandRange(-16384.f, 16384.f);
	teleportDistance=VSize(dir)*9/10;


	dest=lastTarget.Location+Normal(Vector(rot))*teleportDistance;
	traceStart=dest;
	traceEnd=dest;
	traceStart.Z=10000.f;
	traceEnd.Z=-3000;

	hitActor = gMe.Trace( hitLocation, hitNormal, traceEnd, traceStart, true, gMe.GetCollisionExtent() );
	if( hitActor == none )
	{
		hitLocation = traceEnd;
	}

	gMe.GetBoundingCylinder( r, h );
	hitLocation.Z+=h;
	gMe.SetLocation(hitLocation);

	//WorldInfo.Game.Broadcast(self, "To:" $ hitLocation);
}

function FindClosestEnemy()
{
	local vector dir;
	local float dist, minDist;
	local GGPawn newPawn, tmpPawn;

	minDist=-1;
	lastTarget=none;
	foreach gMe.AllActors( class'GGPawn', newPawn )
	{
		if( newPawn != gMe && newPawn.Controller != none )
		{
			dir=gMe.Location-newPawn.Location;
			dir.Z=0;
			dist=VSize(dir);
			if(minDist == -1 || dist < minDist)
			{
				minDist=dist;
				tmpPawn=newPawn;
			}
		}
	}

	lastTarget=tmpPawn;
}

function StopTeleportEffect()
{
	ac.Stop();
	mTeleportParticle.DeactivateSystem();
	mTeleportParticle.KillParticlesForced();
}

function DisplayLockMessage()
{
	gMe.WorldInfo.Game.Broadcast(gMe, "Slender Goat Locked :( Win one round of Slender Survival to unlock it.");
	gMe.SetTimer(3.f, false, NameOf(DisplayLockMessage), self);
}

DefaultProperties
{
	mSpaceGoatMesh=SkeletalMesh'CH_HeadBobber.Mesh.HeadBobber_01'
    mSpaceGoatAnimSet=AnimSet'CH_HeadBobber.Anim.HeadBobber_Anim_01'
    mSpaceGoatAnimTree=AnimTree'CH_HeadBobber.AnimTree.Creature_AnimTree'
    mSpaceGoatPhysAsset=PhysicsAsset'CH_HeadBobber.Mesh.HeadBobber_Physics_01'

    mNewCollisionRadius=25.0f
    mNewCollisionHeight=150.0f

	mSightRadius=1500.0f
	mTeleportParticleTemplate=ParticleSystem'Goat_Effects.Effects.Effects_RepulsiveGoat_01'
	teleportSound=SoundCue'SlenderGoatSounds.Ambience_Graveyard_whispers_loop_Cue'

	slenderBaaSoundCue=SoundCue'CH_HeadBobber.Cue.Wobblehead_Hurt'
}