# Quol's BZFlag Server Setup

I have made this public incase anyone wants to see how I run bzfs instances.  I also use this to synchronize the base scripts across servers.

## How to use this repository
* create a new user, and a new home directory (exmaple. /home/bzflag for user bzflag)
* clone this repo directly into the users' home folder (example in /home/bzflag)
  * if you use the usual adduser command, then the homedir that's created will not be empty
  * use the lower level useradd commands and then manually make a new blank homedir, then you can 'git clone' straight into that directory
    * this is probably the best option. the new user will not have a password at all, will never be able to log in, and can't use any sudo commands so is a pretty restricted user
  * if you need to use adduser for whatever reason, then the new homedir will have files (.bash* etc.), so you can't just git clone into that directory. in this case (move the .bash* .profile files somewhere else and then clone and move them back, or):
    * cd ~/
      * make sure you are logged in as this new user, and you are in that users home directory
    * git clone <repourl> /tmp/tmprepo
    * cp -rf /tmp/tmprepo/.git ~/
    * git checkout -f main
    * rm -rf /tmp/tmprepo
* this will give you the following layout:
  * ~/bin
    * where all your server startup scripts will reside
    * the main srvctrl.sh script is located here. this manages (starts, stops, restarts) all the individual server scripts (no changes to this file should be needed)
    * an example server startup script is provided. srvctrl.sh will start/stop this one (and all others that you will create). You should edit/copy the example startup script and grow as needed.
  * ~/config
    * an example configuration has been provided for the "example" server (config/example)
    * other configuration files are located in this directory, such as the common configuration files for all server instances
  * ~/logs
    * where all the logs for each server will reside
    * srvctrl.sh start the servers in the background and redirects all output to *servername*.log in this directory
  * ~/maps
    * a place to put all your bz worlds/maps, and reference them in your configs
  * ~/pid
    * srvctrl.sh places the pid information per server here (*servername*.gpid)
    * srvctrl.sh uses group pid's for all servers to track status and stop running instances
    * the servers parent script (like example.sh) spawns a bzfs instance, so there are two pid's to track per running hzfs instance. The pid for the server script (example.sh), and the pid for the spawned bzfs instance. However, both of these pid's share the same group pid, so performing an action on the group pid affects all pid's part of that group (the pid's for example.sh itself, as well as the running hzfs instance), this way we only need to track a single pid - the group pid.
  * ~/recordings
    * where all the recordings should go.
    * this way you can spin up a single recording only server, and it will display recordings from all your instances.
  * know where you have installed/compiled bzflag/bzfs. see the section in this Readme (How I compile BZFlag) on how I do it if you are interested.

## Reviewing the home directory

Once the repository is cloned in your desired home directory, all that is needed is to edit/copy the example server script and example configuration directory, and you should be up and running quickly.

* ~/bin/srvctrl.sh
  * this is the main server control script.
  * calls/manages all the individual servers scripts (like example.sh - see below)
  * this can start/stop/restart all, a single, or multiple bzfs instances with a few simple commands like:
