Include %ZAPM.ext.Common

/// Testing modules ZPM, ZAPM, Registry
Class %ZAPM.ext.test [ Abstract ]
{

/// do ##class(%ZAPM.ext.test).Test2("spool-demo,spool-mapping","/home/irisusr/test/")
/// do ##class(%ZAPM.ext.test).Test2("sudoku-en,sudoku-es","d:\_proj\!\test\")
ClassMethod Test2(zpmname As %String, workdir = "", ByRef data) As %Status
{
	New $Namespace
	;zn "%SYS" d ##class(Security.SSLConfigs).Create("z") s r=##class(%Net.HttpRequest).%New(),r.Server="pm.community.intersystems.com",r.SSLConfiguration="z" d r.Get("/packages/zpm/latest/installer"),$system.OBJ.LoadStream(r.HttpResponse.Data,"c")
	set st=##class(%File).CreateDirectoryChain(workdir)
	if 'st  write !,$System.Status.GetErrorText(st) q st
	set st=$zapm("ver") if 'st quit st
	;do ##class(%ZAPM.ext.zpm).LoadRegistrys(zpmmask,1)
	set zpmname2=$p(zpmname,",",2)
	set zpmname=$p(zpmname,",",1)
	set st=$zapm("newdb "_zpmname) if 'st quit st
	set st=$zapm("newdb "_zpmname2) if 'st quit st
	
	set ns=$zconvert($tr(zpmname,"$.","S"),"U")
	set ns2=$zconvert($tr(zpmname2,"$.","S"),"U")
	
	try { zn ns set st=1 }
	catch ex { set st=$$$ERROR($$$GeneralError,$ze)	}
	if 'st quit st
	
	;set st=$zapm("zna") if 'st quit st
	
	set st=$zpm("list") if 'st quit st
	set st=$zpm("repo -n registry -r -url https://test.pm.community.intersystems.com/registry/ -user test -pass PassWord42") if 'st quit st
	set st=$zpm("repo -list") if 'st quit st
	set st=$zpm("find") if 'st quit st
	set st=$zpm("publish "_zpmname) if 'st quit st
	set st=$zpm("find") if 'st quit st
	set st=$zpm("package "_zpmname_" -p "_workdir_zpmname_"\") if 'st quit st

	try { zn ns2 set st=1 }
	catch ex { set st=$$$ERROR($$$GeneralError,$ze)	}

	set st=$zpm("list") if 'st quit st
	set st=$zpm("load "_workdir_zpmname) if 'st quit st
	set st=$zpm("list") if 'st quit st
	
	set st=$zpm("repo -r -n registry -reset-defaults") if 'st quit st
	set st=$zpm("repo -list") if 'st quit st
	set st=$zpm("uninstall "_zpmname) if 'st quit st
	set st=$zpm("uninstall "_zpmname2) if 'st quit st
	set st=$zpm("repo -list") if 'st quit st
	set st=$zapm("dbdelete "_ns) if 'st quit st
	set st=$zapm("dbdelete "_ns2) if 'st quit st
	
	quit $$$OK
}

}

