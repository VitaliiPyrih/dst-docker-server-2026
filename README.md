# DST Docker Server (2026) — Multi-Server Setup

## Структура проєкту

```
dst-dedicated-server/
├── Dockerfile
├── Dockerfile.base
├── docker-compose.yml
├── start-container-server.sh
├── .gitignore
└── clusters/
    ├── server1/
    │   └── DSTWhalesCluster/
    │       ├── cluster.ini
    │       ├── cluster_token.txt
    │       ├── mods/
    │       ├── Master/
    │       │   └── server.ini
    │       └── Caves/
    │           └── server.ini
    ├── server2/
    │   └── DSTCluster2/
    │       ├── cluster.ini
    │       ├── cluster_token.txt
    │       ├── mods/
    │       ├── Master/
    │       │   └── server.ini
    │       └── Caves/
    │           └── server.ini
    └── server3/
        └── DSTCluster3/
            ├── cluster.ini
            ├── cluster_token.txt
            ├── mods/
            ├── Master/
            │   └── server.ini
            └── Caves/
                └── server.ini
```

---

## Перший запуск (тільки один раз)

```bash
# 1. Збудувати базовий образ (~3GB, завантажує гру)
docker build -f Dockerfile.base -t dst-base:latest .

# 2. Запустити перший сервер
docker compose --profile server1 up -d --build
```

---

## Запуск серверів

```bash
# Server 1
docker compose --profile server1 up -d

# Server 2
docker compose --profile server2 up -d

# Server 3
docker compose --profile server3 up -d

# Всі одразу
docker compose --profile all up -d
```

---

## Зупинка серверів

```bash
# Server 1
docker compose --profile server1 down

# Server 2
docker compose --profile server2 down

# Server 3
docker compose --profile server3 down

# Всі одразу
docker compose --profile all down
```

---

## Перезапуск серверів

```bash
# Server 1
docker compose --profile server1 restart

# Всі одразу
docker compose --profile all restart
```

---

## Логи

```bash
# Server 1 Master (live)
docker compose logs -f dst_master

# Server 1 Caves
docker compose logs -f dst_caves

# Server 2 Master
docker compose logs -f dst_master2

# Server 3 Master
docker compose logs -f dst_master3

# Всі одразу
docker compose logs -f
```

---

## Моніторинг ресурсів

```bash
# CPU і RAM по контейнерах (live)
docker stats

# Всі запущені контейнери
docker ps
```

---

## Оновлення гри

> Виконувати коли вийшло оновлення DST

```bash
# 1. Зупинити всі сервери
docker compose --profile all down

# 2. Оновити базовий образ (завантажує нову версію гри)
docker build -f Dockerfile.base -t dst-base:latest .

# 3. Перезібрати образи
docker compose --profile server1 build

# 4. Запустити
docker compose --profile all up -d
```

---

## Перенесення світу на інший сервер

```bash
# 1. Зупинити сервер
docker compose --profile server1 down

# 2. Скопіювати папку кластера
cp -r clusters/server1/DSTWhalesCluster /шлях/до/нового/сервера/clusters/server1/

# На новому сервері:
git clone https://github.com/VitaliiPyrih/dst-docker-server-2026.git
# Покласти папку кластера і запустити
docker compose --profile server1 up -d
```

---

## Додати новий сервер (server4)

### 1. Створити папку кластера
```bash
cp -r clusters/server1/DSTWhalesCluster clusters/server4/DSTCluster4
```

### 2. Змінити в `clusters/server4/DSTCluster4/cluster.ini`
```ini
cluster_name = My Server 4
cluster_key = УнікальнийКлюч4
```

### 3. Змінити порти в `Master/server.ini`
```ini
[NETWORK]
server_port = 11002

[SHARD]
is_master = true
```

### 4. Змінити порти в `Caves/server.ini`
```ini
[NETWORK]
server_port = 10995

[SHARD]
is_master = false
```

### 5. Додати в `docker-compose.yml`
```yaml
dst_master4:
  container_name: dst_master4
  build: .
  networks:
    - dst_cluster4
  ports:
    - "11002:11002/udp"
  volumes:
    - ./clusters/server4:/home/dst/.klei/DoNotStarveTogether
  environment:
    - CLUSTER_NAME=DSTCluster4
    - SHARD_NAME=Master
  stdin_open: true
  tty: true
  profiles:
    - server4
    - all

dst_caves4:
  container_name: dst_caves4
  build: .
  networks:
    - dst_cluster4
  links:
    - dst_master4
  ports:
    - "10995:10995/udp"
  volumes:
    - ./clusters/server4:/home/dst/.klei/DoNotStarveTogether
  environment:
    - CLUSTER_NAME=DSTCluster4
    - SHARD_NAME=Caves
  profiles:
    - server4
    - all
```

### 6. Додати мережу в `docker-compose.yml`
```yaml
networks:
  dst_cluster4:
```

### 7. Відкрити порти на файрволі
```bash
sudo ufw allow 11002/udp
sudo ufw allow 10995/udp
```

### 8. Запустити
```bash
docker compose --profile server4 up -d --build
```

---

## Таблиця портів

| Сервер | CLUSTER_NAME    | Master UDP | Caves UDP | master_port |
|--------|-----------------|-----------|-----------|-------------|
| server1 | DSTWhalesCluster | 10999    | 10998     | 10888       |
| server2 | DSTCluster2      | 11000    | 10997     | 10877       |
| server3 | DSTCluster3      | 11001    | 10996     | 10866       |
| server4 | DSTCluster4      | 11002    | 10995     | 10855       |

---

## Відкрити порти на файрволі (всі сервери)

```bash
sudo ufw allow 10999/udp
sudo ufw allow 10998/udp
sudo ufw allow 11000/udp
sudo ufw allow 10997/udp
sudo ufw allow 11001/udp
sudo ufw allow 10996/udp
```

---

## Важливі нотатки

- `cluster_key` — має бути **унікальним** для кожного сервера
- `CLUSTER_NAME` в docker-compose.yml має **точно співпадати** з назвою папки в `clusters/serverN/`
- Базовий образ (`dst-base:latest`) будується **один раз** — всі сервери його спільно використовують
- Збереження світу знаходиться в `clusters/serverN/ClusterName/Master/save/` і `Caves/save/`