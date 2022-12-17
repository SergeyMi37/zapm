Class %ZAPM.ext.preload Extends %ZPM.PackageManager.Developer.Lifecycle.Module
{

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
