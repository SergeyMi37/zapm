[![Repo-GitHub](https://img.shields.io/badge/dynamic/xml?color=gold&label=GitHub%20module.xml&prefix=ver.&query=%2F%2FVersion&url=https%3A%2F%2Fraw.githubusercontent.com%2Fsergeymi37%2Fzapm%2Fmaster%2Fmodule.xml)](https://raw.githubusercontent.com/sergeymi37/zapm/master/module.xml)
[![OEX-zapm](https://img.shields.io/badge/dynamic/json?url=https:%2F%2Fpm.community.intersystems.com%2Fpackages%2Fzapm%2F&label=ZPM-pm.community.intersystems.com&query=$.version&color=green&prefix=zapm)](https://pm.community.intersystems.com/packages/zapm)

[![Docker-ports](https://img.shields.io/badge/dynamic/yaml?color=blue&label=docker-compose&prefix=ports%20-%20&query=%24.services.iris.ports&url=https%3A%2F%2Fraw.githubusercontent.com%2Fsergeymi37%2Fzapm%2Fmaster%2Fdocker-compose.yml)](https://raw.githubusercontent.com/sergeymi37/zapm/master/docker-compose.yml)

![](https://github.com/SergeyMi37/zapm/blob/master/doc/zapm-red.png)
## zapm
[![Gitter](https://img.shields.io/badge/Available%20on-Intersystems%20Open%20Exchange-00b2a9.svg)](https://openexchange.intersystems.com/package/zapm)
[![Demo](https://img.shields.io/badge/Demo%20on-GCR-black)](https://zapm.demo.community.intersystems.com/terminal/)
[![Habr](https://img.shields.io/badge/Available%20article%20on-Intersystems%20Community-orange)](https://community.intersystems.com/post/zapm-shell-extends-zpm-shell-and-adds-any-other-commands)

[![](https://img.shields.io/badge/InterSystems-IRIS-blue.svg)](https://www.intersystems.com/products/intersystems-iris/)
<img alt="GitHub last commit" src="https://img.shields.io/github/last-commit/SergeyMi37/zapm">
[![Quality Gate Status](https://community.objectscriptquality.com/api/project_badges/measure?project=intersystems_iris_community%2Fzapm&metric=alert_status)](https://community.objectscriptquality.com/dashboard?id=intersystems_iris_community%2Fzapm)

ZAPM is a shell - extends the ZPM shell and adds any other commands.

Working in the terminal I got tired of going from my shell to the zpm shell and back.
My shell was supplied with additional specific commands and I decided to merge the two shells.

The ZAPM checks if the command entered is a ZPM command, then sends the execution to the ZPM shell.
Then I wanted to improve the color commands and expand the functionality.
And now ZAPM has survived to the first version and can add any command that I need and remember it so that I can re-execute it.

## What's new
- fixed test and upd command
- added extensions newdb command
- added proxy mode

```
 Available commands extention:
 -----------------------------
 
 newdb <module>
  Create a new database and an Namespace with a name derived from the name of the module and Install the module into it,
 
 dbcreate namespace <path>
  Create a new database and an Namespace,
  dbcreate testdb2 -p d:/!/database/durable
 
 dbdelete namespace
  Delete database and an Namespace,
 
 info
  Show more complete information about modules in the current namespace.
 info -m module
  Show file module.xml.
 info -f module
  List file in repository.
 info -r module
  Show file readme.md.
 
 upg
  Upgrade the versions of modules installed in the current namespace.
 
 load http://git-repo/developer-name/repo-name
  Load the module directly from the repository into the current Namespace. The 'git clone' command is applied. The git program must be installed.
 
 find app* -d  load description from modules, and the description is always displayed
 
 find app* -u /rcemper  show modules only including context from repository
 
 cmd
  Alias: ?
  Show all commands.
 
 cmd <context>
  Show all commands including context.
 
 cmd -init
  Reload all commands. Run do ##class(%ZAPM.ext.zapp).init()
 
 hist
  Alias: ??
  Show all history.
 
 hist <context>
  Show all history including context.
 
 hist - <context>
  Show all history including context. Sorting by date
 
 hist + <context>
  Show all history including context. Reverse sorting by date
 
 hist -del Number_day
  Delete all history older than the number of days.
 
 hist -add Number_hist
  Added history in list for non-removable.
 
 hist -add Number_hist [name_cmd] [a/i/n] description
  Added history in list commans.
```

## Installation with ZPM

If the current ZPM instance is not installed, then in one line you can install the latest version of ZPM even with a proxy.
```
s r=##class(%Net.HttpRequest).%New(),proxy=$System.Util.GetEnviron("https_proxy") Do ##class(%Net.URLParser).Parse(proxy,.pr) s:$G(pr("host"))'="" r.ProxyHTTPS=1,r.ProxyTunnel=1,r.ProxyPort=pr("port"),r.ProxyServer=pr("host") s:$G(pr("username"))'=""&&($G(pr("password"))'="") r.ProxyAuthorization="Basic "_$system.Encryption.Base64Encode(pr("username")_":"_pr("password")) set r.Server="pm.community.intersystems.com",r.SSLConfiguration="ISC.FeatureTracker.SSL.Config" d r.Get("/packages/zpm/latest/installer"),$system.OBJ.LoadStream(r.HttpResponse.Data,"c") zn "%SYS" zpm "install zapm"
```
If ZPM is installed, then ZAPM can be set with the command
```
zpm:USER>install zapm
```
## Installation with Docker

### Prerequisites
Make sure you have [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) and [Docker desktop](https://www.docker.com/products/docker-desktop) installed.

## Installation 
Clone/git pull the repo into any local directory

```
$ git clone https://github.com/SergeyMi37/zapm.git
```

Open the terminal in this directory and run:

```
$ docker-compose build
```

Run the IRIS container with your project:

```
$ docker-compose up -d
```

## How to Test it
Open IRIS terminal:

```
$ docker-compose exec iris iris session iris
USER>
USER>zapm "cmd"
```
![](https://raw.githubusercontent.com/SergeyMi37/zapm/blob/master/doc/Screenshot_1_cmd.png)

## Command extensions zpm.
## help - coloring command description

![](https://raw.githubusercontent.com/SergeyMi37/zapm/master/doc/2-help.gif)

## load <https...git-repo> - loading the module directly from the git-repository

![](https://raw.githubusercontent.com/SergeyMi37/zapm/master/doc/Screenshot_3_load.png)

## show modules with context by repository URL

![](https://raw.githubusercontent.com/SergeyMi37/zapm/master/doc/Screenshot_8_find.png)


## Additional commands.

 Commands for working with databases and namespaces:

## dbcreate - create a database with %DB resources ans namespace and interoperability mapping.
```
USER>zapm "dbcreate testdb3 -p d:/!/database/durable"
```
## dbdelete - delete a database with %DB resources ans namespace.
```
USER>zapm "dbdelete testdb3"
```


## cmd - list of possible additional commands

![](https://raw.githubusercontent.com/SergeyMi37/zapm/master/doc/Screenshot_4_cmd.png)

## hist - list of executed commands

![](https://raw.githubusercontent.com/SergeyMi37/zapm/master/doc/Screenshot_5_hist.png)

## newdb <module> -creating a database with a scope and installing the module there

To add a new command to the zapm shell, use the ##class(%ZAPM.ext.zapp).addcmd
For example, let's execute sequentially

- create a database with the area and install the zpmshow module there
```
hp-msw>IRISZPM>USER> newdb zpmshow

Creating Database zpmshow... done!
Creating Namespace zpmshow... done!
Creating Interoperability mappings ... done!
Adding Interoperability SQL privileges ... done!
Creating CSP Application ... done!
 
zpm "install zpmshow"
[zpmshow]       Reload START
[zpmshow]       Reload SUCCESS
[zpmshow]       Module object refreshed.
[zpmshow]       Validate START
[zpmshow]       Validate SUCCESS
[zpmshow]       Compile START
[zpmshow]       Compile SUCCESS
[zpmshow]       Activate START
[zpmshow]       Configure START
[zpmshow]       Configure SUCCESS
[zpmshow]       Activate SUCCESS

```
- add a new command named zshow, which should be executed immediately.
```
do ##class(%ZAPM.ext.zapp).addcmd("new $namespace zn ""zpmshow"" do ^zpmshow", "zpm", "i", "zshow", "Show a zpm modules with extention description")
added
```
![](https://raw.githubusercontent.com/SergeyMi37/zapm/master/doc/Screenshot_7_zshow.png)

- check the execution of the new command from the system shell
USER>zapm "zshow"
- or from the zapm shell

![](https://raw.githubusercontent.com/SergeyMi37/zapm/master/doc/Screenshot_6_zshow.png)


This solution can replace not only the zpm shell but also the main terminal shell. 
For me it almost happened ;-)
