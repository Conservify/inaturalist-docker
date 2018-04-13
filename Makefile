clean:
	docker-compose rm -f
	docker rmi nature_server nature_elastic || /bin/true

up:
	docker-compose up
