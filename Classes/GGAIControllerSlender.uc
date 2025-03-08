class GGAIControllerSlender extends GGAIController;

var kActorSpawnable destActor;
var GGGoat fearPoint;
var GGPawn lastTarget;

var ParticleSystem mTeleportParticleTemplate;
var ParticleSystemComponent mTeleportParticle;
var AudioComponent ac;
var SoundCue teleportSound;
var SoundCue slenderRoar;
var float teleportDistance;
var float maxTeleportDistance;
var float teleportDelay;
var float slenderSenseRadius;
var array<GoatBook> slenderBooks;
var int nbBooks;
var float mVictoryScore;
var bool mDoInstantAttack;

var bool isHardmode;

var int mWaterTeleportChain;
var vector mLastKnownValidPos;

var instanced GGCombatTextManager mCachedCombatTextManager;

/**
 * Cache the NPC and mOriginalPosition
 */
event Possess(Pawn inPawn, bool bVehicleTransition)
{
	local ProtectInfo destination;
	local GGGameInfoMMO gameInfoMMO;

	super.Possess(inPawn, bVehicleTransition);

	SpawnFearPoint();
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " fearPoint=" $ fearPoint);

	mMyPawn.mProtectItems.Length=0;
	SpawnDestActor();
	destActor.SetLocation(mMyPawn.Location);
	destination.ProtectItem = destActor;
	destination.ProtectRadius = 1000000.f;
	mMyPawn.mProtectItems.AddItem(destination);
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " mMyPawn.mProtectItems[0].ProtectItem=" $ mMyPawn.mProtectItems[0].ProtectItem);
	if(mCachedCombatTextManager == none)
	{
		gameInfoMMO = GGGameInfoMMO( WorldInfo.Game );
		if( gameInfoMMO != none )
		{
			mCachedCombatTextManager = gameInfoMMO.mCombatTextManager;
		}
		else
		{
			mCachedCombatTextManager = Spawn( class'GGCombatTextManager' );
		}
	}

	SaveConfig();
}

function SpawnDestActor()
{
	if(destActor == none || destActor.bPendingDelete)
	{
		destActor = Spawn(class'kActorSpawnable', mMyPawn,,,,,true);
		destActor.SetHidden(true);
		destActor.SetPhysics(PHYS_None);
		destActor.SetCollision(false, false);
		destActor.SetCollisionType(COLLIDE_NoCollision);
		destActor.CollisionComponent=none;
	}
}

function SpawnFearPoint()
{
	if(fearPoint == none || fearPoint.bPendingDelete)
	{
		fearPoint = Spawn(class'GGGoat', mMyPawn,,,,,true);
		fearPoint.SetHidden(true);
		fearPoint.SetPhysics(PHYS_None);
		fearPoint.SetCollision(false, false);
		fearPoint.SetCollisionType(COLLIDE_NoCollision);
		fearPoint.CollisionComponent=none;
	}
}

function UnlockSlenderGoat()
{
	if(!class'SlenderGoat'.default.isSlenderGoatUnlocked)
	{
		class'SlenderGoat'.static.UnlockSlenderGoat();
	}
}

function AddScore(int score, PlayerController pc)
{
	local GGGameInfo GGGI;

	GGGI = GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game );
	GGGI.AddScore( score, pc );
}

function int GetScore( PlayerController pc)
{
	local GGGameInfo GGGI;

	GGGI = GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game );
	return GGGI.GetScore( pc );
}

