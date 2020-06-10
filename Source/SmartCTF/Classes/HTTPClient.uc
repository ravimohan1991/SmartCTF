/*
    IpToCountry 1.6 Copyright (C) 2006-2010

    Initial to v1.2 by [es]Rush
    v1.6 by Matthew 'MSuLL' Sullivan

    This program is free software; you can redistribute and/or modify
    it under the terms of the Open Unreal Mod License version 1.1.
*/

/**
 * This Class does all the "Grunt Work" including querying, switching the <br/>
 * queryservers and receiving the IPData.
 *
 * @author Too Many!
 * @version 1A
 * @since 1A
 */

class HTTPClient extends BrowserHTTPClient;

/*
 * Global Variables
 */

 /** The IpToNation Actor reference.*/
 var LinkActor S;

 /** Query in progress logical switch.*/
 var bool bQueryInProgress;

 /** Queue Array of IP addresses of the Players. */
 var string QueryQueue[64];

 /** Queue string of the IP addresses.*/
 var string QueryString;

 /***/
 var bool bContinueAtClose;

 /** */
 var bool bSwitchAtClose;

 /***/
 var bool bResolutionRequest;

 /***/
 var bool bReceivedData;

 /***/
 var string GMT;

 /***/
 var int Errors;

function CheckAddresses()
{
	if(!bResolutionRequest && S.resolvedAddress[S.currentServer] == "")
	{
		bResolutionRequest = True;
		bQueryInProgress = True;

		Resolve(S.QueryServerHost[S.currentServer]);
	}
}

event Resolved( IpAddr Addr )
{
	if(bResolutionRequest)
	{
		S.resolvedAddress[S.currentServer] = IpAddrToString(Addr);

		// strip out port number
		if (InStr(S.resolvedAddress[S.currentServer],":") != -1)
			S.resolvedAddress[S.currentServer] = Left(S.resolvedAddress[S.currentServer],InStr(S.resolvedAddress[S.currentServer],":"));

		S.SaveConfig();

		bResolutionRequest = False;
		bQueryInProgress = False;

		SendQueue();
	}
	else
	{
		Super.Resolved(Addr);
	}
}

event ResolveFailed()
{
	if(bResolutionRequest)
	{
		Log("[IpToNation] Error while resolving"@S.QueryServerHost[S.currentServer]@"to an IP.");
		Log("[IpToNation] If the error continues this could indicate that the operating system is not configured to resolve DNS records.");
		Log("[IpToNation] A work-around can be performed by manually setting the value of 'resolvedAddress' to the IP To Country database host's IP in the configuration, and setting 'bNeverPurgeAddress' to True");

		S.restartHTTPClient(true); // true = also try different query server
	}
	else
	{
   		SetTimer(0.0, false);
   		SetError(-4);
	}
}

function string SendData(string IP)
{
	local LinkActor control;
	local int i;

	if(S == None)
	{
		foreach AllActors(class'LinkActor', control)
		{
			S = control;
			break;
		}
	}

	/* a way of TimeReplication to communicate with this actor */
	if(Left(IP, 7) == "AOLSUX ")
		AOLHandler(Mid(IP, 7));

	IP = FixIpAddr(IP);

	if(IP == "")
	{
		return "!Bad Input";
	}

	i = IpInDatabase(IP);

	if(i != -1)
	{
		if(InStr(S.IPData[i], "AMERICA ONLINE") == -1)
			return S.IPData[i];
		else
			return "!AOL - Trying to clarify";
	}
	else if(IpInQueue(IP))
		return "!Waiting in queue";
	else if(InStr(QueryString, IP) != -1)
		return "!Resolving now";
	else
	{
		if(QueryQueue[(ArrayCount(QueryQueue) - 1)] != "")
			return "!Queue full";
		else
		{
			AddToQueue(IP);
			SendQueue();
			return "!Added to queue";
		}
	}
}

function HTTPReceivedData(string data)
{
	local string result, temp;
	local int elems, i;
	local string IP;

	result = ParseString(data);
	elems = S.ElementsNum(result, ",");

	Super.SetTimer(0.0, false); // disable the timeout count
	bReceivedData = true;

	GMT=left(result, 5); // get the GMT time of a query server
	result=Mid(result, 6); // leave the rest of the string in the good old format

	if(InStr(result, "Warning") != -1) // php warning ?
	{
		SwitchQueryServer("IpToNation: "$S.QueryServerHost[S.currentServer]$" returned bad data! Switching to alternate.");
		SendQueue();
		return;
	}
	if(elems==1)
	{
		IP=S.SelElem(result, 1);
		if(S.ElementsNum(result)!=5  || FixIpAddr(IP) == "") // some weird data ?
		{
			SwitchQueryServer("IpToCountry: "$S.QueryServerHost[S.currentServer]$" returned bad data! Switching to alternate.");
			SendQueue();
			return;
		}
		if(Right(S.SelElem(result, 2), 8) == ".aol.com" && S.bCheckAOL)
		{
			SaveIPData(SetAOL(result)); /* save IP to keep the record, this data won't be returned anywhere anyway */
			InitAOLCheck(IP);
		}
		else
   		SaveIPData(result);
  	}
 	else
 	{
 	 	for(i=1;i<=elems;i++)
 	 	{
 	 		temp=S.SelElem(result, i, ",");
 	 		IP=S.SelElem(temp, 1);
			if(i==1)
			{
				if(S.ElementsNum(temp)!=5 || FixIpAddr(IP) == "") // some weird data ?
				{
					SwitchQueryServer("IpToCountry: "$S.QueryServerHost[S.currentServer]$" returned bad data! Switching to alternate.");
					SendQueue();
					return;
				}
			}
			if(Right(S.SelElem(temp, 2), 8) == ".aol.com" && S.bCheckAOL)
			{
				SaveIPData(SetAOL(temp));
				InitAOLCheck(IP);
			}
			else
				SaveIPData(temp);
 	 	}
 	}

 	QueryString="";
	bQueryInProgress=False;

	SendQueue();
}

