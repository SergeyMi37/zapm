Include %ZAPM.ext.Common

/// apptools favourite commands in %ZLANGC00.mac
/// ZAPP(pArgs...) Do ##class(%ZAPM.ext.zapp).prompt(pArgs...) 
/// try { do ##class(%ZAPM.ext.zapp).UpdateLanguageExtensions() } catch ex {}
Class %ZAPM.ext.zapp [ Abstract ]
{

/// Storage of work history
Parameter GN = "^%ZAPM.hist";

/// do ##class(%ZAPM.ext.zapp).initeditor()
ClassMethod initeditor(NoExt = 0) As %Status
{
	new $namespace
	set $namespace="%sys"
	try {do init^%ZAPM.ed.a	} 
	catch e {}
	quit $$$OK
}

/// do ##class(%ZAPM.ext.zapp).AddLine2Rou("ZPIPE(%a) new $namespace zn """_$namespace_""" do cmd^Zpipe(%a) quit","%ZLANGC00",.err)
ClassMethod AddLine2Rou(line, rou As %String = "%ZLANGC00", err, r) As %Status
{
	new $namespace
	set $namespace="%sys"
	merge r=^rMAC(rou,0)
	for i=1:1 { quit:'$DATA(r(i),str)
		if $p(str,"(")=$p(line,"(") set r(i)=line,yes=1
	}
	if '$GET(yes) {
		set r(i)=line
		set r(0)=i
	}
	D ROUTINE^%R(rou_".MAC",.r,.err,"CS",0)
	quit $$$OK
}

/// do ##class(%ZAPM.ext.zapp).init(1)
ClassMethod init(NoExt = 0) As %Status
{
	new $namespace
	set $namespace="%sys"
	do ..favourite(.list)
	try {
		set i=""
		for {
			set i=$Order(list(i)) q:i=""
			set ii="" 
			for { 
				set ii=$Order(list(i,ii),1,val) q:ii=""
				do ##class(%ZAPM.ext.commands).AddUpdate($lg(val,1),$lg(val,3),i,$lg(val,2),$lg(val,4))
			}
		}
		if 'NoExt {
			do ##class(%ZAPM.ext.zapp).UpdateLanguageExtensions()
			do ##class(%ZPM.PackageManager).UpdateLanguageExtensions()
			if $System.Status.GetErrorText(##class(%ZAPM.ext.zpm).GetDataURL("https://raw.githubusercontent.com/SergeyMi37/zpm/master/src/%ZPM/Repo/Remote/PublishService.cls",.o,.req)) { 
				;set $namespace="%SYS", name="DefaultSSL" do:'##class(Security.SSLConfigs).Exists(name) ##class(Security.SSLConfigs).Create(name) set url="https://pm.community.intersystems.com/packages/zpm/latest/installer" Do ##class(%Net.URLParser).Parse(url,.comp) set ht = ##class(%Net.HttpRequest).%New(), ht.Server = comp("host"), ht.Port = 443, ht.Https=1, ht.SSLConfiguration=name, st=ht.Get(comp("path")) quit:'st $System.Status.GetErrorText(st) 
				;set cls=##class(%File).TempFilename("cls"), tFile = ##class(%Stream.FileBinary).%New(), tFile.Filename = xml do tFile.CopyFromAndSave(req.HttpResponse.Data) do ht.%Close(), $system.OBJ.Load(xml,"ck") do ##class(%File).Delete(xml)
				do $system.OBJ.LoadStream(req.HttpResponse.Data,"c") 
			}
		}
		if $zversion(1)=3 {  //Linux
			set dir="/opt/irisapp/src/"
			set dir2="/irisdev/" 
			;set outputpath="/usr/irissys/mgr/Temp/"
			if ##class(%File).DirectoryExists(dir) {
			 if '##class(%File).DirectoryExists(dir2) {	;for demo  GCR
				for name="webterminal" {
					if '##class(%ZAPM.ext.zapp).IsInstallzpm(name) {
						do ##class(%ZPM.PackageManager).Shell("install "_name)
				    }
				}
			 }
			}
		}
		;do ##class(%ZAPM.ext.zpm).SetColorScheme()
		write !,"To work in the shell, enter 'zapm' in the terminal, and then 'cmd' or '?' "
		do ##class(%ZAPM.ext.zpm).SetModuleVersion("zapm",##class(%ZAPM.ext.zpm).#GNSET,##class(%ZAPM.ext.zpm).#VERSION)
	} 
	catch e {}
	quit $$$OK
}

