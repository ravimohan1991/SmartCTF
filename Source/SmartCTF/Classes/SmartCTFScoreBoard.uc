/*
 *   --------------------------
 *  |  SmartCTFScoreBoard.uc
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
 */

/**
 * We write this Class to show all the Smart statistics collected by  <br />
 * SmartCTF in a visually appealing order. We also display the the     <br />
 * appropriate Time Stamp (DayofWeek, Day Month Year | Elapsed Time) and <br />
 * server information.
 *
 * TODO: Find better Textures.
 * @author The_Cowboy
 * @version 1A
 * @since 1A
 */

class SmartCTFScoreBoard extends ScoreboardTeamDeathMatch;

#exec texture Import File=Textures\Flag.bmp Name=Flag MIPS=OFF
#exec texture Import File=Textures\StatusBar.bmp Name=StatusBar MIPS=OFF
#exec texture Import File=Textures\bot1.bmp Name=Bot MIPS=OFF
#exec texture Import File=Textures\firstblood.pcx Name=FirstBlood MIPS=OFF
#exec FONT Import File=Textures\LEDNum.bmp Name=LEDNum
//#exec new TRUETYPEFONTFACTORY File=Textures\Texture1.bmp name = LEDNum FONTNAME="LEDNum" HEIGHT=24 ANTIALIAS=1 DROPSHADOWX=1 DROPSHADOWY=1 CHARS=".0123456789x"

/*
 * Global Variables
 */

 /** The SmartCTFGameReplicationInfo reference.*/
 var   SmartCTFGameReplicationInfo                      SCTFGame;

 /** The Array of PlayerReplicationInfo to be rendered.*/
 var   array<PlayerReplicationInfo>                     CurrPRI;

 /** The Array of SmartPlayerReplicationInfo to be rendered.*/
 var   array<SmartCTFPlayerReplicationInfo>             CurrSmartPRI;

 /** The font without the compression Scheme.*/
 var   font                                             OriginalFont;

 /** The player box height without the compression Scheme.*/
 var   int                                              OriginalBoxSpaceY;

 /** Number of red/blue players beyond display.*/
 var   int                                              MoreRedPlayerCounter, MoreBluePlayerCounter;

 /** Maximum of SmartStatistics in the current game.*/
 var   int                                              MaxCaptures, MaxCovers, MaxSeals,
                                                          MaxFlagKills, MaxSuicides, MaxGrabs;// Graphing purpose

 /** For estimating the time of individual player.*/
 var   float                                            FPHSTime;

 /** The space covered by the TitleFooter.*/
 var   float                                            TitleFooterLength;
 var   ScoreBoardTeamDeathMatch                         DefaultScoreBoard;


struct FlagData {
	var string Prefix;
	var texture Tex;
};

 /** Cache for flag rendering.*/
 var   FlagData                                         FD[32]; // there can be max 32 so max 32 different flags
 var   int                                              saveindex; // new loaded flags will be saved in FD[index]


simulated event PostNetBeginPlay(){

    Log("Searching SmartCTFGameReplicationInfo Instance in NetBeginPlay");
    foreach DynamicActors(class'SmartCTFGameReplicationInfo', SCTFGame)
       break;

}



/**
 * The function loads the Flag Textures for Rendering.
 *
 * @author Rush
 * @since version 1A
 */

 function int GetFlagIndex(string Prefix){

    local int i;

    for(i = 0;i < 32; i++)
	   if(FD[i].Prefix == Prefix)
	   return i;

    FD[saveindex].Prefix=Prefix;
	FD[saveindex].Tex = texture(DynamicLoadObject("CountryFlags2"$"."$Prefix, class'Texture'));
	i=saveindex;
	saveindex = (saveindex + 1) % 256;
	return i;
 }


/**
 * The function loads the Textures for Rendering Scoreboard.
 *
 * @since version 1A
 */

 simulated function UpdatePrecacheMaterials(){

   Level.AddPrecacheMaterial(texture'Flag');
   Level.AddPrecacheMaterial(texture'StatusBar');
   Level.AddPrecacheMaterial(texture'Bot');
   super.UpdatePrecacheMaterials();
 }
/*
simulated function PostBeginPlay()
{
    Super.PostBeginPlay();
    DefaultScoreBoard = Spawn(class'ScoreBoardTeamDeathMatch', Owner);
}

simulated event DrawScoreboard( Canvas C )
{
    DefaultScoreBoard.DrawScoreboard(C);
} */


