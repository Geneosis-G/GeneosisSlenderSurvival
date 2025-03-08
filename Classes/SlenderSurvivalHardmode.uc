class SlenderSurvivalHardmode extends GGMutator;

function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;

	goat = GGGoat( other );

	if( goat != none )
	{
		if( IsValidForPlayer( goat ) )
		{
			ClearTimer(NameOf(InitSurvivalHardmode));
			SetTimer(1.f, false, NameOf(InitSurvivalHardmode));
		}
	}

	super.ModifyPlayer( other );
}

function InitSurvivalHardmode()
{
	local GGAIControllerSlender slender;
	local bool slenderFound;

	//Find RPGoat component
	foreach AllActors(class'GGAIControllerSlender', slender)
	{
		slender.isHardmode=true;
		slenderFound=true;
	}
	if(!slenderFound)
	{
		DisplayUnavailableMessage();
	}
}

function DisplayUnavailableMessage()
{
	WorldInfo.Game.Broadcast(self, "Slender Survival - Hardmode only works if combined with Slender Survival");
	SetTimer(3.f, false, NameOf(DisplayUnavailableMessage));
}

DefaultProperties
{

}