```
The next docker compose start the services of odoo, postgresql and pgadmin4 to manage database.
To know which is the ip to connect with pgadmin you can type in a terminal:
docker network inspect odoo_default
In the output data you can see the name of the postgre container instance and the ip to connect your pgadmin.
```
## docker-compose.yml

```
version: '2'
services:
  web:
    image: tmozos/docker_odoo:10
    #image: odoo:10
    depends_on:
      - db
    ports:
      - "0.0.0.0:8069:8069"
    volumes:
      - /opt/odoo/conf:/etc/odoo
      - /opt/odoo/extra-addons:/mnt/extra-addons
    privileged: true
    restart: always

  db:
    image: postgres:9.5
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_PASSWORD=odoo
      - POSTGRES_USER=odoo
    volumes:
      - /opt/odoo/database:/var/lib/postgresql/data
    restart: always

  pgadmin:
    depends_on:
      - db
    links:
      - db
    image: chorss/docker-pgadmin4
    volumes:
      - /opt/odoo/database/pgadmin:/root/.pgadmin
    ports:
      - "5050:5050"
    restart: always

```