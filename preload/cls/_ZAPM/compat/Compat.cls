Class %ZAPM.compat.Compat
{
/// Will be invoked after Reload and before Compile
ClassMethod CheckCompatibility()
{
    If $Namespace '= "%SYS" {
        Throw ##class(%Exception.General).%New("This application must be installed in the ""%SYS"" namespace ")
    }
    // Some classes have been renamed in IPM (v0.9+). 
    // The following code will change the class definition to the old class name for backward compatibility
    Set oldClass = "%ZPM.PackageManager.Developer.Lifecycle.Module"
    Set newClass = "%IPM.Lifecycle.Module"
    if ##class(%Dictionary.ClassDefinition).%ExistsId(newClass) {
       Return
    } ElseIf '##class(%Dictionary.ClassDefinition).%ExistsId(oldClass) {
        Throw ##class(%Exception.General).%New("Neither "_oldClass_" nor "_newClass_" exists. Please check your installation of zpm/ipm")
    }
    set classname = "%zapm.ext.Lifecycle"
    set cls = ##class(%Dictionary.ClassDefinition).%OpenId(classname)
    if '$IsObject(cls) {
        Throw ##class(%Exception.General).%New("Class "_ classname _" does not exist. Please check your src folder")
    }
    set cls.super = oldClass
}

}