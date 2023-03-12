Include %ZAPM.ext.Common

Class %ZAPM.ext.commands Extends %Persistent
{

/// Command
Property Command As %String(MAXLEN = "");

/// Commands name
Property CommandName As %String(MAXLEN = "");

/// Partition 
Property Partition As %String(MAXLEN = "");

/// Description
Property Description As %String(MAXLEN = "");

/// Prompt (yes, no, never run - show only)
Property Prompt As %String(MAXLEN = "");

/// Namespace
Property Namespace As %String(MAXLEN = "");

/// Date and time
Property TimeStamp As %TimeStamp [ InitialExpression = {$zdt($h, 3, 1)} ];

Index idxCommand On Command;

Index idxCommandName On CommandName;

/// Get List commands
/// do ##class(%ZAPM.ext.commands).GetList(.list)
/// do $CLASSMETHOD("%ZAPM.ext.commands", "%KillExtent")
ClassMethod GetList(ByRef list, Command As %String = "", CommandName = "", Partition = "", Prompt = "", Description = "", Namespace = "")
{
	Set tQuery = "select * from %ZAPM_ext.commands where (1=1) "
	Set tRes = ##class(%SQL.Statement).%ExecDirect(,tQuery)
	
	If (tRes.%SQLCODE < 0) {
		Throw ##class(%Exception.SQL).CreateFromSQLCODE(tRes.%SQLCODE,tRes.%Message)
	}
	While tRes.%Next(.tSC) {
		$$$ThrowOnError(tSC)
		set part=tRes.%Get("Partition")
		if part="" set part="Other"
		Set list(part,$i(list))=$lb(tRes.%Get("Command"),tRes.%Get("Prompt"),tRes.%Get("CommandName"),tRes.%Get("Description"),tRes.%Get("Partition"))
	}
}

/// Get command
/// do ##class(%ZAPM.ext.commands).GetCmd("do ##class(%ZAPM.ext.zpm).extcmd(%cmd)","help",.cmd,.id) 
ClassMethod GetCmd(Command = "", CommandName = "", cmd, id) As %Status
{
	Set tQuery = "select * from %ZAPM_ext.commands where (1=1) "
	if CommandName="" set tQuery=tQuery_" and CommandName is null "
	else  set tQuery=tQuery_" and CommandName='"_CommandName_"'"
	if Command'="" set tQuery=tQuery_" and Command='"_Command_"'"
	Set tRes = ##class(%SQL.Statement).%ExecDirect(,tQuery)
	set cmd="",id=""
	If (tRes.%SQLCODE < 0) {
		Throw ##class(%Exception.SQL).CreateFromSQLCODE(tRes.%SQLCODE,tRes.%Message)
	}
	While tRes.%Next(.tSC) {
		$$$ThrowOnError(tSC)
		Set cmd=$lb(tRes.%Get("Command"),tRes.%Get("Prompt"),tRes.%Get("CommandName"),tRes.%Get("Description"),tRes.%Get("Partition"))
		set id=tRes.%Get("ID")
	}
	quit $$$OK
}

/// Delete command
/// write $System.Status.GetErrorText(##class(%ZAPM.ext.commands).Delete("job"))
ClassMethod Delete(Command)
{
	do ##class(%ZAPM.ext.commands).GetCmd(,Command,.cmd,.id)
	if $g(id) {
		set obj=..%OpenId(id)
		if $iso(obj) {
			Set tQuery = "delete from %ZAPM_ext.commands where CommandName = '"_Command_"'"
			Set tRes = ##class(%SQL.Statement).%ExecDirect(,tQuery)
			quit tRes
		}
	}
	quit $$$ERROR($$$GeneralError,"Command is udefined")
}

/// Add new command
/// write $System.Status.GetErrorText(##class(%ZAPM.ext.commands).AddUpdate("new $namespace zn ""zpmshow"" do ^zpmshow","zshow","zpm","n","Show a zpm modules with extention description"))
ClassMethod AddUpdate(Command As %String = "", CommandName = "", Partition = "", moderun = "", Description = "", Namespace = "")
{
	#dim obj As %ZAPM.ext.commands = ""
	Set tQuery = "select * from %ZAPM_ext.commands where (1=1) "
	if Command="" $$$ThrowOnError($$$ERROR($$$GeneralError,"Command is empty"))
	do ..GetCmd(Command,CommandName,.cmd,.id)
	;w !,Command,!,CommandName,!,"id = "_$g(id)
	if cmd'="" set obj=..%OpenId(id)
	if '$iso(obj) Set obj = ..%New()
	set obj.Command=Command
	set obj.CommandName=CommandName
	set obj.Partition=Partition
	set obj.Description=Description
	set obj.Prompt=$zconvert($e(moderun,1),"L")
	set obj.Namespace=Namespace
	quit obj.%Save()
}

Storage Default
{
<Data name="commandsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Command</Value>
</Value>
<Value name="3">
<Value>CommandName</Value>
</Value>
<Value name="4">
<Value>Partition</Value>
</Value>
<Value name="5">
<Value>Namespace</Value>
</Value>
<Value name="6">
<Value>TimeStamp</Value>
</Value>
<Value name="7">
<Value>Prompt</Value>
</Value>
<Value name="8">
<Value>Description</Value>
</Value>
</Data>
<DataLocation>^%ZAPM.ext.commandsD</DataLocation>
<DefaultData>commandsDefaultData</DefaultData>
<IdLocation>^%ZAPM.ext.commandsD</IdLocation>
<IndexLocation>^%ZAPM.ext.commandsI</IndexLocation>
<StreamLocation>^%ZAPM.ext.commandsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