/// write ##class(%ZAPM.ext.zapp).IsInstallzpm("exchange-rate-cbrf")
ClassMethod IsInstallzpm(modulename, ns = {$namespace}) As %String
{
	do ##class(%ZPM.PackageManager).GetListModule(ns,.list)
	;zw list
	quit $DATA(list(modulename))
}

/// do ##class(%ZAPM.ext.zapp).favourite(.list)
ClassMethod favourite(ByRef list) As %Status
{
	;sys		           execute code     prompt:yes,no,never=""  name-cmd   description
	set list("sys",$i(list))=$lb("do 1^%SS","i",                    "proc-ss",     "system status")
	set list("sys",$i(list))=$lb("new $namespace zn ""%SYS"" do ^JOBEXAM","a","job","job examing")
	set list("sys",$i(list))=$lb("new $namespace zn ""%SYS"" do display^GLOBUFF(25)","i","globuff","show global buffer")
	set list("sys",$i(list))=$lb("new $namespace zn ""%SYS"" do ^LOCKTAB","i","","show lock table")
	set list("sys",$i(list))=$lb("new $namespace zn ""%SYS"" do ^SECURITY","i","","security utility")
	set list("sys",$i(list))=$lb("new $namespace zn ""%SYS"" do ^TASKMGR","i","","Task mgr utility")
	set list("sys",$i(list))=$lb("new $namespace zn ""%SYS"" write ##class(Security.System).ExportAll(""/backup/iris/SecureItem-"_$zu(110)_"-"_$p($zu(86),"*",2)_".xml"", .NumExported)","","")
	set list("sys",$i(list))=$lb("zn ""%SYS"" ","i","zn1","Go to namespace %SYS")
	set list("sys",$i(list))=$lb("w !,""Host "",$zu(110),!,##class(apptools.core.net).GetURI()_""/csp/sys/%25CSP.Portal.Home.zen"",!,""w ##class(apptools.core.net).GetIP()"",!,##class(apptools.core.net).GetIP(),! do ##class(apptools.core.net).GetIPext(,.IPexternal) zw IPexternal ","i","myip","Show my IP")
	;sql
	set list("sql",$i(list))=$lb("do $system.SQL.Shell()","i","sql","Shell SQL")
	set ecmd="do ##class(%ZAPM.ext.zpm).extcmd(%cmd)"
	;zmp
	set list("zpm",$i(list))=$lb("do ##class(%ZAPM.ext.zpm).LoadRegistrys()","i","zloginst","Install all repos do ##class(%ZAPM.ext.zpm).LoadRegistrys()")
	set list("zpm",$i(list))=$lb("do ##class(%ZAPM.ext.zpm).ShowLog()","i","zloglist","Show log list do ##class(%ZAPM.ext.zpm).ShowLog()")
	set list("zpm",$i(list))=$lb("zpm ""zn *"" ","i","zna","navigate to namespases")
	;set list("zpm",$i(list))=$lb("do ##class(%ZAPM.ext.zpm).SetColorScheme()","i","setcolor","set default color scheme")
	set list("zpm",$i(list))=$lb("do ##class(%ZAPM.ext.zpm).CreateDBNSAndLoad(""zppretty"")","a","","create new db,namespace and install module")
	set list("zpm",$i(list))=$lb(ecmd,"i","load","Extension Load module from repo")
	set list("zpm",$i(list))=$lb(ecmd,"i","help","Extension help command")
	set list("zpm",$i(list))=$lb(ecmd,"i","ver","Extension show version")
	set list("zpm",$i(list))=$lb(ecmd,"i","find","Show modules")
	set list("zpm",$i(list))=$lb(ecmd,"i","repo","Show repository")
	set list("zpm",$i(list))=$lb(ecmd,"i","upg","Upgrade modules in namespace")
	set list("zpm",$i(list))=$lb(ecmd,"i","info","Show more complete information about modules")
	;zapm
	set list("zapm",$i(list))=$lb("do ##class(%ZAPM.ext.code).ExportUDL()","i","export-zapm","export zapm project")
	set list("zapm",$i(list))=$lb(ecmd,"i","cpipe","Run host console command")

	set list("zapm",$i(list))=$lb("do ##class(%ZAPM.ext.util).cpipe(""ps -eo pid,ppid,%mem,%cpu,cmd --sort=-%mem | head"")","i","proc-max-mem","proc max memory")
	set list("zapm",$i(list))=$lb("do ##class(%ZAPM.ext.util).cpipe(""ps -eo pid,ppid,%mem,%cpu,cmd --sort=-%cpu | head"")","i","proc-max-cpu","proc max cpu")
	set list("zapm",$i(list))=$lb("do ##class(%ZAPM.ext.util).cpipe(""ps ax|grep iris"")","i","proc-iris","proc iris")

	set list("zapm",$i(list))=$lb(ecmd,"i","reg","Choice registrys")
	set list("zapm",$i(list))=$lb(ecmd,"i","task","Group work with all custom tasks")
	set list("zapm",$i(list))=$lb(ecmd,"i","log","View protocols")
	set list("zapm",$i(list))=$lb(ecmd,"i","pick","Pick modeles in global registry")
	set list("zapm",$i(list))=$lb(ecmd,"i","prod","Product handling, startup and shutdown information")
	set list("zapm",$i(list))=$lb(ecmd,"i","newdb","create new db,namespace and install module")
	set list("zapm",$i(list))=$lb(ecmd,"i","dbcreate","create new database and namespace and role")
	set list("zapm",$i(list))=$lb(ecmd,"a","dbdelete","delete database, namespace and role")
	;set list("zapm",$i(list))=$lb("write ##class(%ZAPM.ext.zpm).LoadFromRepo(""https://github.com/Vassil2010/iris-sms"")","","","Example Load module from repo")
	;set list("zapm",$i(list))=$lb("do ##class(%ZAPM.ext.zapp).addcmd(""new $namespace zn """"zpmshow"""" do ^zpmshow"",""zpm"",""i"",""zshow"",""Show a zpm modules with extention description"")","","","Example added command")
	set list("zapm",$i(list))=$lb(ecmd,"i","edz","navigator for zpm")
	set list("zapm",$i(list))=$lb(ecmd,"i","edit-zpm","navigator for zpm")
	set list("zapm",$i(list))=$lb(ecmd,"i","edg","globals edotor")
	set list("zapm",$i(list))=$lb(ecmd,"i","edit-glo","globals and lockals edotor")
	set list("zapm",$i(list))=$lb(ecmd,"i","edr","routine editor")
	set list("zapm",$i(list))=$lb(ecmd,"i","edit-rou","routine editor")
	set list("zapm",$i(list))=$lb(ecmd,"i","edf","navigator for file system")
	set list("zapm",$i(list))=$lb(ecmd,"i","edit-file","navigator for file system")
	set list("zapm",$i(list))=$lb(ecmd,"i","edt","navigator for tables")
	set list("zapm",$i(list))=$lb(ecmd,"i","eds","navigator for sql-queries")
	set list("zapm",$i(list))=$lb(ecmd,"i","edit-sql","navigator for sql-queries")
	set list("zapm",$i(list))=$lb(ecmd,"i","edj","navigator for jobs")
	set list("zapm",$i(list))=$lb(ecmd,"i","edit-job","navigator for jobs")
	set list("zapm",$i(list))=$lb(ecmd,"i","edl","Locktab navigator")
	set list("zapm",$i(list))=$lb(ecmd,"i","edit-lock","Locktab navigator")
	q $$$OK
}