event Tick( float deltaTime )
{
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " dist=" $ VSize(lastTarget.Location - Pawn.Location));
	if(mMyPawn == none || mMyPawn.bPendingDelete)
	{
		SpawnSlenderGoat();
		NewRound();
	}

	Super.Tick( deltaTime );

	// Fix dead attacked pawns
	if( mPawnToAttack != none )
	{
		if( mPawnToAttack.bPendingDelete )
		{
			mPawnToAttack = none;
		}
	}

	//Fix dissapearing dest actor and fear point
	SpawnFearPoint();
	SpawnDestActor();

	//Fix infinite recursion CanSplash() crash when slender exit water
	if(mMyPawn.mInWater || mMyPawn.IsWaterMaterial(mMyPawn.GetMaterialBelowFeet()))
	{
		Teleport(true, false, true);
	}

	if(!mMyPawn.mIsRagdoll)
	{
		//WorldInfo.Game.Broadcast(self, mMyPawn $ "@" $ mMyPawn.Location $ "(" $ mCurrentState $ ")");

		//Fix Slender with no collisions
		if(mMyPawn.CollisionComponent == none)
		{
			mMyPawn.CollisionComponent = mMyPawn.mesh;
		}

		//Fix Slender rotation
		UnlockDesiredRotation();
		if(mPawnToAttack != none)
		{
			Pawn.SetDesiredRotation( rotator( Normal2D( mPawnToAttack.mesh.GetPosition() - mMyPawn.Location ) ) );
			mMyPawn.LockDesiredRotation( true );
			destActor.SetLocation(mMyPawn.Location);

			//Fix pawn stuck after attack
			if(!IsValidEnemy(mPawnToAttack))
			{
				EndAttack();
			}
			else if(mCurrentState != 'ProtectItem')
			{
				GotoState( 'ProtectItem' );
			}
		}
		else
		{
			if(mCurrentState != '')
			{
				GotoState( '' );
			}

			if(lastTarget != none)
			{
				Pawn.SetDesiredRotation( rotator( Normal2D( lastTarget.mesh.GetPosition() - Pawn.Location ) ) );
			}
			mMyPawn.LockDesiredRotation( true );
			destActor.SetLocation(mMyPawn.Location);
		}

		if(IsZero(mMyPawn.Velocity))
		{
			if( !mMyPawn.isCurrentAnimationInfoStruct( mMyPawn.mDefaultAnimationInfo ) )
			{
				mMyPawn.SetAnimationInfoStruct( mMyPawn.mDefaultAnimationInfo );
			}
		}
		else
		{
			if( !mMyPawn.isCurrentAnimationInfoStruct( mMyPawn.mRunAnimationInfo ) )
			{
				mMyPawn.SetAnimationInfoStruct( mMyPawn.mRunAnimationInfo );
			}
		}
	}

	if(mMyPawn.Location.Z < -3000)
	{
		Teleport(true);
	}
}

function SpawnSlenderGoat()
{
	local GGNpcGoatSlender slenderGoat;

	slenderGoat=Spawn(class'GGNpcGoatSlender',,,vect(0, 0, 2000),,, true);
	Possess(slenderGoat, false);
	//WorldInfo.Game.Broadcast(self, "GGNpcGoatSlender=" $ slenderGoat);
}

function NewRound()
{
	local GoatBook tmpBook;
	local int i;

	foreach AllActors( class'GoatBook', tmpBook )
	{
		tmpBook.DestroyCorrectly();
	}

	slenderBooks.Length=0;
	for(i=0 ; i<nbBooks ; i++)
	{
		tmpBook=Spawn(class'GoatBook');
		tmpBook.placeBook(self);
		slenderBooks.AddItem(tmpBook);
	}
	mDoInstantAttack=false;
	teleportDistance=maxTeleportDistance;
	Teleport(true, true);
}

function SlenderBookFound(GoatBook book, Actor grabbingActor)
{
	slenderBooks.RemoveItem(book);
	mCachedCombatTextManager.AddCombatTextString(8 - slenderBooks.Length @ "/ 8", book.Location - grabbingActor.Location, TC_XP, Pawn(grabbingActor).Controller);
	book.DestroyCorrectly();
	if(slenderBooks.Length == 0)
	{
		AddScore(mVictoryScore*10.f, PlayerController( Pawn(grabbingActor).Controller ));
		UnlockSlenderGoat();
		NewRound();
	}
	else
	{
		teleportDistance=(teleportDistance+maxTeleportDistance)/2.f;
		Teleport(!isHardmode, !isHardmode);
	}
}

