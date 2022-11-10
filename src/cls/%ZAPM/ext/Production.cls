Include %ZAPM.ext.Common

/// Utilities for group work with Ensemble or Interoperability products of different Namespaces
/// do ##class(%ZAPM.ext.Production).SaveAndStop()
/// do ##class(%ZAPM.ext.Production).StartAll()
Class %ZAPM.ext.Production [ Abstract ]
{

/// How long to wait for the product to stop before being stopped again by force (seconds)
Parameter TIMEOUTSTOP = 60;

Parameter SettingsGN = "^%ZAPM.ext.Productions";

///  Check and save settings and status of products in all Namespaces
///  d ##class(%ZAPM.ext.Production).SaveStat(1)
ClassMethod SaveStat(resave = 0) As %Status
{
	s listns=..ListNS(.inf,"NotPref,Ens")
	s GN=..#SettingsGN
	i 'resave,$d(@GN) w !,"Settings have already been saved. Rewrite ? [Y/N] <N>" r r q:$zconvert(r,"L")'["y" $$$OK
	KILL @GN
	MERGE @GN=inf
	w !,"Updated "_GN,!!
	s ns=""
	f { s ns=$o(inf(ns)) q:ns=""
	 zw inf(ns,"Ens")
	}
 quit $$$OK
}

/// Get a list of domain namespaces separated by commas
/// w ##class(%ZAPM.ext.Production).ListNS(.info,"NotPre,Ens")
/// Flag = "Ens" - only where the ensemble is installed
/// Flag = "NotPre" - exclude prepared
ClassMethod ListNS(info, Flag = "")
{
	s disp=""
	$$$NspGoto(curNs,"%SYS")	
	set tRS = ##class(%ResultSet).%New("Config.Namespaces:List")
	if '$isobject(tRS) q ""
	set tSC = tRS.Execute()
	While tRS.Next() {	
		s name=tRS.GetData(1) KILL ens
		if Flag["NotPre" continue:..IsPreparedNS(name)
		if Flag["Ens",..getEnsProd(name,.ens) k info("Ens") m info(name,"Ens")=ens
		s disp=disp_","_name
		m info(name)=tRS.Data
	}
	d tRS.Close()
	$$$NspReturn(curNs)	
	Q $g(disp)
}

/// Get a list of products in namespace
/// w ##class(apptools.core.sys).getEnsProd("ENSDEMO",.info)
ClassMethod getEnsProd(name, info)
{
	s sc=$$$OK
	try {
		$$$NspGoto(curNs,name) KILL info
		DO ##CLASS(Ens.Director).GetProductionSummary(.info,name)
	}
	catch e { s sc=$$$ERROR($$$GeneralError,$ze)}
	$$$NspReturn(curNs)
	Q sc
}

/// Check whether the namespace is prepared
/// w ##class(%ZAPM.ext.Production).IsPreparedNS("%SYS")
ClassMethod IsPreparedNS(name)
{
	quit $lf($lb("%SYS","%ALL","DOCBOOK","ENSDEMO","ENSEMBLE","SAMPLES","USER"),$zconvert(name,"U"))
}

///  Save settings and status of products in all Namespaces; Stop all productions
///  d ##class(%ZAPM.ext.Production).SaveAndStop()
ClassMethod SaveAndStop() As %Status
{
	d ..SaveStat(1)
	d ..StopAll()
	quit $$$OK
}

/// Remove autostart from all products; stop all products in Namespaces before restarting the OS
/// d ##class(%ZAPM.ext.Production).StopAll()
ClassMethod StopAll() As %Status
{
 d ..EnsAction("auto0")
 d ..EnsAction("stop")
 w !!,"ok"
 quit $$$OK
}

/// Check and restore autorun products in Namespaces, run all products that were launched
/// d ##class(%ZAPM.ext.Production).StartAll()
ClassMethod StartAll() As %Status
{
 	d ..EnsAction("auto1")
 	d ..EnsAction("start")
 	w !!,"ok"
 	quit $$$OK
}

/// Initiate all Namespaces for the Ensemble\Interoperability
/// d ##class(%ZAPM.ext.Production).Init("USER")
ClassMethod Init(nsList = "") As %Status
{
 if nsList="" set nsList=..ListNS(.inf,"NotPref")
	for i=1:1:$l(nsList) {
		continue:$p(nsList,",",i)=""
		do ##class(%EnsembleMgr).EnableNamespace($p(nsList,",",i),1) 
	}
	q $$$OK
}

///  d ##class(%ZAPM.ext.Production).Start("user")
ClassMethod Start(ns) As %Status
{
	new $namespace
	try {
		set $namespace=ns
		Set sc = ##class(Ens.Director).StartProduction() ; Quit:$$$ISERR(tSC)
		if 'sc w $System.Status.DisplayError(sc)
	}
	catch e { w $ze 
	}
	quit $$$OK
}

///  d ##class(%ZAPM.ext.Production).Recover("user")
ClassMethod Recover(ns) As %Status
{
	new $namespace
	try {
		set $namespace=ns
		set sc=##class(Ens.Director).RecoverProduction()
		if 'sc w $System.Status.DisplayError(sc)
	}
	catch e { w $ze 
	}
	quit $$$OK
}

///  d ##class(%ZAPM.ext.Production).Stop("user")
ClassMethod Stop(ns) As %Status
{
	new $namespace
	try {
		set $namespace=ns
		s sc=##class(Ens.Director).StopProduction(..#TIMEOUTSTOP)
		i 'sc {
			s sc2=##class(Ens.Director).StopProduction(..#TIMEOUTSTOP,1) 
			i 'sc2 w $System.Status.DisplayError(sc2)
		}
	}
	catch e { w $ze 
	}
	quit $$$OK
}

/// Change products status in Namespaces
/// d ##class(%ZAPM.ext.Production).EnsAction("restart")
/// ex= "auto0" - clean all Namespaces of auto start products
/// ex= "auto1" - enable auto start products, restore from #SettingsGN(ns)
/// ex= "stop"  - stop all products
/// ex= "restart"  - reload all products
/// ex= "start"  - run the ones that were started, restore from #SettingsGN(ns)
/// ex= "status" - output statuses
/// ex= "recover" - output statuses
/// ex= "info" - output of additional information about products and services with parameters d ##class(%ZAPM.ext.Production).EnsAction("info",,.out)
/// out - result ;d ##class(%ZAPM.ext.Production).EnsAction("status",$Namespace,.out)
ClassMethod EnsAction(ex = "", nsOnly = "", out) As %Status [ PublicList = (tProductionName, inf) ]
{
	;get all namespace with ensemble
	s listns=..ListNS(.inf,"NotPref,Ens")
	#define NotSaveStat " settings not saved, to do ##class(%ZAPM.ext.Production).SaveStat(1) "
	$$$forAll(ns,inf)
	i nsOnly'="",nsOnly'=ns continue
	$$$NspGoto(curN,ns)
	i '$d(inf(ns,"Ens")) continue
	s GN=..#SettingsGN
	if ex'="info" w !!,"--- ",ns
	if ex="stop" {
		s sc=##class(Ens.Director).StopProduction(..#TIMEOUTSTOP)
		i 'sc {
			s sc2=##class(Ens.Director).StopProduction(..#TIMEOUTSTOP,1) 
			i 'sc2 w $System.Status.DisplayError(sc2)
		}
	}
	elseif ex="recover" { //This method recovers the last running production whose status is eProductionStateTroubled
		set sc=##class(Ens.Director).RecoverProduction()
		write !,"Recover "
		if 'sc w $System.Status.DisplayError(sc)
		else  write "OK"
		
	}
	elseif ex="restart" {
		s sc=##class(Ens.Director).RestartProduction()
		i 'sc w $System.Status.DisplayError(sc)
	}
	elseif ex="start" {
		i '$d(@GN@(ns,"Ens")) w !,$$$NotSaveStat
		$$$forAll(tProductionName,@GN@(ns,"Ens"))
			continue:$lg(@GN@(ns,"Ens",tProductionName),1)'[$$$EnsProductStatusRun
			w !,ns," ",tProductionName
			Set sc = ##class(Ens.Director).StartProduction(tProductionName) ; Quit:$$$ISERR(tSC)
			i 'sc w $System.Status.DisplayError(sc)
		$$$forEnd	
	}
	if ex="auto0" {
		i '$d(@GN@(ns,"Ens")) w !,$$$NotSaveStat
			$$$NspGoto(curNs,ns)
			Set sc = ##class(Ens.Director).SetAutoStart("")
			i 'sc w $System.Status.DisplayError(sc)
			e  w " clean auto start"
			$$$NspReturn(curNs)
	} elseif ex="auto1" {
		i '$d(@GN@(ns,"Ens")) w !,$$$NotSaveStat
		$$$forAll(tProductionName,@GN@(ns,"Ens"))
			continue:'$lg(@GN@(ns,"Ens",tProductionName),4)
			$$$NspGoto(curNs,ns)
			Set sc = ##class(Ens.Director).SetAutoStart(tProductionName)
			i 'sc w $System.Status.DisplayError(sc)
			e  w " set auto start"
			$$$NspReturn(curNs)
		$$$forEnd		
	} elseif ex="status"||(ex="info") {
		i '$d(@GN@(ns,"Ens")) w !,$$$NotSaveStat
		Set sc = ##class(Ens.Director).GetProductionSummary(.pInfo, ns)	if ex'="info" w ! zw pInfo
		Set sc = ##class(Ens.Director).GetProductionSettings("",.tSettings)	if ex'="info" w ! zw tSettings
		$$$forAll(tProductionName,@GN@(ns,"Ens"))
			;continue:'$lg(@GN@(ns,"Ens",tProductionName),4)
			$$$NspGoto(curNs,ns)
			if ex'="info" w !,"Name production :"_tProductionName
			Set sc = ##class(Ens.Director).GetProductionStatus(tProductionName,.Stat)
			s stat=$s(Stat=1:"Running",Stat=2:"Stopped",Stat=3:"Suspended",Stat=4:"Troubled",1:"?")
			if ex'="info" w " Status :"_stat
			i 'sc w $System.Status.DisplayError(sc)
			s out(ns,tProductionName)=stat
			;if ex="info" k ou d ..ExtInfo(tProductionName,.ou) m out(ns,tProductionName)=ou
			$$$NspReturn(curNs)
		$$$forEnd		
	}
	$$$forEnd
	if $g(curN)'="" $$$NspReturn(curN)
 	quit $$$OK
}

/// do ##class(%ZAPM.ext.Production).repair() 
ClassMethod repair() As %Status
{
	new $namespace
	set gn=$na(^%SYS("Ensemble","InstalledNamespace"))
	set ns=""
	for { set ns=$o(@gn@(ns)) quit:ns=""
		try {
			zn ns
		}
		catch ex {
			KILL @gn@($zconvert(ns,"U"))
			KILL @gn@($zconvert(ns,"L"))
			write !,"remove node "_$zr
		}
	}
}

/// do ##class(%ZAPM.ext.Production).delete() 
ClassMethod delete(ns = {$namespace}) As %Status
{
	new $namespace
	if $zconvert(ns,"U")'=$namespace set $namespace=ns
	;Set sc = ##class(Ens.Director).GetProductionSettings("",.tSettings)	w !,"Settings " zw tSettings
	do ##class(Ens.Director).StopProduction(1,1)
	;Set sc = ##class(Ens.Director).GetProductionSummary(.pInfo, ns)	;w !,"Summary " zw pInfo
	;set pn=""
	;for { set pn=$o(pInfo(pn)) quit:pn=""
	;		w !,pn_" deleted"
	;	do ##class(Ens.Director).DeleteProduction(pn)
	;}
	try {
		Set pn = ##class(Ens.Director).GetActiveProductionName()
		if pn'="",##class(Ens.Director).DeleteProduction(pn) write !,pn_" deleted"
	}
	catch ex {}
	KILL ^%SYS("Ensemble","InstalledNamespace",$zconvert(ns,"U"))
	KILL ^%SYS("Ensemble","InstalledNamespace",$zconvert(ns,"L"))
	quit $$$OK
}

/// do ##class(%ZAPM.ext.Production).exportXMLprod("d:\_proj\_zapp\zpm-addition+\zapm-addcmd\addcmd\zapm\_zapmprod.xml")
ClassMethod exportXMLprod(dir = "")
{
 	s list("%ZAPM.ext.Common.INC")=""
	s list("%ZAPM.ext.Production.CLS")=""
	d $SYSTEM.OBJ.Export(.list, dir)
}

}

