Include %ZAPM.ext.Common

/// research and development ZPM
Class %ZAPM.ext.zpm [ Abstract ]
{

Parameter VERSION = "1.0.2";

/// Storage of work history
Parameter GN = "^%ZAPM.ZpmLoad";

/// extention zpm commans
/// do ##class(%ZAPM.ext.zpm).extcmd("load https://github.com/Vassil2010/iris-sms")
/// zapp "newdb spool-demo"
ClassMethod extcmd(cmd = "") As %Status
{
	if $p(cmd," ")="help" q ##class(%ZAPM.ext.zpm).help($p(cmd," ",2,*))
	if $p(cmd," ")="newdb" q ##class(%ZAPM.ext.zpm).CreateDBNSAndLoad($p(cmd," ",2,*))
	if $p(cmd," ")="load" q ##class(%ZAPM.ext.zpm).LoadFromRepo($p(cmd," ",2,*))
	if $p(cmd," ")="ver" zpm "ver" write !,$$$escGreen("zapm")_" "_..#VERSION,!
}

ClassMethod help(cmd = "") As %Status
{
	OPEN 2:$j USE 2
	if '$lf(..cmdzpmext(),cmd) {
		do ##class(%ZPM.PackageManager).Shell("help "_cmd)
		do ##class(%ZAPM.ext.zpm).exthelp(cmd)
	}
	else { 
		do ##class(%ZAPM.ext.zpm).exthelp(cmd)
		}
 	CLOSE 2
 	set i=""
 		,help=""
 		,cmds=..cmdzpm()_..cmdzpmext()
 	for { set i=$o(^SPOOL($j,i),1,s) q:i=""
 		set s=" "_s
 		if $o(^SPOOL($j,i)) {
	 		for cm=1:1:$ll(cmds) if s[(" "_$lg(cmds,cm)_" ") set s=$replace(s," "_$lg(cmds,cm)_" "," "_$$$escViolet($lg(cmds,cm))_" ")
 			set help=help_s
 		}
 	}
 	KILL ^SPOOL($j)
	write !,help
	quit $$$OK
}

ClassMethod exthelp(cmd = "") As %Status
{
 if cmd="" {
	write !!,"Available commands extention:"
	write !,"-----------------------------"
 }
 if cmd=""||(cmd="newdb") {
	write !,"newdb <module>"
 	write !," Create a new database and an Namespace with a name derived from the name of the module and Install the module into it,"
 }
 if cmd=""||(cmd="load") {
	write !!,"load http://git-repo/developer-name/repo-name"
 	write !," Load the module directly from the repository into the current Namespace. The 'git clone' command is applied. The git program must be installed."
 }
 if cmd=""||(cmd="cmd") {
	write !!,"cmd "
 	write !," Alias: ?"
 	write !," Show all commands."
 	write !!,"cmd context"
 	write !," Show all commands including context."
 }
 if cmd=""||(cmd="hist") {
	write !!,"hist "
	write !," Alias: ??"
 	write !," Show all history."
 	write !!,"hist context"
 	write !," Show all history including context."
 }

 write !
	quit $$$OK
}

ClassMethod cmdzpm() As %String
{
	quit $lb("ver","quit","help","namespace","orphans","list-dependents","list-installed","reload","compile","test","package","verify","publish","load","zn","help","install","uninstall","manage","list","find","search","version","repo","config","generate")
}

ClassMethod cmdzpmext() As %String
{
	quit $lb("newdb","cmd","hist")
}

/// do ##class(%ZAPM.ext.zpm).SetColorScheme("dark")
ClassMethod SetColorScheme(scheme = {$s($zversion(1)=3:"dark",1:"white")}) As %Status
{
	write !,1,scheme,1
	Quit ##class(%ZPM.PackageManager).Shell("config set ColorScheme "_scheme)
}

/// write ##class(%ZAPM.ext.zpm).LoadFromRepo("https://github.com/Vassil2010/iris-sms")
ClassMethod LoadFromRepo(path = "") As %Status
{
	set sls=$$$slash
	set st=$$$OK
	if $e(path,1,4)="http" {
		set dirrepo=$p($p(path,"/",*),".git")
		set dirrnd=$tr($zts,".,")
		Set TempDir = ##class(%File).GetDirectory(##class(%File).GetDirectory($zu(86))_"mgr"_sls_"Temp"_sls_dirrnd_sls)
		set st=##class(%File).CreateDirectoryChain(TempDir)
		if 'st  write !,$System.Status.GetErrorText(st) q st
		;write !,"Create tempory directory "_TempDir
		set filemodule=TempDir_dirrepo_sls_"module.xml"
		set cmd="cd "_TempDir_" && git clone "_path
		;w !,cmd,!
		if $zf(-1,cmd)
		h 2
		if $zu(140,1,filemodule)>0 {
			set st=##class(%ZPM.PackageManager).Shell("load "_TempDir_sls_dirrepo)
		}
		else {
			set urlarh=..GetUrlRepoArhive(path)
		}
		do ##class(%File).RemoveDirectoryTree(TempDir)
		if 'st write !,$System.Status.GetErrorText(st)
		Quit st
	}
	else {
		Quit ##class(%ZPM.PackageManager).Shell("load "_path)
	}
	
	q $$$OK
}

ClassMethod GetUrlRepoArhive(tLocation) As %Status
{
	Do ##class(%Net.URLParser).Parse(tLocation,.tComponents)
	if
}

/// zpm-utility 
/// repo -r -n registry -url http://127.0.0.1:52773/registry/ -user "superuser" -pass "pass"
/// do ##class(%ZAPM.ext.zpm).LoadRegistrys("realworld")
ClassMethod LoadRegistrys(modulename = "", all = 0, skipZPM = 1) As %Status
{
	set currns=$namespace
	set gn=..#GN
	set sql="select Name, Version, Repo from %ZPM_PackageManager_Developer.Utils_GetModuleList('registry') "_$s(modulename="":"",1:"where Name=?")
		,rs=##class(%ResultSet).%New()
		,sc=rs.Prepare(sql)
	set:sc sc=rs.Execute($zconvert(modulename,"L"))
	if sc {
		for i=1:1 {
			quit:'rs.%Next()  
			set name=rs.Get("Name")
			set Version=rs.Get("Version")
			set Repo=rs.Get("Repo")
			set ns=$zconvert($tr(name,"-."),"U")
			if skipZPM, name["isc-apptools"||($e(name,1,3)="zpm")||($e(name,1,6)="appmsw") w !,"Skip" continue
			if $d(@gn@(name)) { ;already load
				if $lg($g(@gn@(name,"generate")),2)'=""||($lg($g(@gn@(name,"install")),1)'="") {
					write !,ns_" Unload Removed DBNS ? Y\N " Read R   quit:"q"[R
					if $g(R)="y" {
						do ##class(%ZAPM.ext.zpm).UnloadAndDeleteDBNS(name,,,gn)
					}
					continue
				}
				write !,"Already loaded - Skip"
			} elseif 1 {
				set sta=##class(%ZPM.PackageManager).Shell("find -r -d "_name) write !
				if 'sta s err=$System.Status.GetErrorText(sta) w !,err w !,"Skip" continue
				if 'all w !,ns_" Load into a new database ? Y\N " Read R   quit:"q"[R
				if $g(R)="y"||(all=1) {
					do ##class(%ZAPM.ext.zpm).CreateDBNSAndLoad(name,,,,gn)
				}
			}
		}
	}
}

/// d ##class(%ZAPM.ext.zpm).UnloadAndDeleteDBNS("sync-dstime")
ClassMethod UnloadAndDeleteDBNS(name, Version = "", Repo = "", gn = {..#GN}) As %Status
{
	set currns=$namespace
	new $namespace
	s ns=$zconvert($tr(name,"-."),"U")
	set $Namespace=ns
	set sta=##class(%ZPM.PackageManager).Shell("uninstall "_name)
	if 'sta w !,$system.Status.GetErrorText(sta)
	else  k @gn@(name)
	set $namespace=currns
	s st=##class(%ZAPM.ext.database).DeleteDBNS(ns)
	i 'st w $system.Status.GetErrorText(st)
}

/// d ##class(%ZAPM.ext.zpm).CreateDBNSAndLoad("isc-tar")
ClassMethod CreateDBNSAndLoad(name, ns = "", Version = "", Repo = "", gn = "") As %Status
{
	new $namespace
	k err w !
	if ns="" s ns=$zconvert($tr(name,"-."),"U")
	s st=##class(%ZAPM.ext.database).CreateDBNS(ns)
	i 'st s err=$System.Status.GetErrorText(st) w !,err
	s:gn'="" @gn@(name,"generate")=$lb(ns,$g(err),st)
	if st {
		zn ns
		;s sta=$zpm("install "_name_" -v")
		k err
		w !,"zpm ""install "_name_""""
		s sta=##class(%ZPM.PackageManager).Shell("install "_name)
		i 'sta s err=$System.Status.GetErrorText(sta) w !,err
		s:gn'="" @gn@(name,"install")=$lb($g(err),sta,Version,Repo)
	}
	q $$$OK
}

/// Recompilation to IRIS namespace
/// d ##class(%ZAPM.ext.zpm).CompNS("AAA")
ClassMethod CompNS(ns) As %Status
{
	zn ns
	d ##class(%EnsembleMgr).EnableNamespace(ns,1)
	w !,"Compilation started, please wait..."
	k err d $system.OBJ.CompileAll("cfk-u-d",.err) zw err
	q $$$OK
}

ClassMethod CollectPackage(pPath As %String, Output pList, pRoot As %String)
{
  set rs = ##class(%File).FileSetFunc(pPath)
  WHILE rs.%Next() {
    If rs.Type="D" {
      do ..CollectPackage(rs.Name, .pList, pRoot)
    } ELSE {
      #; Set $LISTBUILD(url) = $SYSTEM.CSP.FilenameToUrls(rs.Name) 
      Set pList($INCREMENT(pList)) = $LISTBUILD(rs.Name, $EXTRACT(rs.Name, $LENGTH(pRoot) + 1, *))
    }
  }
}

ClassMethod CompactPackage(ByRef pList, classname = {$CLASSNAME()}) As %Status
{
  set file = ""
  for i=1:1:$Get(pList) {
    Set $LISTBUILD(file, name) = pList(i)
    
    set tmpFile = ##class(%File).TempFilename("gz")

    set stream = ##class(%Stream.FileBinary).%New()
    set stream.Filename = file

    Set gzip = ##class(%Stream.FileBinaryGzip).%New()
    Set gzip.Filename = tmpFile
    do gzip.CopyFromAndSave(stream)
    
    Set gzip = ##class(%Stream.FileBinary).%New()
    Set gzip.Filename = tmpFile

    Set xdata = ##class(%Dictionary.XDataDefinition).%New()
    Set xdata.Name = "Data"_i
    Set xdata.Description = name
    Do xdata.parentSetObjectId(classname)
    set chunkSize = 22800
    while 'gzip.AtEnd {
      set data = gzip.Read(chunkSize)
      set base64 = $SYSTEM.Encryption.Base64Encode(data)
      do xdata.Data.WriteLine(base64)
      set data1 = $SYSTEM.Encryption.Base64Decode(base64)
    }
    do xdata.%Save()
    set hash = $SYSTEM.Encryption.SHA1HashStream(gzip)
  
    do ##class(%File).Delete(tmpFile)
  }
  QUIT $$$OK
  
  
  Quit $$$OK
}

ClassMethod ExtractPackage(Output pFolder As %String, classname = {$CLASSNAME()}) As %String
{
  Set pFolder = ##class(%File).NormalizeDirectory($$$FileTempDir)

  For i=1:1:..#FILESCOUNT {
    Set xdata = ##class(%Dictionary.XDataDefinition).%OpenId(classname_"||Data"_i)
    Set name = xdata.Description
    Set fileName = pFolder_name

    Set tParentFolder = ##class(%File).ParentDirectoryName(fileName)    
    if '##class(%File).DirectoryExists(tParentFolder) {
      Do ##class(%File).CreateDirectoryChain(tParentFolder)
    }

    set tmpFile = ##class(%File).TempFilename("gz")

    set stream = ##class(%Stream.FileBinary).%New()
    set stream.Filename = tmpFile
    set prev = ""
    set chunkSize = 30400
    do {
      set data = prev
      if 'xdata.Data.AtEnd {
        set data = data _ xdata.Data.Read()
      }
      set data = $ZSTRIP(data, "*C")
      set prev = $EXTRACT(data, chunkSize + 1, *)
      set data = $EXTRACT(data, 1, chunkSize)
      set chunk = $SYSTEM.Encryption.Base64Decode(data)
      do stream.Write(chunk)
    } while (prev'="")||('xdata.Data.AtEnd)
    do stream.%Save()

    set gzip = ##class(%Stream.FileBinaryGzip).%New()
    set gzip.Filename = tmpFile

    set fs = ##class(%Stream.FileCharacter).%New()
    set fs.Filename = fileName
    do fs.CopyFromAndSave(gzip)

    do ##class(%File).Delete(tmpFile)
  }
  Quit $$$OK
}

/// Add XDATA to another class
///  d ##class(%ZAPM.ext.zpm).add2xdata("/backup/iris/distr/apptools-task/","Test.test")
ClassMethod add2xdata(dir = "d:\_proj\_zpm\appt-core\src\cls\", classname)
{
	;w $classname() q
	Do ..CollectPackage(dir, .tList, dir)
	zw tList
    ;Do ##class(%ZPM.Installer).CompactPackage(.tList,"App.MSW.type")
    Do ..CompactPackage(.tList,classname)
}

/// Output color escape sequence
/// do ##class(%ZAPM.ext.zpm).EscColor()
ClassMethod EscColor(mode = "") As %String
{
	if mode="" { //write all colors
		write ..EscColor(0)
		//brightness
		for b=1,2 {
			for f=30:1:37 {  //font
				for i=40:1:47 {  //background
					s code=b_";"_f_";"_i
					s txt=" write $$$escSeq("""_code_""",""any text"")"
					w !,$$$escSeq(code,txt)
				}
			}
		}
	
	} elseif mode=0 { //cleaning
		q $c(27)_"[0m"
	} else {
		q $c(27)_"["_mode_"m"
	}
}

/// write ##class(%ZAPM.ext.zpm).ZPMColorScheme()
ClassMethod ZPMColorScheme() As %String
{
	try {
		set scheme=##class(%ZPM.PackageManager.Client.Settings).GetValue("ColorScheme")
	} 
	catch e {
		set scheme=0
	}
	quit scheme
}

/// do ##class(%ZAPM.ext.zpm).exportXML("d:\_proj\_zapp\zpm-addition+\zapm\zapm\_zapm.xml")
ClassMethod exportXML(dir = "")
{
 	s list("%ZAPM.ext.INC")=""
	s list("%ZAPM.ext.zpm.CLS")=""
	s list("%ZAPM.ext.zapp.CLS")=""
	s list("%ZAPM.ext.database.CLS")=""
	s list("%ZAPM.ext.commands.CLS")=""
	d $SYSTEM.OBJ.Export(.list, dir)
}

}

