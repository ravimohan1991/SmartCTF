/*
 *   --------------------------------
 *  |  SmartCTFHudCCaptureTheFlag.uc
 *   --------------------------------
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
 * This Class renders the FlagCarrier location at the top of the Screen,
 *
 * @author The_Cowboy
 * @version 1A
 * @since 1A
 */

class SmartCTFHudCCaptureTheFlag extends HudCCaptureTheFlag;

/*
var vector MapCenter;
var float RadarTrans, RadarRange;
*/

/**
 * The function gets called at the begning of map.
 *
 * @since Experimental for FC on HUD feature
 */
/*
simulated function PostBeginPlay(){

  super.PostBeginPlay();
   // Set RadarMaxRange to size of primary terrain
    if (Level.CustomRadarRange > 0)
        RadarRange = Clamp(Level.CustomRadarRange, 500.0, 500000.000000);
}
*/

/**
 * The function gets called just at the Client while drawing the CTF HUD.
 *
 * @param Canvas The Canvas on which HUD is drawn
 * @since version 1A
 */

simulated function ShowTeamScorePassA(Canvas C)
{
	local CTFBase B;
	local int i;
	local PlayerReplicationInfo LPRI;
	local float XL, YL;

	if ( bShowPoints )
	{
		DrawSpriteWidget (C, TeamScoreBackground[0]);
		DrawSpriteWidget (C, TeamScoreBackground[1]);
		DrawSpriteWidget (C, TeamScoreBackgroundDisc[0]);
		DrawSpriteWidget (C, TeamScoreBackgroundDisc[1]);

        TeamScoreBackground[0].Tints[TeamIndex] = HudColorBlack;
        TeamScoreBackground[0].Tints[TeamIndex].A = 150;
        TeamScoreBackground[1].Tints[TeamIndex] = HudColorBlack;
        TeamScoreBackground[1].Tints[TeamIndex].A = 150;

        DrawSpriteWidget (C, NewFlagWidgets[0]);
        DrawSpriteWidget (C, NewFlagWidgets[1]);

        NewFlagWidgets[0].Tints[0] = HudColorTeam[0];
        NewFlagWidgets[0].Tints[1] = HudColorTeam[0];

        NewFlagWidgets[1].Tints[0] = HudColorTeam[1];
        NewFlagWidgets[1].Tints[1] = HudColorTeam[1];

        DrawSpriteWidget (C, VersusSymbol );
	 	DrawNumericWidget (C, ScoreTeam[0], DigitsBig);
		DrawNumericWidget (C, ScoreTeam[1], DigitsBig);

		if ( RedBase == None )
		{
			ForEach DynamicActors(Class'CTFBase', B)
			{
				if ( B.IsA('xRedFlagBase') )
					RedBase = B;
				else
					BlueBase = B;
			}
		}
		if ( RedBase != None )
		{
			C.DrawColor = HudColorRed;
			Draw2DLocationDot(C, RedBase.Location,0.5 - REDtmpPosX*HUDScale, REDtmpPosY*HUDScale, REDtmpScaleX*HUDScale, REDtmpScaleY*HUDScale);
		}
		if ( BlueBase != None )
		{
			C.DrawColor = HudColorBlue;
			Draw2DLocationDot(C, BlueBase.Location,0.5 + BLUEtmpPosX*HUDScale, BLUEtmpPosY*HUDScale, BLUEtmpScaleX*HUDScale, BLUEtmpScaleY*HUDScale);
		}

        if ( PlayerOwner.GameReplicationInfo == None )
			return;
		for (i = 0; i < 2; i++)
		{
			if ( PlayerOwner.GameReplicationInfo.FlagState[i] == EFlagState.FLAG_HeldEnemy )
			DrawSpriteWidget (C, FlagHeldWidgets[i]);
			else if ( PlayerOwner.GameReplicationInfo.FlagState[i] == EFlagState.FLAG_Down )
			DrawSpriteWidget (C, FlagDownWidgets[i]);
		}

		for(i = 0; i < PlayerOwner.GameReplicationInfo.PRIArray.Length; i++){
		   if(PlayerOwner.GameReplicationInfo.PRIArray[i].HasFlag != none && PlayerOwner.PlayerReplicationInfo.Team.TeamIndex ==
                 PlayerOwner.GameReplicationInfo.PRIArray[i].Team.TeamIndex && PlayerOwner.PlayerReplicationInfo != PlayerOwner.GameReplicationInfo.PRIArray[i]){
              LPRI = PlayerOwner.GameReplicationInfo.PRIArray[i];
              C.Font = LoadFontStatic(7);
              C.StrLen("FC:"$LPRI.GetLocationName(), XL, YL);
		      if(LPRI.Team.TeamIndex == 0){
		            C.DrawColor = WhiteColor;//C.static.MakeColor(Rand(255), Rand(50), Rand(50));
		            C.SetPos(C.ClipX / 2 + C.ClipX * 0.03, C.ClipY * 0.08);
                 }
		      else{
                 C.DrawColor = WhiteColor;//C.static.MakeColor(Rand(50), Rand(50), Rand(255));
                 C.SetPos(C.ClipX / 2 - C.ClipX * 0.03 - XL, C.ClipY * 0.08);
                 }
              C.DrawText("FC:"$LPRI.GetLocationName());
           }
        }

	}
 }

