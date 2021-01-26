Include %ZAPM.ext.Common

/// apptools favourite commands in %ZLANGC00.mac
/// ZAPP(pArgs...) Do ##class(%ZAPM.ext.zapp).prompt(pArgs...) 
/// try { do ##class(%ZAPM.ext.zapp).UpdateLanguageExtensions() } catch ex {}
Class %ZAPM.ext.zapp [ Abstract ]
{

/// Storage of work history
Parameter GN = "^%ZAPM.hist";

/// do ##class(%ZAPM.ext.zapp).init()
ClassMethod init() As %Status
{
	new $namespace
	set $namespace="%sys"
	do ##class(%ZAPM.ext.zapp).UpdateLanguageExtensions()
	do ##class(%ZPM.PackageManager).UpdateLanguageExtensions()
	do ..favourite(.list)
	;merge list=@..#GN@("cmd")
	set i=""
	for {
		set i=$Order(list(i)) q:i=""
		set ii="" 
		for { 
			set ii=$Order(list(i,ii),1,val) q:ii=""
			do ##class(%ZAPM.ext.commands).AddUpdate($lg(val,1),$lg(val,3),i,$lg(val,2),$lg(val,4))
		}
	}
	do ##class(%ZAPM.ext.zpm).SetColorScheme()
	write !,"To work in the shell, enter 'zapm' in the terminal, and then 'cmd' or '?' "
	quit $$$OK
}

ClassMethod TerminalPrompt(comm = "") As %String
{
	set del=$$$escRed(">")
	set tp=##class(%SYSTEM.Process).TerminalPrompt()
	set prompt=$$$escRed("<")
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
	for {
		if comm="" {
			write !,..TerminalPrompt() 
			read cmd 
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
			write !
			xecute $lg(command,1)
			do addhist(command,$lg(command,3),$lg(command,4))
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
				 continue:$e($zconvert(sure,"L"))'="y"
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
	quit 1
iszpmcmd(cmd) ;If is a zpm command
	if $lf(##class(%ZAPM.ext.zpm).cmdzpm(),cmd) q $$$OK
	quit 0
iszapmcmd(cmd,command) ;
	do ##class(%ZAPM.ext.commands).GetCmd("",cmd,.comman)
	if comman'="" set command=comman quit 1
	quit 0
}

/// do ##class(%ZAPM.ext.zapp).history("dark")
ClassMethod history(mask = "") As %Status
{
	set mask=$ZStrip(mask,"<>WC")
	kill %zapm
	set gn=..#GN
	set cmd=""
		,num=0
	for {
		set cmd=$Order(@gn@("cmd",cmd)) q:cmd=""
		if mask'="",$zconvert(cmd,"L")'[mask continue
		set num=num+1
		write !,$$$escRed(num)_"."_$$$escViolet($lg(cmd,3))_" "_$lg(cmd,1)_" //"_$lg(cmd,4)
		set %zapm(num)=cmd
	}
}

/// do ##class(%ZAPM.ext.zapp).help("dark")
ClassMethod help(mask = "") As %Status
{
	set mask=$ZStrip(mask,"<>WC")
	#define escRed(%t) $Select($$$escBg=0:%t,1:$c(27)_"[1;31;"_$$$escBg_"m"_%t_$$$escClear)
	kill %zapm
	write !,$$$escViolet("Extending ZPM commands, the standard ZPM commands also work as from zpm shell.")
		,!,"Enter the command "_$$$escRed("number")_" or "_$$$escViolet("name")_" to execute."
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
	;do ..write("","Q,q,^,h,H",$lb("Quit"),1)
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
	write !,$$$escRed(num)_"."_$$$escViolet($lg(cmd,3))_" "_$lg(cmd,1)_prompt_" "_$lg(cmd,4)
 quit $$$OK
}

/// do ##class(%ZAPM.ext.zapp).favourite(.list)
ClassMethod favourite(ByRef list) As %Status
{
	;sys		           execute code     prompt:yes,no,never=""  name-cmd   description
	set list("sys",$i(list))=$lb("do 1^%SS","i",                    "sys",     "system status")
	set list("sys",$i(list))=$lb("new $namespace zn ""%SYS"" do ^JOBEXAM","a","","job examing")
	set list("sys",$i(list))=$lb("new $namespace zn ""%SYS"" do display^GLOBUFF(25)","i","globuff","show global buffer")
	set list("sys",$i(list))=$lb("new $namespace zn ""%SYS"" do ^LOCKTAB","i","","show lock table")
	set list("sys",$i(list))=$lb("new $namespace zn ""%SYS"" do ^SECURITY","i","","security utility")
	set list("sys",$i(list))=$lb("new $namespace zn ""%SYS"" write ##class(Security.System).ExportAll(""/backup/iris/SecureItem-"_$zu(110)_"-"_$p($zu(86),"*",2)_".xml"", .NumExported)","","")
	;zmp
	set list("zpm",$i(list))=$lb("zpm ""zn *"" ","i","zna","navigate to namespases")
	set list("zpm",$i(list))=$lb("do ##class(%ZAPM.ext.zpm).SetColorScheme()","i","setcolor","set default color scheme")
	set list("zpm",$i(list))=$lb("do ##class(%ZAPM.ext.zpm).CreateDBNSAndLoad(""zppretty"")","a","","create new db,namespace and install module")
	set list("zpm",$i(list))=$lb("do ##class(%ZAPM.ext.zpm).extcmd(%cmd)","i","newdb","create new db,namespace and install module")
	set list("zpm",$i(list))=$lb("write ##class(%ZAPM.ext.zpm).LoadFromRepo(""https://github.com/Vassil2010/iris-sms"")","","","Example Load module from repo")
	set list("zpm",$i(list))=$lb("do ##class(%ZAPM.ext.zpm).extcmd(%cmd)","i","load","Extension Load module from repo")
	set list("zpm",$i(list))=$lb("do ##class(%ZAPM.ext.zpm).extcmd(%cmd)","i","help","Extension help command")
	set list("zpm",$i(list))=$lb("do ##class(%ZAPM.ext.zpm).extcmd(%cmd)","i","ver","Extension show version")
	;zapm
	;set list("zapm",$i(list))=$lb("do ##class(%ZAPM.ext.zapp).addcmd(""new $namespace zn """"zpmshow"""" do ^zpmshow"",""zapp"",""i"",""zshow"",""Show a zpm modules with extention description"")","n","addzshow","")
	
	q $$$OK
}

/// do ##class(%ZAPM.ext.zapp).addcmd("new $namespace zn ""zpmshow"" do ^zpmshow","zpm","i","zshow","Show a zpm modules with extention description")
ClassMethod addcmd(cmd = "", partion = "", moderun = "", namecmd = "", description = "") As %Status
{
	if partion="" set partion="other"
	;set @..#GN@("cmd",partion,$i(@..#GN@("cmd")))=$lb(cmd,moderun,namecmd,description)
	set st=##class(%ZAPM.ext.commands).AddUpdate(cmd,namecmd,partion,moderun,description)
	if 'st write $System.Status.GetErrorText(st) quit st
	else  write !,"added"
	quit $$$OK
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
		Quit
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

