#! /usr/bin/env bash

if [[ -z $PROJECT_PATH ]]; then
	PROJECT_PATH=$(pwd)
fi

if [[ $1 == 'build' ]]; then
	docker build . -t jwoos/csuy4783-project2
elif [[ $1 == 'test' ]]; then
	docker run -it --rm -v $PROJECT_PATH:/csproj/ jwoos/csuy4783-project2:test
else
	docker run -it --rm -v $PROJECT_PATH:/csproj/ jwoos/csuy4783-project2:latest
fi

