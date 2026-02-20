#!/bin/bash

# Check for game updates before each start. If the game client updates and your server is out of date, you won't be
# able to see it on the server list. If that happens just restart the containers and you should get the latest version
/home/dst/steamcmd.sh +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login anonymous +force_install_dir /home/dst/server_dst +app_update 343050 +quit

echo "=== Starting mod setup ==="

ds_mods_setup="/home/dst/.klei/DoNotStarveTogether/DSTWhalesCluster/mods/dedicated_server_mods_setup.lua"
echo "Checking file: $ds_mods_setup"
if [ -f "$ds_mods_setup" ]
then
  echo "File found, copying..."
  cp $ds_mods_setup "$HOME/server_dst/mods/"
else
  echo "File NOT found!"
fi

# Copy modoverrides.lua
echo "=== Copying modoverrides.lua ==="
modoverrides="$HOME/.klei/DoNotStarveTogether/DSTWhalesCluster/mods/modoverrides.lua"
echo "Checking file: $modoverrides"
if [ -f "$modoverrides" ]
then
  echo "File found, copying to Master and Caves..."
  cp $modoverrides "$HOME/.klei/DoNotStarveTogether/DSTWhalesCluster/Master/"
  cp $modoverrides "$HOME/.klei/DoNotStarveTogether/DSTWhalesCluster/Caves/"
  echo "Done!"
else
  echo "File NOT found!"
fi

cd $HOME/server_dst/bin
./dontstarve_dedicated_server_nullrenderer -cluster DSTWhalesCluster -shard "$SHARD_NAME"