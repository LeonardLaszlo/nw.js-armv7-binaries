# Cheatsheet

In case the build fails you might want to connect to the docker container to remove a file or edit a file.

Here are some usefull docker commands:

``` bash
# List containers.
docker ps -a

# Connect to an existing container
docker container attach 71ebf03500f0
# or
docker container exec -it 71ebf03500f0 /bin/bash
```