function ReplaceBook(GoatBook book)
{
	local GoatBook tmpBook;

	slenderBooks.RemoveItem(book);
	tmpBook=Spawn(class'GoatBook');
	tmpBook.placeBook(self);
	slenderBooks.AddItem(tmpBook);
}

function Teleport(optional bool keepDistance, optional bool reset, optional bool waterOrRagdoll)
{
	local vector dest, dir;
	local rotator newRot;
	local Actor hitActor;
	local vector hitLocation, hitLocationWater, hitNormal, traceEnd, traceStart;
	//WorldInfo.Game.Broadcast(self, "Teleport keepDistance=" $ keepDistance $ ", reset=" $ reset $ ", waterOrRagdoll=" $ waterOrRagdoll);

	//Save last known good land position (in case we keep teleporting on water)
	if(mMyPawn.Physics == PHYS_Walking && (mMyPawn.Base.bStatic || mMyPawn.Base.bWorldGeometry) && !mMyPawn.mIsInWater)
	{
		//WorldInfo.Game.Broadcast(self, "mLastKnownValidPos updated");
		mLastKnownValidPos=mMyPawn.Location;
	}

	if(mMyPawn.mIsRagdoll)
	{
		mMyPawn.StandUp();
	}

	if( GetALocalPlayerController().IsTimerActive( NameOf( Teleport ), self ) )
	{
		GetALocalPlayerController().ClearTimer( NameOf( Teleport ), self );
	}
	GetALocalPlayerController().SetTimer( teleportDelay, false, NameOf( Teleport ), self );
	//No periodic teleport if attacking
	if(!keepDistance && GetStateName() == 'ProtectItem')
	{
		return;
	}

	if( GetALocalPlayerController().IsTimerActive( NameOf( StopTeleportEffect ), self ) )
	{
		GetALocalPlayerController().ClearTimer( NameOf( StopTeleportEffect ), self );
		StopTeleportEffect();
	}
	if(ac == none || ac.IsPendingKill())
	{
		ac=CreateAudioComponent(teleportSound, false);
	}
	if(!isHardmode) ac.Play();
	mTeleportParticle=mMyPawn.WorldInfo.MyEmitterPool.SpawnEmitter(mTeleportParticleTemplate, mMyPawn.Location);
	GetALocalPlayerController().SetTimer( 2.f, false, NameOf( StopTeleportEffect ), self );

	if(!keepDistance)
	{
		teleportDistance-=teleportDistance/10;
	}

	if(waterOrRagdoll)
	{
		mWaterTeleportChain++;
	}
	else
	{
		mWaterTeleportChain=0;
	}

	if(mWaterTeleportChain >= 5 && !IsZero(mLastKnownValidPos))
	{
		mWaterTeleportChain=0;
		hitLocation=mLastKnownValidPos;
	}
	else
	{
		FindClosestGoat();
		if(lastTarget == none)
		{
			dir=Normal2D(vector(mMyPawn.Rotation)) * teleportDistance;
		}
		else
		{
			dir=lastTarget.mesh.GetPosition()-mMyPawn.Location;
			dir.Z=0.f;
		}
		newRot=rotator(dir);
		newRot.Yaw+=RandRange(-16384.f, 16384.f);
		if(!reset)
		{
			teleportDistance=Min(teleportDistance, VSize(dir));
		}

		if(lastTarget == none)
		{
			dest=mMyPawn.Location+Normal(vector(newRot))*teleportDistance*2.f;
		}
		else
		{
			dest=lastTarget.mesh.GetPosition()+Normal(vector(newRot))*teleportDistance;
			if(VSize2D(dest-lastTarget.mesh.GetPosition()) < lastTarget.GetCollisionRadius() + mMyPawn.GetCollisionRadius() + 1.f)
			{// Fix slender teleporting on top of targets
				teleportDistance*=10.f/9.f;
				dest=lastTarget.mesh.GetPosition() + Normal(vector(newRot))*(lastTarget.GetCollisionRadius() + mMyPawn.GetCollisionRadius() + 1.f);
			}
		}
		traceStart=dest;
		traceEnd=dest;
		traceStart.Z=10000.f;
		traceEnd.Z=-3000;

		hitActor = Trace( hitLocation, hitNormal, traceEnd, traceStart, true, mMyPawn.GetCollisionExtent() );
		if( hitActor == none )
		{
			hitLocation = traceEnd;
		}
		//Try to never ever enter water because it cause random crash
		hitActor = Trace( hitLocationWater, hitNormal, traceEnd, traceStart, false,,, TRACEFLAG_PhysicsVolumes );
		if(WaterVolume( hitActor ) != none || (Volume( hitActor ) != none && mMyPawn.IsWaterMaterial( hitActor.Tag )))
		{
			if(hitLocationWater.Z > hitLocation.Z)
			{
				hitLocation=hitLocationWater;
				hitLocation.Z+=mMyPawn.GetCollisionHeight()*0.5f;//To let time to Tick to detect water below
			}
		}
	}

	hitLocation.Z+=mMyPawn.GetCollisionHeight();
	mMyPawn.SetLocation(hitLocation);
	destActor.SetLocation(hitLocation);
	mOriginalPosition=hitLocation;

	//WorldInfo.Game.Broadcast(self, "To:" $ hitLocation);
}

