/*
 *   -----------------------------------
 *  |  SmartCTFPlayerReplicationInfo.uc
 *   -----------------------------------
 *   This file is part of SmartCTF for UT2004.
 *
 *   SmartCTF is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SmartCTF is distributed in the hope and belief that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with SmartCTF.  If not, see <https://www.gnu.org/licenses/>.
 *
 *   Timeline:
 *   April, 2019: First Reincarnation.
 */

/**
 * This class stores the relevant player information and replicates it to the
 * dumb clients according to the roles.
 *
 * @author The_Cowboy
 * @version 1A
 * @since 1A
 */

class SmartCTFPlayerReplicationInfo extends ReplicationInfo;

/*
 * Global Variables
 */

 /*
  * CTF (teambased) type variables (Replicated)
  */

 /** Number of flag captures.*/
 var    int				Captures;				// Flags captured.

 /** Number of flag grabs.*/
 var    int             Grabs;                  // Flag grabs.

 /** Number of flag carrier covers.*/
 var    int             Covers;                 // Number of covers. Universal, nah joking. Universal Covers exist in Geometry only.

 /** Number of base seals.*/
 var    int             Seals;                  // Number of seals of the base

 /** Number of flag carrier kills.*/
 var    int             FlagKills;              // Number of flagkills.

 /*
  * DM (personal) type variables (Replicated)
  * TODO: Think about vehicles and stuff
  */

 /** Number of frags.*/
 var    int             Frags;                  // Number of frags

 /** Number of headshots.*/
 var    int             HeadShots;              //

 /** Number of shieldbelts picked.*/
 var    int             ShieldBelts;            //

 /** Number of amplifiers picked.*/
 var    int             Amps;                   //

 /** Number of suicides.*/
 var    int             Suicides;               // Self instigation

 /** If the player drew the first blood.*/
 var    bool            bFirstBlood;

 /*
  * Other information (Replicated)
  */

 /** Player's netspeed*/
 var    int             NetSpeed;

 /** Player's Nation.*/
 var    string          NationPrefix;

 /** Player's unique identification number.*/
 var    int             SPlayerID;

 /** Player's name.*/
 var    string          SPlayerName;             // for restoring SmartStats

 /*
  * Serverside variables (Never Replicated)
  */

 var    int             FragSpree;              // FragSpree Counter
 var    int             CoverSpree;             // CoverSpree Counter
 var    int             SpawnKillSpree;         // SpawnKillspree Counter

 /** IpToNation reference.*/
 var    LinkActor       IpToNation;

 /** If IpToNation is active.*/
 var    bool            bIpToNation;


/**
 * The Replication Block. Here we decide what to send to the dumb clients.
 * More information on Replication https://wiki.beyondunreal.com/Replication_overview
 *
 * @since version 1A
 */

 replication
 {
	// Things the server should send to the client.
	reliable if (bNetDirty && (Role == Role_Authority))
		Captures, Grabs, Covers, Seals, FlagKills,
		Frags, HeadShots, ShieldBelts, Amps, Suicides,
        bFirstBlood;

    // Things the server should send to the client.
	reliable if (bNetDirty && (Role == Role_Authority))
		NetSpeed, NationPrefix, SPlayerName, SPlayerID;
 }

/**
 * Called when the Actor is Spawned. Here we set the Timer to
 * get the Client's NetSpeed for showing purpose.
 *
 * @since version 1A
 */

 function PostBeginPlay(){

    ClearStats();
    SetTimer(0.5, true);
 }

/**
 * Standard Timer function.
 *
 * @see LinkActor.GetIPInfo
 * @since version 1A
 * @author [es]Rush
 */

 event Timer(){

  local string temp;
  local PlayerController LPC;

  if(Owner == none || Owner.Owner == none){
     return;
  }

  if(bIpToNation){
     if(NationPrefix == ""){
       if(Owner.Owner.IsA('PlayerController')){
          LPC = PlayerController(Owner.Owner);
          if(NetConnection(LPC.Player) != none)
	      {
             temp = LPC.GetPlayerNetworkAddress();
             temp = Left(temp, InStr(temp, ":"));
             temp = IpToNation.GetIpInfo(temp);
             Log(temp);
             if(temp == "!Disabled") /* after this return, iptonation won't resolve anything anyway */
                bIpToNation = False;
             else if(Left(temp, 1) != "!") /* good response */
             {
                NationPrefix = IptoNation.SelElem(temp, 5);
                if(NationPrefix == "") /* the country is probably unknown(maybe LAN), so as the prefix */
                  bIpToNation=False;
             }
	      }
	      else
	         bIpToNation=False;
	    }
	    else
	       bIpToNation=False;
      }
      else
         bIpToNation=False;
  }

  if(PlayerController(Owner.Owner) != none)
     NetSpeed = PlayerController(Owner.Owner).Player.CurrentNetSpeed;
}

/**
 * For cleaning purpose. Added for compatibility with certain
 * gametypes like Last Man Standing.
 *
 * @since version 1A
 */

 function ClearStats(){

    Captures = 0;
    Grabs = 0;
    Covers = 0;
    Seals = 0;
    FlagKills = 0;
    Frags = 0;
    HeadShots = 0;
    ShieldBelts = 0;
    Amps = 0;
    Suicides = 0;
    FragSpree = 0;
    CoverSpree = 0;
    SpawnKillSpree = 0;
 }

/**
 * Method to copy SmartStats to enforce the Stats Restoring feature
 *
 * @since version 1A
 */

 function CopyStats(SmartCTFPlayerReplicationInfo SPRI){

    Captures = SPRI.Captures;
    Grabs = SPRI.Grabs;
    Covers = SPRI.Covers;
    Seals = SPRI.Seals;
    FlagKills = SPRI.FlagKills;
    Frags = SPRI.Frags;
    HeadShots = SPRI.HeadShots;
    ShieldBelts = SPRI.ShieldBelts;
    Amps = SPRI.Amps;
    Suicides = SPRI.Suicides;
 }

 defaultproperties
 {
     NetUpdateFrequency=1.000000
     bNetNotify=True
 }

