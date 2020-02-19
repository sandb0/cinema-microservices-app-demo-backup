# Cinema Microservices App (Demo/Backup)

### Requisitos

- Node.js
- Docker
- Docker Compose (Opcional)
- Docker Machine (Opcional)
- Virtual Box (Opcional)

### Como executar

- Subir os serviços com Docker Compose.
```
$ sudo docker-compose up --build
```
- Ou subir os serviços com o shell script `kraken.sh`.
```
$ sudo kraken.sh
```
##### Atenção!
Ao subir os microservices com `kraken.sh` usando as flags `-s` e `-l`, o arquivo `/etc/docker/daemon.json` será modificado.
É gerado um backup `/etc/docker/daemon.json.bkp`.

- ~Ou manualmente com o `start-service__study-only.sh`. Deve ser copiado e executado na raiz de cada microservice.~