/**
 * The event does it all!
 *
 * @since version 1A
 */

 simulated event UpdateScoreBoard(Canvas C){

    local PlayerReplicationInfo OwnerPRI, PRI;
    local int RedOwnerHighlight, BlueOwnerHighlight;// The player number to be Highlighted
    local int RedPlayerCounter, BluePlayerCounter, MaxPlayerCount;
    local float XL,YL, IconSize, MessageFoot, MaxScaling;
    local int BoxSpaceY, PlayerBoxSizeY, FontReduction, HeadFoot, HeaderOffsetY;
    local font MemorizeFont;
    local int i;
    local array<PlayerReplicationInfo> RedPRI, BluePRI;
    local array<SmartCTFPlayerReplicationInfo> RedSmartPRI, BlueSmartPRI;

    // Set the Owner
    OwnerPRI = PlayerController(Owner).PlayerReplicationInfo;

    RedOwnerHighlight = -1;
    BlueOwnerHighlight = -1;

    if(SCTFGame == none){
       Log("SmartCTFGameReplicationInfo instance not found. Retrying...", 'SmartCTF');
       foreach DynamicActors(class'SmartCTFGameReplicationInfo', SCTFGame)
          break;
       return;
    }

    // Count the number of players in Red and Blue teams
    // and assign the (SmartCTF)ReplicationInfo arrays
    // and compute the max Smart scores.
    for(i = 0; i < GRI.PRIArray.Length; i++){

       PRI = GRI.PRIArray[i];
       if((PRI.Team != None) && (!PRI.bIsSpectator || PRI.bWaitingPlayer)){
          if(PRI.Team.TeamIndex == 0){// Red
             RedPRI[RedPlayerCounter] = PRI;
             RedSmartPRI[RedPlayerCounter] = SCTFGame.GetStats(PRI);
             ComputeMaxima(RedSmartPRI[RedPlayerCounter]);
             if(PRI == OwnerPRI)
                RedOwnerHighlight = RedPlayerCounter;
             RedPlayerCounter++;
          }
          else{// Blue (Hopefully)
             BluePRI[BluePlayerCounter] = PRI;
             BlueSmartPRI[BluePlayerCounter] = SCTFGame.GetStats(PRI);
             ComputeMaxima(BlueSmartPRI[BluePlayerCounter]);
             if(PRI == OwnerPRI)
                BlueOwnerHighlight = BluePlayerCounter;
             BluePlayerCounter++;
          }
       }
    }

    MaxPlayerCount = Max(RedPlayerCounter, BluePlayerCounter);// Max column length (Red or Blue)

    // Now, Select best font size and box size to fit as many players as possible on screen
    C.Font = HUDClass.static.GetMediumFontFor(C);
    OriginalFont = C.Font;
    C.StrLen("Test", XL, YL);
    IconSize = FMax(2 * YL, 64 * C.ClipX / 1024);
    BoxSpaceY = 0.25 * YL;
    OriginalBoxSpaceY = BoxSpaceY;
    if (HaveHalfFont(C, FontReduction))
		PlayerBoxSizeY = 2.125 * YL;
	else
		PlayerBoxSizeY = 1.75 * YL;
	HeadFoot = 4*YL + IconSize;
	MessageFoot = 1.5 * HeadFoot;

	if(MaxPlayerCount > (C.ClipY - MessageFoot)/(PlayerBoxSizeY + BoxSpaceY)){
	   // Compress the Scoreboard: Decrease the Header Box
	   BoxSpaceY = 0.125 * YL;
	   if(MaxPlayerCount > (C.ClipY - MessageFoot)/(PlayerBoxSizeY + BoxSpaceY)){
	      // Compress the Scoreboard: Decrease individual PlayerBoxSize and Font
	      FontReduction++;
	      C.Font = GetSmallerFontFor(C, FontReduction);
	      C.StrLen("Test", XL, YL);
	      BoxSpaceY = 0.125 * YL;
	      if (HaveHalfFont(C, FontReduction))
	         PlayerBoxSizeY = 2.125 * YL;
	      else
	         PlayerBoxSizeY = 1.75 * YL;
	      HeadFoot = 4*YL + IconSize;
          if(MaxPlayerCount > (C.ClipY - MessageFoot)/(PlayerBoxSizeY + BoxSpaceY)){
             // Compress further by reducing Font
             FontReduction++;
             C.Font = GetSmallerFontFor(C, FontReduction);
	         C.StrLen("Test", XL, YL);
	         BoxSpaceY = 0.125 * YL;
	         if (HaveHalfFont(C, FontReduction))
	            PlayerBoxSizeY = 2.125 * YL;
	         else
	            PlayerBoxSizeY = 1.75 * YL;
	         HeadFoot = 4*YL + IconSize;
	         if(C.ClipY >= 600 && (MaxPlayerCount > (C.ClipY - HeadFoot)/(PlayerBoxSizeY + BoxSpaceY))){
	            // Compress further if Resolution is High enough (Why HeadFoot?)
	            FontReduction++;
                C.Font = GetSmallerFontFor(C, FontReduction);
	            C.StrLen("Test", XL, YL);
	            BoxSpaceY = 0.125 * YL;
	            if (HaveHalfFont(C, FontReduction))
	               PlayerBoxSizeY = 2.125 * YL;
	            else
	               PlayerBoxSizeY = 1.75 * YL;
	            HeadFoot = 4*YL + IconSize;
	            if(MaxPlayerCount > (C.ClipY - 1.5 * HeadFoot)/(PlayerBoxSizeY + BoxSpaceY)){
                   // final Compression
                   FontReduction++;
                   C.Font = GetSmallerFontFor(C, FontReduction);
	               C.StrLen("Test", XL, YL);
	               BoxSpaceY = 0.125 * YL;
	               if (HaveHalfFont(C, FontReduction))
	                  PlayerBoxSizeY = 2.125 * YL;
	               else
	                  PlayerBoxSizeY = 1.75 * YL;
	               HeadFoot = 4*YL + IconSize;
                }
             }
          }
       }
    }

    MaxPlayerCount = Min(MaxPlayerCount, 1+(C.ClipY - HeadFoot)/(PlayerBoxSizeY + BoxSpaceY));
    if(FontReduction > 2)
		MaxScaling = 3;
	else
		MaxScaling = 2.125;

    PlayerBoxSizeY = FClamp((1+(C.ClipY - 0.67 * MessageFoot))/MaxPlayerCount - BoxSpaceY, PlayerBoxSizeY, MaxScaling * YL);// Don't know what it does
	bDisplayMessages = (MaxPlayerCount < (C.ClipY - MessageFoot)/(PlayerBoxSizeY + BoxSpaceY));

    HeaderOffsetY = 1.5 * YL + IconSize;// The ordinate where HeaderBox and first PlayerBox meet.

    // Draw Title
    C.Style = ERenderStyle.STY_Normal;// The Enum
    MemorizeFont = C.Font;// Memorize the compression Scheme. In DrawTitle we use the fonts with FontReduction = 3.
    DrawTitle(C, HeaderOffsetY, (MaxPlayerCount+1)*(PlayerBoxSizeY + BoxSpaceY), PlayerBoxSizeY);
    C.Font = MemorizeFont;// Recall

    MaxPlayerCount = Min(MaxPlayerCount, (C.ClipY - HeaderOffsetY - TitleFooterLength) / (PlayerBoxSizeY + BoxSpaceY));// Make sure to not overwrite the Title

    // Number of team individuals to be displayed after the compression and all that
    // and set the "More" coutner.
    MoreRedPlayerCounter = RedPlayerCounter;
    MoreBluePlayerCounter = BluePlayerCounter;

    RedPlayerCounter = Min(RedPlayerCounter, MaxPlayerCount);
	BluePlayerCounter = Min(BluePlayerCounter, MaxPlayerCount);

    MoreRedPlayerCounter =  MoreRedPlayerCounter - RedPlayerCounter;
    MoreBluePlayerCounter = MoreBluePlayerCounter - BluePlayerCounter;

	// PlayerOwner score isn't High enough. So make way for the Owner!
    if(RedOwnerHighlight >= RedPlayerCounter)
		RedPlayerCounter -= 1;
	if(BlueOwnerHighlight >= BluePlayerCounter)
		BluePlayerCounter -= 1;

    if(GRI != none){
       // Draw Red team
       CurrPRI.Remove(0, CurrPRI.Length);
       CurrSmartPRI.Remove(0, CurrSmartPRI.Length);
       for(i = 0; i < RedPRI.Length; i++){
          CurrPRI[i] = RedPRI[i];
          CurrSmartPRI[i] = RedSmartPRI[i];
       }
       DrawTeam(0, RedPlayerCounter, RedOwnerHighlight, C, FontReduction, BoxSpaceY, PlayerBoxSizeY, HeaderOffsetY);

       // Draw Blue team
       CurrPRI.Remove(0, CurrPRI.Length);
       CurrSmartPRI.Remove(0, CurrSmartPRI.Length);
       for(i = 0; i < BluePRI.Length; i++){
          CurrPRI[i] = BluePRI[i];
          CurrSmartPRI[i] = BlueSmartPRI[i];
       }
       DrawTeam(1, BluePlayerCounter, BlueOwnerHighlight, C, FontReduction, BoxSpaceY, PlayerBoxSizeY, HeaderOffsetY);
    }
 }

