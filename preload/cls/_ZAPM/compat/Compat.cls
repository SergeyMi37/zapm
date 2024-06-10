Class %ZAPM.compat.Compat
{
/// Will be invoked after Reload and before Compile
ClassMethod CheckCompatibility()
{
    Write !, $c(9)_"Checking namespace compatibility..."
    If $Namespace '= "%SYS" {
        Throw ..GetError("This application must be installed in the ""%SYS"" namespace")
    }
    Write " OK!"
    // Some classes have been renamed in IPM (v0.9+). 
    // The following code will change the class definition to the old class name for backward compatibility
    Write !, $c(9)_"Checking package manager version compatibility..."
    Set oldClass = "%ZPM.PackageManager.Developer.Lifecycle.Module"
    Set newClass = "%IPM.Lifecycle.Module"
    If ##class(%Dictionary.ClassDefinition).%ExistsId(newClass) {
       Return
    } ElseIf '##class(%Dictionary.ClassDefinition).%ExistsId(oldClass) {
        Throw ..GetError("Neither "_oldClass_" nor "_newClass_" exists. Please check your installation of zpm/ipm")
    }
    Set classname = "%ZAPM.ext.Lifecycle"
    Set cls = ##class(%Dictionary.ClassDefinition).%OpenId(classname)
    If '$IsObject(cls) {
        Throw ..GetError("Class "_ classname _" does not exist. Please check your src folder")
    }
    Set cls.Super = oldClass
    $$$ThrowOnError(cls.%Save())
    Write " OK!"
}

ClassMethod GetError(msg As %String) As %Exception.General [ Internal, Private ]
{
    Write !, "ERROR: ", msg, !
    Return ##class(%Exception.General).%New(msg)
}

}