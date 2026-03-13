#!/bin/bash

# CLUSTER_NAME and SHARD_NAME are passed via docker-compose environment
CLUSTER_NAME="${CLUSTER_NAME:-DSTWhalesCluster}"
SHARD_NAME="${SHARD_NAME:-Master}"

echo "=== Starting: CLUSTER=$CLUSTER_NAME | SHARD=$SHARD_NAME ==="

# Check for game updates before each start
/home/dst/steamcmd.sh \
  +@ShutdownOnFailedCommand 1 \
  +@NoPromptForPassword 1 \
  +@sSteamCmdForcePlatformType linux \
  +login anonymous \
  +force_install_dir /home/dst/server_dst \
  +app_update 343050 \
  +quit

echo "=== Starting mod setup ==="
ds_mods_setup="/home/dst/.klei/DoNotStarveTogether/${CLUSTER_NAME}/mods/dedicated_server_mods_setup.lua"
echo "Checking file: $ds_mods_setup"
if [ -f "$ds_mods_setup" ]; then
  echo "File found, copying..."
  cp $ds_mods_setup "$HOME/server_dst/mods/"
else
  echo "File NOT found!"
fi

echo "=== Copying modoverrides.lua ==="
modoverrides="$HOME/.klei/DoNotStarveTogether/${CLUSTER_NAME}/mods/modoverrides.lua"
echo "Checking file: $modoverrides"
if [ -f "$modoverrides" ]; then
  echo "File found, copying to Master and Caves..."
  cp $modoverrides "$HOME/.klei/DoNotStarveTogether/${CLUSTER_NAME}/Master/"
  cp $modoverrides "$HOME/.klei/DoNotStarveTogether/${CLUSTER_NAME}/Caves/"
  echo "Done!"
else
  echo "File NOT found!"
fi

cd $HOME/server_dst/bin
./dontstarve_dedicated_server_nullrenderer \
  -cluster "$CLUSTER_NAME" \
  -shard "$SHARD_NAME" \
  -console