/**
 * Now we compute the maximum SmartScores
 *
 * @param SmartPRI SmartCTFPlayerReplicationInfo of the Controller class
 * @since version 1A
 */

 function ComputeMaxima(SmartCTFPlayerReplicationInfo SmartPRI){

    if(SmartPRI != none){
       if(SmartPRI.Captures > MaxCaptures)
          MaxCaptures = SmartPRI.Captures;
       if(SmartPRI.Covers > MaxCovers)
          MaxCovers = SmartPRI.Covers;
       if(SmartPRI.FlagKills > MaxFlagKills)
          MaxFlagKills = SmartPRI.FlagKills;
       if(SmartPRI.Seals > MaxSeals)
          MaxSeals = SmartPRI.Seals;
       if(SmartPRI.Grabs > MaxGrabs)
          MaxGrabs = SmartPRI.Grabs;
       if(SmartPRI.Suicides > MaxSuicides)
          MaxSuicides = SmartPRI.Suicides;
    }
 }

/**
 * Now we draw a individual team lineup.
 *
 * @param TeamNum The index of the team to be drawn.
 * @param PlayerCount Number of players in the team.
 * @param OwnerHighlight The place of the player (in PRI array) who is to be Highlighted.
 * @param Canvas The Canvas on which teams are to be drawn.
 * @param FontReduction The compression Scheme counter.
 * @param BoxSpaceY  The height of Header Box
 * @param PlayerBoxSizeY The height of the Player Box.
 * @param HeaderOffsetY
 * @since version 1A
 */

 function DrawTeam(int TeamNum, int PlayerCount, int OwnerHighlight,
          Canvas Canvas, int FontReduction, int BoxSpaceY, int PlayerBoxSizeY, int HeaderOffsetY){

    local int OwnerPos, BoxWidth, BoxXPos, FaceXPos, NameXPos, ScoreXPos, ScoreYPos, SStatsXPos, NameY, BoxTextOffsetY, BoxSmartStatOffsetY;
    local float IconScale, ScoreBackScale, HXL, HYL, HPXL, HPYL, SCXL, SCYL, XL, YL, MaxNamePos;
    local float PSXL, PSYL, Eff;
    local int SymbolUSize, SymbolVSize;
    local float ratiof, LongestNameLength, PXL, PYL, FBXL, FBYL, UXL, UYL, MXL, MYL;
    local int i;
    local float avgping, avgpl;
    local int LastLine;
    local float CoverXPos, GrabsXPos, CapXPos, FlagKillXPos, SealXPos, SuicideXPos; // Smart Stats offsets.
    local int NumOfSmartStats;
    local string LongestName;
    local bool bNameFontReduction, bHaveHalfFont;
    local font memorizefont, ReducedFont;
    local string  playername[64];
    local material FaceMat; //LineFire;
    local string tempstr, PLTime;

    memorizefont = Canvas.Font;

    // Compute the background Box figures
    BoxWidth = 0.47 * Canvas.ClipX;
    BoxXPos = 0.5 * (0.5 * Canvas.ClipX - BoxWidth);
    BoxWidth = 0.5 * Canvas.ClipX - 2 * BoxXPos;
    BoxXPos = BoxXPos + TeamNum * 0.5 * Canvas.ClipX;
    FaceXPos = BoxXPos + 0.02 * BoxWidth;
    SStatsXPos = BoxXPos + 0.55 * BoxWidth; // for trimming Names
    bHaveHalfFont = HaveHalfFont(Canvas, FontReduction);// What does it do?

    // Render background box and more player count
	Canvas.Style = ERenderStyle.STY_Alpha;
	Canvas.DrawColor = HUDClass.default.WhiteColor;
	Canvas.SetPos(BoxXPos, HeaderOffsetY);
    Canvas.DrawTileStretched(TeamBoxMaterial[TeamNum], BoxWidth, PlayerCount * (PlayerBoxSizeY + BoxSpaceY));
    Canvas.Font = HUDClass.static.LoadFontStatic(6);
    Canvas.StrLen("Test", MXL, MYL);
    Canvas.SetPos(BoxXPos + BoxWidth, HeaderOffsetY + PlayerCount * (PlayerBoxSizeY + BoxSpaceY) - 1.1 * MYL);
    if(TeamNum == 0 && MoreRedPlayerCounter > 0){
       Canvas.DrawText(MoreRedPlayerCounter$"+");
    }
    else if(TeamNum == 1 && MoreBluePlayerCounter > 0){
       Canvas.DrawText(MoreBluePlayerCounter$"+");
    }
    Canvas.Font = memorizefont;

    // Compute the team Header figures (Epic's way)
    IconScale = Canvas.ClipX/4096;
	ScoreBackScale = Canvas.ClipX/1024;
	if(GRI.TeamSymbols[TeamNum] != None){
	   SymbolUSize = GRI.TeamSymbols[TeamNum].USize;
	   SymbolVSize = GRI.TeamSymbols[TeamNum].VSize;
	}
	else{
	   SymbolUSize = 256;
       SymbolVSize = 256;
	}
	ratiof = 0.75;// I am reducing the header box height by 0.75
    SymbolUSize = SymbolUSize * ratiof;
    SymbolVSize = SymbolVSize * ratiof;
    IconScale = IconScale * ratiof;
    BoxSpaceY = BoxSpaceY * ratiof;
	ScoreYPos = HeaderOffsetY - SymbolVSize * IconScale - BoxSpaceY;

    // Render the team Header box
    Canvas.DrawColor = 0.75 * HUDClass.default.WhiteColor;
	Canvas.SetPos(BoxXPos, ScoreYPos - BoxSpaceY);// Putting the Box little down
	Canvas.DrawTileStretched(Material'InterfaceContent.ScoreBoxA', BoxWidth, HeaderOffsetY + BoxSpaceY - ScoreYPos);

    // Render the team Icon
    Canvas.Style = ERenderStyle.STY_Normal;
	Canvas.DrawColor = TeamColors[TeamNum];
	Canvas.SetPos(FaceXPos, ScoreYPos - BoxSpaceY);// Pull the Icon in left
	if (GRI.TeamSymbols[TeamNum] != None)
		Canvas.DrawIcon(GRI.TeamSymbols[TeamNum], IconScale * BoxReductionRatio(BoxSpaceY, SymbolVSize * IconScale));

	// Write team score and HeadLine
    Canvas.Font = HUDClass.static.LoadFontStatic(0);
    //Canvas.Font = Font(DynamicLoadObject("SmartCTF1A.LEDNum", class'Font'));
    Canvas.StrLen(int(GRI.Teams[TeamNum].Score), SCXL, SCYL);
    Canvas.SetPos(FaceXPos + 0.13 * BoxWidth, HeaderOffsetY - (HeaderOffsetY + BoxSpaceY - ScoreYPos)/2 - SCYL / 2);// Middle of the header box (y axis)
    Canvas.DrawText(int(GRI.Teams[TeamNum].Score));
    Canvas.Font = HUDClass.static.LoadFontStatic(3);
    // Canvas.Font = Font(DynamicLoadObject("SmartCTF1A.UnrealT", class'Font'))
    Canvas.StrLen("Frags/Pts", HXL, HYL);
    Canvas.SetPos(BoxXPos + BoxWidth - 0.02 * BoxWidth - HXL, HeaderOffsetY - (HeaderOffsetY + BoxSpaceY - ScoreYPos)/2 - HYL / 2); //Middle of headerbox (y axis)
    Canvas.DrawText("Frags/Pts");

    // Write team average ping and packetloss
    avgping = 0;
    avgpl = 0;
    if (Level.NetMode != NM_Standalone){
       for(i = 0; i < CurrPRI.Length; i++)
          avgping += Min(999, 4 * CurrPRI[i].Ping);
       avgping /= CurrPRI.Length;
       Canvas.Font = HUDClass.static.LoadFontStatic(8);
       Canvas.DrawColor = HUDClass.default.GoldColor;
       Canvas.StrLen("AVG PING:"@int(avgping), HPXL, HPYL);
       Canvas.SetPos(FaceXPos + 0.13 * BoxWidth + 2 * SCXL, HeaderOffsetY - (HeaderOffsetY + BoxSpaceY - ScoreYPos)/2 - HPYL);
       Canvas.DrawText("AVG PING:"@int(avgping));
       for(i = 0; i < CurrPRI.Length; i++)
          avgpl += CurrPRI[i].PacketLoss;
       avgpl /= CurrPRI.Length;
       Canvas.SetPos(FaceXPos + 0.13 * BoxWidth + 2 * SCXL, HeaderOffsetY - (HeaderOffsetY + BoxSpaceY - ScoreYPos)/2);
       Canvas.DrawText("AVG PACKETLOSS:"@int(avgpl)$"%");
    }

    Canvas.Font = memorizefont;
    IconScale = Canvas.ClipX/1024 * BoxReductionRatio(BoxSpaceY, SymbolVSize * IconScale);// Dunno what for

    if (PlayerCount <= 0)
		return;

    // Draw lines between sections (Epic style)
	if (TeamNum == 0)
		Canvas.DrawColor = HUDClass.default.RedColor;
	else
		Canvas.DrawColor = HUDClass.default.BlueColor;
	if (OwnerHighlight >= PlayerCount)// if our owner player is Omega!
		LastLine = PlayerCount+1;
	else
		LastLine = PlayerCount;
	//LineMaterial = Material(DynamicLoadObject("SmartCTF1A.FireRingRed", class'Material'));TODO find better material (eg Fire :D)
    //LineFire = new class'FireTexture';
    for(i = 1; i < LastLine; i++){
	   Canvas.SetPos(FaceXPos, HeaderOffsetY + (PlayerBoxSizeY + BoxSpaceY) * i - 0.5 * BoxSpaceY);
	   Canvas.DrawTileStretched(Material'InterfaceContent.ButtonBob', 0.9 * BoxWidth, ScorebackScale * 3);
	  // Canvas.DrawTileStretched(LineFire, 0.9 * BoxWidth, ScorebackScale * 3);
	}
	Canvas.DrawColor = HUDClass.default.WhiteColor;

    // Draw player names (with Schematic font)
    // and Player Information (including Smart Info)
    Canvas.Font = memorizefont;// Recall compression Scheme.
    NameXPos = BoxXPos + 4 * 0.02 * BoxWidth + YL / 2;
    MaxNamePos = 0.95 * (SStatsXPos - NameXPos);
    for(i = 0; i < PlayerCount; i++){
       playername[i] = CurrPRI[i].PlayerName;
       Canvas.StrLen(playername[i], XL, YL);
       if (XL > FMax(LongestNameLength, MaxNamePos)){
          LongestName = PlayerName[i];
          LongestNameLength = XL;
        }
    }
    if(OwnerHighlight >= PlayerCount){// Player Omega
       playername[OwnerHighlight] = CurrPRI[OwnerHighlight].PlayerName;
       Canvas.StrLen(playername[OwnerHighlight], XL, YL);
		if (XL > FMax(LongestNameLength, MaxNamePos)){
		   LongestName = PlayerName[OwnerHighlight];// Found bug in Epic's code!
		   LongestNameLength = XL;
		}
	}

	if(LongestNameLength > 0){// Are you South Indian?:P Let us try to accomodate the name
       bNameFontReduction = true;
	   Canvas.Font = GetSmallerFontFor(Canvas, FontReduction + 1);
	   Canvas.StrLen(LongestName, XL, YL);
	   if (XL > MaxNamePos){
	      Canvas.Font = GetSmallerFontFor(Canvas, FontReduction + 2);
	      Canvas.StrLen(LongestName, XL, YL);
	      if (XL > MaxNamePos)
	         Canvas.Font = GetSmallerFontFor(Canvas, FontReduction + 3);// This is it, we give up!
		}
		ReducedFont = Canvas.Font;
	}

	// Let us do the trimming
    for(i = 0; i < PlayerCount; i++){
       Canvas.StrLen(playername[i], XL, YL);
       if (XL > MaxNamePos)
          playername[i] = left(playername[i], MaxNamePos/XL * len(playerName[i]));
	}
	if(OwnerHighlight >= PlayerCount){
       Canvas.StrLen(playername[OwnerHighlight], XL, YL);
          if (XL > MaxNamePos)
             playername[OwnerHighlight] = left(playername[OwnerHighlight], MaxNamePos/XL * len(playerName[OwnerHighlight]));
	}

	if (Canvas.ClipX < 512)// Get better Hardware
		NameY = 0.5 * YL;
	else if(!bHaveHalfFont)
		NameY = 0.125 * YL;

    Canvas.Style = ERenderStyle.STY_Normal;
	Canvas.DrawColor = HUDClass.default.WhiteColor;
    BoxTextOffsetY = HeaderOffsetY + 0.5 * PlayerBoxSizeY - 0.5 * YL;

    for(i = 0; i < PlayerCount; i++) //
       if(i != OwnerHighlight){
          Canvas.DrawColor = HUDClass.default.WhiteColor;// Not to get overwritten by Red color!
          Canvas.SetPos(NameXPos, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY - 0.5 * YL + NameY);
          Canvas.StrLen(playername[i], PXL, PYL);
          Canvas.DrawText(playername[i], true);
          FBXL = 0;
          FBYL = 0;
          if(CurrSmartPRI[i] != none && CurrSmartPRI[i].bFirstBlood){
             Canvas.Font = GetSmallerFontFor(Canvas, FontReduction + 4);
             Canvas.DrawColor = HUDClass.default.RedColor;
             Canvas.StrLen("First Blood", FBXL, FBYL);
             Canvas.SetPos(NameXPos + 1.1 * PXL, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY + 0.5 * YL - FBYL);
             //Canvas.DrawTile(texture'FirstBlood', 0.8 * PYL, 0.8 * PYL, 0 , 0, 256, 256);
             Canvas.DrawText("First Blood");
             //Canvas.Font = memorizefont;
             //Canvas.DrawColor = HUDClass.default.WhiteColor;
          }
          if(CurrSmartPRI[i] != none){
             Canvas.Font = GetSmallerFontFor(Canvas, FontReduction + 7);
             Canvas.DrawColor = HUDClass.default.GoldColor;
             Canvas.StrLen("Test", UXL, UYL);
             // Row1
             Canvas.SetPos(NameXPos + 1.1 * PXL + 1.1 * FBXL, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY + 0.5 * YL - 3 * UYL);
             if(CurrSmartPRI[i].Frags + CurrPRI[i].Deaths == 0) Eff = 0;
             else Eff = CurrSmartPRI[i].Frags / (CurrSmartPRI[i].Frags + CurrPRI[i].Deaths) * 100;
             if(((FPHSTime == 0) || (!UnrealPlayer(Owner).bDisplayLoser && !UnrealPlayer(Owner).bDisplayWinner))
		        && (GRI.ElapsedTime > 0))
		        FPHSTime = GRI.ElapsedTime;
		     PLTime = FormatTime(Max(0, FPHSTime - CurrPRI[i].StartTime));
             Canvas.DrawText("EFF:"@int(Eff)$"% TIME:"@PLTime@"NETSPEED:"@CurrSmartPRI[i].NetSpeed);
             Canvas.SetPos(NameXPos + 1.1 * PXL + 1.1 * FBXL, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY + 0.5 * YL - 2 * UYL);
             Canvas.DrawText("HeadShots:"@CurrSmartPRI[i].HeadShots@"Amps:"@CurrSmartPRI[i].Amps@"Shields:"@CurrSmartPRI[i].ShieldBelts);// More stats to draw
          }
          Canvas.Font = memorizefont;
       }

	// Draw player Faces or Flags
    for(i = 0; i < PlayerCount; i++){
	   if(i != OwnerHighlight){
          Canvas.SetPos(FaceXPos, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY - 0.5 * YL + NameY);
          if(CurrPRI[i].HasFlag == none){
	         FaceMat = CurrPRI[i].GetPortrait();
             DrawPotrait(Canvas, FaceMat, XL, YL);
          }
          else
             DrawFlag(Canvas, TeamNum, XL, YL);
       }
	}

    // Draw scores and SmartStats (lower half of the Box)
	Canvas.DrawColor = HUDClass.default.WhiteColor;
	for(i = 0; i < PlayerCount; i++){
	   if(i != OwnerHighlight){
          if(CurrSmartPRI[i] != none && CurrPRI[i] != none){
             Canvas.StrLen(CurrSmartPRI[i].Frags$"/"$int(CurrPRI[i].Score), PSXL, PSYL);
             ScoreXPos = BoxXPos + BoxWidth - 0.02 * BoxWidth - HXL / 2 - PSXL / 2;
             Canvas.SetPos(ScoreXPos, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY - 0.5 * YL + NameY);
             if(CurrPRI[i].bOutOfLives)
	            Canvas.DrawText(OutText, true);
             else
                Canvas.DrawText(CurrSmartPRI[i].Frags$"/"$int(CurrPRI[i].Score), true);
             // First Row (lower half of the PlayerBox)
             BoxSmartStatOffsetY = HeaderOffsetY + 0.5 * PlayerBoxSizeY;
             NumOfSmartStats = 3; // In the Row.
             CapXPos = NameXPos;
             Canvas.SetPos(CapXPos, (PlayerBoxSizeY + BoxSpaceY) * i + BoxSmartStatOffsetY);
             DrawStatType(Canvas, "Caps:", CurrSmartPRI[i].Captures, MaxCaptures, FontReduction);
             CoverXPos = CapXPos + 1 * (BoxXPos + BoxWidth - 0.02 * BoxWidth - CapXPos) / NumOfSmartStats;
             Canvas.SetPos(CoverXPos, (PlayerBoxSizeY + BoxSpaceY) * i + BoxSmartStatOffsetY);
             DrawStatType(Canvas, "Covers:", CurrSmartPRI[i].Covers, MaxCovers, FontReduction);
             SealXPos = CapXPos + 2 * (BoxXPos + BoxWidth - 0.02 * BoxWidth - CapXPos) / NumOfSmartStats;
             Canvas.SetPos(SealXPos, (PlayerBoxSizeY + BoxSpaceY) * i + BoxSmartStatOffsetY);
             DrawStatType(Canvas, "Seals:", CurrSmartPRI[i].Seals, MaxSeals, FontReduction);
             // Second Row
             BoxSmartStatOffsetY += 2 * 0.125 * PlayerBoxSizeY;
             FlagKillXPos = CapXPos + 0 * (BoxXPos + BoxWidth - 0.02 * BoxWidth - CapXPos) / NumOfSmartStats;
             Canvas.SetPos(FlagKillXPos, (PlayerBoxSizeY + BoxSpaceY) * i + BoxSmartStatOffsetY);
             DrawStatType(Canvas, "FlagKls:", CurrSmartPRI[i].FlagKills, MaxFlagKills, FontReduction);
             GrabsXPos = CapXPos + 1 * (BoxXPos + BoxWidth - 0.02 * BoxWidth - CapXPos) / NumOfSmartStats;
             Canvas.SetPos(GrabsXPos, (PlayerBoxSizeY + BoxSpaceY) * i + BoxSmartStatOffsetY);
             DrawStatType(Canvas, "Grabs:", CurrSmartPRI[i].Grabs, MaxGrabs, FontReduction);
             SuicideXPos = CapXPos + 2 * (BoxXPos + BoxWidth - 0.02 * BoxWidth - CapXPos) / NumOfSmartStats;
             Canvas.SetPos(SuicideXPos, (PlayerBoxSizeY + BoxSpaceY) * i + BoxSmartStatOffsetY);
             DrawStatType(Canvas, "Suicides:", CurrSmartPRI[i].Suicides, MaxSuicides, FontReduction);
          }
       }
    }

    // Next, we draw the CountryFlags and Ping and maybe PacketLoss? (only for Humans)
    memorizefont = Canvas.Font;
    for(i = 0; i < PlayerCount; i++){
	   if(i != OwnerHighlight){
          if(CurrSmartPRI[i] != none && PlayerController(CurrPRI[i].Owner) != none){
             Canvas.SetPos(FaceXPos + YL / 3.0 - 8 * 1.2, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY + 0.5 * YL + 0.15 * YL);
             Canvas.bNoSmooth = false;
             Canvas.DrawColor = HUDClass.default.WhiteColor;
             Canvas.DrawIcon(FD[GetFlagIndex(CurrSmartPRI[i].NationPrefix)].Tex, 1.2);// IpToCountry Hook
             Canvas.Font = HUDClass.static.LoadFontStatic(8);
             tempstr = "PI:" $ Min(999, 4 * CurrPRI[i].Ping);
             if(Len(tempstr) > 5) TempStr = "P:" $ Min(999, 4 * CurrPRI[i].Ping);
             if(Len(tempstr) > 5) TempStr = string(Min(999, 4 * CurrPRI[i].Ping));
             Canvas.StrLen(tempstr, HPXL, HPYL);
             Canvas.SetPos(FaceXPos + YL / 3.0 - HPXL / 2, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY + 0.5 * YL + 0.15 * YL + 16 * 1.2);
             Canvas.DrawText(tempstr);
          }
          else if(CurrPRI[i].bBot){
             Canvas.SetPos(FaceXPos + YL / 3.0 - 16 * 0.4, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY + 0.5 * YL + 0.15 * YL);
             Canvas.DrawIcon(texture'Bot', 0.4);
          }
       }
	}
	Canvas.Font = memorizefont;

    // Finally we draw the Owner's stats (Start From the Begining)
    if(OwnerHighlight >= 0){
       Canvas.Style = ERenderStyle.STY_Alpha;
       if(OwnerHighlight > PlayerCount){// If your score is too low, then Draw over the last displayable player.
          OwnerPos = (PlayerBoxSizeY + BoxSpaceY) * PlayerCount + BoxTextOffsetY;
			// draw extra box
          Canvas.SetPos(BoxXPos, HeaderOffsetY + (PlayerBoxSizeY + BoxSpaceY) * PlayerCount);
          Canvas.DrawTileStretched(TeamBoxMaterial[TeamNum], BoxWidth, PlayerBoxSizeY);
       }
       else
           OwnerPos = (PlayerBoxSizeY + BoxSpaceY) * OwnerHighlight + BoxTextOffsetY;
       Canvas.StrLen(playername[OwnerHighlight], PXL, PYL);
       Canvas.DrawColor = HUDClass.default.CyanColor;// May have to modify according to the Color Scheme
       Canvas.SetPos(NameXPos, OwnerPos - 0.5 * YL + NameY);// Or PYL
       Canvas.DrawText(playername[OwnerHighlight], true);
       //Level.Game.Broadcast(none, CurrSmartPRI.Length@OwnerHighlight);
       // If owner drew the First Blood
       FBXL = 0;
       FBYL = 0;
       if(CurrSmartPRI[OwnerHighlight] != none && CurrSmartPRI[OwnerHighlight].bFirstBlood){
          Canvas.Font = GetSmallerFontFor(Canvas, FontReduction + 4);
          Canvas.DrawColor = HUDClass.default.RedColor;
          Canvas.StrLen("First Blood", FBXL, FBYL);
          Canvas.SetPos(NameXPos + 1.1 * PXL, OwnerPos + 0.5 * YL - FBYL);
          //Canvas.DrawTile(texture'FirstBlood', 0.8 * PYL, 0.8 * PYL, 0 , 0, 256, 256);
          Canvas.DrawText("First Blood");
       }
       // Draw Eff, Netspeed, Headshots etc
       if(CurrSmartPRI[OwnerHighlight] != none){
          Canvas.Font = GetSmallerFontFor(Canvas, FontReduction + 7);
          Canvas.DrawColor = HUDClass.default.GoldColor;
          Canvas.StrLen("Test", UXL, UYL);
          // Row1
          Canvas.SetPos(NameXPos + 1.1 * PXL + 1.1 * FBXL, OwnerPos + 0.5 * YL - 3 * UYL);
          if(CurrSmartPRI[OwnerHighlight].Frags + CurrPRI[OwnerHighlight].Deaths == 0) Eff = 0;
          else Eff = CurrSmartPRI[OwnerHighlight].Frags / (CurrSmartPRI[OwnerHighlight].Frags + CurrPRI[OwnerHighlight].Deaths) * 100;
          if(((FPHSTime == 0) || (!UnrealPlayer(Owner).bDisplayLoser && !UnrealPlayer(Owner).bDisplayWinner))
		        && (GRI.ElapsedTime > 0))
             FPHSTime = GRI.ElapsedTime;
          PLTime = FormatTime(Max(0, FPHSTime - CurrPRI[OwnerHighlight].StartTime));
          Canvas.DrawText("EFF:"@int(Eff)$"% TIME:"@PLTime@"NETSPEED:"@CurrSmartPRI[OwnerHighlight].NetSpeed);
          Canvas.SetPos(NameXPos + 1.1 * PXL + 1.1 * FBXL, OwnerPos + 0.5 * YL - 2 * UYL);
          Canvas.DrawText("HeadShots:"@CurrSmartPRI[OwnerHighlight].HeadShots@"Amps:"@CurrSmartPRI[OwnerHighlight].Amps@"Shields:"@CurrSmartPRI[OwnerHighlight].ShieldBelts);// More stats to draw
          }
          Canvas.Font = memorizefont;

          // Draw Owner's Face or Flag
          Canvas.SetPos(FaceXPos, OwnerPos - 0.5 * YL + NameY);
          if(CurrPRI[OwnerHighlight].HasFlag == none){
	         FaceMat = CurrPRI[OwnerHighlight].GetPortrait();
             DrawPotrait(Canvas, FaceMat, XL, YL);
          }
          else
             DrawFlag(Canvas, TeamNum, XL, YL);

       // Draw Owner's Smart Stats
       if(CurrSmartPRI[OwnerHighlight] != none && CurrPRI[OwnerHighlight] != none){
          Canvas.DrawColor = HUDClass.default.CyanColor;
          Canvas.StrLen(CurrSmartPRI[OwnerHighlight].Frags$"/"$int(CurrPRI[OwnerHighlight].Score), PSXL, PSYL);
          ScoreXPos = BoxXPos + BoxWidth - 0.02 * BoxWidth - HXL / 2 - PSXL / 2;
          Canvas.SetPos(ScoreXPos, OwnerPos - 0.5 * YL + NameY);
          if(CurrPRI[OwnerHighlight].bOutOfLives)
             Canvas.DrawText(OutText, true);
          else
             Canvas.DrawText(CurrSmartPRI[OwnerHighlight].Frags$"/"$int(CurrPRI[OwnerHighlight].Score), true);

          // First Row (lower half of the PlayerBox)
          BoxSmartStatOffsetY = HeaderOffsetY + 0.5 * PlayerBoxSizeY;
          NumOfSmartStats = 3; // In the Row.
          CapXPos = NameXPos;
          Canvas.SetPos(CapXPos, OwnerPos - BoxTextOffsetY + BoxSmartStatOffsetY);
          DrawStatType(Canvas, "Caps:", CurrSmartPRI[OwnerHighlight].Captures, MaxCaptures, FontReduction);
          CoverXPos = CapXPos + 1 * (BoxXPos + BoxWidth - 0.02 * BoxWidth - CapXPos) / NumOfSmartStats;
          Canvas.SetPos(CoverXPos, OwnerPos - BoxTextOffsetY + BoxSmartStatOffsetY);
          DrawStatType(Canvas, "Covers:", CurrSmartPRI[OwnerHighlight].Covers, MaxCovers, FontReduction);
          SealXPos = CapXPos + 2 * (BoxXPos + BoxWidth - 0.02 * BoxWidth - CapXPos) / NumOfSmartStats;
          Canvas.SetPos(SealXPos, OwnerPos - BoxTextOffsetY + BoxSmartStatOffsetY);
          DrawStatType(Canvas, "Seals:", CurrSmartPRI[OwnerHighlight].Seals, MaxSeals, FontReduction);
          // Second Row
          BoxSmartStatOffsetY += 2 * 0.125 * PlayerBoxSizeY;
          FlagKillXPos = CapXPos + 0 * (BoxXPos + BoxWidth - 0.02 * BoxWidth - CapXPos) / NumOfSmartStats;
          Canvas.SetPos(FlagKillXPos, OwnerPos - BoxTextOffsetY + BoxSmartStatOffsetY);
          DrawStatType(Canvas, "FlagKls:", CurrSmartPRI[OwnerHighlight].FlagKills, MaxFlagKills, FontReduction);
          GrabsXPos = CapXPos + 1 * (BoxXPos + BoxWidth - 0.02 * BoxWidth - CapXPos) / NumOfSmartStats;
          Canvas.SetPos(GrabsXPos, OwnerPos - BoxTextOffsetY + BoxSmartStatOffsetY);
          DrawStatType(Canvas, "Grabs:", CurrSmartPRI[OwnerHighlight].Grabs, MaxGrabs, FontReduction);
          SuicideXPos = CapXPos + 2 * (BoxXPos + BoxWidth - 0.02 * BoxWidth - CapXPos) / NumOfSmartStats;
          Canvas.SetPos(SuicideXPos, OwnerPos - BoxTextOffsetY + BoxSmartStatOffsetY);
          DrawStatType(Canvas, "Suicides:", CurrSmartPRI[OwnerHighlight].Suicides, MaxSuicides, FontReduction);
       }

       // Now draw CountryFlags and Ping
       if(CurrSmartPRI[OwnerHighlight] != none && PlayerController(CurrPRI[OwnerHighlight].Owner) != none){
          Canvas.SetPos(FaceXPos + YL / 3.0 - 8 * 1.2, OwnerPos + 0.5 * YL + 0.15 * YL);
          Canvas.bNoSmooth = false;
          Canvas.DrawColor = HUDClass.default.WhiteColor;
          Canvas.DrawIcon(FD[GetFlagIndex(CurrSmartPRI[OwnerHighlight].NationPrefix)].Tex, 1.2);// IpToCountry Hook
          Canvas.Font = HUDClass.static.LoadFontStatic(8);
          tempstr = "PI:" $ Min(999, 4 * CurrPRI[OwnerHighlight].Ping);
          if(Len(tempstr) > 5) TempStr = "P:" $ Min(999, 4 * CurrPRI[OwnerHighlight].Ping);
          if(Len(tempstr) > 5) TempStr = string(Min(999, 4 * CurrPRI[OwnerHighlight].Ping));
          Canvas.StrLen(tempstr, HPXL, HPYL);
          Canvas.SetPos(FaceXPos + YL / 3.0 - HPXL / 2, OwnerPos + 0.5 * YL + 0.15 * YL + 16 * 1.2);
          Canvas.DrawText(tempstr);
          }
    }
    Canvas.Font = memorizefont;
 }