ClassMethod TerminalPrompt(comm = "") As %String
{
	set del=$$$escGreen(">")
	set tp=##class(%SYSTEM.Process).TerminalPrompt()
	set prompt="zapm:"
	for i=1:1:$l(tp,",") {
		if $p(tp,",",i)=1 {	set prompt=prompt_$p($system,":")_del continue}
		elseif $p(tp,",",i)=2 {	set prompt=prompt_$namespace_del continue}
		elseif $p(tp,",",i)=3 {	set prompt=prompt_$p($system,":",2)_del continue}
		elseif $p(tp,",",i)=4 {	set prompt=prompt_$zt(+$p($h,",",2),1)_del continue}
		elseif $p(tp,",",i)=5 {	set prompt=prompt_$job_del continue}
		elseif $p(tp,",",i)=6 {	set prompt=prompt_$username_del continue}
		;i think for zapm shell 7 and 8 do not need to be implemented
	}
	quit prompt
}

/// do ##class(%ZAPM.ext.zapp).prompt("globuff")
ClassMethod prompt(comm = "") As %Status
{
	set comm=$ZStrip(comm,"<>WC")
	if comm="" write !,"Welcome to the Package Manager with addons Shell. "_##class(%ZAPM.ext.zpm).ver(),!,"Enter /q/quit to exit the shell. Enter ?/help to view available commands",!
	for {
		if comm="" {
			write !,..TerminalPrompt() 
			read cmd
			set cmd=$ZStrip(cmd,"<>WC")
		}
		else {
			set cmd=comm
		}
		if cmd="" {
			continue
		}
		elseif $lf($lb("q","Q",".","^","h","H",,"zpm","zapp"),cmd) {
			Quit
		}
		elseif cmd="zpm" {
			;quit ##class(%ZPM.PackageManager).Shell()
			;continue
		}
		elseif $$iszapmcmd($p(cmd," "),.command) { 
			;extention command
			set %cmd=cmd
			set yes=$lg(command,2)
			if $e(yes)="a" {
				write !!,"  ",$lg(command,1)_" ; "_$lg(command,4)
				write !,"     Are you sure ? [Y] " 
				read sure 
				if $e($zconvert(sure,"L"))'="y"  quit:cmd=comm   continue
				set yes="i"
			}
			if yes="i" {
				write !
				xecute $lg(command,1)
				do addhist(command,$lg(command,3),$lg(command,4))
			}
			quit:cmd=comm
			continue
		}
		elseif $$iszpmcmd($p(cmd," ")) { 
			;zpm command
			write !
			d ##class(%ZPM.PackageManager).Shell(cmd)
			do addhist(cmd)
			quit:cmd=comm
			continue
		}
		elseif $e(cmd,1,2)="??"||($e(cmd,1,4)="hist") {
			write !
			do ..history($p(cmd,$select(cmd["??":"??",1:"hist"),2,*)) 
			quit:cmd=comm
			continue
		}
		elseif $e(cmd,1)="?"||($e(cmd,1,3)="cmd") {
			write !
			do ..help($p(cmd,$select(cmd["?":"?",1:"cmd"),2,*)) 
			quit:cmd=comm
			continue
		}		
		elseif (cmd'=(+cmd)) {
			set %cmd=cmd
			try {
				write !
				xecute cmd
				do addhist(cmd)
			} catch ex {
   				write !,"Error "_$ze
   				do ..write("","? or ?text",$lb("Show help"),1)
			}
			quit:cmd=comm
			continue
		}
		elseif $d(%zapm(cmd),command) {
			set yes=$lg(command,2)
			if $e(yes)="a" {
				write !!,"  ",$lg(command,1)_" ; "_$lg(command,4)
				write !,"     Are you sure ? [Y] " 
				 read sure 
				 if $e($zconvert(sure,"L"))'="y" quit:cmd=comm  continue
				 set yes="i"
			}
			if yes="i" {
				write !,"Executing "_$lg(command,1),!
				xecute $lg(command,1) 
				do addhist(command,$lg(command,3),$lg(command,4))
				quit:cmd=comm
				continue
			}
			else {
				write !,$lg(command,1),!
				write !,"Show only"
			}
		}
		elseif '$data(%zapm(cmd)) {
				quit:cmd=comm
				continue			
		}
		else { 
			do ..help()
		}
	}
	if cmd="zpm" write ! quit ##class(%ZPM.PackageManager).Shell()
	quit $$$OK
addhist(cmd,namecmd="",desc="") ;add to history
	quit:cmd=+cmd
	quit:cmd=""
	set gn=..#GN
	if '$lv(cmd) s cmd=$lb(cmd,"a",namecmd,desc)
	set @gn@("cmd",cmd)=$GET(@gn@("cmd",cmd))+1
	set @gn@("cmd",cmd,"date")=$h
	quit 1
iszpmcmd(cmd) ;If is a zpm command
	if $lf(##class(%ZAPM.ext.zpm).cmdzpm(),cmd) q $$$OK
	quit 0
iszapmcmd(cmd,command) ;
	do ##class(%ZAPM.ext.commands).GetCmd("",cmd,.comman)
	if comman'="" set command=comman quit 1
	quit 0
}

/// hist 
/// do ##class(%ZAPM.ext.zapp).history("dark")
ClassMethod history(mask = "") As %Status
{
	set gn=..#GN
	set mask=$ZStrip(mask,"<>WC")
	if $e(mask,1,4)="-add" { //flag added Number_hist <name_cmd> description
		set num=$p($p(mask,"-add ",2,*)," ")
		if '$D(%zapm(num),cmd) write !,"number invalid" q $$$OK
		set name=$p($p(mask,"-add ",2,*)," ",2)
		set type=$p($p(mask,"-add ",2,*)," ",3)
		set desc=$p($p(mask,"-add ",2,*)," ",4,*)
		if name="" set @..#GN@("cmd",cmd,"nonrem")=$h write !,"added in list non-removable" q $$$OK
		do ##class(%ZAPM.ext.commands).GetCmd("",name,.comman)
		if comman'="" write !,"command name '"_name_"' already exist" q $$$OK
		if '$lf($lb("i","a","n"),type) write !,"command type '"_type_"' invalid" q $$$OK
		do ##class(%ZAPM.ext.zapp).addcmd($lg(cmd,1),"hist",type,name,desc) 
		write !,"added in list of commands" q $$$OK
	}
	if $e(mask,1,4)="-del" { //flag added Number_hist <name_cmd> description
		set days=$p($p(mask,"-del ",2,*)," ",1)
		if days'="" {
			set hor=$h-days
				,count=0
			do ..CreateHistArray(.list)
			set h="" for { set h=$o(list(h),1) q:h=""
				if h<hor {
					set cmd="" for { set cmd=$o(list(h,cmd)) q:cmd=""
						if '$D(@gn@("cmd",cmd,"nonrem")) KILL @gn@("cmd",cmd) set count=count+1
					}
				}
			}
			w !,"killed "_count
		}
		quit $$$OK
	}
	kill %zapm

	set cmd=""
		,num=0
	
	set order=$select($e(mask,1)="+":-1,1:1)
	if $e(mask,1)="-"||($e(mask,1)="+") set mask=$e(mask,2,*)
	do ..CreateHistArray(.list)
	set h="" for { set h=$o(list(h),order) q:h=""
		set cmd=""	for { set cmd=$Order(list(h,cmd)) q:cmd=""  do write($$$escBlue($zd(h,3))_" ") }
	}
	;for { set cmd=$Order(@gn@("cmd",cmd)) q:cmd=""  
	;do write() }
 quit $$$OK
write(date="")
	if mask'="",$zconvert(cmd,"L")'[mask quit
	set num=num+1
	set cmdline=$lg(cmd,1)
	if $D(@gn@("cmd",cmd,"nonrem")) set cmdline=$$$escRed(cmdline)
	write !,date_" "_num_"."_$$$escMagenta($lg(cmd,3))_" "_cmdline_$select($lg(cmd,4)="":"",1:" //")_$lg(cmd,4)
	set %zapm(num)=cmd
 quit
}

ClassMethod CreateHistArray(ByRef list) As %Status
{
	set gn=..#GN
	set cmd="" for {set cmd=$o(@gn@("cmd",cmd)) q:cmd=""  
	  if $D(@gn@("cmd",cmd,"date"),Hor) 
	  else  set Hor="100,1"
	  set list(Hor,cmd)=""
	}
	quit $$$OK
}

/// cmd 
/// do ##class(%ZAPM.ext.zapp).help("dark")
ClassMethod help(mask = "") As %Status
{
	set mask=$ZStrip(mask,"<>WC")
	if $e(mask,1,5)="-init" { //flags init
		do ##class(%ZAPM.ext.zapp).init(1) q $$$OK
	}
	//#define escRed(%t) $Select($$$escBg=0:%t,1:$c(27)_"[1;31;"_$$$escBg_"m"_%t_$$$escClear)
	kill %zapm
	write !,$$$escMagenta("Extending ZPM commands, the standard ZPM commands also work as from zpm shell.")
		,!,"Enter the command "_$$$escRed("number")_" or "_$$$escMagenta("name")_" to execute."
	do ##class(%ZAPM.ext.commands).GetList(.list)
	set i=""
	for {
		set i=$Order(list(i)) q:i=""
		set ii="" 
		for { 
			set ii=$O(list(i,ii),1,val) q:ii=""
			set vall=$zconvert($lts(val),"L")
			set namecmd=$lg(val,3)
			if vall[").extcmd(%cmd)" continue
			if mask'="" {
				if vall[mask set %zapm($i(%zapm))=val do ..write(i,%zapm,%zapm(%zapm))
			}
			else {
				set %zapm($i(%zapm))=val do ..write(i,%zapm,%zapm(%zapm))
			}
		}
	}
	do ..write("","cmd or cmd context",$lb("Show help"),1)
	do ..write("","hist or hist context",$lb("Show history"),1)
	write !,$$$escBlue("A")_"-Ask before launch, "_$$$escBlue("I")_"-Launch immediately, "_$$$escBlue("N")_"-Do not run"
	q $$$OK
}

ClassMethod write(part, num, cmd, noprompt = 0) As %Status
{
	;if part="" {write !	}
	if part'=$g(%partit) { 
		set %partit=part
		w !,$$$escGreen(part)	
	}
	set prompt=$lg(cmd,2)
	;if 'noprompt set prompt=" //"_$$$escBlue($s(prompt="y":"Ask before launch",prompt="n":"Launch immediately",1:"Do not run"))
	if 'noprompt set prompt=" //"_$$$escBlue($s(prompt="a":"A",prompt="i":"I",prompt="n":"N",1:"N"))
	write !,num_"."_$$$escMagenta($lg(cmd,3))_" "_$lg(cmd,1)_prompt_" "_$lg(cmd,4)
 quit $$$OK
}

/// do ##class(%ZAPM.ext.zapp).addcmd("new $namespace zn ""zpmshow"" do ^zpmshow","zpm","i","zshow","Show a zpm modules with extention description")
ClassMethod addcmd(cmd = "", partion = "", moderun = "", namecmd = "", description = "", noprompt = "") As %Status
{
	if partion="" set partion="other"
	do ##class(%ZAPM.ext.commands).GetCmd("",namecmd,.comman)
	if comman'="",'noprompt {
		
		write !,"command name '"_namecmd_"' already exist" 
		q $$$OK
	}
	set st=##class(%ZAPM.ext.commands).AddUpdate(cmd,namecmd,partion,moderun,description)
	if 'st write $System.Status.GetErrorText(st) quit st
	else  write !,"added"
	quit $$$OK
}

ClassMethod log(extcmd) As %Status
{
	new $namespace
	zn "%SYS"
	;write extcmd,!
	if (extcmd)="mess " quit ..logmess()
	if $p(extcmd,"mess ",2)'="" quit ..logmess($p($p(extcmd,"mess ",2)," ",1))
	quit ..logmess()
	;quit $$$OK
}

ClassMethod logmess(extcmd = "") As %Status
{
	set msg=$System.Util.ManagerDirectory()_"messages.log"
	if '$$$isWINDOWS {
		set num=20,cmd="tail -n "_num_" "_msg
		if extcmd>20 set num=+extcmd,cmd="tail -n "_num_" "_msg
		if extcmd, extcmd<4 set cmd="more "_msg_" | grep -E ') 1 \[|) 2 \[|) 3 \['"
		write !,cmd
		do ##class(%ZAPM.ext.util).cpipe(cmd)
	}
	else {
		set f=##class(%File).%New(msg)
 		set st=f.Open("RSU")
 		if 'st do f.%Close() Quit st
 		while 'f.AtEnd {
     		set str = f.ReadLine()
     		write !,str
  		}
 		do f.%Close()
	}
	quit $$$OK
}

