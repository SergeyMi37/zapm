Class %ZAPM.ext.Lifecycle Extends %ZPM.PackageManager.Developer.Lifecycle.Module
{

ClassMethod RunOnLoad() [ CodeMode = objectgenerator ]
{
	
	Set sc = $$$OK
	Try {
		if $Namespace'="%SYS" {
			$$$ThrowOnError($$$ERROR($$$GeneralError,"This application must be installed in the ""%SYS"" namespace "))
		}
		;$$$ThrowOnError($$$ERROR($$$GeneralError,"some error"))
	} Catch e {
		Set sc = e.AsStatus()
	}
	Return sc
}

}