/**
 * Another compression scheme for the SmartStats in the upperhalf of the PlayerBox
 *
 * @since version 1A
 */
 //FindAppropriateText(int(Eff), PLTime, CurrSmartPRI[i].NetSpeed, NameXPos + 1.1 * PXL + 1.1 * FBXL, ScoreXPos);
 function string FindAppropriateText(int Data1, int Data2, int Data3, float BeginPos, float EndPos){

   return "";
 }


/**
 * Method to draw Flags if the Player has One!. This method remembers
 * the original position and font of the canvas.
 *
 * @param Canvas The drawing canvas.
 * @param TeamNum Team of the Player (0 = Red, 1 = Blue).
 * @param XL The width of the main text.
 * @param YL The height of the main text.
 *
 * TODO: Find better texture :P
 * @since version 1A
 */

 function DrawStatType(Canvas Canvas, string Label, float Count, float MaxCount, int FontReduction){

    local float XL, YL, MemorizeX, MemorizeY;
    local font MemorizeFont;
   // local color MemorizeColor;

    MemorizeFont = Canvas.Font;
    MemorizeX = Canvas.CurX;
    MemorizeY = Canvas.CurY;
    Canvas.Font = GetSmallerFontFor(Canvas, FontReduction + 5);

    Canvas.StrLen(Label$" "$int(Count), XL, YL);
    Canvas.DrawText(Label$" "$int(Count));

    Canvas.SetPos(MemorizeX + XL + 1.5, MemorizeY + YL / 2 - 0.3 * YL /2);
    //Canvas.DrawColor = Canvas.static.MakeColor(Rand(255), Rand(255), Rand(255)); Only if you are Fruitcake!!!
    Canvas.DrawRect(texture'StatusBar', (Count / MaxCount) * 80, 0.3 * YL);

    Canvas.SetPos(MemorizeX, MemorizeY);
    Canvas.Font = MemorizeFont;
   // Canvas.DrawColor = MemorizeColor;
 }

