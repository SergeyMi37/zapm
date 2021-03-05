Include %ZAPM.ext.Common

/// installation string ZPM, ZAPM, Registry
/// set $namespace="%SYS", name="DefaultSSL" do:'##class(Security.SSLConfigs).Exists(name) ##class(Security.SSLConfigs).Create(name) set url="https://pm.community.intersystems.com/packages/zpm/latest/installer" Do ##class(%Net.URLParser).Parse(url,.comp) set ht = ##class(%Net.HttpRequest).%New(), ht.Server = comp("host"), ht.Port = 443, ht.Https=1, ht.SSLConfiguration=name, st=ht.Get(comp("path")) quit:'st $System.Status.GetErrorText(st) set xml=##class(%File).TempFilename("xml"), tFile = ##class(%Stream.FileBinary).%New(), tFile.Filename = xml do tFile.CopyFromAndSave(ht.HttpResponse.Data) do ht.%Close(), $system.OBJ.Load(xml,"ck") do ##class(%File).Delete(xml) zpm "install zapm" zapm "newdb zpm-registry" zapm "zna"
/// research and development ZPM
Class %ZAPM.ext.zpm [ Abstract ]
{

Parameter VERSION = "1.0.11";

/// Storage of work history
Parameter GN = "^%ZAPM.ZpmLoad";

/// extention zpm commans
/// do ##class(%ZAPM.ext.zpm).extcmd("load https://github.com/Vassil2010/iris-sms")
/// zapp "newdb spool-demo"
ClassMethod extcmd(cmd = "") As %Status
{
	if $lf($lb("find","search"),$p(cmd," ")) quit ##class(%ZAPM.ext.zpm).find($p(cmd," ",2,*)_" ")
	if $p(cmd," ")="help" quit ##class(%ZAPM.ext.zpm).help($p(cmd," ",2,*))
	if $p(cmd," ")="newdb" quit ##class(%ZAPM.ext.zpm).CreateDBNSAndLoad($p(cmd," ",2,*))
	if $p(cmd," ")="load" quit ##class(%ZAPM.ext.zpm).LoadFromRepo($p(cmd," ",2,*))
	if $p(cmd," ")="ver" zpm "ver" write !,$$$escGreen("zapm")_" "_..#VERSION,!
	if $p(cmd," ")="repo" set st=##class(%ZPM.PackageManager).Shell(cmd) do:cmd'="repo -list"&&(cmd["repo -r -n ") ##class(%ZPM.PackageManager).Shell("repo -list") quit st
	if $p(cmd," ")="dbcreate" {
		if ($p(cmd," ",2,*))[" -p " set path=$p($p(cmd," -p ",2)," ")
		 quit ##class(%ZAPM.ext.database).CreateDBNS($p(cmd," ",2),,$GET(path))
	}
	if $p(cmd," ")="dbdelete" quit ##class(%ZAPM.ext.database).DeleteDBNS($p(cmd," ",2,*))
	
	;if $p(cmd," ")="rolecreate" quit ##class(%ZAPM.ext.database).CreateRole($p(cmd," ",2,*))
	;if $p(cmd," ")="roledelete" quit ##class(%ZAPM.ext.database).DeleteRole($p(cmd," ",2,*))
}

ClassMethod find(extcmd) As %Status
{
	if (extcmd)[" -r " set ViewRepo=1
	if (extcmd)[" -d " set ViewFromModule=1
	if (extcmd)[" -u " set ViewUrl=$p($p(extcmd," -u ",2)," ")
	do ##class(%ZAPM.ext.zpm).Description($p(extcmd," "),$GET(ViewUrl),$GET(ViewRepo),$GET(ViewFromModule))
	quit $$$OK
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
 if cmd=""||(cmd="dbcreate") {
	write !,"dbcreate namespace <path>"
 	write !," Create a new database and an Namespace,"
 	write !," dbcreate testdb2 -p d:/!/database/durable"
 }
 if cmd=""||(cmd="dbdelete") {
	write !,"dbdelete namespace"
 	write !," Delete database and an Namespace,"
 }
 if cmd=""||(cmd="load") {
	write !!,"load http://git-repo/developer-name/repo-name"
 	write !," Load the module directly from the repository into the current Namespace. The 'git clone' command is applied. The git program must be installed."
 }
 if cmd=""||(cmd="find")||(cmd="search") {
	write !!,"find app* -d  load description from modules, and the description is always displayed"
 	write !!,"find app* -u /rcemper  show modules only including context from repository"
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
	quit $lb("newdb","cmd","hist","dbcreate","dbdelete")
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
		//first try
		set UrlArchive = ..GetUrlRepoArhive(path)
		if UrlArchive'="" {
			Do ##class(%Net.URLParser).Parse(UrlArchive,.tComponents)
			Set tClient = ##class(%ZPM.PackageManager.Client.REST.PackageManagerClient).%New()
			set tRequest = tClient.GetHttpRequest(UrlArchive)
			Set tRequest.Timeout = 300
    		Set tSC = tRequest.Get(tComponents("path"))
    		If $$$ISOK(tSC), tRequest.HttpResponse.StatusCode=200 {
      			Set tFileBinStream = ##class(%Stream.FileBinary).%New()
      			Set tFileBinStream.Filename = TempDir_"tmp.zip"
      			do tFileBinStream.CopyFromAndSave(tRequest.HttpResponse.Data)      
			}
		  	If $GET(tFileBinStream)'="" {
				if $zversion(1)=3 { //for Linux
					set cmd="cd "_TempDir_" && unzip -q tmp.zip"
				}
				else { //for Windows
					set cmd="cd "_TempDir_" && powershell Expand-Archive -LiteralPath "_TempDir_"tmp.zip -DestinationPath "_TempDir
				}
				write !,cmd,!
				$$$ThrowOnError(##class(%ZPM.PackageManager.Developer.Utils).RunCommandViaZF(cmd,.tLog,.tErr))
				hang 2
			}
		}
		if $$$FileSize(TempDir_dirrepo_"-master"_sls_"module.xml")>0 {
			set st=##class(%ZPM.PackageManager).Shell("load "_TempDir_sls_dirrepo_"-master")
			do ##class(%File).RemoveDirectoryTree(TempDir)
			if 'st write !,$System.Status.GetErrorText(st)
			Quit st
		}
		//second try
		set cmd="cd "_TempDir_" && git clone "_path
		write !,cmd,!
		$$$ThrowOnError(##class(%ZPM.PackageManager.Developer.Utils).RunCommandViaZF(cmd,.tLog,.tErr))
		hang 2
		if $$$FileSize(TempDir_dirrepo_sls_"module.xml")>0 {
			set st=##class(%ZPM.PackageManager).Shell("load "_TempDir_sls_dirrepo)
			do ##class(%File).RemoveDirectoryTree(TempDir)
			if 'st write !,$System.Status.GetErrorText(st)
			Quit st
		}
	}
	else {
		Quit ##class(%ZPM.PackageManager).Shell("load "_path)
	}
	q $$$OK
}

/// https://github.com/SergeyMi37/zapm-addcmd.git
/// https://codeload.github.com/SergeyMi37/zapm/zip/master
/// write ##class(%ZAPM.ext.zpm).GetUrlRepoArhive("https://github.com/SergeyMi37/zapm-addcmd.git")
/// https://gitlab.com/sergeymi/test.git
/// https://gitlab.com/sergeymi/test/-/archive/master/test-master.zip
/// write ##class(%ZAPM.ext.zpm).GetUrlRepoArhive("https://gitlab.com/sergeymi/test.git")
ClassMethod GetUrlRepoArhive(tLocation) As %String
{
	Do ##class(%Net.URLParser).Parse(tLocation,.tComponents)
	set reponame=$piece($piece(tComponents("path"),"/",3),".")
	If tComponents("host")="gitlab.com" {
		set ref="https://gitlab.com/"_$piece(tComponents("path"),"/",2)_"/"_reponame_"/-/archive/master/"_reponame_"-master.zip"
	}
	If tComponents("host")="github.com" {
		set ref="https://codeload.github.com/"_$piece(tComponents("path"),"/",2)_"/"_reponame_"/zip/master"
	}
	quit $get(ref)
}

/// zpm-utility 
/// repo -r -n registry -url http://127.0.0.1:52773/registry/ -user "superuser" -pass "pass"
/// do ##class(%ZAPM.ext.zpm).LoadRegistrys("c*",1)
ClassMethod LoadRegistrys(modulename = "", all = 0, skipZPM = 1) As %Status
{
	set currns=$namespace
	set gn=..#GN
	set sql="select Name, Version, Repo, Description from %ZPM_PackageManager_Developer.Utils_GetModuleList('registry') "_$s(modulename="":"",modulename["*":"where Name like '"_$tr(modulename,"*","%")_"'",1:"where Name=?")
		,rs=##class(%ResultSet).%New()
		,sc=rs.Prepare(sql)
	set:sc sc=rs.Execute($zconvert(modulename,"L"))
	write !,sql
	if sc {
		for i=1:1 {
			quit:'rs.%Next()  
			set name=rs.Get("Name")
			set Version=rs.Get("Version")
			set Repo=rs.Get("Repo")
			set ns=$zconvert($tr(name,"-."),"U")
			if skipZPM, name["isc-apptools"||($e(name,1,3)="zpm")||($e(name,1,6)="appmsw")||($e(name,1,4)="zapm") w !,"Skip "_$$$escGreen(name) continue
			if $d(@gn@(name)) { ;already load
				if $lg($g(@gn@(name,"generate")),2)'=""||($lg($g(@gn@(name,"install")),1)'="") {
					write !,ns_" Unload Removed DBNS ? Y\N " Read R   quit:"q"[R
					if $g(R)="y" {
						do ##class(%ZAPM.ext.zpm).UnloadAndDeleteDBNS(name,,,gn)
					}
					continue
				}
				write !,"Already loaded - Skip "_$$$escGreen(name)
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
	write !,"Log in global ",!,gn
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

/// Show description 
/// do ##class(%ZAPM.ext.zpm).Description("z*","/rcep",1)
ClassMethod Description(tModuleName, UrlInc = "", RepoView = "0", ViewFromModule = 0)
{
	#define gn "^||tmpDesc"
	Kill @$$$gn
	Set tRegistry = ""
	If (tModuleName["/") {
		set $lb(tRegistry, tModuleName) = $lfs(tModuleName, "/")
	}
	set where=""
		,maxlenname=0
		,Module=""
	If tModuleName["*" {
		Set where="where name like ?"
		Set Module=$Replace(tModuleName,"*","%")
	} Elseif tModuleName'="" { 
		Set Module=tModuleName
		Set where="where name = ?"
	}
	If UrlInc'="" set RepoView=1 Write !,"Search by owner repository "_$$$escRed(UrlInc)
	If where="" Write !,"Search the entire repository"
	Else  Write !,"Search the repository context "_Module
	//Load the list info registry modules
	Set sql="select Name, Version, Repo, Description from %ZPM_PackageManager_Developer.Utils_GetModuleList('registry') "_where
		,rs=##class(%ResultSet).%New()
		,sc=rs.Prepare(sql)
	Set:sc sc=rs.Execute(Module)
	set maxlenname=20
	If sc {
		For i=1:1 {
			Quit:'rs.%Next()  
			Set name=rs.Get("Name")
			set (Description,desc)=rs.Get("Description")
			Set (repo,url)=rs.Get("Repo")
			If $Zconvert(url,"L")'[$Zconvert($Get(UrlInc),"L") Continue
			if desc="",ViewFromModule	{
				Do ..GetDescFromRepo(url,.desc,.repo,.modxml)
				if desc="" { set desc="not yet"}
				else { set desc="from module.xml: "_desc}
			}
			Write !,$$$escGreen(name)
				,?(maxlenname+1),rs.Get("Version")
				,?(maxlenname+8),$$$escYellow("Desc: ")_desc
			if $Get(UrlInc)'="",repo'="" set repo=$replace(repo,UrlInc,$$$escRed(UrlInc))
			if RepoView write:repo'="" !?3,repo
		 }
	}
	Else { 
		Write !,"Not found "_tModuleName_" in current registry"
	}
	Quit $$$OK
}

/// draw description, code from zpmshow.mac
ClassMethod DrawColumn(desc) As %String
{
 Set dx=$x
	For d=1:1:$Length(desc," ") {
 		Set wd=$Piece(desc," ",d) 
		If $x+$l(wd)>80 Write !,?dx
		Write wd," " 
	}
 Quit ""
}

/// TODO GitLab repo
ClassMethod GetDescFromRepo(url As %String, ByRef desc, ByRef repo, ByRef modxml) As %Status
{
	Set desc=""
	Set url="https://raw.githubusercontent.com"_$Piece(url,"/github.com",2)
	If url="" {
		Set repo="not repository"
	}
	Else {
		Set:$Extract(url,*)'="/" url=url_"/"
		Set url=url_"master/module.xml"
		If ..GetDataURL(url,.modxml) {
			Set desc=$Piece($Piece($Get(modxml),"Description>",2),"</")
			If 0,desc="",..GetDataURL($replace(url,"module.xml","README.md"),.readme) {
				Set d=$Translate($Extract(readme,1,300),$Char(13,10),"  ")
				If d["](" {
					For  { Quit:d'["]("
						Set d=$Translate($Piece(d,"](",1),"[()","   ")_$Piece($Piece(d,"](",2,*),")",$Select($Piece(d,"](",2,*)[")":2,1:1),*)
						
					}
				}
				Set desc="from readme: "_d_"..."
			}
		}
	}
	Quit $$$OK
}

/// write $System.Status.GetErrorText(##class(%ZPM.PackageManager).GetDataURL("https://raw.githubusercontent.com/intersystems-community/zpm/master/module.xml",.o)) w o
ClassMethod GetDataURL(url As %String, ByRef data) As %Status
{
	New $Namespace
	Set data=""
 	#dim req As %Net.HttpRequest
	Set req=##class(%Net.HttpRequest).%New()
	Set server=$p(url,"/",3)

	If server[":" {
		Set port=$p(server,":",2)
		Set server=$p(server,":")
	}
	If $zconvert(url,"L")["https:" {
	 	Set SSLConfig = "ZPM"
	 	Zn "%SYS"
	 	Do:'##class(Security.SSLConfigs).Exists(SSLConfig) ##class(Security.SSLConfigs).Create(SSLConfig)
	 	Set req.Https=1
		Set req.SSLConfiguration=SSLConfig
		Set:$g(port)="" port=443
	}
	Set:$Get(port)="" port=80
	Set req.Server=server
	Set req.Port=port
	Set location=$Piece(url,"/",4,*)

	Set req.Location =location

	Set st = req.Get()
	Return:$$$ISERR(st) st
	Return:(req.HttpResponse.StatusCode = 404) $$$ERROR($$$GeneralError,"Repository doesn't exist OR you don't have access")
	Return:((req.HttpResponse.StatusCode = 403) && (req.HttpResponse.GetHeader("X-RATELIMIT-REMAINING")=0)) $$$ERROR($$$GeneralError,"API rate limit exceeded. Try logging in.")
 	Return:(req.HttpResponse.StatusCode '= 200) $$$ERROR($$$GeneralError,"Received " _ req.HttpResponse.StatusCode _ " status, expected 200")

	Set data=req.HttpResponse.Data.Read()

 	Return $$$OK
}

}