function FindClosestGoat()
{
	local GGPlayerControllerGame pc;
	local vector dir;
	local float dist, minDist;
	local GGPawn tmpPawn;

	minDist=-1;
	foreach WorldInfo.AllControllers( class'GGPlayerControllerGame', pc )
	{
		if( pc.IsLocalPlayerController() && pc.Pawn != none )
		{
			dir=mMyPawn.Location-pc.Pawn.Location;
			dir.Z=0;
			dist=VSize(dir);
			if(minDist == -1 || dist < minDist)
			{
				minDist=dist;
				tmpPawn=GGPawn(pc.Pawn);
			}
		}
	}

	lastTarget=tmpPawn;
}

function StopTeleportEffect()
{
	if(ac.IsPlaying()) ac.Stop();
	mTeleportParticle.DeactivateSystem();
	mTeleportParticle.KillParticlesForced();
}

function TortureGoat()
{
	local TortureDevice td;
	td=Spawn(class'TortureDevice');
	td.Torture(mPawnToAttack);
	//WorldInfo.Game.Broadcast(self, td $ " Torturing Player!!!");
}

/**
 * Called when we and the goat are both near a protect item
 * Initiates the protection of a given item
 * @param protectInformation - Information struct for a given protect item
 */
function StartProtectingItem( ProtectInfo protectInformation, GGPawn threat )
{
	//WorldInfo.Game.Broadcast(self, mMyPawn $ ": I see you! " $ mMyPawn.mAttackAnimationInfo.SoundToPlay[0]);
	if(!isHardmode) mMyPawn.PlaySound( slenderRoar );
	super.StartProtectingItem(protectInformation, threat);
}

/**
 * Attacks mPawnToAttack using mMyPawn.mAttackMomentum
 * called when our pawn needs to protect and item from a given pawn
 */
function AttackPawn()
{
	local PlayerController pc;

	super.AttackPawn();

	pc=PlayerController( mPawnToAttack.Controller );
	TortureGoat();
	AddScore(-GetScore(pc)/2, pc);
	NewRound();

	//Fix pawn stuck after attack
	if(IsValidEnemy(mPawnToAttack))
	{
		GotoState( 'ProtectItem' );
	}
	else
	{
		EndAttack();
	}
}

/**
 * Initiate the attack chain
 * called when our pawn needs to protect a given item
 */
function StartAttack( Pawn pawnToAttack )
{
	super.StartAttack(pawnToAttack);

	if(mDoInstantAttack
	|| (mPawnToAttack == pawnToAttack && !IsTimerActive(nameof( AttackPawn ))))
	{
		ClearTimer(nameof( AttackPawn ));
		AttackPawn();
	}
}

/**
 * Helper function to determine if the last seen goat is near a given protect item
 * @param  protectInformation - The protectInfo to check against
 * @return true / false depending on if the goat is near or not
 */
