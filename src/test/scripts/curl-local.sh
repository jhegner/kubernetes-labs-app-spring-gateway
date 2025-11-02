# !/bin/bash
# inicie a aplicacao

curl http://localhost:8080/api/users

curl http://localhost:8080/api/users | jq '.[].name'

