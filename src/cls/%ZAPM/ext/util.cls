Include %ZAPM.ext.Common

/// Utilites ZPM, ZAPM, Registry
Class %ZAPM.ext.util [ Abstract ]
{

/// do ##class(%ZAPM.ext.util).CreateModuleXML("apptoolsadmin",.list)
ClassMethod CreateModuleXML(namespace, tPath, tName, tVersion = "1.0.0", tDescription = "", tKeywords = "", tWebAppList) As %Status
{
	;set st=##class(%ZPM.PackageManager.Developer.ModuleTemplate).GenerateTemplate(tPath)
	Set tTemplate = ##class(%ZPM.PackageManager.Developer.ModuleTemplate).NewTemplate(tPath, tName, tVersion, tDescription, tKeywords)
	Return:'$IsObject(tTemplate) $$$ERROR($$$GeneralError,"Module creation error")
	;Do tTemplate.SetAuthorProps(tAuthorPerson, tAuthorOrg, tAuthorLicense, tAuthorCopy, tAuthorNotes)
	if namespace ;stupid line to please the quality of the code
	;Do tTemplate.AddWebApps(tWebAppList,.tCSPapps,namespace) //TODO https://github.com/intersystems-community/zpm/pull/275
	Do tTemplate.AddWebApps(tWebAppList,.tCSPapps) // tCSP - list of CSP (not REST apps) 
	
	For i=1:1:$Listlength(tCSPapps) {
		set namecsp=$Listget(tCSPapps,i)
		Set tCSPPath = "/csp/"_$p(namecsp,"/",*)
		Do tTemplate.SetSourcePathForCSPApp(namecsp,tCSPPath)
	}
	Do tTemplate.ReadResorces("src")
	Do tTemplate.ProcessResources()
	Return tTemplate.SaveFile(tPath)
}

/// do ##class(%ZAPM.ext.util).GetListApps("apptoolsadmin",.list)
ClassMethod GetListApps(sourcedb, ByRef list) As %Status
{
	new $namespace
	set $namespace="%SYS"
	set result=##CLASS(%ResultSet).%New("%DynamicQuery:SQL")
	set tSC=result.Prepare("select NameLowerCase FROM Security.Applications where NameSpace=?")
	set:tSC tSC=result.Execute($zconvert(sourcedb,"U"))
	if '$$$ISOK(tSC) {
		set text="Application setup error :"_$SYSTEM.Status.GetErrorText(tSC)  write !,text QUIT $$$ERROR(text)
	}
	else {
		while result.Next() {
			set name=result.Data("NameLowerCase")
			set tSC=##class(Security.Applications).Get(name,.prop)
			merge list(name)=prop
		}
	}
}

ClassMethod CopyCSP(path, TempDir, slash = {$s($zversion(1)=3:"/",1:"\")}) As %Status
{
	set from=path ;##class(%File).GetDirectory($zu(86))_"csp"_slash_source
	set del=slash_"csp"_slash
	if path'[del set del=slash_"CSP"_slash
	set to=TempDir_"csp"_slash_$p(path,del,2)
	write !,"Copy csp from: "_from,!,"       to: "_to
	set st=##class(%File).CopyDir(from, to,1)
	quit st
}

/// do ##class(%ZAPM.ext.util).MakeZapmSrc("/backup/repo-iris-test/zapm/","%ZAPM")
ClassMethod MakeZapmSrc(dir, pack) As %Status
{
	set dirpath=##class(%File).GetDirectory(dir_"src/")
	write !,dirpath
	do ##class(%ZAPM.ext.code).ExportOneResource(dirpath,"001001",pack)
	quit $$$OK
    return $$$OK
}

/// do ##class(%ZAPM.ext.util).MakeZpmProject("zapm","/backup/repo-iris-test/zapm/",.res,"zapm is a shell - extends the zpm shell and adds any other commands.")
ClassMethod MakeZpmProject(namemodule, dir, ByRef resources, desc) As %Status
{
	set dirpath=##class(%File).GetDirectory(dir_"src/")
	write !,dirpath
	
	do ##class(%ZAPM.ext.code).ExportOneResource(dirpath,"001001","%ZAPM")
	quit $$$OK
	;do ##class(apptools.core.code).exp(dir_"src","appmsw")
	;do $classmethod("apptools.core.code","exp",dir_"src","appmsw")
	;set List("appmsw.cbrf.tabexDayD.GBL")=""
	;set target=##class(%File).NormalizeFilename("appmsw.cbrf.tabexDayD.xml",dir_"src/gbl/")
	;Write $SYSTEM.OBJ.Export(.List, target)
	
	do ..GetListApps($namespace,.list)
	set name=""
	set tWebAppList=""
	for { set name=$order(list(name)) quit:name=""
		set tWebAppList=tWebAppList_name_","
	}
	do ..CreateModuleXML($namespace,dir,namemodule,,desc,"",$e(tWebAppList,1,*-1))
    return $$$OK
}

/// Code from Robert Cemper https://github.com/rcemper/Zpipe
/// write ##class(%ZAPM.ext.util).cpipe("ping -c 3 community.intersystems.com")
ClassMethod cpipe(command = "", test = 0) As %Status
{
 //Zpipe  quit ; CPIPE example to run host console command
 //cmd(command="",test=0) ;
 if command="" set command="dir"
 set dev="|CPIPE|1"
 set $zt="cls"
 set empty=0
 open dev:command:0 
 write:test $test,! 
 else  write "pipe failed",! quit 0 
 while empty<3 {
    use dev read line 
    set empty=$s($l(line):0,1:$i(empty))
    use 0 write line,!  ;;; or do any kind of analysis of the line 
    }

cls ;
 set $zt="" use 0 
 close dev 
 if $ze'["<ENDOFFILE>" w $ze,!
 quit $t
}

}

