crane stop
crane rm

docker build --build-arg NODE=peer -t yusukew/dejima-peer . --no-cache
docker build --build-arg NODE=client -t yusukew/dejima-client . --no-cache