function string SetAOL(string Input)
{
	return S.SelElem(Input, 1)$":"$S.SelElem(Input, 2)$":AMERICA ONLINE:AOL:us";
}

function bool InitAOLCheck(string IP)
{
	local Controller P;
	local TimeReplication TR;

	for(P = Level.ControllerList; P != None; P = P.nextController )
		if(P.IsA('PlayerController'))
			if(NetConnection(PlayerController(P).Player) != None)
			{
				if(S.SepLeft(PlayerController(P).GetPlayerNetworkAddress()) == IP)
				{
					TR = Spawn(class'TimeReplication', P);
					TR.IpToNation = self.S;
					return true;
				}
			}
	return false;
}

event Opened()
{
	Enable('Tick');

	if(ProxyServerAddress != "")
	{
		SendBufferedData("GET http://"$ServerAddress$":"$string(ServerPort)$ServerURI$" HTTP/1.1"$CR$LF);
	}
	else
	{
		SendBufferedData("GET "$ServerURI$" HTTP/1.1"$CR$LF);
	}

	SendBufferedData("Connection: close"$CR$LF);
	SendBufferedData("Host: "$S.QueryServerHost[S.currentServer]$":"$S.QueryServerPort[S.currentServer]$CR$LF);
	SendBufferedData("User-Agent: Mozilla/5.0 (Unreal Tournament)"$CR$LF$CR$LF);

	CurrentState = WaitingForHeader;
}

function AOLHandler(string Data)
{
	local int ClientTime;
	local string IP;

	IP=S.SelElem(Data, 1);
	ClientTime = int(S.SelElem(Data, 2))*60 + int(S.SelElem(Data, 3));

	UpdateAOLData(IP$":"$GetAOLArrayCountry(ClientTime));
}

function string GetAOLArrayCountry(int ClientTime)
{
	local int GMTTime;
	local int TimeDiff;
	local string ArrayCountry;

	GMTTime = int(S.SelElem(GMT, 1))*60 + int(S.SelElem(GMT, 1));
	TimeDiff = abs(GMTTime - ClientTime) % 1440;

	if (TimeDiff > 720)
		TimeDiff = abs(TimeDiff - 1440);

	if (TimeDiff < 30)
		ArrayCountry = "UNITED KINGDOM:GBR:gb";
	else if (TimeDiff < 120)
		ArrayCountry = "GERMANY:DEU:de";
	else
		ArrayCountry = "UNITED STATES:USA:us";

	return ArrayCountry;
}

function SwitchQueryServer(optional string LogStr)
{
	if(LogStr != "")
		log(LogStr);

	bQueryInProgress = False;

	if(++Errors > S.ErrorLimit)
	{
		if(!bReceivedData && !S.bNeverPurgeAddress)
		{
			Log("[IpToNation] No data was received during the last session; will attempt to re-resolve"@S.QueryServerHost[S.currentServer]@"upon HTTP client reload.");
			S.resolvedAddress[S.currentServer] = "";
			S.SaveConfig();
		}
		S.restartHTTPClient();
	}
	else
	{
		if((S.currentServer + 1) == S.NumberOfServers)
		{
			S.currentServer = 0;
		}
		else
		{
			S.currentServer++;
		}

		ServerIpAddr.Addr=0; // ensures that the Browse() function will open a connection to a new address
	}
}

// override original function to silence the warning log
function DoBind()
{
	if( BindPort() == 0 )
	{
		SetError(-2);
		return;
	}

	Open( ServerIpAddr );
	bClosed = False;
}