/**
 * Method to draw Flags if the Player has One!
 *
 * @param Canvas The drawing canvas.
 * @param TeamNum Team of the Player (0 = Red, 1 = Blue).
 * @param XL The width of the main text.
 * @param YL The height of the main text.
 *
 * TODO: Find better texture :P
 * @since version 1A
 */

 function DrawFlag(Canvas Canvas, int TeamNum, float XL, float YL){

    local float FlagWidth, FlagHeight;
    local float MemorizeX, MemorizeY;

    MemorizeX = Canvas.CurX;
    MemorizeY = Canvas.CurY;
    FlagHeight = YL;
    FlagWidth = YL / 1.5;

    if(TeamNum == 1){
       Canvas.DrawColor = HUDClass.default.RedColor;
       Canvas.DrawTile(Texture'Flag', FlagWidth , FlagHeight, 0, 0, 64, 64);
    }
    else{
       Canvas.DrawColor = HUDClass.default.BlueColor;
       Canvas.DrawTile(Texture'Flag', FlagWidth , FlagHeight, 0, 0, 64, 64);
    }
    Canvas.DrawColor = HUDClass.default.WhiteColor;
 }

/**
 * Method to draw Potrait on the scoreboard. Ripped right from Epic's HudBDeathMatch.DrawHudPassC(Canvas)
 * (of course with some modifications!).
 *
 * @param Canvas The drawing canvas.
 * @param Potrait Potrait of the Player.
 * @param XL The width of the main text.
 * @param YL The height of the main text.
 *
 * @since version 1A
 */

 function DrawPotrait(Canvas Canvas, Material Portrait, float XL, float YL){

    local float PortraitWidth, PortraitHeight;
    local float MemorizeX, Memorizey;

    MemorizeX = Canvas.CurX;
    MemorizeY = Canvas.CurY;
    PortraitHeight = YL;
    PortraitWidth = YL / 1.5;
    Canvas.DrawColor = HUDClass.default.WhiteColor;

    if(Portrait != none){
       Canvas.DrawTile(Portrait, PortraitWidth , PortraitHeight, 0, 0, 256, 384);
    }
    else
       Canvas.DrawTile(Texture'PlayerPictures.cDefault', PortraitWidth , PortraitHeight, 0, 0, 256, 384);

    Canvas.DrawColor = Canvas.static.MakeColor(160, 160, 160);
    Canvas.SetPos(MemorizeX, MemorizeY);
    Canvas.DrawTile(Material'XGameShaders.ModuNoise', PortraitWidth, PortraitHeight, 0.0, 0.0, 512, 512 );

    Canvas.DrawColor = HUDClass.default.WhiteColor;
    Canvas.SetPos(MemorizeX, MemorizeY);
    Canvas.DrawTileStretched(texture 'InterfaceContent.Menu.BorderBoxA1', 1.05 * PortraitWidth, 1.05*PortraitHeight);
 }


