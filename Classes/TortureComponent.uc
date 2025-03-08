class TortureComponent extends GGRollerSkatesComponent;

function FindSocketsToAttachTo( SkeletalMeshComponent mesh, out array<name> out_sockets )
{
	super.FindSocketsToAttachTo(mesh, out_sockets);
		
	out_sockets.AddItem('hairSocket');
}

function FindBonesToRagdoll( SkeletalMeshComponent mesh, const out array<name> sockets, out array<name> out_bones );

function SetLegsFixed( bool fixed );

function KeyDown( name newKey );

function ForceOff();

function EnabledChanged();


function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator );

function AttachToPawn(GGPawn gpawn)
{
	local array<name> attachedSockets;
	local int i;
	local TortureItem skate;

	FindSocketsToAttachTo( gpawn.mesh, attachedSockets );

	// Good to have debug line to find height for different meshes
	//`log( `showvar( PathName( goat.mesh.SkeletalMesh ) )@`showvar( mOriginalHeight )@`showvar( mOriginalOffset ) );

	for( i = 0; i < attachedSockets.Length; ++i )
	{
		if( i < mSkates.Length )
		{
			skate = TortureItem(mSkates[i]);
		}
		else
		{
			skate = new( self ) class'TortureItem';
			mSkates.AddItem( skate );
		}

		skate.AttachToPawn( gpawn, attachedSockets[i] );
	}

	// Remove unnessesary skates
	mSkates.Length = attachedSockets.Length;
}

function SwitchOn(bool off=false)
{
	local int i;
	
	for( i = 0; i < mSkates.Length; ++i )
	{
		mSkates[i].mThruster.bThrustEnabled=!off;
		if(off)
		{
			TortureItem(mSkates[i]).Detach();
		}
	}
}