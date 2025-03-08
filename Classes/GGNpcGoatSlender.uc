class GGNpcGoatSlender extends GGNpcGoat;

/**
 * Human readable name of this actor.
 */
function string GetActorName()
{
	return "Slender Goat";
}

/**
 * How much score this actor gives.
 */
function int GetScore()
{
	return -666;
}

DefaultProperties
{
	Begin Object Name=WPawnSkeletalMeshComponent
		SkeletalMesh=SkeletalMesh'goat.Mesh.GoatRipped'
		PhysicsAsset=PhysicsAsset'CH_HeadBobber.Mesh.HeadBobber_Physics_01'
		AnimSets(0)=AnimSet'CH_HeadBobber.Anim.HeadBobber_Anim_01'
		AnimTreeTemplate=AnimTree'CH_HeadBobber.AnimTree.Creature_AnimTree'
		bCacheAnimSequenceNodes=false
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOwnerNoSee=false
		CastShadow=true
		BlockRigidBody=true
		CollideActors=true
		bUpdateSkelWhenNotRendered=false
		bIgnoreControllersWhenNotRendered=true
		bUpdateKinematicBonesFromAnimation=true
		bCastDynamicShadow=true
		RBChannel=RBCC_Untitled3
		RBCollideWithChannels=(Untitled3=true,Vehicle=true)
		LightEnvironment=MyLightEnvironment
		bOverrideAttachmentOwnerVisibility=true
		bAcceptsDynamicDecals=false
		bHasPhysicsAssetInstance=true
		TickGroup=TG_PreAsyncWork
		bChartDistanceFactor=true
		RBDominanceGroup=15
		bSyncActorLocationToRootRigidBody=true
		bNotifyRigidBodyCollision=true
		ScriptRigidBodyCollisionThreshold=0.1f
		// Don't update skeletons on far distance
		MinDistFactorForKinematicUpdate=0.2
	End Object
	mesh=WPawnSkeletalMeshComponent
	Components.Add(WPawnSkeletalMeshComponent)

	Begin Object name=CollisionCylinder
		CollisionRadius=25.0f
		CollisionHeight=150.0f
		CollideActors=true
		BlockActors=true
		BlockRigidBody=true
		BlockZeroExtent=true
		BlockNonZeroExtent=true
	End Object

	mPanicAtWallAnimationInfo=(AnimationNames=(Sprint),AnimationRate=1.0f,MovementSpeed=0.0f,LoopAnimation=true,SoundToPlay=(SoundCue'CH_HeadBobber.Cue.Wobblehead_Hurt'))
	mPanicAnimationInfo=(AnimationNames=(Run),AnimationRate=1.0f,MovementSpeed=700.0f,LoopAnimation=true,SoundToPlay=(SoundCue'CH_HeadBobber.Cue.Wobblehead_Hurt'))
	mAttackAnimationInfo=(AnimationNames=(Ram),AnimationRate=1.0f,MovementSpeed=0.0f,LoopAnimation=false,SoundToPlay=(SoundCue'CH_HeadBobber.Cue.Wobblehead_Hurt'))
	mAngryAnimationInfo=(AnimationNames=(Baa),AnimationRate=1.0f,MovementSpeed=0.0f,LoopAnimation=true,SoundToPlay=(SoundCue'CH_HeadBobber.Cue.Wobblehead_Hurt'))
	mApplaudAnimationInfo=(AnimationNames=(Baa),AnimationRate=1.0f,MovementSpeed=0.0f,LoopAnimation=false,SoundToPlay=(SoundCue'CH_HeadBobber.Cue.Wobblehead_Hurt'))
	mNoticeGoatAnimationInfo=(AnimationRate=1.0f,MovementSpeed=0.0f,LoopAnimation=false,SoundToPlay=(SoundCue'CH_HeadBobber.Cue.Wobblehead_Hurt'))

	mKnockedOverSounds=(SoundCue'CH_HeadBobber.Cue.Wobblehead_Hurt')

	SightRadius=1500.0f
	HearingThreshold=1500.0f

	mStandUpDelay=0.f

	mAttackRange=200.0f;
	mAttackMomentum=1000.0f

	mTimesKnockedByGoatStayDownLimit=1000000
}