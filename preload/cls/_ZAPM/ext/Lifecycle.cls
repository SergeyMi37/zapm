Class %ZAPM.ext.Lifecycle Extends %ZPM.PackageManager.Developer.Lifecycle.Module
{

ClassMethod RunOnLoad() [ CodeMode = objectgenerator ]
{
	
	Set sc = $$$OK
	Try {
		;Write !,"Doing ...RunOnLoad",!,$Namespace,!,$zv
		;$$$ThrowOnError($$$ERROR($$$GeneralError,"some error"))
	} Catch e {
		Set sc = e.AsStatus()
	}
	Return sc
}

}

