Include %ZAPM.ext.Common

/// Export different types of modules in different subfolders in UDL (plain) format
/// test.dfi -> /dfi/test.dfi
/// testpkg.test.cls -> /cls/testpkg/test.cls
/// Fork from https://github.com/intersystems-ru/cache-udl
/// do ##class(%ZAPM.ext.code).ExportUDL("d:\!\zapm\src\") ;export zapm project
Class %ZAPM.ext.code [ Abstract ]
{

/// do ##class(%ZAPM.ext.code).exp("/irisrun/repo/chmod777-R/apptools/src/","apptools.","apptools.M")
/// do ##class(%ZAPM.ext.code).exp("/irisdev/app/chmod777-R/zapm/src/","%ZAPM")
/// do ##class(%ZAPM.ext.code).exp("/irisdev/app/chmod777-R/zapm/preload/","%ZAPM.ext.preload")
/// do ##class(%ZAPM.ext.code).Export2dir("/irisrun/repo/chmod777-R/zapm/src/","011","%ZAPM.ZpmLoad.GBL",.app)
/// do ##class(%ZAPM.ext.code).Export2dir("/irisrun/repo/chmod777-R/zapm/src/","011","%ZAPM.ext.Common.INC",.app)
ClassMethod exp(dir = "", mask = "", ignoremask = "", ByRef list)
{
 new $namespace
 do ..workdir(dir)
 if $e(mask,1,8)="apptools" set $namespace=$g(^%apptools.Setting("HomeNamespace"))
 if $e(mask,1)="%" set $namespace="%SYS"
 do ..export(,,$e(mask,1)="%",,mask,ignoremask,1,.list)
}

/// import 
/// do ##class(%ZAPM.ext.code).imp("/backup/iris/distr/apptools-all/src/xml/")
ClassMethod imp(dir = "", mask = "")
{
 do ..workdir(dir)
 d ..import(mask)
}

/// get or set working directory for export/import source
/// d ##class(%ZAPM.ext.code).workdir("/backup/source")
ClassMethod workdir(workdir)
{
	s gln = ..gln() s:$d(workdir) @gln = workdir
	///zu(12) namespace directory by default
	#define nsdir $zu(12,"")
	Q $g(@gln, $$$nsdir)
}

/// export all available code
/// d ##class(%ZAPM.ext.code).export(,,,,"apptools.","apptools.M")
/// d ##class(%ZAPM.ext.code).export(,,,,"apptools.","apptools.M",1,"/csp/aaa")
ClassMethod export(generated = 0, system = 0, percent = 0, mapped = 0, mask = "", ignoremask = "", ignoredfi = 0, ByRef item)
{

	#define export(%code, %file) try {s sc = $system.OBJ.ExportUDL(%code, %file,"/diffexport")} catch e {s sc=$$$ERROR($$$GeneralError,"Old version")} ##continue
								 w:sc "Ok" d:'sc $system.OBJ.DisplayError(sc)

	#define isGenerated(%code) ##class(%RoutineMgr).IsGenerated( %code )
	#define isPercented(%code) ("%" = $e(%code))
	#define isMapped(%code) ##class(%RoutineMgr).IsMapped( %code )
	#define log w !, code, " -> ", $piece(filename,..workdir(),2), " "
	
	#define mkdir(%filename) ##continue
			s path = ##class(%File).GetDirectory( %filename ) ##continue
			if '##class(%File).DirectoryExists( path ) { ##continue
				s sc = ##class(%File).CreateDirectoryChain( path ) ##continue
				w !, "mkdir ", path, " ", sc ##continue
			}
						
	w "#; Exporting to ", ..workdir(),!
	#; classes
	s rs = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:Summary")
	if rs.Execute() {

		while rs.%Next(){

			s code = rs.Name _ ".cls", isSystem = rs.System
			;w !,code
			if ( 'system && isSystem ) continue
			if ( 'generated && $$$isGenerated( code ) ) continue
			if ( 'percent && $$$isPercented( code ) ) continue
			if ( 'mapped && $$$isMapped( code ) ) continue
			if mask'="",(("@"_code)'[("@"_mask )) continue
			if ignoremask'="",(("@"_code)[("@"_ignoremask )) continue
			
			s filename = ..filename( code )
			$$$mkdir( filename )
			$$$log
			$$$export( code, filename )
			s item(code)=""
		} s rs=""
	}

	#; routines
	s rs = ##class(%ResultSet).%New("%Routine:RoutineList")
	if rs.Execute() {

    	while rs.%Next() {

	 		s code = rs.Name
	 		if ( 'generated && $$$isGenerated( code ) ) continue
	 		if ( 'percent && $$$isPercented( code ) ) continue
			if ( 'mapped && $$$isMapped( code ) ) continue
			if ( '$find( code, mask ) ) continue
			
			s filename = ..filename( code )
			$$$mkdir( filename )
			$$$log
			$$$export( code, filename )
			s item(code)=""
	    } s rs=""
	}


	#; dfi
	#define export(%code,%file) s sc = ##class(%DeepSee.UserLibrary.Utils).%Export( %code, %file, 0 ) 
	if 'ignoredfi {
		s sql = "Select fullName as Name From %DeepSee_UserLibrary.FolderItem"
	    s rs = ##class(%SQL.Statement).%ExecDirect( .stm, sql )
	    while rs.%Next() {
			s code = rs.Name, filename = ..filename( code_".dfi" )
			if ( '$find( code, mask ) ) continue
			if ($L(code,"$TRASH")>1) continue
			$$$mkdir( filename )
			$$$log
			$$$export(code,filename)
			s item(code)=""
		} s rs=""
	}
	w !!, "#; Exported to ", ..workdir()
    Q $$$OK
}

/// import all from workdir
/// d ##class(%ZAPM.ext.code).import()
ClassMethod import(filemask = "*.xml;*.cls;*.mac;*.int;*.inc;*.dfi", qspec = "cku-d", ByRef err = "", recurse = 1, ByRef loaded = "", verbose = 1) As %Status
{
	#define push(%dir) s dirs( $i( dirs ) ) = %dir
	#define next(%i,%dir) s %i=$o( dirs( "" ), 1, %dir )  k:%i'="" dirs(%i)
	#define isDirectory(%type) ( %type = "D" )
	#define log w !,filename_" " w:sc "Ok" d:'sc $system.OBJ.DisplayError(sc)
	
	s sc = 1, dirs = "", dir = ..workdir() $$$push(dir)
	if verbose w "#; Importing from ", dir,!
	d ..setIgnore(.fm,verbose)
	for { $$$next(i,dir) Q:i=""  Q:dir=""

		s rs = ##class(%File).FileSetFunc( dir, filemask, , 1 )

		while rs.%Next() {
			s filename = rs.Name

			if $$$isDirectory(rs.Type) {
				if recurse $$$push(filename)
				continue
			}
			// check file filter
			if ..inFilter(.fm,filename) continue

			s ext = $p( filename, ".", * )

			if $zcvt( ext, "l" ) = "dfi" {
				s sc = ##class(%DeepSee.UserLibrary.Utils).%Import( filename, 1, 0, 0, "", .dsloaded )
			} else {
				// load classes only
				s sc = $system.OBJ.Load( filename, "k-d", .err, .loaded)
			}

			if verbose $$$log
			
	    }
		// compile all the loaded classes to obey dependencies
		s sc=$system.OBJ.CompileList( .loaded, "cukbr-d/multicompile",.err )
		
	}
	
	if verbose {
	
		if $D(err) {
			s i=$Order(err("")) 
			while i'="" {
			w !,err(i)
			s i=$O(err(i))
			}
		}
		
		w !,!,"#; Imported from ", ..workdir()
		}
	Q sc
}

ClassMethod inFilter(ByRef filtermask, filename) As %Boolean
{
	s result=0
	for 
	{
		if '$d(filtermask($I(i))) quit
		set filter=$piece(filtermask(i),"*")
		if $length(filename,filter)>1 set result=1
	}

	quit result
}

/// get the filtermask for the repository.
/// looks for .gitignore file and applies all the lines to filters
ClassMethod setIgnore(ByRef filtermask, verbose)
{
	
	// working with .gitignore file
	// gitignore consists of masks of filtering files
	s filename=..workdir()_"/.gitignore"
	if '##class(%File).Exists(filename) quit
	s file=##class(%File).%New(filename)
	s sc=file.Open("R")
	if 'sc 
	{
		if verbose d $System.OBJ.DisplayError(sc) return
	}

	While 'file.AtEnd
	{
		s filtermask($I(filtermask))=file.ReadLine()
	}
quit
}

/// gl[obal] n[ame] - storage for settings
ClassMethod gln() [ CodeMode = expression, Private ]
{
"%apptools"
}

ClassMethod init()
{
	#define confile "/cos.json"
	set stream=##class(%Stream.FileCharacter).%New()
	set sc=stream.LinkToFile(..workdir()_$$$confile)
	s conf={}.%FromJSON(stream.Read($$$MaxCacheInt))
	s gln=..gln()
	s @gln@("compileList")=conf.compileList
	s @gln@("projectName")=conf.projectName
	w "compileList="_conf.compileList,!
	w "projectName="_conf.projectName
}

/// export release file for list and project settings
ClassMethod release()
{
	s gln=..gln()
	s list=$G(@gln@("compileList"))
	if list="" w "Nothing to release. Run init method first" quit

	s release=$G(@gln@("projectName"),"release")
	s release=release_$p($zdt($h,8)," ")_$tr($p($p($zdt($h)," ",2),":",1,2),":")_".xml"
	D $System.OBJ.Export(list,release)
	w "All objects with mask "_list_" has been exported to "_release
}

ClassMethod compile()
{
	s gln=..gln()
	s list=$G(@gln@("compileList"))
	if list="" w "Nothing to compile. Run init method first" quit
	d $System.OBJ.compile(list)
}

/// test.dfi -> /dfi/test.dfi
/// test.cls -> /cls/test.cls
/// testpkg.test.cls -> /cls/testpkg/test.cls
/// etc
ClassMethod filename(code)
{
	#define log(%dir,%sc) w !, "mkdir ", %dir, " ", sc

	s wd = ..workdir()

	if '##class(%File).DirectoryExists( wd ) {
		s sc = ##class(%File).CreateDirectoryChain( wd )
		$$$log(wd,sc)
	}

	s ext = $p( code, ".", * ), ext = $zcvt( ext, "l" )
	#; for each type - different directory

	s:ext'="" wd = ##class(%File).NormalizeDirectory( ext, wd )

	#; directory must exist before any call (%File).NormalizeFilename( , wd)
	if '##class(%File).DirectoryExists( wd ) {
		s sc = ##class(%File).CreateDirectoryChain( wd )
		$$$log(wd,sc)
	}

	s filename = ##class(%File).NormalizeFilename( code, wd )
	#; lowercase file extension
	if ext="gbl" set ext="xml"
	s $p(filename,".",*)=ext
	//B:code="DPRep.Rest.JSON.cls" "L"
	#; for *.cls Package.Subpackage.ClassName.cls -> Folder/Subfolder/ClassName.cls
	if ext ="cls"||(ext ="inc") {
		s dirs = $piece( code, ".",1, *-2 ), dirs = $translate( dirs, ".", "/" )
		s relpath = dirs _ "/" _ $piece( code, ".", *-1, * ) ;
		s filename = ##class(%File).NormalizeFilename( relpath, wd )
	}
	if filename["%",(ext'="inc")  set filename=$tr(filename,"%","_") ;zpm bug ? (ext'="inc") 
	Q filename
}

/// import from workdir all files with ts newer than code ts in db
ClassMethod importUpdated(filemask = "*.*", qspec = "cku-d", ByRef err = "", recurse = 1, ByRef loaded = "", verbose = 1) As %Status
{
	#define push(%dir) s dirs( $i( dirs ) ) = %dir
	#define next(%i,%dir) s %i=$o( dirs( "" ), 1, %dir )  k:%i'="" dirs(%i)
	#define isDirectory(%type) ( %type = "D" )
	#define log w !, $piece(filename,..workdir(),2)," " w:sc "Ok" d:'sc $system.OBJ.DisplayError( sc )

	s sc = 1, dirs = "", dir = ..workdir() $$$push(dir)
	if verbose w "#; Importing updated from ", dir,!
	d ..setIgnore(.fm,verbose)
	for { $$$next(i,dir) Q:i=""  Q:dir=""

		s rs = ##class(%File).FileSetFunc( dir, filemask, , 1 )

		while rs.%Next() {
		   s filename = rs.Name

		   if $$$isDirectory( rs.Type ) {
			 if ( recurse ) $$$push(filename) ;push directory
			 continue
		   }

			// check file filter
			if ..inFilter(.fm,filename) continue

		   s filets = rs.DateModified
		   s codename = ..codename( filename, .ext )
		   s codets = ..codets( codename, ext )
		   
		   #; w !, filename, $c(9), "(", filets, ")"
		   #; w !, codename, $c(9), "(", codets, ")"
		   
		   if ( filets '] codets ) continue
			 
		   if ext = "dfi" {

			   s sc = ##class(%DeepSee.UserLibrary.Utils).%Import( filename, 1, 0, 0, "", .loaded )

		   } else {

			   #; drop existing code before import ( purge DateModified )
			   #; s:codets'="" sc = ##class(%RoutineMgr).Delete( codename )
			   k err s sc = $system.OBJ.Load( filename, qspec, .err, .loaded)

		   }

		   if verbose $$$log
	    }
	}
	w:verbose !,"#; Imported updated from ", ..workdir()
	Q sc
}

/// presumable codename
ClassMethod codename(filename, ByRef ext = "")
{
	s ext = $p( filename, ".", * ), ext = $zcvt( ext, "l" )
	s path = ##class(%File).NormalizeDirectory( ext, ..workdir() )
	s codename = $p( filename, path, 2 )
	if ext = "dfi" {
		s fullname  = $tr( codename, "\", "/" ) ; return fullname for dfi in $$$IsWINDOWS
		Q $p( fullname, ".", 1, *-1 ) ;remove extension
	}
	if (ext ="cls")!(ext="int")!(ext="inc")!(ext="mac") s codename=$tr(codename,"\/","..")
	Q codename
}

ClassMethod codets(codename, ext)
{
	s ts = ""
	if ext'="dfi" {
		s ts = ##class(%RoutineMgr).TS( codename )
	} else {
		s sql="Select timeModified From %DeepSee_UserLibrary.FolderItem Where fullname = ?"
		s rs = ##class(%SQL.Statement).%ExecDirect( , sql, codename )
		if rs.%Next() {
			s utcts = rs.timeModified
			s utch = $zdth( utcts, 3, , 3 ) ;utc internal format
			s loch = $zdth( utch, -3 ) ; utc to local timezone
			s ts = $zdt( loch, 3, ,0 ) ; local timestamp*/
		}
	}
	Q $p( ts, "." ) ;remove ms
}

/// Export Resources 
/// Example: ExportList="00100,%ZAPM^00000,apptools.,apptools.M"
ClassMethod ExportResources(Path As %String = "", ExportList As %String = "") As %Status
{
	Set st=$$$OK
		For i=1:1:$Length(ExportList,"^") { Set item=$Piece(ExportList,"^",i)
			Continue:item=""
			Do ..ExportOneResource(Path,$Piece(item,",",1),$Piece(item,",",2),$Piece(item,",",3))	
		}
	Quit st
}

/// Export different types of modules in different subfolders in UDL (plain) format
/// test.dfi -> /dfi/test.dfi
/// testpkg.test.cls -> /cls/testpkg/test.cls
/// Fork from https://github.com/intersystems-ru/cache-udl
/// do ##class(%ZAPM.ext.code).ExportOneResource("/backup/repo-iris-test/zapm/src/","001001","%ZAPM")
/// byte=1 isGenerated
/// byte=2 isSystem
/// byte=3 isPercented
/// byte=4 isMapped
/// byte=5 isDFI
/// byte=6 isINC
ClassMethod ExportOneResource(workdir, flags, mask = "", ignoremask = "")
{
	//$zu(12) namespace directory by default
	//If workdir="" Set workdir=$zu(12,"")
	#define export(%code, %file) Try {Set sc = $system.OBJ.ExportUDL(%code, %file,"/diffexport")} catch e {s sc=$$$ERROR($$$GeneralError,"Old version")} ##continue
								 Write:sc "Ok" Do:'sc $system.OBJ.DisplayError(sc)

	#define isGenerated(%code) ##class(%RoutineMgr).IsGenerated( %code )
	#define isPercented(%code) ("%" = $Extract(%code))
	#define isMapped(%code) ##class(%RoutineMgr).IsMapped( %code )
	#define log Write !, code, " -> ", $Piece(filename,workdir,2), " "
	
	#define mkdir(%filename) ##continue
			Set path = ##class(%File).GetDirectory( %filename ) ##continue
			If '##class(%File).DirectoryExists( path ) { ##continue
				Set sc = ##class(%File).CreateDirectoryChain( path ) ##continue
				Write !, "mkdir ", path, " ", sc ##continue
			}
						
	w "#; Exporting to ", workdir,!
	#; classes
	Set rs = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:Summary")
	If rs.Execute() {

		While rs.%Next(){

			Set code = rs.Name _ ".cls", isSystem = rs.System
			If ( '$Extract(flags,2) && isSystem ) Continue
			If ( '$Extract(flags,1) && $$$isGenerated( code ) ) Continue
			If ( '$Extract(flags,3) && $$$isPercented( code ) ) Continue
			If ( '$Extract(flags,4) && $$$isMapped( code ) ) Continue
			If mask'="",(("@"_code)'[("@"_mask )) Continue
			If ignoremask'="",(("@"_code)[("@"_ignoremask )) Continue
			
			Set filename = ..Expfilename( code,workdir )
			$$$mkdir( filename )
			$$$log
			$$$export( code, filename )
			Set item(code)=""
		} Set rs=""
	}

	#; routines
	Set rs = ##class(%ResultSet).%New("%Routine:RoutineList")
	If rs.Execute() {
    	While rs.%Next() {
	 		Set code = rs.Name
	 		If ( '$e(flags,1) && $$$isGenerated( code ) ) Continue
	 		If ( '$e(flags,3) && $$$isPercented( code ) ) Continue
			If ( '$e(flags,4) && $$$isMapped( code ) ) Continue
			If ( '$find( code, mask ) ) Continue
			
			Set filename = ..Expfilename( code,workdir )
			$$$mkdir( filename )
			$$$log
			$$$export( code, filename )
			Set item(code)=""
	    } Set rs=""
	}
	#; INC
	If $Extract(flags,6) { 
		set code=""
		for { set code=$o(^rINC(code)) quit:code=""
			If mask'="",(("@"_code)'[("@"_mask )) Continue
			If ignoremask'="",(("@"_code)[("@"_ignoremask )) Continue
			set filename = ..Expfilename( code_".inc",workdir )
			$$$mkdir(filename)
			$$$log
			$$$export(code_".inc",filename)
			Set item(code_".inc")=""
		}
	}
	#; dfi
	#define export(%code,%file) s sc = ##class(%DeepSee.UserLibrary.Utils).%Export( %code, %file, 0 ) 
	If $Extract(flags,5) {
		Set sql = "Select fullName as Name From %DeepSee_UserLibrary.FolderItem"
	    Set rs = ##class(%SQL.Statement).%ExecDirect( .stm, sql )
	    While rs.%Next() {
			Set code = rs.Name, filename = ..Expfilename( code_".dfi",workdir )
			If ( '$Find( code, mask ) ) Continue
			If ($Length(code,"$TRASH")>1) Continue
			$$$mkdir( filename )
			$$$log
			$$$export(code,filename)
			Set item(code)=""
		} Set rs=""
	}
	Write !!, "#; Exported to ", workdir
    Quit $$$OK
}

/// test.dfi -> /dfi/test.dfi
/// test.cls -> /cls/test.cls
/// testpkg.test.cls -> /cls/testpkg/test.cls
/// %ZAPM.ext.Common.inc -> inc/%ZAPM/ext/Common.inc 
ClassMethod Expfilename(code, wd)
{
	#define log(%dir,%sc) Write !, "mkdir ", %dir, " ", sc

	If '##class(%File).DirectoryExists( wd ) {
		Set sc = ##class(%File).CreateDirectoryChain( wd )
		$$$log(wd,sc)
	}

	Set ext = $Piece( code, ".", * ), ext = $Zconvert( ext, "l" )
	#; for each type - different directory

	Set:ext'="" wd = ##class(%File).NormalizeDirectory( ext, wd )

	#; directory must exist before any call (%File).NormalizeFilename( , wd)
	If '##class(%File).DirectoryExists( wd ) {
		Set sc = ##class(%File).CreateDirectoryChain( wd )
		$$$log(wd,sc)
	}

	Set filename = ##class(%File).NormalizeFilename( code, wd )
	#; lowercase file extension
	Set $Piece(filename,".",*)=ext
	//B:code="DPRep.Rest.JSON.cls" "L"
	If ext ="cls"||(ext ="inc") {
		Set dirs = $Piece( code, ".",1, *-2 ), dirs = $Translate( dirs, ".", "/" )
		Set relpath = dirs _ "/" _ $Piece( code, ".", *-1, * ) ;
		Set filename = ##class(%File).NormalizeFilename( relpath, wd )
	}
	Quit filename
}

/// do ##class(%ZAPM.ext.code).Export2dir("/backup/repo-iris-test-iris20203/new-pack",,"community.PKG",.app)
/// byte=1 isGenerated
/// byte=2 isSystem
/// byte=3 isPercented
/// byte=4 isMapped
/// byte=5 isDFI
ClassMethod Export2dir(dir, flags = "00000", code = "", ByRef item)
{
	#define isGenerated(%code) ##class(%RoutineMgr).IsGenerated( %code )
	#define isPercented(%code) ("%" = $Extract(%code))
	#define isMapped(%code) ##class(%RoutineMgr).IsMapped( %code )
	#define export(%code, %file) try {s sc = $system.OBJ.ExportUDL(%code, %file,"/diffexport")} catch e {s sc=$$$ERROR($$$GeneralError,"Old version")} ##continue
								 w:sc&($G(%write)) "Ok" d:'sc $system.OBJ.DisplayError(sc)
	#define log w:$G(%write) !, code, " -> ", $piece(filename,..workdir(),2), " "
	
	#define mkdir(%filename) ##continue
			s path = ##class(%File).GetDirectory( %filename ) ##continue
			if '##class(%File).DirectoryExists( path ) { ##continue
				s sc = ##class(%File).CreateDirectoryChain( path ) ##continue
				w:$G(%write) !, "mkdir ", path, " ", sc ##continue
			}
	do ..workdir(dir)
	write:$G(%write) "#; Exporting to ", dir,!
	set EXT=$zconvert($p(code,".",*),"U")
	set mask=$p(code,".",1,*-1)
	if EXT="PKG"||(EXT="") {
		#; classes
		set rs = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:Summary")
		if rs.Execute() {
			while rs.%Next(){
				set code = rs.Name _ ".cls", isSystem = rs.System
				;w !,code
				If ( '$Extract(flags,2) && isSystem ) Continue
				If ( '$Extract(flags,1) && $$$isGenerated( code ) ) Continue
				If ( '$Extract(flags,3) && $$$isPercented( code ) ) Continue
				If ( '$Extract(flags,4) && $$$isMapped( code ) ) Continue
				if mask'="",(("@"_code)'[("@"_mask )) continue
				set filename = ..filename( code )
				$$$mkdir( filename )
				$$$log
				$$$export( code, filename )
				set item(code)=""
			}
		}
	}
	elseif EXT="CLS" {
		set filename = ..filename(code)
		$$$mkdir( filename )
		$$$log
		$$$export( code, filename )
		set item(code)=""
	}
	elseif EXT="INC" {
		set filename = ..filename(code)
		$$$mkdir( filename )
		$$$log
		$$$export( code, filename )
		set item(code)=""
	}
	elseif EXT="GBL" {
		set filename = ..filename(code)
		$$$mkdir( filename )
		$$$log
		set arr(code)=""
		Write $SYSTEM.OBJ.Export(.arr, filename)
		set item(code)=""
	}
	quit $$$OK
}

/// do ##class(%ZAPM.ext.code).ExportUDL("/irisrun/repo/chmod777-R/zapm/")
/// do ##class(%ZAPM.ext.code).ExportUDL("d:\_proj\_mygirhub\zapm\")
ClassMethod ExportUDL(dir = "")
{
	set gn=##class(%ZAPM.ext.zpm).#GNSET  ;= "^%ZAPM.settings";
	if dir'="" set @gn@("ExpoPath")=dir
	set dir=$g(@gn@("ExpoPath"))
	write !,"Enter path <",dir,">",!," [q]-quit :" read r quit:r="q" $$$OK  if r'="" set dir=r
	quit:dir=""
	if dir'="" set @gn@("ExpoPath")=dir
	set dirsrc=dir_"src"_$$$slash
	;do ##class(%ZAPM.ext.code).exp(dirsrc,"%ZAPM","%ZAPM.ext.Lifecycle")
	do ##class(%ZAPM.ext.code).exp(dirsrc,"%ZAPM")
	do ##class(%ZAPM.ext.code).Export2dir(dirsrc,"011","%ZAPM.ZpmLoad.GBL",.app)
	do ##class(%ZAPM.ext.code).Export2dir(dirsrc,"011","%ZAPM.ext.Common.inc",.app)
	set dirpre=dir_$$$slash_"preload"_$$$slash
	do ##class(%ZAPM.ext.code).exp(dirpre,"%ZAPM.ext.Lifecycle")
	quit $$$OK
}

}

