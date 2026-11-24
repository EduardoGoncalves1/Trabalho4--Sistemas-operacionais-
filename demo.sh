#!/usr/bin/env bash
# Sequência da apresentação. Saída salva em evidencias/
cd "$(dirname "$0")"; mkdir -p evidencias
P=$(grep -E '^PORT=' .env | cut -d= -f2); P=${P:-8080}
rc() { docker inspect -f '{{.RestartCount}}' trabalho4; }
t() { echo; echo "=== $* ==="; }
{
t "1. BUILD + START"; docker compose up -d --build
sleep 2
t "docker ps"; docker ps
t "teste HTTP"; curl -s localhost:$P/ ; curl -s localhost:$P/health
t "usuario efetivo (UID != 0)"; docker exec trabalho4 id; docker top trabalho4 -o user,pid,comm 2>/dev/null || docker top trabalho4
t "usuario configurado / privileged"; docker inspect -f 'User={{.Config.User}} Privileged={{.HostConfig.Privileged}} CapDrop={{.HostConfig.CapDrop}} ReadOnly={{.HostConfig.ReadonlyRootfs}}' trabalho4
t "env externa"; docker exec trabalho4 env | grep -E '^(PORT|LOG_LEVEL)='
t "limites aplicados"; docker inspect -f 'Mem={{.HostConfig.Memory}} bytes NanoCpus={{.HostConfig.NanoCpus}} Restart={{.HostConfig.RestartPolicy.Name}}' trabalho4
docker stats --no-stream trabalho4

t "2. FALHA CONTROLADA (aguardando 12s)"; sleep 12
ANTES=$(rc); echo "RestartCount ANTES: $ANTES"; docker inspect -f 'StartedAt={{.State.StartedAt}}' trabalho4
curl -s localhost:$P/crash >/dev/null; echo "(/crash chamado)"
sleep 6
t "3. RECUPERACAO"; echo "RestartCount DEPOIS: $(rc) (antes: $ANTES)"
docker inspect -f 'Running={{.State.Running}} StartedAt={{.State.StartedAt}}' trabalho4
docker ps
t "logs"; docker compose logs --tail 15
t "app respondendo de novo"; curl -s localhost:$P/

t "PARADA NORMAL"; docker compose stop; docker ps -a --filter name=trabalho4
docker inspect -f 'ExitCode={{.State.ExitCode}} RestartCount={{.RestartCount}}' trabalho4
} 2>&1 | tee evidencias/saida-demo-$(date +%Y%m%d-%H%M%S).txt