/// do ##class(%ZAPM.ext.zapp).writerow("test",",1,.,40")
/// "test" - text in columns
/// "33,1,.,40" - formatting options
/// 33 - Yellow - escape sequence color code
/// 1  - left alignment  0 - right alignment  2 - center
/// .  - character padding
/// 40 - column width
ClassMethod writerow(arg...) As %Status
{
	set res=""
	for i=1:2 { quit:'$d(arg(i))
		set color=$p(arg(i+1),",")
		if 'color set color=$$$Default
		set val=arg(i)
		set aligh=$p(arg(i+1),",",2)
		set space=$p(arg(i+1),",",3)
		set width=+$p(arg(i+1),",",4)
		if width<$l(val) s val=$e(val,1,width)
		if aligh=1 {
			set res=res_$$$FormattedLine(color,val)_$tr($j("",width-$l(val))," ",space)_" "
		}
		elseif aligh=2 { //center
			set w1=(width-$l(val))\2
			set w2=(width-$l(val))-w1
			set res=res_$tr($j("",w1)," ",space)_$$$FormattedLine(color,val)_$tr($j("",w2)," ",space)_" "
		}
		else {
			set res=res_$tr($j("",width-$l(val))," ",space)_$$$FormattedLine(color,val)_" "
		}
	}
	quit res
}