function SetError(int code)
{
	Super.SetError(code);

	switch(code)
	{
		case -1:
			Log("[IpToNation] Error in binding the port while connecting to "$S.QueryServerHost[S.currentServer]);
			break;
		case -2:
         		Log("[IpToNation] Error while resolving the host "$S.QueryServerHost[S.currentServer]);
         		break;
		case -3:
			Log("[IpToNation] "$S.QueryServerHost[S.currentServer]$" timed out after "$string(S.MaxTimeout)$" seconds");
			break;
		case -4:
			Log("[IpToNation] Error resolving to the host of the IP for the domain "$S.QueryServerHost[S.currentServer]);
			break;
		default:
			Log("[IpToNation] Server received HTTP error with code "$string(code)$" from "$S.QueryServerHost[S.currentServer]);
	}

	// sometimes the connection doesn't break immediately, it is probably due to some bug in BrowserHTTPClient, if it happens we have to wait for it inside event Closed() cause we cannot open the same socket if it is already opened
	if(IsConnected())
	{
		bSwitchAtClose=True;
	}
	else
	{
		SwitchQueryServer("[IpToNation] "$S.QueryServerHost[S.currentServer]$" failed! Trying the alternate server...");
		SendQueue();
	}
}

event Closed()
{
	Super.Closed();
	bQueryInProgress=False;

	if(bSwitchAtClose)
	{
		//NoSendQueue = True;
		//HTTPReceivedData(InputBuffer);

		bSwitchAtClose=False;
		SwitchQueryServer();
		SendQueue();
	}
	else if(bContinueAtClose)
	{
		//NoSendQueue = True;
		//HTTPReceivedData(InputBuffer);

		bContinueAtClose=False;
		bQueryInProgress=False;
		SendQueue();
	}
}

function SendQueue()
{
	local int i;
	local string IP;

	CheckAddresses();

	if(IsConnected())
	{
		bContinueAtClose=True;
	}

	if(bQueryInProgress || (QueryQueue[0] == "" && QueryString == ""))
	{
		return;
	}

	for(i=0;i<ArrayCount(QueryQueue);i++)
	{
		if(QueryQueue[i] == "")
			continue;
		IP=QueryQueue[i];
		if(QueryString=="")
			QueryString=QueryQueue[i];
		else
			QueryString=QueryString$","$QueryQueue[i];
		QueryQueue[i]="";
	}

	if(QueryString == "")
	{
		return;
	}

	bQueryInProgress=True;

	Browse(S.resolvedAddress[S.currentServer],S.QueryServerFilePath[S.currentServer]$"?ip="$QueryString, S.QueryServerPort[S.currentServer], S.MaxTimeout);
}

function AddToQueue(string data)
{
	local int i;

	if(IpInDatabase(data) != -1 || InStr(QueryString, data) != -1)
	{
		return;
	}

	for(i=0;i<ArrayCount(QueryQueue);i++)
	{
		if(QueryQueue[i]!="")
			continue;
		QueryQueue[i] = data;
		if(!bQueryInProgress)
			SendQueue();
		break;
	}
}

function UpdateAOLData(string SetString)
{
	local int i;
	local string IP, Rest;

	IP = S.SelElem(SetString, 1);
	Rest = Mid(SetString, InStr(SetString, ":")+1); /* rest of the elements */

	for(i=0;i<ArrayCount(S.IPData);i++)
	{
		if(S.SepLeft(S.IPData[i]) == IP)
		{
			S.IPData[i] = IP$":"$S.SelElem(S.IPData[i], 2)$":"$Rest;
			S.SaveConfig();
			return;
		}
	}
	SaveIPData(SetString); /* just in case there's nothing to alter, add new data */
}

function bool SaveIPData(string SetString)
{
	local int i;

	for(i=0;i<ArrayCount(S.IPData);i++)
	{
		if(S.IPData[i] != "")
			continue;
		S.IPData[i]=SetString;
		S.SaveConfig();
		return true;
	}

	S.IPData[S.IPDataIndex] = SetString;
	S.IPDataIndex = (S.IPDataIndex+1) % ArrayCount(S.IPData);
	S.SaveConfig();
}

function int IpInDatabase(string IP)
{
	local int i;

	for(i=0;i<ArrayCount(S.IPData);i++)
	{
		if(S.SepLeft(S.IPData[i]) == IP)
			return i;
	}
	return -1;
}

function bool IpInQueue(string data)
{
	local int i;

	for(i=0;i<ArrayCount(QueryQueue);i++)
	{
		if(QueryQueue[i] == data)
			return true;
	}
	return false;
}

function string FixIpAddr(string IP)
{
	local IpAddr Addr;
	local int i;
	local String StrAddr;

	if(!StringToIpAddr(IP, Addr))
		return "";
	StrAddr=IpAddrToString(Addr);
	i = InStr(StrAddr, ":");
	if(i != -1)
		StrAddr = Left(StrAddr, i);
	else
		return "";
	return StrAddr;
}

function string ParseString (String Input)
{
	local int LCRLF;
	local string result;

	LCRLF = InStr(Input ,CR$LF);

	// No CR or LF in string
	if (LCRLF == -1)
		return Input;
	else
	{
		result = Right(Input, len(Input)-LCRLF-2);
		LCRLF = InStr(result ,CR$LF);
		result = Left(result, LCRLF);
		return result;
	}
}

defaultproperties
{
    Tag='HTTPClient'
    bHidden=true
}