/**
 * Method to estimate the ratio of BoxReduction Scheme.
 *
 * @param BoxSpaceY The space beyond the Icon in the header area
 * @param ScaledVertical SymbolSize times Iconscale (from 4k res!)
 * @since version 1A
 */

 function float BoxReductionRatio(int BoxSpaceY, float ScaledVertical){

    return (2 * BoxSpaceY + ScaledVertical) / (2 * OriginalBoxSpaceY + ScaledVertical);
 }

/**
 * Here we draw a sensible Title (Epic's default Title system SUCKS!)
 *
 * @param Canvas The Canvas to Draw on
 * @param HeaderOffsetY
 * @param PlayerAreaY
 * @param PlayerBoxSizeY
 * @since version 1A
 */

 function DrawTitle(Canvas Canvas, float HeaderOffsetY, float PlayerAreaY, float PlayerBoxSizeY)
 {
	local string HeaderTitleString, FooterTitleString, TimeString, SpectatorString;
	local float HeaderTitleXL, FooterTitleXL, TimeXL, YL, RYL, SpectatorXL, SpectatorYL;

	if ( Canvas.ClipX < 512 )// Really, are you kidding?
		return;

	HeaderTitleString = GetHeaderTitleString();
	SpectatorString   = GetSpectatorString();
    TimeString        = GetTimeString();
	FooterTitleString = GetFooterTitleString();

	Canvas.DrawColor = HUDClass.default.WhiteColor;

	Canvas.StrLen(HeaderTitleString, HeaderTitleXL, YL);
	Canvas.SetPos(0.5*(Canvas.ClipX - HeaderTitleXL), YL);
	Canvas.DrawText(HeaderTitleString, true);

    Canvas.Font = GetSmallerFontFor(Canvas, 3);
    Canvas.StrLen(FooterTitleString, FooterTitleXL, YL);
    Canvas.SetPos(0.5*(Canvas.ClipX - FooterTitleXL), Canvas.ClipY - 1.3 * YL);
    RYL = YL;
	Canvas.DrawText(FooterTitleString, true);

	Canvas.StrLen(TimeString, TimeXL, YL);
    Canvas.SetPos(0.5*(Canvas.ClipX - TimeXL), Canvas.ClipY - 1.3 * RYL - 0.9 * YL);
	Canvas.DrawText(TimeString, true);

	if(SpectatorString != ""){
       SpectatorString = "Spectators:"@SpectatorString$".";
      // Canvas.Font = GetSmallerFontFor(Canvas, 3);
       Canvas.StrLen(SpectatorString, SpectatorXL, SpectatorYL);
       Canvas.DrawColor = Canvas.static.MakeColor(255, 192, 203);
       Canvas.SetPos(0.5*(Canvas.ClipX - SpectatorXL), Canvas.ClipY - 1.3 * RYL - 0.9 * YL - 0.9 * SpectatorYL);
       Canvas.DrawText(SpectatorString, true);
    }
    Canvas.DrawColor = HUDClass.default.WhiteColor;
    TitleFooterLength = 1.3 * RYL + 0.9 * YL + SpectatorYL;
 }

