/*
 *   ---------------------------------
 *  |  SmartCTFGameReplicationInfo.uc
 *   ---------------------------------
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
 * This is a custom GameReplication Class to communicate the SmartCTF game
 * information to the clients.
 *
 * @author The_Cowboy
 * @version 1A
 * @since 1A
 */

class SmartCTFGameReplicationInfo extends ReplicationInfo;

/*
 * Global Variables
 */

 /** The Array of SmartCTFPlayerReplicationInfo.*/
 var()    array<SmartCTFPlayerReplicationInfo>                PRIBuffer;

 /** The server TickRate.*/
 var()    int                                                 TickRate;

 /** Show countryflags? */
 var()    bool                                                bShowCountryFlags;

replication
{
  // Settings
  reliable if(Role == ROLE_Authority)
    TickRate, bShowCountryFlags;//, GetStats, ReloadBuffer;
}

/**
 * Method to return the SmartCTFPlayerReplicationInfo object
 * of the Controller.
 *
 * @param A The Controller object.
 * @return PRIBuffer[i] The SmartPRI oject associated to the Controller
 *         None         If no SmartPRI is associated.
 *
 * @see #SmartCTFGameRules.PreventDeath(Killed, Killer, damageType, HitLocation)
 * @since version 1A
 */

 simulated function SmartCTFPlayerReplicationInfo GetStats(PlayerReplicationInfo A){

  local int i;

  if(A == none) return none;
  ReloadBuffer();// Collect the swarm of SmartCTFPlayerReplication instances.
  for(i = 0; i < PRIBuffer.Length; i++){
     if(A.PlayerID == PRIBuffer[i].SPlayerID){
        return PRIBuffer[i];
     }
  }
  return none;
 }

/**
 * Method to refresh the PRIBuffer
 *
 * @since version 1A
 */

 simulated function ReloadBuffer(){

    local SmartCTFPlayerReplicationInfo SPRI;

    PRIBuffer.Remove(0, PRIBuffer.Length);

    foreach DynamicActors(class'SmartCTFPlayerReplicationInfo', SPRI)
       PRIBuffer[PRIBuffer.Length] = SPRI;

 }

defaultproperties
{
     RemoteRole=ROLE_SimulatedProxy
     bNetNotify=True
}