function bool GoatNearProtectItem( ProtectInfo protectInformation )
{
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " mProtectItems[0]=" $ mMyPawn.mProtectItems[0].ProtectItem);
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " ProtectItem=" $ protectInformation.ProtectItem);

	if( protectInformation.ProtectItem == None || mVisibleEnemies.Length == 0 )
	{
		return false;
	}
	else
	{
		return true;
	}
}

/**
 * Helper function to determine if our pawn is close to a protect item, called when we arrive at a pathnode
 * @param currentlyAtNode - The pathNode our pawn just arrived at
 * @param out_ProctectInformation - The info about the protect item we are near if any
 * @return true / false depending on if the pawn is near or not
 */
function bool NearProtectItem( PathNode currentlyAtNode, out ProtectInfo out_ProctectInformation )
{
	out_ProctectInformation=mMyPawn.mProtectItems[0];
	return true;
}

event SeeMonster( Pawn Seen )
{
	local GGNpc npc;
	local GGAIController aic;

	super.SeeMonster( Seen );

	//Make humans panic when they see the Slender Goat
	npc = GGNpc(Seen);
	if(npc != none)
	{
		aic = GGAIController(npc.Controller);
		if(!aic.IsInState('StartPanic'))
		{
			//Use a fake goat to make the NPC panic in the opposite direction of the zombie
			fearPoint.SetLocation(mMyPawn.Location);
			aic.mLastSeenGoat=fearPoint;
			aic.Panic();
		}
	}
}

function bool IsValidEnemy( Pawn newEnemy )
{
	if(PlayerController(newEnemy.Controller) != none)
	{
		return true;
	}

	return false;
}

/**
 * Helper functioner for determining if the goat is in range of uur sightradius
 * if other is not specified mLastSeenGoat is checked against
 */
function bool PawnInRange( optional Pawn other )
{
	if(mMyPawn.mIsRagdoll)
	{
		return false;
	}
	else if(VSize(other.Location-mMyPawn.Location) < slenderSenseRadius)
	{
		return true;
	}
	else
	{
		return super.PawnInRange(other);
	}
}

/**
 * Is there world geometry between us and another pawn
 */
function bool GeometryBetween( Actor other )
{
	if(VSize(other.Location-mMyPawn.Location) < slenderSenseRadius)
	{
		return false;
	}
	else
	{
		return super.GeometryBetween(other);
	}
}

/**
 * Helper function for when we see the goat to determine if it is carrying a scary object
 */
function bool GoatCarryingDangerItem()
{
	return false;
}

function bool PawnUsesScriptedRoute()
{
	return false;
}

function bool CanReturnToOrginalPosition()
{
	return false;
}

/**
 * Go back to where the position we spawned on
 */
function ReturnToOriginalPosition()
{
	GotoState( '' );
}

/**
 * Sets timers for the look at actor functionality
 * @param lookAtActor - The actor we want to look at
 * @param lookAtDuration - How long to look at the actor for
 */
function StartLookAt( Actor lookAtActor, float lookAtDuration );

/**
 * Clears timers and disables the pawn's skelcontrol
 */
function StopLookAt();

/**
 * Called when we are near an interaction item
 * Makes our pawn loook at a given actor and play a given animatiopn
 * Sets a timer to resume scripted route
 * @param intertactionInfo - Information struct for the a given interaction
 */
function StartInteractingWith( InteractionInfo intertactionInfo );

//--------------------------------------------------------------//
//			GGNotificationInterface								//
//--------------------------------------------------------------//

/**
 * Called when a trick was made
 */
function OnTrickMade( GGTrickBase trickMade );

/**
 * Called when an actor takes damage
 */
function OnTakeDamage( Actor damagedActor, Actor damageCauser, int damage, class< DamageType > dmgType, vector momentum )
{
	local GGPawn gpawn;

	if(damagedActor == mMyPawn)
	{
		gpawn=GGPawn(damageCauser);
		//WorldInfo.Game.Broadcast(self, mMyPawn $ " damaged by " $ damageCauser);
		if(gpawn != none && PlayerController(gpawn.Controller) != none)
		{
			if(class< GGDamageTypeAbility >(dmgType) != none)
			{
				AddScore(mVictoryScore, PlayerController(gpawn.Controller));
				UnlockSlenderGoat();
				NewRound();
			}
			else if(IsTimerActive(nameof( AttackPawn ))) // Attack interrupted by collision
			{
				mDoInstantAttack=true;
			}
		}
	}
}

