/*
 *   --------------------------
 *  |  SmartCTF.uc
 *   --------------------------
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
 *   along with SmartCTF.  if not, see <https://www.gnu.org/licenses/>.
 *
 *   Timeline:
 *   April, 2019: First Reincarnation.
 *   June, 2020: Feature add - bDisableOvertime
 */

/**
 * SmartCTF is a mutator to reinforce and encourage the collaborative teamplay <br />
 * and reward the players accordingly. It shows the relevant data via custom   <br />
 * Scoreboard. This is the main class responsible to mutate the CTF game.      <br />
 *
 * @author The_Cowboy
 * @version 1A
 * @since 1A
 */

class SmartCTF extends Mutator config;


/*
 * Global Variables
 */

 /** String with Version of the Mutator.*/
 var   string                                     Version;

 /** The SmartCTF's personal GameReplicationInfo referance.*/
 var   SmartCTFGameReplicationInfo                SCTFGame;

 /** Controller Array of CTF's Flag Carriers.*/
 var   Controller                                 FCs[2];

 /** Server's frequency of estimating the TickRate.*/
 var   int                                        TRcount;

 /** SmartCTF's silent spectator.*/
 var   MessagingSpectator                         Witness;

 /** Statistics of Players leaving server, for SmartStatistics restoration.*/
 var   array<SmartCTFPlayerReplicationInfo>       GoneSmartPRI;

 /** IpToNation's referance.*/
 var   LinkActor                                  IpToNation;

 /** For tracking the PlayerJoin.*/
 var   int                                        CurrID;

 /*
  * Configurable Variables
  */

 var()   config           bool         bShowLogo;
 var()   config           int          CoverReward;
 var()   config           int          CoverAdrenalineUnits;
 var()   config           int          SealAward;
 var()   config           int          SealAdrenalineUnits;
 var()   config           string       RedFlagZone;
 var()   config           string       BlueFlagZone;
 var()   config           string       ScoreBoardType;
 var()   config           bool         bShowFCLocation;
 var()   config           bool         bDisableOvertime;
 var()   config           bool         bShowCountryFlags;
 var()   config           bool         bShowFirstBlood;
 var()   config           bool         bRecoverTotalScore;

 /** Switch for broadcasting Monsterkill and above.*/
 var()   config           bool         bBroadcastMonsterKillsAndAbove;

/**
 * The function gets called just after game begins. So we set up the
 * environmnet for SmartCTF to operate.
 *
 * @since version 1A
 */

 function PostBeginPlay(){

     local SmartCTFLogo S;
     local bool bSmartLogo;
     local SmartCTFGameRules SCTFGrules;

     Log("Howdy!");
     Log("+-------------------------------------------------------", 'SmartCTF');
     log("| Loading SmartCTF"$Version, 'SmartCTF');

     SaveConfig();
     SCTFGame = Level.Game.Spawn(class'SmartCTFGameReplicationInfo');
     SetSCTFGame();
     SCTFGrules = Level.Game.Spawn(class'SmartCTFGameRules'); // for accessing PreventDeath function
     SCTFGrules.SCTFMut = self;
     Level.Game.AddGameModifier(SCTFGrules);// Register the GameRules Modifier
     RegisterBroadcastHandler();
     if(bShowFCLocation)
        Level.Game.HUDType = string(class'SmartCTFHudCCaptureTheFlag');
     Witness = Level.Game.Spawn(class'UTServerAdminSpectator');
     if(Witness != none){
        Log("| Successfully Spawned the Witness"@Witness, 'SmartCTF');
        Witness.PlayerReplicationInfo.PlayerName = "Witness";
     }
     else
        Log("ERROR! Couldn't Spawn the Witness", 'SmartCTF');

     SetTimer(1, true);
     if(bShowCountryFlags){
     Log("| Initilaizing IpToNation...", 'SmartCTF');
        IpToNation = Level.Spawn(class'LinkActor');
        Level.Game.BaseMutator.AddMutator(IpToNation);// for identifying the Nation of the players
     }
     Level.Game.ScoreBoardType = ScoreBoardType;
     if(bShowLogo){
        foreach DynamicActors(class'SmartCTFLogo', S){
           bSmartLogo = true;
           break;
        }

        if(!bSmartLogo)
           Spawn(class'SmartCTFLogo');
     }

     log("| Loading complete", 'SmartCTF');
     Log("+-------------------------------------------------------", 'SmartCTF');
     super.PostBeginPlay();
 }

