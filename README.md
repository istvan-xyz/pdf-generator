# PDF Generator service

Running:

```sh
docker run -p 8081:8080 istvan32/pdf-generator
```

Example call: http://localhost:8081/pdf?url=https://google.com

## Publishing

```sh
docker build -t istvan32/pdf-generator .
docker push istvan32/pdf-generator
```
