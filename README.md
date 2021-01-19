![](https://github.com/SergeyMi37/zapm/blob/master/doc/prompt.ico)

## zapm
[![Gitter](https://img.shields.io/badge/Available%20on-Intersystems%20Open%20Exchange-00b2a9.svg)](https://openexchange.intersystems.com/package/zapm-1)

zapm is a shell - extends the zpm shell and adds any other commands.

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

3. Run the IRIS container with your project:

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
## Command extensions zpm.
help - coloring command description

load <https...git-repo> - loading the module directly from the git-repository

These extensions are planned to be included in the main branch of the zpm project in the future.
[101](https://github.com/intersystems-community/zpm/issues/101)
[154](https://github.com/intersystems-community/zpm/issues/154)

GIF shows command execution

## Additional commands.
cmd - list of possible additional commands

hist - list of executed commands

newdb <module> -creating a database with a scope and installing the module there

GIF shows command execution

To add a new command to the zapm shell, use the ##class(%ZAPM.ext.zapp).addcmd
For example, let's execute sequentially

- create a database with the area and install the zpmshow module there
newdb zpmshow

GIF shows command execution

- add a new command named zshow, which should be executed immediately.

do ##class(%ZAPM.ext.zapp).addcmd("new $namespace zn ""zpmshow"" do ^zpmshow", "zpm", "i", "zshow", "Show a zpm modules with extention description")

GIF shows command execution

- check the execution of the new command from the system shell
USER>zapm "zshow"

- or from the zapm shell

zapm
cmd
zshow or number

GIF shows command execution

## It is planned to do:
the ability to supplement the zapm shell with commands, the specifics of calling them are described in a special file zapm.json, which is located in the repository.
So when deploying enterprise application instances, you can use application command systems.

command expansion
install module - if the zapm.json file (command or command description) is in the repository, then commands from it can be added to the zapm shell

additional zapm commands
cmd-add - add command
cmd-del - delete command

## This solution can replace not only the zpm shell but also the main terminal shell. 
For me it almost happened ;-)
The solution for contest in the competition uses multi-model:
- Object (
- Relational (
- Key-Value (