/**
 * The function to set the SCTFGame parameters.
 *
 * @since version 1A
 */

 function SetSCTFGame(){

    SCTFGame.bShowFirstBlood = bShowFirstBlood;
 }

/**
 * The function to check the SmartCTFPlayerReplicationInfo instance
 * association.
 *
 * @param Other The Pawn instance of humanplayer or bot
 * @since version 1A
 */

 function ModifyPlayer(Pawn Other){

    local SmartCTFPlayerReplicationInfo SPRI;
    local bool bFoundMatch;

    if(Other.PlayerReplicationInfo == none) return;
    foreach DynamicActors(class'SmartCTFPlayerReplicationInfo', SPRI)
         if(SPRI.Owner == Other.PlayerReplicationInfo){
            bFoundMatch = true;
            break;
         }

    if(!bFoundMatch){
       AssociateSmartReplication(Other);
    }

    if(NextMutator != None)
	   NextMutator.ModifyPlayer(Other);
 }

/**
 * The function for associating SmartCTFPlayerReplicationInfo with the
 * PlayerReplicationInfo of the Controller. Note that Controller don't seem to
 * replicate as owner on the client box.  If a plyer rejoins, SmartStats are restored.
 *
 * @param Other The Pawn instance of humanplayer or bot.
 * @see Replication block of this Actor.
 * @since version 1A
 */

 function AssociateSmartReplication(Pawn Other){

       local SmartCTFPlayerReplicationInfo NewSPRI;
       local int i;

       NewSPRI = Spawn(class'SmartCTFPlayerReplicationInfo', Other.PlayerReplicationInfo);
       NewSPRI.SPlayerName = Other.PlayerReplicationInfo.PlayerName;
       NewSPRI.SPlayerID = Other.PlayerReplicationInfo.PlayerID;
       NewSPRI.IpToNation = IpToNation;
       NewSPRI.bIpToNation = true;
       for(i = 0; i < GoneSmartPRI.Length; i++){
          if(GoneSmartPRI[i] != none && Other.PlayerReplicationInfo.PlayerName == GoneSmartPRI[i].SPlayerName){// Include IP check?
             NewSPRI.CopyStats(GoneSmartPRI[i]);
             if(bRecoverTotalScore)
                Other.PlayerReplicationInfo.Score = GoneSmartPRI[i].PlayerScore;
             GoneSmartPRI.Remove(i, 1);
          }
       }
 }

/**
 * The function for restoring the SmartStats of the exiting players
 *
 * @since version 1A
 */

 function NotifyLogout(Controller Exiting){

    local SmartCTFPlayerReplicationInfo LSPRI;
    local int PlayerIndex;

    foreach DynamicActors(class'SmartCTFPlayerReplicationInfo', LSPRI){
       if(Exiting.PlayerReplicationInfo == LSPRI.Owner){
          PlayerIndex = GoneSmartPRI.Length;
          GoneSmartPRI[PlayerIndex] = LSPRI;
          if(bRecoverTotalScore){
             GoneSmartPRI[PlayerIndex].PlayerScore = Exiting.PlayerReplicationInfo.Score;
             }
          LSPRI.SetTimer(0.0, false);
          break;
       }
    }

    super.NotifyLogout(Exiting);
 }

