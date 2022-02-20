/// Utility for creating and deleting databases with one command 
/// Create DataBase and Namespace with CSP, REST application 
/// Forked from https://openexchange.intersystems.com/package/isc-generate-db
/// 
/// Added resource and role creation for the database. (Many modules ZPM require MatchRoles=":{$dbrole}")
/// Added deletion of DataBases, role resources and Namespace.
/// Adding rest application is optional.
/// 
/// example:
/// write $System.Status.GetErrorText(##class(%ZAPM.ext.database).CreateDBNS("TESTDB2"))
/// write $System.Status.GetErrorText(##class(%ZAPM.ext.database).DeleteDBNS("TESTDB2"))
/// create db and namespace without resource and role
/// write $System.Status.GetErrorText(##class(%ZPM.PackageManager.Developer.UnitTest.Utils).CreateNamespace("testdb14"))
/// write $System.Status.GetErrorText(##class(%ZPM.PackageManager.Developer.UnitTest.Utils).DeleteNamespace("testdb14"))
Class %ZAPM.ext.database [ Abstract ]
{

Parameter LIBRARY = {$Select($Select($ZVersion["IRIS":1,1:0):"IRISLIB",1:"CACHELIB")};

Parameter SYSGLOBALS = {$Select($Select($ZVersion["IRIS":1,1:0):"IRISSYS",1:"CACHESYS")};

Parameter TEMPGLOBALS = {$Select($Select($ZVersion["IRIS":1,1:0):"IRISTEMP",1:"CACHETEMP")};

Parameter DATABASENAME = {$Select($Select($ZVersion["IRIS":1,1:0):"IRIS.DAT",1:"CACHE.DAT")};

ClassMethod Init() As %Status
{
	write !,"Creating and deleting db, namespace, resource and role with one command"
	write !,"example:"
	write !,"write $System.Status.GetErrorText(##class(appmsw.util.database).CreateDBNS(""TESTDB2""))"
	write !,"write $System.Status.GetErrorText(##class(appmsw.util.database).DeleteDBNS(""TESTDB2""))",!
	quit $$$OK
}

/// write ##class(%ZAPM.ext.database).CreateDBNS("NEWNS")
ClassMethod CreateDBNS(pNamespace As %String, pCodeData As %Boolean = 0, pPathDataset As %String = "", pInterOperability As %Boolean = 1, pREST As %String = "") As %Status
{
	set pNamespace=$ZCONVERT(pNamespace,"L")
	quit ..Install(pNamespace, pCodeData, pPathDataset, pInterOperability, pREST)
}

ClassMethod Install(pNamespace As %String, pCodeData As %Boolean = 1, pPathDataset As %String = "", pInterOperability As %Boolean = 0, pREST As %String = "") As %Status
{
    Set sc = $$$OK
    Try {
        Set sc = $$$ADDSC(sc,..CreateDatabase(pNamespace, pCodeData, pPathDataset)) quit:$$$ISERR(sc)
        Set sc = $$$ADDSC(sc,..CreateNamespace(pNamespace, pCodeData, pInterOperability, pREST)) quit:$$$ISERR(sc)
    }
    Catch (err) {
        Set sc = $$$ADDSC(sc,err.AsStatus())
    }
    Return sc
}

/// Create new database directory
ClassMethod CreateDatabase(pNamespace As %String, pCodeData As %Boolean, pPathDataset As %String = "") As %Status [ Private ]
{
	set CurrNS=$Namespace
    New $Namespace
    Set $Namespace = "%SYS"
    Set sc = $$$OK
    Try {
        Set dbList = $Listbuild("")
        Set:(pCodeData = $$$YES) dbList= $Listbuild("-CODE","-DATA") 

        For i = 1:1:$Listlength(dbList) {
            Set dbSuffix = $Listget(dbList,i)
            If (pPathDataset '= "") {
                Set directory = pPathDataset_$Case($$$isWINDOWS,1:"\",:"/")_pNamespace_dbSuffix
            }
            Else {
                Set directory = ..GetDatabaseDirectory(pNamespace_dbSuffix)
            }

            #; create a new directory if does not exist
            If '..CheckDatabaseDirExists(directory) {
                Set directory = $ZStrip(directory,"<>W")
                Set sc = $$$ADDSC(sc,##class(%File).CreateDirectoryChain(directory))
                If $$$ISERR(sc) {
                    Set msg = directory_": Could not create this directory. Please check the directory and try again."
                    Set sc = $$$ADDSC(sc,$$$ERROR($$$GeneralError,msg))				
                }
            }
            Else {
                #; abort if database is already created
                If ..CheckDatabaseExists(directory) {
                    Set msg = directory_": Database already existent in this directory. Please check the directory and try again."
                    Set sc = $$$ADDSC(sc,$$$ERROR($$$GeneralError,msg))
                }
            }
            Quit:$$$ISERR(sc)

            #; create new Resource
            Set dbName = pNamespace_dbSuffix
            set $Namespace=CurrNS
            Set sc = $$$ADDSC(sc,..CreateRole($ZCONVERT(dbName,"U")))
            Quit:$$$ISERR(sc)
            Set $Namespace = "%SYS"
            
            #; create new database
            Write "Creating Database "_dbName_"... "
            Set size = 1
            Set blockSize = 8192
            Set properties("Directory") = directory
            Set journalState = 1
            Set sc = $$$ADDSC(sc,##class(SYS.Database).CreateDatabase(directory,size,blockSize,0,"%DB_"_dbName,journalState,"",""))
            Quit:$$$ISERR(sc)

            #; Handle if we have dismounted then deleted the database at the O/S level,
            #; but the CPF entry still exists with the same directory, then recreate the DB only
            If ##class(Config.Databases).Exists(dbName,.obj) {
                If obj.Directory '= ##class(%File).ComputeFullDBDir(directory) {
                    Set sc = $$$ADDSC(sc,##Class(Config.Databases).Create(dbName,.properties))
                    Quit:$$$ISERR(sc)
                }
            }
            Else {
                Set sc = $$$ADDSC(sc,##Class(Config.Databases).Create(dbName,.properties))
                Quit:$$$ISERR(sc)
            }
            Write "done!",!
        }
    }
    Catch (err) {
        Set sc = $$$ADDSC(sc,err.AsStatus())
    }
    Return sc
}

/// Create new Role
/// w $system.Status.GetErrorText(##class(%ZAPM.ext.database).CreateRole("SWAGGERUI-CODE"))
ClassMethod CreateRole(dbName As %String) As %Status
{
   ;create new role
   New $Namespace
   Set $Namespace = "%SYS"
   Set sc = $$$OK
   s nameR="%DB_"_dbName,desc="Role for "_nameR 
	s pResources=nameR_":RW" 
	if '##class(Security.Resources).Exists(nameR) {
		Set sc = $$$ADDSC(sc,##class(Security.Resources).Create(nameR,"Resources for "_nameR,"RW"))
		Quit:$$$ISERR(sc) sc
	}
	s pRolesGranted=""
	if '##class(Security.Roles).Exists(nameR) {
		Set sc = $$$ADDSC(sc,##class(Security.Roles).Create(nameR,desc,pResources,pRolesGranted))
		Quit:$$$ISERR(sc) sc
		w !,"Create new role "_nameR
	}
	Return sc
}

/// Create new Resource
/// w $system.Status.GetErrorText(##class(%ZAPM.ext.database).CreateResource("DSW-DATA"))
ClassMethod CreateResource(dbName As %String, Permiss As %String = "RW") As %Status
{
   ;create new resource
   New $Namespace
   Set $Namespace = "%SYS"
    Set sc = $$$OK
   s nameR="%DB_"_dbName,desc="Resource for "_nameR 
	if '##class(Security.Resources).Exists(nameR) {
		Set sc = $$$ADDSC(sc,##class(Security.Resources).Create(nameR,desc,Permiss))
		Quit:$$$ISERR(sc) sc
		w !,"Create new Resource "_nameR
	}
	Return sc
}

/// Delete Resource
/// w $system.Status.GetErrorText(##class(%ZAPM.ext.database).DeleteResource("DSWDATA"))
ClassMethod DeleteResource(dbName As %String) As %Status
{
 New $Namespace
 Set $Namespace = "%SYS"
 Set sc = $$$OK
   s nameR="%DB_"_dbName
	if ##class(Security.Resources).Exists(nameR) {
		Set sc = $$$ADDSC(sc,##class(Security.Resources).Delete(nameR))
		Quit:$$$ISERR(sc) sc
		w !,"Delete Resource "_nameR
	}
	Return sc
}

/// Delete Role
/// w $system.Status.GetErrorText(##class(%ZAPM.ext.database).DeleteRole("DSWDATA"))
ClassMethod DeleteRole(dbName As %String) As %Status
{
 New $Namespace
 Set $Namespace = "%SYS"
 Set sc = $$$OK
   s nameR="%DB_"_dbName
	if ##class(Security.Roles).Exists(nameR) {
		Set sc = $$$ADDSC(sc,##class(Security.Roles).Delete(nameR))
		Quit:$$$ISERR(sc) sc
		w !,"Delete role "_nameR
	}
	Return sc
}

/// Create new namespace
ClassMethod CreateNamespace(pNamespace As %String, pCodeData As %Boolean, pInterOperability As %Boolean, pREST As %String) As %Status [ Private ]
{

    New $Namespace
    Set $Namespace = "%SYS"

    If (pCodeData = $$$YES) {
        Set strGlobals = pNamespace_"-DATA"
        Set strRoutine = pNamespace_"-CODE"
    }
    Else {
        Set (strGlobals, strRoutine) = pNamespace
    }

    Set sc = $$$OK
    Try {

        Write "Creating Namespace "_pNamespace_"... "

        Set nsProperties("Globals") = strGlobals
        Set nsProperties("Library") = ..#LIBRARY
        Set nsProperties("Routines") = strRoutine
        Set nsProperties("SysGlobals") = ..#SYSGLOBALS
        Set nsProperties("SysRoutines") = ..#SYSGLOBALS
        Set nsProperties("TempGlobals") = ..#TEMPGLOBALS
        Set sc = $$$ADDSC(sc,##Class(Config.Namespaces).Create(pNamespace,.nsProperties))

        Write "done!",!

        #; enable Interoperability
        If (pInterOperability = $$$YES) {
            Write "Creating Interoperability mappings ... "
            #; create InterOperability mappings
            Set:'$Data(^%SYS("Ensemble","InstalledNamespace",pNamespace)) ^%SYS("Ensemble","InstalledNamespace",pNamespace)=""
            Set sc = $$$ADDSC(sc,##class(%EnsembleMgr).createMappings(pNamespace))
            Write "done!",!

            Write "Adding Interoperability SQL privileges ... "
            #; add InterOperability SQL privileges
            Set sc = $$$ADDSC(sc,##class(%EnsembleMgr).addEnsembleSQLPrivileges(pNamespace))	
            Write "done!",!
        }
        Set sc = $$$ADDSC(sc,..CreateCSPApplication(pNamespace))
        If (pREST '= "") {
            Set sc = $$$ADDSC(sc,..createRESTApp(pNamespace,pREST))
        }
    }
    Catch (err) {
        Set sc = $$$ADDSC(sc,err.AsStatus())
    }
    Return sc
}

/// Create CSP application
ClassMethod CreateCSPApplication(pNamespace As %String) As %Status [ Private ]
{
    Set sc = $$$OK
    New $Namespace
    Set $Namespace="%SYS"
    Try {
        Write "Creating CSP Application ... "
        Set lower = $ZConvert(pNamespace,"L")
        Set del = $Case($$$isWINDOWS,1:"\",:"/")
        Set cspName = "/csp/"_lower

        Set properties("Name") = cspName
        Set properties("CookiePath") = "/csp/"_lower
        Set properties("AutheEnabled") = $$$AutheUnauthenticated
        Set properties("NameSpace") = pNamespace
        Set properties("Path") = ##class(%File).GetDirectory($zu(86))_"csp"_del_lower
        Set properties("GroupById") = $$$IscMgtPortalId
        Set properties("AutoCompile") = 1

        // If the application exists, quit
        If '##class(Security.Applications).Exists(cspName,.existingApp,.sc2) {
            // Create the csp application properties	
            Set sc = $$$ADDSC(sc,##class(Security.Applications).Create(cspName,.properties))
        }
        Else {
            Set sc = $$$ADDSC(sc,sc2)
        }
        Write "done!",!
    }
    Catch (err) {
        Set sc = $$$ADDSC(sc,err.AsStatus())
    }
    Return sc
}

/// Create REST Application
ClassMethod createRESTApp(pNamespace As %String, DispatchClass = "REST.Dispatch") As %Status
{
    #dim sc As %Status = $$$OK

    New $Namespace
    Set $Namespace = "%SYS"

    Write "Creating CSP Application ... "

    Set lower = $ZConvert(pNamespace,"L")
    Set restName = "/rest/"_lower

    If '##class(Security.Applications).Exists(restName) {
        Set props("AutheEnabled") = $$$AutheUnauthenticated
        Set props("NameSpace") = pNamespace
        Set props("IsNameSpaceDefault") = $$$NO
        Set props("DispatchClass") = DispatchClass
        Set props("MatchRoles")=":%All"
        Set sc = ##class(Security.Applications).Create(restName, .props)
        Write "done!",!


        Write "Creating "_DispatchClass_".cls ... "
        Do ..CreateDispatchClass(pNamespace,DispatchClass)
        Write "done!",!
    }

    Quit sc
}

/// Create a dummy REST service to populate messages
ClassMethod CreateDispatchClass(pNamespace As %String, classname = "REST.Dispatch") As %Status [ Private ]
{
    New $Namespace
    Set $Namespace = pNamespace
    Set sc = $$$OK
    Try {
        ;Set classname = "REST.Dispatch"
        Set class = ##class(%Dictionary.ClassDefinition).%New(classname)
        Set class.GeneratedBy = $ClassName()
        Set class.Super = "%CSP.REST"

        Set xdata = ##class(%Dictionary.XDataDefinition).%New()
        Set xdata.Name = "UrlMap"
        Set xdata.XMLNamespace = "http://www.intersystems.com/urlmap"
        Do xdata.Data.WriteLine("<Routes>")
        Do xdata.Data.WriteLine("<Route Url=""/"" Method=""GET"" Call=""Test"" Cors=""true""/>")
        Do xdata.Data.WriteLine("</Routes>")
        Do class.XDatas.Insert(xdata)
        Set sc = $$$ADDSC(sc,class.%Save())

        Set method = ##class(%Dictionary.MethodDefinition).%New(classname)
        Set method.Name = "Test"
        Set method.ClassMethod = 1
        Set method.ReturnType = "%Status"
        Set stream = ##class(%Stream.TmpCharacter).%New()
        Do stream.WriteLine("	Set %response.ContentType = ""application/json"" ")
        Do stream.WriteLine("	Set retObj = {}")
        Do stream.WriteLine("	Set retMessage = ""Hello World!"" ")
        Do stream.WriteLine("	Set retObj.Message = retMessage")
        Do stream.WriteLine("	Write retObj.%ToJSON()")
        Do stream.WriteLine("	Quit $$$OK")
        Set method.Implementation = stream
        Set sc = $$$ADDSC(sc,method.%Save())

        Set sc = $$$ADDSC(sc,$System.OBJ.Compile(classname,"fck-dv"))
    }
    Catch (err) {
        Set sc = $$$ADDSC(sc,err.AsStatus())
    }
    Return sc
}

/// Get database directory
ClassMethod GetDatabaseDirectory(pNamespace As %String) As %String [ CodeMode = expression ]
{
##class(%File).SubDirectoryName($System.Util.ManagerDirectory(),pNamespace)
}

/// Checks if database directory exist
ClassMethod CheckDatabaseDirExists(directory As %String) As %Status [ CodeMode = expression ]
{
##class(%File).DirectoryExists(directory)
}

/// Checks if database directory exist
ClassMethod CheckDatabaseExists(directory As %String) As %Status [ CodeMode = expression ]
{
##class(%File).Exists(directory_$Case($$$isWINDOWS,1:"\",:"/")_..#DATABASENAME)
}

/// w $system.Status.GetErrorText(##class(%ZAPM.ext.database).DeleteDBNS("SWAGGERUI", 0))
ClassMethod DeleteDBNS(pNamespace) As %Status
{
	write !,"Delete "_pNamespace
	if $namespace=$ZCONVERT(pNamespace,"U") set $namespace="%SYS"
	do ##class(%ZAPM.ext.Production).delete(pNamespace)
	set sc = ##class(%ZPM.PackageManager.Developer.UnitTest.Utils).DeleteNamespace($ZCONVERT(pNamespace,"L"))
	quit:$$$ISERR(sc) sc
	set sc = ..DeleteResource($ZCONVERT(pNamespace,"U"))
	;Quit:$$$ISERR(sc) sc
	set sc = ..DeleteRole($ZCONVERT(pNamespace,"U"))
	;Quit:$$$ISERR(sc) sc
	quit sc
}

/// zn "app" w $System.Status.GetErrorText(##class(%ZAPM.ext.database).DismountListDB("DOJO"))
ClassMethod DismountListDB(Database) As %Status
{
	s st=..DismountDB(Database)
	if st {
		s st1=..DismountDB(Database_"ENSTEMP")
		if 'st1 q st1
		s st2=..DismountDB(Database_"SECONDARY")
		if st2 q st2
	} else { q st }
	q $$$OK
}

/// write $System.Status.GetErrorText(##class(%ZAPM.ext.database).DismountDB("PROD"))
ClassMethod DismountDB(Database) As %Status
{
	new $namespace
	zn "%sys"
	s st=$$$OK
	If ##Class(Config.Databases).Get(Database,.Properties) {
		Set Directory = $G(Properties("Directory"))
  		Set st = ##class(SYS.Database).DismountDatabase(Directory)
	}
	q st
}

}

