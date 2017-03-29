
### Time Drift

Docker has a core issue with regards to time drift of containers.
Namely time proceeds non-linearly with respect to up time of the
container.

It will manifest if you run signature bearing REST API tools in
the container (e.g. awscli).

The solution is to add to the entrypoint script the following
command:

```text
hwclock -s
```

References:

- https://forums.docker.com/t/time-in-container-is-out-of-sync/16566/11
- https://github.com/docker/for-mac/issues/17