/**
 * The function estimating the Server TickRate.
 *
 * @since version 1A
 */

 event Timer(){

    if(Level.NetMode == NM_DedicatedServer || Role == ROLE_Authority){
       if(++TRCount > 2){
         SCTFGame.TickRate = int( ConsoleCommand( "get IpDrv.TcpNetDriver NetServerMaxTickRate" ) );
         TRCount = 0;
       }
    }
 }


/**
 * The function for setting the SmartCTFBroadcastHandler at the begining of the
 * linked list of BroadcastHandlers.
 *
 * @since version 1A
 */

 function RegisterBroadcastHandler(){

    local BroadcastHandler LBGT;// Acronym for Local BroadcastHandler to Get Terminal
    local SmartCTFBroadcastHandler SBH;

    LBGT = Level.Game.BroadcastHandler;
    while(LBGT.NextBroadcastHandler != none)
       LBGT = LBGT.NextBroadcastHandler;
    SBH = Level.Game.Spawn(class'SmartCTFBroadcastHandler');
    SBH.SCTFMut = self;
    LBGT.NextBroadcastHandler = Level.Game.BroadcastHandler;
    Level.Game.BroadcastHandler = SBH;
 }

/**
 * Method to evaluate Covers, Seals and all that.
 *
 * @param Killed The Pawn class getting screwed.
 * @param Killer The Controller class screwing around.
 * @param damageType The nature of damage.
 * @param HitLocation The place of crime.
 *
 * TODO: Add Legendary Sounds for Coverspree :D:D:D
 * TODO: Rigorously test the Cover/Seal Hypothesis
 *
 * @see #SmartCTFGameRules.PreventDeath(Killed, Killer, damageType, HitLocation)
 * @since version 1A
 * authors of this routine can be found at http://wiki.unrealadmin.org/SmartCTF
 */

 function EvaluateKillingEvent(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation){

    local SmartCTFPlayerReplicationInfo KillerStats, KilledStats;
    local PlayerReplicationInfo KilledPRI, KillerPRI;
    local bool bKilledTeamHasFlag;

    if(Killed == none || Killed.Controller == none) return;
    KilledPRI = Killed.PlayerReplicationInfo;
    if(KilledPRI == none || (KilledPRI.bIsSpectator && !KilledPRI.bWaitingPlayer)) return;

    KilledStats = SCTFGame.GetStats(Killed.PlayerReplicationInfo);

    if(KilledStats != None){
       KilledStats.FragSpree = 0;// Reset FragSpree for Victim
       KilledStats.CoverSpree = 0;
       KilledStats.SpawnKillSpree = 0;
    }

    if(Killer == none || Killer == Killed.Controller){
       if(KilledStats != None) KilledStats.Suicides++;
       return;
    }

    KillerPRI = Killer.PlayerReplicationInfo;
    if(KillerPRI == none && (KillerPRI.bIsSpectator && !KillerPRI.bWaitingPlayer)) return;

    KillerStats = SCTFGame.GetStats(Killer.PlayerReplicationInfo);

    if(KilledPRI.Team == KillerPRI.Team)
       return;// Mistakes can happen :)

    // Increase Frags and FragSpree for Killer
    if(KillerStats != none){
       KillerStats.Frags++;
       KillerStats.FragSpree++;
    }

    if(KilledPRI.HasFlag != None){
       if(KillerStats != none) KillerStats.FlagKills++;
    }
    if(KillerPRI.HasFlag == none && FCs[KillerPRI.Team.TeamIndex] != none && FCs[KillerPRI.Team.TeamIndex].PlayerReplicationInfo.HasFlag != none){
       // COVER FRAG  / SEAL BASE
       // if Killer's Team has had an FC
       // if the FC has Flag Right now
       // Defend kill
       // org: if victim can see the FC or is within 600 unreal units (approx 40 feet) and has a line of sight to FC.
       //if( Victim.canSee( FCs[KillerPRI.Team] ) || ( Victim.lineOfSightTo( FCs[KillerPRI.Team] ) && Distance( Victim.Location, FCs[KillerPRI.Team].Location ) < 600 ) )
       // new: Killed was within 512 uu(UT) of FC
       //      or Killer was within 512 uu(UT) of FC
       //      or Killed could see FC and was killed within 1536 uu(UT) of FC
       //      or Killer can see FC and killed Killed within 1024 uu(UT) of FC
       //      or Killed had direct line to FC and was killed within 768 uu(UT)
       //
       // Note:      The new measures probably appeared in version 4, but don't quote me on that.
       // Also Note: Different Unreal Engines have different scales. Source: https://wiki.beyondunreal.com/Unreal_Unit
       //            It roughly translates to 1 uu(UT) = 1.125 uu(UT2k4) ~(The_Cowboy)
       // Level.Game.Broadcast(none, "Inside Cover/Seal: KillerPRI"@KillerPRI@"Flag Carrier"@FCs[KillerPRI.Team.TeamIndex]); For debug purpose :)
       if((VSize(Killed.Location - FCs[KillerPRI.Team.TeamIndex].Pawn.Location) < 512*1.125)
       || (VSize(Killer.Pawn.Location - FCs[KillerPRI.Team.TeamIndex].Pawn.Location) < 512*1.125)
       || (VSize(Killed.Location - FCs[KillerPRI.Team.TeamIndex].Pawn.Location) < 1536*1.125 && Killed.Controller.CanSee(FCs[KillerPRI.Team.TeamIndex].Pawn))
       || (VSize(Killed.Location - FCs[KillerPRI.Team.TeamIndex].Pawn.Location) < 1024*1.125 && Killer.CanSee(FCs[KillerPRI.Team.TeamIndex].Pawn))
       || (VSize(Killed.Location - FCs[KillerPRI.Team.TeamIndex].Pawn.Location) < 768*1.125 && Killed.Controller.LineOfSightTo(FCs[KillerPRI.Team.TeamIndex].Pawn))){
       // Killer DEFENDED THE Flag CARRIER
          if(KillerStats != none){
             KillerStats.Covers++;
             KillerStats.CoverSpree++;// Increment Cover spree
             if(KillerStats.CoverSpree == 3){// Cover x 3
                BroadcastLocalizedMessage(class'SmartCTFMoreMessages', 2, KillerPRI);
             }
             else if(KillerStats.CoverSpree == 4){// Cover x 4
                BroadcastLocalizedMessage(class'SmartCTFMoreMessages', 1, KillerPRI);
             }
             else{// Cover
                BroadcastLocalizedMessage(class'SmartCTFMoreMessages', 0, KillerPRI);
             }
          }
          KillerPRI.Score += CoverReward;// Cover Bonus
          Killer.AwardAdrenaline(CoverAdrenalineUnits);
       }

       // Defense Kill
       bKilledTeamHasFlag = true;
       if(FCs[KilledPRI.Team.TeamIndex] == none) bKilledTeamHasFlag = false;
       if(FCs[KilledPRI.Team.TeamIndex] != none &&
        FCs[KilledPRI.Team.TeamIndex].PlayerReplicationInfo.HasFlag == none) bKilledTeamHasFlag = false;// Safety check

       // if Killed's FC has not been set / if Killed's FC doesn't have our Flag
       if(!bKilledTeamHasFlag){
          // If Killed and Killer's FC are in Killer's Flag Zone
          if(IsInZone(KilledPRI, KillerPRI.Team.TeamIndex) && IsInzone(FCs[KillerPRI.Team.TeamIndex].PlayerReplicationInfo, KillerPRI.Team.TeamIndex)){
             // Killer SEALED THE BASE
             if(KillerStats != none)
                KillerStats.Seals++;
             BroadcastLocalizedMessage(class'SmartCTFMoreMessages', 3, KillerPRI);
             KillerPRI.Score += SealAward;//Seal Bonus
             Killer.AwardAdrenaline(SealAdrenalineUnits);
          }
       }
    }

    // HeadShot tracking
    if(damageType == Class'UTClassic.DamTypeClassicHeadshot' && KillerStats != none)
       KillerStats.HeadShots++;

 }