/**
 * Obtain the list of Spectators.
 *
 * @since version 1A
 */

 function string GetSpectatorString(){

    local string ReturnString;
    local int i;

    if(GRI == none || !GRI.bMatchHasBegun)// No spectators are shown during the Match Survey
       return "";
    for(i = 0; i < GRI.PRIArray.Length; i++){
       if(GRI.PRIArray[i].bIsSpectator && GRI.PRIArray[i].PlayerName != "Witness"){
          if(ReturnString == "")
             ReturnString = ReturnString@GRI.PRIArray[i].PlayerName;
          else
             ReturnString = ReturnString$","@GRI.PRIArray[i].PlayerName;
       }
    }
    return ReturnString;
 }


/**
 * Obtain the Title Header String with the status information.
 *
 * @since version 1A
 */

 function string GetHeaderTitleString(){

    local string str;
    local int team;

    if(!GRI.bMatchHasBegun) return "Match Survey";

    if(UnrealPlayer(Owner).PlayerReplicationInfo.Team == none) return "You are Spectating!";

    team = UnrealPlayer(Owner).PlayerReplicationInfo.Team.TeamIndex;

    if(UnrealPlayer(Owner).bDisplayLoser){
	   if(team == 0) str = "Blue wins the Match!";
       else str = "Red wins the Match";
    }
	else if(UnrealPlayer(Owner).bDisplayWinner){
	   if(team == 0) str = "Red wins the Match!";
	   else str = "Blue wins the Match!";
    }

    if(str == "")
       str = "Match in progress...";
    return str;
 }