/// do ##class(%ZAPM.ext.zapp).UpdateLanguageExtensions()
ClassMethod UpdateLanguageExtensionsOne(RoutineName As %String, pTestOnly As %Boolean = 0, Output pFound As %Boolean = 0, ByRef tGenLines) As %Status
{
	#def1arg STARTTAGQ " ;Generated by %ZAPM.ext.zapp: Start"
	#def1arg ENDTAGQ " ;Generated by %ZAPM.ext.zapp: End"
	#def1arg STARTTAG ##Expression($$$STARTTAGQ)
	#def1arg ENDTAG ##Expression($$$ENDTAGQ)
	Set tRtn = ##class(%Routine).%New(RoutineName)
	If ##class(%Routine).Exists(RoutineName) {
		Set tEnded = 1
		While 'tRtn.AtEnd {
			Set tLine = tRtn.ReadLine()
			If (tLine = $$$STARTTAGQ) {
				// Read through the ending tag.
				While ('tRtn.AtEnd) && (tRtn.ReadLine() '= $$$ENDTAGQ) {}
				
				// Generate the lines.
				Set pFound = 1
				For i=1:1:tGenLines {
					Set tRtnLines($i(tRtnLines)) = tGenLines(i)
				}
			} Else {
				Set tIsZAPM = ($ZConvert($Extract(tLine,1,4),"U") = "ZAPM(")
				If tIsZAPM {
					Set pFound = 1
					Set tEnded = 0
					Set tRtnLines($i(tRtnLines)) = $$$STARTTAGQ
				}
				If '(tIsZAPM || tEnded) {
					If ($ZStrip($Extract(tLine),"*W") '= "") {
						Set tRtnLines($i(tRtnLines)) = $$$ENDTAGQ
						Set tEnded = 1
					}
				}
				Set tRtnLines($i(tRtnLines)) = tLine
			}
		}
		If 'tEnded {
			Set tRtnLines($i(tRtnLines)) = $$$ENDTAGQ
		} ElseIf 'pFound {
			For i=1:1:tGenLines {
				Set tRtnLines($i(tRtnLines)) = tGenLines(i)
			}
		}
	} Else {
		Merge tRtnLines = tGenLines
	}
	If (pTestOnly) {
		Quit $$$OK
	}
	Do tRtn.Clear()
	For i=1:1:tRtnLines {
		Do tRtn.WriteLine(tRtnLines(i))
	}
	$$$ThrowOnError(tRtn.Save())
	$$$ThrowOnError(tRtn.Compile())
	Quit $$$OK
}

