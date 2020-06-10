/*
    IpToCountry 1.6 Copyright (C) 2006-2010 (and then it is Copyleft) <br />
                                                                      <br />
    Initial to v1.2 by [es]Rush                                       <br />
    v1.6 by Matthew 'MSuLL' Sullivan                                  <br />
                                                                      <br />

    This program is free software; you can redistribute and/or modify
    it under the terms of the Open Unreal Mod License version 1.1.
*/

/**
 * IpToNation v1.0                                                         <br />
 * Ported to UT2004 (Anno Domini) by The_Cowboy with name IpToNation       <br />
 * The main actor of IpToNation                                            <br />
 *
 */

class LinkActor extends Mutator config(IpToNation);

/*
 * Global variables
 */

 /** Hosts with the capability of resovling Nations.*/
 var config string QueryServerHost[4];

 /** File path on Hosts.*/
 var config string QueryServerFilePath[4];

 /** Port for query.*/
 var config int QueryServerPort[4];

 /** Limit for the timeout.*/
 var config int MaxTimeout;

 /** Limt for errors.*/
 var config int ErrorLimit;

 /** The IP database stored in ini.*/
 var config string IPData[256];

 /* if IPData[] if full, the next data will be saved to IPData[IPDataIndex] */
 var config int IPDataIndex;

 /** Array of Query server resolved addresses.*/
 var config string ResolvedAddress[4];

 /** .*/
 var config bool bNeverPurgeAddress;

 /** Number of configured servers.*/
 var int NumberOfServers;

 /** Current server counter.*/
 var int CurrentServer;

 /** Switch to check AOL. */
 var bool bCheckAOL;

 /** If HTTP actor is active. */
 var bool HttpClientInstanceStarted;

 /** The HTTP client instance. */
 var HTTPClient HttpClientInstance;

 /** Number of restarts.*/
 var int numHTTPRestarts;


/**
 * The function is called before Replication comes into effect.
 * Here we tag the Actor class with our Name.
 *
 * @since version 1.0
 */

event PreBeginPlay(){

    Tag='IpToNation';
	Super.PreBeginPlay();
}

/**
 * Here we load the environment for IpToNation to work.
 * Nothing is changed from the "old logging system".
 *
 * @since version 1.0
 */

function PostBeginPlay()
{
	local int i;
	local string aolText;

	Super.PostBeginPlay();
	SaveConfig();

	for(i = 0; i < ArrayCount(QueryServerHost); i++){
		if(QueryServerHost[i] == "" || QueryServerFilePath[i] == ""){
			break;
		}
		else{
			NumberOfServers++;
		}
	}

	Log("|####################################", 'SmartCTF');
	Log("|#          IP To Nation            #", 'SmartCTF');
	Log("|#           for UT2004             #", 'SmartCTF');
    Log("|#           Version 1.0            #", 'SmartCTF');
	Log("|#  UT99 version by [es]Rush and    #", 'SmartCTF');
    Log("|#    Matthew 'MSuLL' Sullivan      #", 'SmartCTF');
	Log("|####################################", 'SmartCTF');

	if(NumberOfServers < 1)
	{
		Log("|# You do not seem to have any      #", 'SmartCTF');
		Log("|# query servers configured, this   #", 'SmartCTF');
		Log("|# must be fixed in IpToNation.ini  #", 'SmartCTF');
		Log("|####################################", 'SmartCTF');
		Log("|#    IP TO NATION IS UNLOADING     #", 'SmartCTF');
		Log("|####################################", 'SmartCTF');

		Destroy();
		return;
	}


    bCheckAOL = True;
    aolText = "True ";// Whatever!

	Log("|# Extension for AOL: "$aolText$"         #", 'SmartCTF');
	Log("|# Query Servers: "$NumberOfServers$"                 #", 'SmartCTF');
	Log("|####################################", 'SmartCTF');
    Log("|", 'SmartCTF');

	InitHTTPFunctions();
}

/**
 * Function to restart the HTTPClient instance upon faliure
 *
 * @param bool Wether to switch the QueryServers
 * @since version 1.0
 */

function restartHTTPClient(optional bool bSwitchServers){

    httpClientInstance.Destroy();
	httpClientInstanceStarted = False;

	if(numHTTPRestarts < 4)
	{
		Log("[IpToNation] Too many HTTP errors in one session, HTTP client restarting.");

		if(bSwitchServers)
		{
			if((currentServer + 1) == NumberOfServers)
			{
				currentServer = 0;
			}
			else
			{
				currentServer++;
			}
		}

		initHTTPFunctions();
		numHTTPRestarts++;
	}
	else
	{
		Log("[IpToNation] Too many HTTP client restarts in one session, HTTP functions disabled.");
	}
}


/**
 * Initialize HTTP client actor
 *
 * @since version 1.0
 */

function InitHTTPFunctions(){

    if(!HttpClientInstanceStarted){
		HttpClientInstance = Spawn(class'HTTPClient');
		HttpClientInstance.S = self;
		HttpClientInstanceStarted = true;
	}

}

/**
 * This method returns highly useful information
 * from just the IP.
 * This method can be used by generic mutator in
 * order to get the legit IP info.
 *
 * @param IP The Internet Protocol to be resolved.
 * @since version 1.0
 */

function string GetIPInfo(string IP){

    if(HttpClientInstanceStarted)
        return HttpClientInstance.SendData(IP);
	else
		return "!Disabled";
}

/**
 * Method to obtain the actual IP from IP data
 *
 * @param String IP to be striped from data
 * @param String Char as delimiter.
 * @see HTTPClient.IpInDatabase
 * @since version 1.0
 */

static final function string SepLeft(string Inputs, optional string Char){

    local int pos;

    if(Char == "")
		Char = ":";

	pos = InStr(Inputs, Char);
	if(pos != -1)
		return Left(Inputs, pos);
	else
		return Inputs;
}


/**
 * Method to get desired sub-data from the IP Data
 *
 * @param string input string
 * @param int element to get
 * @param string delimiter
 * @since version 1.0
 * @see HTTPClient.AOLHandler
 */

static final function string SelElem(string Str, int Elem, optional string Char){

    local int pos;

    if(Char == "")
		Char = ":";

	while(Elem > 1){
		Str = Mid(Str, InStr(Str, Char)+1);
		Elem--;
	}
	pos = InStr(Str, Char);
	if(pos != -1)
    	Str = Left(Str, pos);
    return Str;
}

static final function int ElementsNum(string Str, optional string Char){

	local int count, pos;

	if(Char=="")
		Char=":";

	while(true)
	{
		pos = InStr(Str, Char);
		if(pos == -1)
			break;
		Str=Mid(Str, pos+1);
		count++;
	}
	return count+1;
}

defaultproperties
{
    Tag='IpToNation'
    QueryServerHost(0)="iptocountry.ut-files.com"
    QueryServerHost(1)="www.ut-slv.com"
    QueryServerHost(2)="utgl.unrealadmin.org"
    QueryServerFilePath(0)="/iptocountry16.php"
    QueryServerFilePath(1)="/iptocountry/iptocountry16.php"
    QueryServerFilePath(2)="/iptocountry16.php"
    QueryServerPort(0)=80
    QueryServerPort(1)=80
    QueryServerPort(2)=80
    QueryServerPort(3)=80
    MaxTimeout=10
    ErrorLimit=5
}