/**
 * Called when a kismet action is triggered
 */
function OnKismetActivated( SequenceAction activatedKismet );

/**
 * Called when an actor begins to ragdoll
 */
function OnRagdoll( Actor ragdolledActor, bool isRagdoll )
{
	if( ragdolledActor == mMyPawn)
	{
		if(isRagdoll)
		{
			if( IsTimerActive( NameOf( StopPointing ) ) )
			{
				StopPointing();
				ClearTimer( NameOf( StopPointing ) );
			}

			if( IsTimerActive( NameOf( StopLookAt ) ) )
			{
				StopLookAt();
				ClearTimer( NameOf( StopLookAt ) );
			}

			if( mCurrentState == 'ProtectItem' )
			{
				ClearTimer( nameof( AttackPawn ) );
				ClearTimer( nameof( DelayedGoToProtect ) );
			}
			StopAllScheduledMovement();
			Teleport(true, false, true);
		}
	}
}

function bool CanPawnInteract()
{
	return false;
}


/**
 * Called when an actor performs a manual
 */
function OnManual( Actor manualPerformer, bool isDoingManual, bool wasSuccessful );

/**
 * Called when an actor start/stop wall running.
 */
function OnWallRun( Actor runner, bool isWallRunning );

/**
 * Called when an actor performes a wall jump.
 */
function OnWallJump( Actor jumper );

//--------------------------------------------------------------//
//			End GGNotificationInterface							//
//--------------------------------------------------------------//

/**
 * Choose if we want to clap or point at the goat
 * if point initiate the timers etc for pointing
 */
function ApplaudGoat();

/**
 * Sets positional values for the mPointControl to make it point at the goat
 * Called by a timer started in ApplaudGoat
 */
function PointAtGoat();

/**
 * Stops any pointing logic
 */
function StopPointing();

/**
 * Helper function to determine if we should panic over a certain trick
 * Called when the goat has performed a trick
 * @param trickMade - The trick the goat performed
 */
function bool WantToPanicOverTrick( GGTrickBase trickMade )
{
	return false;
}

/**
 * Helper function to determine if we should applaud a certain trick
 * Called when the goat has performed a trick
 * @param trickMade - The trick the goat performed
 */
function bool WantToApplaudTrick( GGTrickBase trickMade  )
{
	return false;
}


/**
 * Helper function to determine if we should panic over a certain kismet trick
 * Called when the goat has performed a trick
 * @param trickRelatedKismet - The trick the goat performed
 */
function bool WantToPanicOverKismetTrick( GGSeqAct_GiveScore trickRelatedKismet )
{
	return false;
}

/**
 * Helper function to determine if we should applaud a certain kismet trick
 * Called when the goat has performed a trick
 * @param trickRelatedKismet - The trick the goat performed
 */
function bool WantToApplaudKismetTrick( GGSeqAct_GiveScore trickRelatedKismet )
{
	return false;
}

/**
 * Helper function to determine if our pawn is close to a interact item, called when we arrive at a pathnode
 * @param currentlyAtNode - The pathNode our pawn just arrived at
 * @param out_InteractionInfo - The info about the interact item we are near if any
 * @return true / false depending on if the pawn is near or not
 */
function bool NearInteractItem( PathNode currentlyAtNode, out InteractionInfo out_InteractionInfo )
{
	return false;
}

function bool ShouldApplaud()
{
	return false;
}

function bool ShouldNotice()
{
	return false;
}

/**
 * Determine if we need to panic over the goat picking up a danger item
 */
event GoatPickedUpDangerItem( GGGoat goat );

/**
 * Searches for an appropiate panic position, sets animation for paniccing and moves the pawn to
 * the found panic position
 */
function Panic();

function Dance(optional bool forever);

