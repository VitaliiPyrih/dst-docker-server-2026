#!/bin/bash

# Якщо запущено від root: виправляємо права на backups і перемикаємось на dst
if [ "$(id -u)" = "0" ]; then
  mkdir -p /home/dst/backups
  chown dst:dst /home/dst/backups
  exec runuser -u dst -- env HOME=/home/dst "$0" "$@"
fi

CLUSTER_NAME="${CLUSTER_NAME:-DSTWhalesCluster}"
SHARD_NAME="${SHARD_NAME:-Master}"
UPDATE_ON_START="${UPDATE_ON_START:-true}"
BACKUP_ENABLED="${BACKUP_ENABLED:-true}"
BACKUP_KEEP="${BACKUP_KEEP:-7}"

KLEI_DIR="$HOME/.klei/DoNotStarveTogether"
CLUSTER_DIR="$KLEI_DIR/${CLUSTER_NAME}"
BACKUP_DIR="$HOME/backups/${CLUSTER_NAME}"

echo "=== Starting: CLUSTER=$CLUSTER_NAME | SHARD=$SHARD_NAME | UPDATE_ON_START=$UPDATE_ON_START ==="

# ---------- Оновлення гри ----------
if [ "$UPDATE_ON_START" = "true" ]; then
  echo "=== Checking for game updates ==="
  /home/dst/steamcmd.sh \
    +@ShutdownOnFailedCommand 1 \
    +@NoPromptForPassword 1 \
    +@sSteamCmdForcePlatformType linux \
    +login anonymous \
    +force_install_dir /home/dst/server_dst \
    +app_update 343050 \
    +quit
else
  echo "=== Skipping update check (UPDATE_ON_START=false) ==="
fi

# ---------- Моди ----------
echo "=== Starting mod setup ==="
ds_mods_setup="$CLUSTER_DIR/mods/dedicated_server_mods_setup.lua"
if [ -f "$ds_mods_setup" ]; then
  echo "dedicated_server_mods_setup.lua found, copying..."
  cp "$ds_mods_setup" "$HOME/server_dst/mods/"
else
  echo "dedicated_server_mods_setup.lua NOT found!"
fi

modoverrides="$CLUSTER_DIR/mods/modoverrides.lua"
if [ -f "$modoverrides" ]; then
  echo "modoverrides.lua found, copying to Master and Caves..."
  cp "$modoverrides" "$CLUSTER_DIR/Master/"
  cp "$modoverrides" "$CLUSTER_DIR/Caves/"
else
  echo "modoverrides.lua NOT found!"
fi

# ---------- Бекапи ----------
# Бекап робить лише Master, щоб шарди не дублювали архів
backup_cluster() {
  [ -d "$CLUSTER_DIR" ] || return 0
  mkdir -p "$BACKUP_DIR"

  local today
  today=$(date +%F)
  local archive="$BACKUP_DIR/${CLUSTER_NAME}_${today}.tar.gz"

  if [ -f "$archive" ]; then
    echo "Backup for $today already exists, skipping."
  else
    echo "=== Creating backup: $archive ==="
    # Зберігаємо все, окрім mods (вони тягнуться заново)
    tar -czf "$archive" -C "$KLEI_DIR" \
      --exclude="${CLUSTER_NAME}/mods" \
      "${CLUSTER_NAME}" \
      && echo "Backup done." \
      || { echo "Backup FAILED"; rm -f "$archive"; }
  fi

  # Видаляємо старі, лишаємо останні N
  ls -1t "$BACKUP_DIR"/${CLUSTER_NAME}_*.tar.gz 2>/dev/null \
    | tail -n +$((BACKUP_KEEP + 1)) \
    | xargs -r rm -v
}

# Фоновий цикл: перший бекап при старті, далі кожні 24 години
backup_loop() {
  while true; do
    backup_cluster
    sleep 86400
  done
}

if [ "$BACKUP_ENABLED" = "true" ] && [ "$SHARD_NAME" = "Master" ]; then
  backup_loop &
fi

# ---------- Запуск сервера ----------
cd "$HOME/server_dst/bin" || exit 1
exec ./dontstarve_dedicated_server_nullrenderer \
  -cluster "$CLUSTER_NAME" \
  -shard "$SHARD_NAME" \
  -console