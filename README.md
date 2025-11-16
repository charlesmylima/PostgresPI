# PostgresPI

Projeto auxiliar para trabalhar com um banco Postgres localmente e um cliente Python mínimo para a próxima versão.

Branching model
----------------

Usamos um modelo simples de branches baseado em `git`:

- **`main`**: branch estável com o código em produção.
- **`develop`**: branch de integração contínua, onde são mescladas features prontas.
- **`feature/<id>-descrição`**: branch para desenvolvimento de uma nova funcionalidade.
- **`release/<versão>`**: branch para preparar uma release (teste/ajustes finais).
- **`hotfix/<versão>`**: branch para correções críticas na `main`.

Exemplos rápidos de comandos:

```
git checkout -b feature/1234-adicionar-livros develop
git checkout -b hotfix/1.0.1 main
git branch -d feature/1234-adicionar-livros
```

Commit messages (convenção)
---------------------------

Use a convenção:

`<ação>(módulo): descrição curta`

Regras:
- `<ação>` — uma das: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`, `perf`, `build`, `ci`.
- `(módulo)` — opcional, indica o módulo/área afetada (ex.: `db`, `livros`, `api`).
- `descrição curta` — verbo no infinitivo (ex.: "adicionar", "corrigir"), claro e direto.

Exemplos:

```
feat(db): adicionar tabela livros
fix(livros): corrigir validação de ISBN
refactor(api): simplificar código de rotas
docs: atualizar README com guia de deployment
```

Docker (Postgres + Adminer)
---------------------------

Incluí um `docker-compose.yml` para facilitar o ambiente local com Postgres e Adminer (interface web para administrar tabelas).

Para subir o ambiente (PowerShell):

```powershell
docker compose up -d --build
```

A configuração monta `sqlstartup.sql` (se presente) em `/docker-entrypoint-initdb.d/` para executar scripts de inicialização.

pgAdmin ficará disponível em `http://localhost:8080` (usuário/email: `admin@local`, senha: `admin` — ou ajuste `PGADMIN_DEFAULT_EMAIL`/`PGADMIN_DEFAULT_PASSWORD` no `docker-compose.yml`).
  
Para conectar ao servidor Postgres via pgAdmin, crie um novo servidor em pgAdmin apontando para `db` (ou `localhost` se preferir) na porta `5432` e use as credenciais `postgres` / `postgres` (ou as variáveis definidas em `docker-compose.yml`).

Uso da instância Docker
-----------------------

Subir os serviços (Postgres + pgAdmin):

```powershell
docker compose up -d --build
```

Verificar status dos containers:

```powershell
docker compose ps
```

Ver logs do Postgres:

```powershell
docker compose logs -f db
```

Acessar o pgAdmin: abrir `http://localhost:8080` e entrar com as credenciais configuradas no `docker-compose.yml` (por padrão `admin@local` / `admin`).

Criar um servidor no pgAdmin apontando para o serviço `db` (host: `db`, porta: `5432`, usuário: `postgres`, senha: `postgres`).

Scripts de inicialização
-----------------------

O arquivo `sqlstartup.sql`, se presente, é automaticamente executado na primeira inicialização do container Postgres via `/docker-entrypoint-initdb.d/`.

Fazer dump (backup) do banco via Docker
---------------------------------------

Existem algumas formas de gerar dumps usando o ambiente Docker. Abaixo duas opções práticas em PowerShell.

1) Gerar dump dentro do container e copiar para host (simples)

```powershell
# Criar dump dentro do container (formato plain SQL)
docker compose exec db pg_dump -U postgres -F p -v -f /tmp/db_dump.sql postgres

# Copiar o arquivo do container para o host (cria a pasta backups se necessário)
mkdir .\backups -ErrorAction SilentlyContinue
docker cp $(docker compose ps -q db):/tmp/db_dump.sql .\backups\db_dump.sql

# (opcional) remover o dump dentro do container
docker compose exec db rm /tmp/db_dump.sql
```

2) Usar um container temporário `postgres` para executar `pg_dump` e montar volume host (bom para automação)

```powershell
mkdir .\backups -ErrorAction SilentlyContinue
docker run --rm --network "$(docker compose ps -q db | ForEach-Object { docker inspect -f '{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' $_ })" -v ${PWD}\backups:/backups -e PGPASSWORD=postgres postgres:15-alpine sh -c "pg_dump -h db -U postgres -F c -b -v -f /backups/db_dump_custom_format.dump postgres"
```

Observação: a segunda forma usa `pg_dump` no formato custom (`-F c`), que é adequado para `pg_restore`.

Restaurar um dump criado com `pg_dump`:

```powershell
# Se o dump estiver no host (ex: .\backups\db_dump_custom_format.dump), copie para o container e restaure
docker cp .\backups\db_dump_custom_format.dump $(docker compose ps -q db):/tmp/db_dump_custom_format.dump
docker compose exec db pg_restore -U postgres -d postgres -v /tmp/db_dump_custom_format.dump

# Remover arquivo temporário
docker compose exec db rm /tmp/db_dump_custom_format.dump
```

Arquivo de inicialização SQL: `sqlstartup.sql` (se presente no repositório) será aplicado automaticamente pelo container Postgres.

