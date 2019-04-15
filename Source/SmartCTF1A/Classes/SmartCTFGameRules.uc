/*
 *   -----------------------
 *  |  SmartCTFGameRules.uc
 *   -----------------------
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
 * This class is for tracking the Killing events in the Game.
 *
 * @see SmartCTF.PostBeginPlay()
 *
 * @author The_Cowboy
 * @version 1A
 * @since 1A
 */

class SmartCTFGameRules extends Gamerules;

/*
 * Global Variables
 */

 /** The SmartCTF reference.*/
 var SmartCTF SCTFMut;

/**
 * Method to notify SmartCTF about the killings.
 *
 * @param Killed The Pawn class getting screwed.
 * @param Killer The Controller class screwing around.
 * @param damageType The nature of damage.
 * @param HitLocation The place of crime.
 *
 * @see #Engine.GameInfo.PreventDeath(Killed, Killer, damageType, HitLocation)
 * @since version 1A
 */

 function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation){

     if ( (NextGameRules != None) && NextGameRules.PreventDeath(Killed,Killer, damageType,HitLocation) )
	    return true; // No Killing! So return.
     SCTFMut.EvaluateKillingEvent(Killed, Killer, damageType, HitLocation);
     return false;
 }

/**
 * Method to notify SmartCTF about the Pickups by the Pawn.
 *
 * @param Other The Pawn class picking the items.
 * @param item Item being picked up.
 * @param bAllowPickup Switch to decide the Pickup.
 *
 * @since version 1A
 */

 function bool OverridePickupQuery(Pawn Other, Pickup item, out byte bAllowPickup){

    if ( (NextGameRules != None) &&  NextGameRules.OverridePickupQuery(Other, item, bAllowPickup) )
		return true;

    // If pickup is allowed
	SCTFMut.RegisterPickupItems(Other, item, bAllowPickup);
    return false;
 }

defaultproperties
{

}
