# Trabalho 4 – Serviço Linux seguro com Docker
Faculdade Serra Dourada – ADS – Sistemas Operacionais (Prof. Guibson Krause)

**Integrante:** Eduardo Gonçalves Oliveira

**Pré-requisitos:** Linux com Docker + Compose plugin (`sudo pacman -S docker docker-compose docker-buildx`), `curl`, serviço docker ativo e usuário no grupo `docker`.

## Aplicação
Servidor HTTP em Python (`app.py`, só biblioteca padrão). Rotas: `/` (mostra uid/pid), `/health`, `/crash` (sai com código 1, só para teste).

## Runbook
1. **Configurar:** `cp .env.example .env` e edite `PORT` / `LOG_LEVEL` (sem mexer no código). `.env` está no `.gitignore`; nenhuma credencial real no Git.
2. **Construir e iniciar:** `docker compose up -d --build`
3. **Testar:** `curl localhost:8080/` e `curl localhost:8080/health`
4. **Estado:** `docker ps` / `docker ps -a`
5. **Usuário:** `docker exec trabalho4 id` → uid=10001 (≠ 0). `docker inspect -f '{{.Config.User}} {{.HostConfig.Privileged}}' trabalho4` → privileged=false.
6. **Logs:** `docker compose logs -f` (inicialização, cada requisição, erro).
7. **Limites:** `docker inspect -f '{{.HostConfig.Memory}} {{.HostConfig.NanoCpus}}' trabalho4` e `docker stats --no-stream` (128 MB, 0,5 CPU).
8. **Simular falha** (após ≥10 s rodando): `docker inspect -f '{{.RestartCount}}' trabalho4`; `curl localhost:8080/crash`; aguarde 5 s.
9. **Confirmar recuperação:** `RestartCount` aumentou (política `restart: on-failure`), `docker compose logs --tail 15`, `curl localhost:8080/`.
10. **Parar:** `docker compose stop` (SIGTERM → exit 0, não reinicia). Remover: `docker compose down`.

Tudo isso é automatizado por `./demo.sh`, que grava a saída em `evidencias/`.

## Permissões e isolamento
- Roda como usuário `app` (UID 10001) via `USER` no Dockerfile; não usa `--privileged`.
- Porta 8080 (>1024): não precisa de root nem de capabilities.
- Só lê `/app/app.py`; não escreve em disco: `read_only: true`.
- `cap_drop: ALL`, `no-new-privileges`, `pids_limit: 64`.
- Limites: `mem_limit: 128m`, `cpus: 0.5`.

## Recuperação
`restart: on-failure`: reinicia apenas quando o processo principal sai com código ≠ 0. `docker stop` (código 0) não dispara reinício.

## Evidências
Ver pasta `evidencias/` (saída do `demo.sh`) e as capturas de tela.

## Explicação das evidências
- `Screenshot_20261124_185857.png`: build da imagem e início do container.
- `Screenshot_20261124_185923.png`: container ativo, UID 10001 (não root), `Privileged=false`, variáveis de ambiente, limites (128 MB, 0,5 CPU), falha controlada e `RestartCount` 0 → 1.
- `Screenshot_20261124_185932.png`: logs (início, requisição, falha simulada, reinício), aplicação respondendo de novo e parada normal (`ExitCode=0`).
- `saida-demo-20261124-185209.txt`: saída completa do `demo.sh`.