/**
 * Method to intercept the broadcasted messages which contain important clues
 * about the Flag and FlagCarriers and Ingame events. We spawned th
 * UTServerAdminSpectator Class instance as the Witness to interpret message only Once.
 *
 * @param Sender The Actor class sending the message.
 * @param Receiver The Controller class receiving the message.
 * @param Message The real message.
 * @param switch Category of Message.
 * @param Related_PRI1 Involved PlayerReplicationInfo 1
 * @param Related_PRI2 Involved PlayerReplicationInfo 2
 * @param OptionalObject Involved Object (Could be a Flag)
 *
 * @see #UnrealGame.CTFMessage
 * @since version 1A
 * authors of this routine can be found at http://wiki.unrealadmin.org/SmartCTF
 */

 function EvaluateMessageEvent(Actor Sender, PlayerController Receiver, class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject){

    local CTFFlag Flag;
    local SmartCTFPlayerReplicationInfo ReceiverStats;

    // First Blood register
    if(Message == class'FirstBloodMessage'){
       if(UTServerAdminSpectator(Receiver) == none) return;
       if(MessagingSpectator(Receiver) == Witness){
          ReceiverStats = SCTFGame.GetStats(RelatedPRI_1);
          if(ReceiverStats != none) ReceiverStats.bFirstBlood = true;
       }
    }

    // "Became a Spectator" fix!
    if(Message == Level.Game.GameMessageClass){
       switch(Switch){
          case 14:
             RelatedPRI_1.bIsSpectator = true;
             break;
       }
    }

    if(bBroadcastMonsterKillsAndAbove && Message == class'xDeathMessage'){
       if(UTServerAdminSpectator(Receiver) == none || RelatedPRI_1 == none || RelatedPRI_1.Owner == none || UnrealPlayer(RelatedPRI_1.Owner) == none) return;
       if(MessagingSpectator(Receiver) == Witness){
          switch(UnrealPlayer(RelatedPRI_1.Owner).MultiKillLevel){
             case 5:
             case 6:
             case 7:
                Level.Game.Broadcast(none, RelatedPRI_1.PlayerName@"had a"@
                class'MultiKillMessage'.default.KillString[Min(UnrealPlayer(RelatedPRI_1.Owner).MultiKillLevel,7)-1]);
                break;
          }
       }
    }

    if(Message == class'CTFMessage'){
       if(Sender.IsA('CTFGame')){
          foreach DynamicActors(class'CTFFlag', Flag)
             if(Flag.Team == UnrealTeamInfo(OptionalObject))
                break;
       }
       else
          if(Sender.IsA('CTFFlag')) Flag = CTFFlag(Sender);
       else
          return;
       if(Flag == None)
          return;
       if(UTServerAdminSpectator(Receiver) == none) return;// No use going further.
       switch(Switch){
          // CAPTURE
          // Sender: CTFGame, PRI: Scorer.PlayerReplicationInfo, OptObj: TheFlag.Team
          case 0:
             if(MessagingSpectator(Receiver) == Witness){//Controller(RelatedPRI_1.Owner)){
                ReceiverStats = SCTFGame.GetStats(RelatedPRI_1);
                if(ReceiverStats != none) ReceiverStats.Captures++;
                ResetSprees(0);
                ResetSprees(1);
                FCs[0] = none;
                FCs[1] = none;
             }
             break;

          // DROP
          // Sender: CTFFlag, PRI: OldHolder.PlayerReplicationInfo, OptObj: TheFlag.Team
          case 2:
             FCs[1-Flag.TeamNum] = none;// Just to be safe
             break;

          // PICKUP (after the FC dropped it)
          // Sender: CTFFlag, PRI: Holder.PlayerReplicationInfo, OptObj: TheFlag.Team
          case 4:
             if(MessagingSpectator(Receiver) == Witness){
                FCs[1-Flag.TeamNum] = Controller(RelatedPRI_1.Owner);
             }
             break;

          // GRAB (from the base mount-point)
          // Sender: CTFFlag, PRI: Holder.PlayerReplicationInfo, OptObj: TheFlag.Team
          case 6:
             if(MessagingSpectator(Receiver) == Witness){// Receiver == FirstHuman
                FCs[1-Flag.TeamNum] = Controller(RelatedPRI_1.Owner);
                ReceiverStats = SCTFGame.GetStats(FCs[1-Flag.TeamNum].PlayerReplicationInfo);
                if(ReceiverStats != none) ReceiverStats.Grabs++;
             }
             break;

          // RETURN
          case 1:
          case 3:
          case 5:
             if(MessagingSpectator(Receiver) == Witness)
                ResetSprees(Flag.TeamNum);
                //return;
             break;
       }
     }
 }

