# useful commands

## docker ---------------------------------------------------
### stoped and clean all containers
docker stop $(docker ps -a -q) &&  docker rm $(docker ps -a -q) && docker system prune -f

### clean up docker 
```
docker system prune -f
```

### start container with iris
```
$ docker-compose up -d
```
docker-compose up --build -d
```

### build container with no cache
```
docker-compose build --no-cache --progress=plain
```

### open terminal to docker
```
docker-compose exec iris iris session iris -U IRISAPP
```

## export IRIS Analytics artifacts
```
d ##class(dev.code).export("*.DFI")
```
## build cube
```
do ##class(%DeepSee.Utils).%BuildCube("CubeName")
```
## export globals
```
do $System.OBJ.Export("po*.GBL","/irisdev/app/src/gbl/globals.xml",,.errors)
zw errors

```
## wsl---------------------------------------  https://docs.microsoft.com/ru-ru/windows/wsl/basic-commands    https://ab57.ru/cmdlist/wslcmd.html

### start docker and ssh
```
sudo service docker start && sudo /etc/init.d/ssh restart
```
### show list
```
wsl --list -v
```
### export to tar
```
wsl --export Ubuntu20.04 d:\wsl\wsl-backup\Ubuntu20-mc-dock.tar
```
### import from tar
```
wsl --import Ubu20 d:\wsl\Ubu20 d:\wsl\wsl-backup\curr-Ubuntu20.tar
```
### terminate
```
wsl -t Ubuntu
```
### shutdown all
```
wsl -shutdown
```
### set default
wsl --set-default Ubu20.04-mc-dock

wsl --distribution Ubu20.04 --user msw

## git ------------------------------------
### commit and push
```
git add * && git commit -am "upd" && git push
```
## git stored
```
git config --global credential.helper "cache --timeout=86400"
git config --global credential.helper store
```

## zpm ---------------------------------------
## Installed zpm short one line
```
zn "%SYS" d ##class(Security.SSLConfigs).Create("z") s r=##class(%Net.HttpRequest).%New(),r.Server="pm.community.intersystems.com",r.SSLConfiguration="z" d r.Get("/packages/zpm/latest/installer"),$system.OBJ.LoadStream(r.HttpResponse.Data,"c")
zpm "generate d:\_proj\_mygirhub\isc-apptools-lockdown-2\isc-apptools-lockdown\src\ -export 00000,appmsw"
```

## .bashrc -------------------
### User specific aliases and functions
```
alias mc="mc -S dark"
alias hi="history"
alias myip='wget -qO myip http://www.ipchicken.com/; grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" myip;  rm myip'
export PATH=$PATH:/opt/libreoffice6.4/program
```

### PgUp/PgDn
### https://qastack.ru/programming/4200800/in-bash-how-do-i-bind-a-function-key-to-a-command
```
if [[ $- == *i* ]]
then
    bind '"\e[5~": history-search-backward'
    bind '"\e[6~": history-search-forward'
fi
```
### f12
```
bind '"\e[24~":"pwd\n"'
```