/**
 * Obtain the Time Information String
 *
 * @since version 1A
 */

 function string GetTimeString(){

    local string TimeStr;
    local int Seconds, Minutes, Hours;

    Seconds = GRI.ElapsedTime;
    Minutes = Seconds / 60;
    Hours = Minutes / 60;
    Seconds = Seconds - ( Minutes * 60 );
    Minutes = Minutes - ( Hours * 60 );
    TimeStr = "Elapsed Time: " $ TwoDigitString( Hours ) $ ":" $ TwoDigitString( Minutes ) $ ":" $ TwoDigitString( Seconds );

    return GetDateTimeStr() @ "|" @ TimeStr;
 }

/**
 * Obtain the Date and Time String
 *
 * @since version 1A
 */

 function string GetDateTimeStr(){
    local string Mon, Day;
    local int Min;

    Min = Owner.Level.Minute;

    switch(Owner.Level.month ){
       case  1: Mon = "Jan"; break;
       case  2: Mon = "Feb"; break;
       case  3: Mon = "Mar"; break;
       case  4: Mon = "Apr"; break;
       case  5: Mon = "May"; break;
       case  6: Mon = "Jun"; break;
       case  7: Mon = "Jul"; break;
       case  8: Mon = "Aug"; break;
       case  9: Mon = "Sep"; break;
       case 10: Mon = "Oct"; break;
       case 11: Mon = "Nov"; break;
       case 12: Mon = "Dec"; break;
    }

    switch(Owner.Level.dayOfWeek){
       case 0: Day = "Sunday";    break;
       case 1: Day = "Monday";    break;
       case 2: Day = "Tuesday";   break;
       case 3: Day = "Wednesday"; break;
       case 4: Day = "Thursday";  break;
       case 5: Day = "Friday";    break;
       case 6: Day = "Saturday";  break;
    }
    return "Current Time:" @ Day @ Owner.Level.Day @ Mon @ Owner.Level.Year $ ","
    @ TwoDigitString(Owner.Level.Hour) $ ":" $ TwoDigitString(Min);
 }

/**
 * Function to return the two digit format
 *
 * @since version 1A
 */

 simulated function string TwoDigitString(int Num){

    if ( Num < 10 )
        return "0"$Num;
    else
        return string(Num);
 }

/**
 * Obtain the Title Footer String
 *
 * @since version 1A
 */

 function String GetFooterTitleString(){
    local string titlestring;

	titlestring = "Playing" @ Level.Title @ "on" @ GRI.ServerName;
	if(SCTFGame != none && SCTFGame.TickRate > 0) titlestring = titlestring @ "(TR:" @ SCTFGame.TickRate $ ")";

	return titlestring;
 }

DefaultProperties
{

}