/**
 * Method to reset sprees
 *
 * @param Team The team of players whose sprees are to be reset
 * @since version 1A
 */

 function ResetSprees(int Team){

    local Controller LC;
    local SmartCTFPlayerReplicationInfo SPRI;

    for(LC = Level.ControllerList; LC != none; LC = LC.nextController){
       if(LC.PlayerReplicationInfo != none && LC.PlayerReplicationInfo.Team != none && LC.PlayerReplicationInfo.Team.TeamIndex == Team){
          SPRI = SCTFGame.GetStats(LC.PlayerReplicationInfo);
          if(SPRI != none){
             SPRI.CoverSpree = 0;
          }
       }
    }
 }

/**
 * Method to Register the Pickups!
 *
 * @param Other The Pawn Class picking the Pickups
 * @param item  The item getting picked up
 * @param bAllowPickup The pickup switch
 * @since version 1A
 */

 function RegisterPickupItems(Pawn Other, Pickup item, out byte bAllowPickup){

    local SmartCTFPlayerReplicationInfo SPRI;

    SPRI = SCTFGame.GetStats(Other.PlayerReplicationInfo);

    if(SPRI != none){
       if(item.IsA('UDamagePack'))
          SPRI.Amps++;
       if(item.IsA('ShieldPickup') || item.IsA('SuperShieldPack'))
          SPRI.ShieldBelts++;
    }
 }

