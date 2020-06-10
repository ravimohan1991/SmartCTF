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
 * This is a custom Class to manage/intercept the Broadcasted messages
 * for appropriate interpretation (SmartCTF.EvaluateMessageEvent). This
 * object is added to the linked list of of BroadcastHandler (Level.Game.BroadcastHandler)
 * by the function SmartCTF.RegisterBroadcastHandler().
 *
 * @author The_Cowboy
 * @version 1A
 * @since 1A
 */

class SmartCTFBroadcastHandler extends BroadcastHandler;

/*
 * Global Variables
 */

 /** The SmartCTF reference.*/
 var SmartCTF SCTFMut;

 /**
 * Method to intercept the broadcasted messages.
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
 */

 function BroadcastLocalized(Actor Sender, PlayerController Receiver, class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
 {
    SCTFMut.EvaluateMessageEvent(Sender, Receiver, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
    super.BroadcastLocalized(Sender, Receiver, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
 }


defaultproperties
{

}
