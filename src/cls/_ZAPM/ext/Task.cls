Include %ZAPM.ext.Common

/// Utilities for group work with taskes different Namespaces
/// do ##class(%ZAPM.ext.Task).tasklist()
/// do ##class(%ZAPM.ext.Task).taskStopAll(2)
Class %ZAPM.ext.Task [ Abstract ]
{

/// How long to wait for the product to stop before being stopped again by force (seconds)
Parameter TIMEOUTSTOP = 60;

Parameter SettingsGN = "^%ZAPM.ext.Task";

/// Creating tasks message cleaning
/// d ##class(%ZAPM.ext.Task).CreateTasksPurgeMess(30)
ClassMethod CreateTasksPurgeMess(days = 90) As %Status
{
	s listns=##class(%ZAPM.ext.Production).ListNS(.inf,"NotPref,Ens")	
	set ns=""
	for { set ns=$o(inf(ns)) q:ns=""
		continue:'$d(inf(ns,"Ens"))
	 	write !,ns," ",..CreateTaskPurge("Cleaning productions messages "_ns,ns,days)
	}
 quit $$$OK
}

/// Create a task to clean productions messages
///  w ##class(%ZAPM.ext.Task).CreateTaskPurge("Cleaning production messages "_$Namespace,$Namespace,7) }
ClassMethod CreateTaskPurge(Name As %String = "", ns = {$Namespace}, days = 90)
{
		Set Task=##Class(%SYSTEM.Task).%New()
		Set Task.Name=Name 
		Set Task.Type=0
		Set Task.Description=Name
		Set Task.TaskClass="Ens.Util.Tasks.Purge"
		#;Every day at 1:00 am
		Set Task.DailyStartTime=3600
		;Do Task.idSet(Number)
		Set Task.RunAsUser="SuperUser"
		Set Task.MirrorStatus=3
		s t=##class(Ens.Util.Tasks.Purge).%New()
		s t.KeepIntegrity=1
		s t.NumberOfDaysToKeep=days
		s t.BodiesToo=1
		s t.TypesToPurge="all"
		Set Task.Settings=t.GetSettings()
		s Task.NameSpace=ns
		q Task.%Save()
}

ClassMethod task(extcmd) As %Status
{
	new $namespace
	if (extcmd)["list" quit ..tasklist()
	if (extcmd)["export" //todo
	if (extcmd)["import" //todo
	if (extcmd)["info" //todo
	if (extcmd)="start " do ..taskSuspend(0)
	if $p(extcmd,"start ",2)'="" do ..taskset($p($p(extcmd,"start ",2)," ",1),0),..tasklist()
	if (extcmd)["save"	do ..taskSave()
	if (extcmd)="stop "	do ..taskSuspend(1)
	if $p(extcmd,"stop ",2)'="" do ..taskset($p($p(extcmd,"stop ",2)," ",1),1),..tasklist()
	quit $$$OK
}

ClassMethod taskSave() As %Status
{
	set q="SELECT * FROM %SYS.Task"
	set gn=..#SettingsGN
	set result=##CLASS(%ResultSet).%New("%DynamicQuery:SQL")
	set tSC=result.Prepare(q)
	set:tSC tSC=result.Execute()
	if '$$$ISOK(tSC) {
		set text=$SYSTEM.Status.GetErrorText(tSC)  write !,text QUIT $$$ERROR(text)
	}
	else {
		while result.Next() {
			set id=result.Data("ID")
			set sus=result.Data("Suspended")
			set @gn@("Susp",id)=sus
		}
	}

	quit $$$OK
}

ClassMethod taskSuspend(set = "") As %Status
{
	;set q="SELECT ID,Type,Name,NameSpace,RunAsUser FROM %SYS.Task where Type="_type
	set q="SELECT * FROM %SYS.Task where ID>999"
	set gn=..#SettingsGN
	set result=##CLASS(%ResultSet).%New("%DynamicQuery:SQL")
	set tSC=result.Prepare(q)
	set:tSC tSC=result.Execute()
	if '$$$ISOK(tSC) {
		set text=$SYSTEM.Status.GetErrorText(tSC)  write !,text QUIT $$$ERROR(text)
	}
	else {
		while result.Next() {
			set id=result.Data("ID")
			set sus=result.Data("Suspended")
			if '$d(@gn@("Susp",id)) set @gn@("Susp",id)=sus
			if $d(@gn@("Susp",id)) set sus=@gn@("Susp",id)
			if set=0,sus continue
			if result.Data("Status")=-1 continue
			set st=..taskset(id,set)
			if 'st set text=$SYSTEM.Status.GetErrorText(st) write !,id_" "_text
			else  write !,id_" OK"
		}
	}
	do ..tasklist()
	quit $$$OK
}

/// write ##class(%ZAPM.ext.Task).taskset(id,set)
ClassMethod taskset(id, set) As %Status
{
	Set Task=##Class(%SYSTEM.Task).%OpenId(id)
	if '$iso(Task) quit $$$ERROR($$$GeneralError,"Can't open object id="_id)
	set Task.Suspended=set
	set st=Task.%Save()
	quit st
}

/// do ##class(%ZAPM.ext.Task).tasklist()
ClassMethod tasklist() As %Status
{
	set query="SELECT ID,Type,Name,NameSpace,RunAsUser,Description,DisplayDayNextScheduled,DisplayEndDate,DisplayErrorDate,DisplayErrorNumber,DisplayFinished, DisplayInterval,DisplayNextScheduled,DisplayNextScheduledBrief,DisplayRun,DisplayStartDate,DisplayStarted,DisplayStatus,Error,SuspendOnError,SuspendTerminated,Suspended,TaskClass FROM %SYS.Task"
	set q="SELECT ID,Type,Name,NameSpace,DisplayDayNextScheduled,DisplayEndDate,Suspended,Status FROM %SYS.Task"
	set result=##CLASS(%ResultSet).%New("%DynamicQuery:SQL")
	set tSC=result.Prepare(q)
	set:tSC tSC=result.Execute()
	set gn=..#SettingsGN
	if '$$$ISOK(tSC) {
		set text=$SYSTEM.Status.GetErrorText(tSC)  write !,text QUIT $$$ERROR(text)
	}
	else {
		write !,##class(%ZAPM.ext.zapp).writerow("ID",",1, ,6","Type",",1, ,4","Name",",1, ,40","Status",",2,.,9","Suspended",",2,.,9","Save",",2, ,4")
		write !,##class(%ZAPM.ext.zapp).writerow("--",",1, ,6","----",",1, ,4","----",",1, ,40","------",",2,.,9","---------",",2,.,9","----",",2, ,4")
		while result.Next() {
			set id=result.Data("ID")
			set type=result.Data("Type")
			set colortype=$s(type:$$$Green,1:"")
			set type=$s(type=0:"syst",type=2:"user",1:type)
			set sus=result.Data("Suspended")
			if '$d(@gn@("Susp",id)) set @gn@("Susp",id)=sus
			;set susp=$s(sus:"yes",1:"")
			set colorname=$s(sus:$$$Red,1:"")
			set save=$g(@gn@("Susp",id),"?")
			set status=result.Data("Status")
			set stat=$s(status=1:"OK",status=-1:"Running",1:$SYSTEM.Status.GetErrorText(status))
			set clrs=$s(status=1:"",status=-1:$$$Green,1:$$$Red)
			write !,##class(%ZAPM.ext.zapp).writerow(result.Data("ID"),colortype_",1, ,6",type,colortype_",1, ,4",result.Data("Name"),colorname_",1,.,40",stat,clrs_",2,.,9",sus,",2,.,9",save,",2, ,4")
		}
	}
	quit $$$OK
}

}