event UnPossess()
{
	Pawn.Destroy();
	if(fearPoint != none)
	{
		fearPoint.Destroy();
		fearPoint=none;
	}
	if(destActor != none)
	{
		destActor.ShutDown();
		destActor.Destroy();
		destActor=none;
	}

	super.UnPossess();
}

event Destroyed()
{
	UnPossess();

	super.Destroyed();
}

state ProtectItem
{
	ignores ApplaudGoat;
	ignores Panic;

	event Tick( float deltaTime )
	{
		super.Tick( deltaTime );

		if( ShouldCheckVisibility() )
		{
			CheckVisibilityOfGoats();

			CheckVisibilityOfEnemies();

			TimeStampVisiblityCheck();
		}

		if( mPawnToAttack == none || ( mPawnToAttack != none && mPawnToAttack.LifeSpan > 0.0f ) || ( mPawnToAttack != none && VSize( mPawnToAttack.mesh.GetPosition() - mCurrentlyProtecting.ProtectItem.Location ) >= mCurrentlyProtecting.ProtectRadius ) )
		{
			EndAttack();
		}
	}

Begin:
	if( mPawnToAttack != none && VSize( mPawnToAttack.mesh.GetPosition() - mCurrentlyProtecting.ProtectItem.Location ) >= mCurrentlyProtecting.ProtectRadius )
	{
		EndAttack();
	}

	UnlockDesiredRotation();

	if( !mMyPawn.isCurrentAnimationInfoStruct( mMyPawn.mRunAnimationInfo ) )
	{
		mMyPawn.SetAnimationInfoStruct( mMyPawn.mRunAnimationInfo );
	}

	if( VSize( mMyPawn.Location - mPawnToAttack.mesh.GetPosition() ) > mMyPawn.mAttackRange )
	{
		MoveToward( mPawnToAttack,, mMyPawn.mAttackRange );
	}

	if( !mMyPawn.mIsRagdoll && VSize( mPawnToAttack.mesh.GetPosition() - mMyPawn.Location ) <= mMyPawn.GetCollisionRadius() + mPawnToAttack.GetCollisionRadius() + mMyPawn.mAttackRange )
	{
		StartAttack( mPawnToAttack );
		FinishRotation();
	}
	else
	{
		if(!isHardmode && !mMyPawn.isCurrentAnimationInfoStruct( mMyPawn.mAngryAnimationInfo ) )
		{
			mMyPawn.SetAnimationInfoStruct( mMyPawn.mAngryAnimationInfo );
		}

		ClearTimer( nameof( DelayedGoToProtect ) );

		DelayedGoToProtect();
	}
}

state WaitingForLanding
{
	event LongFall()
	{
		mDidLongFall = true;
	}

	event NotifyPostLanded()
	{
		if( mDidLongFall || !CanReturnToOrginalPosition() )
		{
			if( mMyPawn.IsDefaultAnimationRestingOnSomething() )
			{
			    mMyPawn.mDefaultAnimationInfo =	mMyPawn.mIdleAnimationInfo;
			}

			mOriginalPosition = mMyPawn.Location;
		}

		mDidLongFall = false;

		StopLatentExecution();
		mMyPawn.ZeroMovementVariables();
		GoToState( '' );
	}

Begin:
	mMyPawn.ZeroMovementVariables();
	WaitForLanding( 1.0f );
}

DefaultProperties
{
	bIsPlayer=true

	mAttackIntervalInfo=(Min=1.f,Max=1.f,CurrentInterval=1.f)
	mIgnoreGoatMaus=true

	mTeleportParticleTemplate=ParticleSystem'Goat_Effects.Effects.Effects_RepulsiveGoat_01'
	teleportSound=SoundCue'SlenderGoatSounds.Ambience_Graveyard_whispers_loop_Cue'
	slenderRoar=SoundCue'CH_HeadBobber.Cue.Wobblehead_Hurt'
	teleportDistance=5000.f
	maxTeleportDistance=5000.f
	teleportDelay=20.f
	slenderSenseRadius=500.f
	nbBooks=8
	mVictoryScore=9999999.f
}
