# Cinema Microservices App (Demo/Backup)

### Requisitos

- Node.js
- Docker
- Docker Compose (Opcional)
- Docker Machine (Opcional)
- Virtual Box (Opcional)

# Executar

Os microservices podem ser executados com o script `kraken.sh`.

```bash
sudo bash kraken.sh
```

###### Atenção!

Ao subir os microservices com `kraken.sh` usando as flags `-s|-S` e `-l|--use-local`, o arquivo `/etc/docker/daemon.json` será modificado.
É gerado um backup `/etc/docker/daemon.json.bkp`.

## Adicionar novos microservices

- Para que a Image de um novo microservice possa ser criada, o caminho do diretório do microservice deve ser adicionado no script `kraken.sh`, na variável `MICROSERVICES`.

- No diretório de cada microservice (`Services/[microservice]-Service`), os arquivos `package.json`, `Dockerfile`, `.dockerignore`, `create-service.sh`, `create-image.sh`, talvez necessitem de algumas modificações.
