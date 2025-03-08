class SlenderSurvivalMutator extends GGMutator;

var AudioComponent ac;
var SoundCue darkMusic;
var GGAIControllerSlender slenderController;

/**
 * See super.
 */
function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;

	super.ModifyPlayer( other );

	goat = GGGoat( other );

	if( goat != none && goat.Controller != none)
	{
		GenerateDarkness(goat);
	}
}

function OnPlayerRespawn( PlayerController respawnController, bool died )
{
	GenerateDarkness(respawnController.Pawn);
}

event Tick( float deltaTime )
{
	Super.Tick( deltaTime );

	if(!GGGameInfo( WorldInfo.Game ).mMusicManager.mIsMuted || ac == none || ac.IsPendingKill())
	{
		StartDarkSound();
	}

	if(slenderController == none || slenderController.bPendingDelete)
	{
		slenderController=Spawn(class'GGAIControllerSlender');
		//WorldInfo.Game.Broadcast(self, "GGAIControllerSlender=" $ slenderController);
	}
}

function GenerateDarkness(Pawn pawn)
{
	local PostProcessSettings pps;
	local LocalPlayer localPlayer;

	localPlayer=LocalPlayer(PlayerController(pawn.Controller).Player);

	//Darkness visual effect
	pps.bEnableDOF=true;
	//pps.Bloom_ScreenBlendThersold=50000.f;
	pps.Bloom_InterpolationDuration=0.f;
	pps.DOF_BlurBloomKernelSize=64.f;
	pps.DOF_FalloffExponent=2.f;
	pps.DOF_BlurKernelSize=4.f;
	//pps.Min=0.6;
	pps.DOF_FocusInnerRadius=1500.f;
	pps.DOF_FocusDistance=1600.f;
	pps.DOF_InterpolationDuration=0.f;
	pps.Scene_Desaturation=0.7;
	pps.Scene_Colorize=vect(1, 1, 0.5);
	pps.Scene_HighLights=vect(0.4, 0.7, 0.04);
	pps.Scene_MidTones=vect(7, 2.5, 0.4);
	pps.Scene_Shadows=vect(0.5, 0.25, 0.05);
	pps.Scene_InterpolationDuration=0.f;
	localPlayer.OverridePostProcessSettings(pps, 0.0);
}

function RemoveDarkness(Pawn pawn)
{
	local LocalPlayer localPlayer;

	localPlayer=LocalPlayer(PlayerController(pawn.Controller).Player);
	localPlayer.ClearPostProcessSettingsOverride();
}

function StartDarkSound()
{
	GGGameInfo( WorldInfo.Game ).mMusicManager.SetMute(true);
	if(ac == none || ac.IsPendingKill())
	{
		ac=CreateAudioComponent(darkMusic, true);
	}
	if(!ac.IsPlaying())
	{
		ac.Play();
	}
}

defaultproperties
{
	darkMusic=SoundCue'SlenderGoatSounds.Ambience_Graveyard_loop_Cue';
}