/**
 * @since Experimental for FC on HUD feature
 */

/*
 simulated function ShowTeamScorePassC(Canvas C){

    local float RadarWidth, CenterRadarPosX, CenterRadarPosY;


        Log("Trying to draw mapradar"@Level.RadarMapImage);
        RadarWidth = 0.5 * 0.2 * HUDScale * C.ClipX;
        CenterRadarPosX = (1.0 * C.ClipX) - RadarWidth;
        CenterRadarPosY = (0.1 * C.ClipY) + RadarWidth;
        DrawRadarMap(C, CenterRadarPosX, CenterRadarPosY, RadarWidth, false);

}

simulated function DrawRadarMap(Canvas C, float CenterPosX, float CenterPosY, float RadarWidth, bool bShowDisabledNodes)
{
	local float MapRadarWidth;
	local vector HUDLocation;
	local plane SavedModulation;

	SavedModulation = C.ColorModulate;

	C.ColorModulate.X = 1;
	C.ColorModulate.Y = 1;
	C.ColorModulate.Z = 1;
	C.ColorModulate.W = 1;

	// Make sure that the canvas style is alpha
	C.Style = ERenderStyle.STY_Alpha;

	MapRadarWidth = RadarWidth;
    if (PawnOwner != None)
    {
//    	MapCenter.X = FClamp(PawnOwner.Location.X, -RadarMaxRange + RadarRange, RadarMaxRange - RadarRange);
//    	MapCenter.Y = FClamp(PawnOwner.Location.Y, -RadarMaxRange + RadarRange, RadarMaxRange - RadarRange);
        MapCenter.X = 0.0;
        MapCenter.Y = 0.0;
    }
    else
        MapCenter = vect(0,0,0);

	HUDLocation.X = RadarWidth;
	HUDLocation.Y = RadarRange;
	HUDLocation.Z = 255;

	DrawMapImage( C, Level.RadarMapImage, CenterPosX, CenterPosY, MapCenter.X, MapCenter.Y, HUDLocation );


}


simulated static function DrawMapImage( Canvas C, Material Image, float MapX, float MapY, float PlayerX, float PlayerY, vector Dimensions )
{
	local float MapScale, MapSize;
	local byte  SavedAlpha;

	if ( Image == None || C == None )
		return;

	MapSize = Image.MaterialUSize();
	MapScale = MapSize / (Dimensions.Y * 2);

	SavedAlpha = C.DrawColor.A;

	C.DrawColor = default.WhiteColor;
	C.DrawColor.A = Dimensions.Z;

	C.SetPos( MapX - Dimensions.X, MapY - Dimensions.X );
	C.DrawTile( Image, Dimensions.X * 2.0, Dimensions.X * 2.0,
	           (PlayerX - Dimensions.Y) * MapScale + MapSize / 2.0,
			   (PlayerY - Dimensions.Y) * MapScale + MapSize / 2.0,
			   Dimensions.Y * 2 * MapScale, Dimensions.Y * 2 * MapScale );

	C.DrawColor.A = SavedAlpha;
}
*/

DefaultProperties
{

}
