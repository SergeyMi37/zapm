Class %ZAPM.ext.Lifecycle Extends %ZPM.PackageManager.Developer.Lifecycle.Module
{

ClassMethod RunOnLoad() [ CodeMode = objectgenerator ]
{
	
	Set sc = $$$OK
	Try {
		Write !,"Doing ...RunOnLoad",!,$Namespace,!,$zv
		set ^tmp=$g(^tmp)_" RunOnLoad"
		w
	} Catch e {
		Set sc = e.AsStatus()
	}
	Return sc
}


Method %Activate(ByRef pParams) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##super(.pParams)
		If $$$ISERR(tSC) {
			Quit
		}
		
		Set tRootDirectory = $Get(pParams("RootDirectory"))
		Set tVerbose = 1 ;$Get(pParams("Verbose"),0)
		Write:tVerbose !,"Doing ...",!,$namespace,!,$zv
		set ^tmp=12 zt "zaaa"
		;Set tSC = ##class(PMML.Interop.Utils).GenerateOperation("Demo.SampleModels.GolfModel")
		;$$$ThrowOnError(tSC)
		;#; do ##class(HoleFoods.Utils).BuildData()
		;Set tSC = $system.OBJ.ImportDir(tRootDirectory _ "Demo", , "ck", , 1)
		;$$$ThrowOnError(tSC)
		Write:tVerbose !,"Done."
	} Catch e {
		Set tSC = e.AsStatus()
	}
	Quit tSC
}

}

