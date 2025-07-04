# Api Spring Boot

## How to run
1. Open intellij
2. Run api and access `http://localhost:8080`
3. Run docker `docker-compose up`

# Routes
- GET `http://localhost:8080/api/hello`
- Actuator `http://localhost:8080/actutuator`
- Prometheus `http://localhost:9090`
- Grafana `http://localhost:3000`
```
login: admin
password: admin
```

## Actuator
<img width="812" alt="Screenshot 2025-05-20 at 22 09 09" src="https://github.com/user-attachments/assets/00902ffe-e7bb-4196-871d-48a37db07bf7" />

## Prometheus
<img width="1624" alt="Screenshot 2025-05-20 at 22 08 45" src="https://github.com/user-attachments/assets/8ee881a5-9bd4-4112-8167-475ba54fc754" />

## Grafana Templantes
- Micrometer

https://github.com/user-attachments/assets/20b03a19-3734-4051-8404-b62c2395acee

- Spring boot

https://github.com/user-attachments/assets/7b6da353-2615-4b73-83e7-e6f49e35b74c

# Desenvolvimento
./gradlew bootRun

# Build completo
./gradlew build

# Docker
docker build -t poc-spring-boot:latest .
docker run -p 8080:8080 poc-spring-boot:latest

# Kubernetes
helm install poc-spring-boot ./helm/poc-spring-boot