```bash
srvctrl.sh start all # starts all instances
srvctrl.sh restart all # restarts all instances
srvctrl.sh stop example # stops the "example" bzfs instance
srvctrl.sh status all # gets the status of all instances
# starts only the example, myotherserver, and yetanother instances
srvctrl.sh start example myotherserver yetanother 
```
* ~/bin/example.sh
  * an example bzfs instance server script. you should copy/edit this one when creating your own bzfs instances.
  * modify ROOT to make sure that it points to the right place.
  * BZFS
    * the path to your bzfs installation/location
  * SERVERTITLE
    * a template variable. all instances of __SERVERTITLE__ in the common.conf or mapspecific conf will be replaced with this value
    * The server title that you want to use for this instance
    * this will be the main title that appears on the list server
    * this title is used across all maps that this instance will host
      * the name of the currently active map will be appended to this Title string
  * Modify all other template variables:
    * SERVERPORT, DNSNAME, PUBLICKEY
    * this way you should only have to modify things in one place (in this server script).
  * ~/config/example:
    * common.conf
      * this is the bzflag configuration that is common between all mapchange configurations. anything that is not map specific should go in the common.conf file. the server script (like example.sh) combines the common.conf, with the corresponding "active" map specific configuration and than starts up the bzfs instance with that combined config
      * note the use of template variables. the server script (example.sh) replaces these template values with the corresponding variables
    * mapchange.conf
      * this is the mapchange plugin configuration make sure the paths are correct for whereever you installed things.
    * mapchange.out
      * the mapchange plugin creates this file
    * tmp.conf
      * the server scipt (example.sh) creates this file. this is the fully assembled config file that is created. This is the common.conf file, and the active map conf file combined with all template variables replaced. 
      * This is the file that the bzfs server uses when it starts
    * vars
      * any server specific bzfs server variables will go here
  * config/*map*.conf
    * map specific configuration files
    * examples for ducati (ducati.conf), and hix (hix.conf)       
    * note the use of template variables. the server script (example.sh) replaces these template values with the corresponding variables (-publictitle uses __SERVERTITLE__ mostly in map specific configs)
    * the config file corresponding with the active map will be combined with the server's common.conf. the server script (example.sh) takes care of this for you.

Knowing all the above, to start a new server, you would:

* copy bin/example.sh to some other name (newserver.sh)
  * edit *newserver*.sh as follows:
    * confirm ROOT, and SRVCONFDIR variables - make sure the paths are correct
    * confirm that the BZFS variable is pointing to the right place
    * confirm the template variables are correct
      * SERVERTITLE, SERVERPORT, DNSNAME, PUBLICKEY
* copy config/example directory, and paste it/rename it to the same name you used when copying the server script (like *newserver* following the above example)
* edit common.conf appropriately
  * since we use template variables, these options will be automatically updated with the data from the new server scrpt (*newserver*.sh):
    * -srvmsg, -publicaddr, -publickey, -p (port to use)
  * add any other bzfs configuration that will be common across all mapchange's for this instance

with this in place, srvctrl.sh can start using this configuration right away with a command line like:
```bash
srvctrl.sh start newserver
```
*newserver* will be whatever name you used when creating the server script (newserver.sh in the above example)

## How I compile BZFlag:

### Pre-Req's (on Ubuntu latest LTS)
apt-get install g++ libtool automake autoconf libsdl2-dev libcurl3-dev libc-ares-dev zlib1g-dev libncurses-dev libglew-dev make

### Clone from github
https://github.com/BZFlag-Dev/bzflag <br />
git clone https://github.com/BZFlag-Dev/bzflag.git ~/src/bzflag

### compile
cd ~/src/bzflag <br />
./autogen.sh <br />
./configure --disable-client --prefix /home/bzflag/v2.4.22/ --enable-custom-plugins=playerJoinHandler,mapchange,playerdb,VPNBlocker,LeagueOverseer,persustentMute <br />
make && make install <br />

Note that the above prefix should match the git release you are compiling for. this way you can easily upgrade your servers by:

* checking out the new git tag for the new bzflag release
* 'make distclean' to make sure that your source tree is ready to re-compile
* proceed with the above autogen, configure, make and make install lines (with a new prefix matching the new release)
* update the server startup scripts to point to the newly compiled bzfs binary.
* rollback is performed simply by pointing back to the previous path in the server startup scripts

## plugins used

### mapChange:
https://github.com/allejo/mapchange <br />
git clone https://github.com/allejo/mapchange.git mapchange <br />

### playerJoinHandler:
https://github.com/allejo/playerJoinHandler <br />
git clone https://github.com/allejo/playerJoinHandler playerJoinHandler <br />

### playerdb:
https://github.com/allejo/playerdb <br />
git clone https://github.com/allejo/playerdb.git playerdb <br />

### vpnblocker:
https://github.com/allejo/VPNBlocker <br />
git clone https://github.com/allejo/VPNBlocker.git VPNBlocker <br />

### Muted Chat Helper:
https://github.com/allejo/persistentMute <br />
git clone https://github.com/allejo/persistentMute.git persustentMute <br />

### League Overseer:
sudo apt install libjson-c-dev <br />
sudo ln -s /usr/include/json-c/ /usr/include/json <br />
sudo ln -s /usr/lib/x86_64-linux-gnu/libjson-c.so /usr/lib/x86_64-linux-gnu/libjson.so <br />

https://github.com/allejo/LeagueOverseer <br />
git clone https://github.com/allejo/LeagueOverseer.git LeagueOverseer <br />


### ServerControl:
default plugin

### TimeLimit:
default plugin