![](https://github.com/SergeyMi37/zapm/blob/master/doc/zapm-red.png)

## zapm
[![Gitter](https://img.shields.io/badge/Available%20on-Intersystems%20Open%20Exchange-00b2a9.svg)](https://openexchange.intersystems.com/package/zapm-1)

zapm is a shell - extends the zpm shell and adds any other commands.

Working in the terminal I got tired of going from my shell to the zpm shell and back.
My shell was supplied with additional specific commands and I decided to merge the two shells.

## Installation with ZPM

zpm:USER>install zapm

## Installation with Docker

## Prerequisites
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
### help - coloring command description

![](https://raw.githubusercontent.com/SergeyMi37/zapm/master/doc/2-help.gif)

### load <https...git-repo> - loading the module directly from the git-repository

![](https://raw.githubusercontent.com/SergeyMi37/zapm/master/doc/Screenshot_3_load.png)

These extensions are planned to be included in the main branch of the zpm project in the future.
[101](https://github.com/intersystems-community/zpm/issues/101)
[154](https://github.com/intersystems-community/zpm/issues/154)

## Additional commands.

### cmd - list of possible additional commands

![](https://github.com/SergeyMi37/zapm/blob/master/doc/Screenshot_4_cmd.png)

### hist - list of executed commands

![](https://github.com/SergeyMi37/zapm/blob/master/doc/Screenshot_5_hist.png)

### newdb <module> -creating a database with a scope and installing the module there

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
![](https://github.com/SergeyMi37/zapm/blob/master/doc/Screenshot_7_zshow.png)

- check the execution of the new command from the system shell
USER>zapm "zshow"
- or from the zapm shell

![](https://github.com/SergeyMi37/zapm/blob/master/doc/Screenshot_6_zshow.png)

## It is planned to do:

additional zapm commands:

cmd-add - add command

cmd-del - delete command


This solution can replace not only the zpm shell but also the main terminal shell. 
For me it almost happened ;-)