ClassMethod UpdateLanguageExtensions(pVerbose As %Boolean = 0, pTestOnly As %Boolean = 0, Output pFound As %Boolean = 0) As %Status
{
	#def1arg STARTTAGQ " ;Generated by %ZAPM.ext.zapp: Start"
	#def1arg ENDTAGQ " ;Generated by %ZAPM.ext.zapp: End"
	#def1arg STARTTAG ##Expression($$$STARTTAGQ)
	#def1arg ENDTAG ##Expression($$$ENDTAGQ)

	Set tSC = $$$OK
	Set tInitTLevel = $TLevel
	Try {
		TSTART
		// Get routine lines to generate
		Set tOffset = 0
		Set tStarted = 0
		For {
			Set tLineName = "zUpdateLanguageExtensions"_"+"_$i(tOffset)_"^"_$ZName
			Set tExtLine = $Text(@(tLineName))
			If (tExtLine=$$$STARTTAGQ) {
				Set tStarted = 1
			}
			If (tStarted) {
				Set tGenLines($i(tGenLines)) = tExtLine
			}
			Quit:(tExtLine=$$$ENDTAGQ)
			Quit:(tExtLine="")
		}

		If '$Data(tGenLines) {
			$$$ThrowStatus($$$ERROR($$$GeneralError,"Could not find %ZLANGC00 routine contents in "_$classname()))
		}
		Do ..UpdateLanguageExtensionsOne("%ZLANGC00.MAC", pTestOnly,.pFound,.tGenLines)
		Quit:pTestOnly
		Set i="" 
		For { set i=$Order(tGenLines(i),1,tStr) Quit:i=""
			If tStr[" Do ##class" Set tGenLines(i)=$Replace($Replace(tStr," Quit","")," Do "," Quit ") Quit
		}
		Do ..UpdateLanguageExtensionsOne("%ZLANGF00.MAC", pTestOnly,.pFound,.tGenLines)
		TCOMMIT
	} Catch e {
		Set tSC = e.AsStatus()
	}
	While ($TLevel > tInitTLevel) {
		TROLLBACK 1
	}
	Quit tSC
#; These are the actual contents of %ZLANGC00 (to be added/updated)
$$$STARTTAG
ZAPM(pArgs...) Do ##class(%ZAPM.ext.zapp).prompt(pArgs...) Quit
$$$ENDTAG
#; Need an extra line down here to avoid the end bracket being on the same line as $$$ENDTAG - a comment is just fine.
}

}

