<?php
header("Content-Type: text/html; charset=utf-8");

/******************************************************************************
 *	IpToCountry v1.6 Masterserver script.
 *	-------------------------------------
 *	[1.2] Non-database version by AnthraX
 *	[1.2] Updated for Daylight Saving Time fix by Rush
 *	[1.3] Updated to new GeoIP Database and retrieval method by AnthraX
 *	[1.4] Bugfix release (short php open tag, php4 support) by sphx
 *	[1.5] Code polish by sphx
 *  [1.6] Fix for DST by MSuLL; in 2007 most DST-observing countries expanded DST's timespan
 ******************************************************************************
 *	Script syntax:
 *	* Single IP resolving:
 *		+ iptocountry15.php?ip=aaa.bbb.ccc.ddd
 *
 *		-> Return: hh:mm aaa.bbb.ccc.ddd:hostname:COUNTRYNAME_LONG:COUNTRYNAME_SHORT:flagname
 *
 *		+ iptocountry15.php?ip=aaa.bbb.ccc.ddd&playerid=xxx
 *
 *		-> Return: hh:mm xxx:aaa.bbb.ccc.ddd:hostname:COUNTRYNAME_LONG:COUNTRYNAME_SHORT:flagname
 *	* Multi IP resolving:
 *		+ iptocountry15.php?ip=aaa.bbb.ccc.ddd,eee.fff.ggg.hhh,iii.jjj.kkk.lll
 *
 *		-> Return: hh:mm aaa.bbb.ccc.ddd:hostname:COUNTRYNAME_LONG:COUNTRYNAME_SHORT:flagname,eee.fff.ggg.hhh:hostname:COUNTRYNAME_LONG:COUNTRYNAME_SHORT:flagname,iii.jjj.kkk.lll:hostname:COUNTRYNAME_LONG:COUNTRYNAME_SHORT:flagname
 ******************************************************************************/

error_reporting(E_WARNING);

/******************************************************************************
 * (Rush) Support for Daylight Saving Time
 ******************************************************************************/

$timestamp = mktime(gmdate("H, i, s, m, d, Y")); // UTC time

// Updated DST functions, added by MSuLL, May 16, 2010
// Rush's old code was rather complex. Using strtotime() is much
// easier to understand and modify, with negligible time trade-off
$dst_start = strtotime("Second Sunday March 0");
$dst_end = strtotime("First Sunday November 0");

$time = time();
if( $time >= $dst_start && $time < $dst_end )  
{  
	$timestamp = $timestamp + 3600; // foward one hour
}
// End DST Update

$gmt = date("H:i", $timestamp);

/******************************************************************************
 * Request Handling
 ******************************************************************************/

/* This file contains the $countries array ... */
include("ip_files/countries.php");

/* This file contains the parsing functions for the binary database */
include("geoip.inc");

/* Opens the database file */
$geoDB = geoip_open("GeoIP.dat", GEOIP_STANDARD);

/* Get an array of IPs out of query string to process */
if(isset($_GET['ip']))
{
	$ipArray = explode(',', $_GET['ip']);
}
else
{
	die();
}

/* (AnthraX) Resolve the ips one by one. This approach is a bit more elegant than the one in v1.2
   (MSuLL) Changed loop from 'for' to 'foreach'
*/
$bFirstRun = true;
foreach ($ipArray as $ip)
{
	$iploc   = geoip_country_code_by_addr($geoDB, $ip);
	$Prefix1 = strtolower($iploc);
	$Prefix2 = $countries[$iploc][0];
	$Country = $countries[$iploc][1];

	/* Handling for unknown country returns -> created by adminthis */
	if(empty($Country))
	{
		$Country = "Unknown"; // GeoIP returns "UNKNOWN" for an unknown country, but if the country isn't listed in the $countries array, this will be empty... and therefore also unknown

		if(!empty($Prefix1))
		{
			// If we did get the country code, append it to our custom Unknown string. E.g.: Unknown (ME)
			$Country .= " (". strtoupper($Prefix1) .")";
		}
	}

	if(strstr($Country, ','))
	{
		$Country = str_replace(', ', "-", $Country);
	}
	
	/* Handling for single IP requests -> fixed by sphx */
	$ip_info = $ip.':'.gethostbyaddr($ip).':'.$Country.':'.$Prefix2.':'.$Prefix1;

	if($bFirstRun)
	{
		echo $gmt.' ';
		if(isset($_GET['playerid']))
		{
			echo $_GET['playerid'] . ':';
		}

		$bFirstRun = false;
	}
	else
	{
		echo ',';
	}

	echo $ip_info;
}
geoip_close($geoDB);
?>