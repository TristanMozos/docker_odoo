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

```