/**
 * Method to check if the Player is in Flag zone.
 *
 * @param PRI The PlayerReplicationInfo class of the Player.
 * @param Team The team of Flag
 *
 * @see #EvaluateKillingEvent(Killed, Killer, DamageType, Location)
 * @since version 1A
 */

 function bool IsInZone(PlayerReplicationInfo PRI, byte Team){

    local string Loc;

    if(PRI.PlayerZone != none) Loc = PRI.PlayerZone.LocationName;
    else return false;

    if(Team == 0) return ( Instr( Caps( Loc ), RedFlagZone) != -1 );
    else return ( Instr( Caps( Loc ), BlueFlagZone) != -1 );
 }

 defaultproperties
 {
    Version="1C"
    bShowLogo=True
    bAddToServerPackages=True
    CoverReward=2
    CoverAdrenalineUnits=5
    SealAward=2
    SealAdrenalineUnits=5
    ScoreBoardType="SmartCTF1C.SmartCTFScoreBoard"
    RedFlagZone="RED BASE LOWER LEVEL"
    BlueFlagZone="BLUE BASE LOWER LEVEL"
    bShowFCLocation=True
    bBroadcastMonsterKillsAndAbove=True
    bDisableOvertime=False
    bShowCountryFlags=True
    bShowFirstBlood=True
    bRecoverTotalScore=True
 }

