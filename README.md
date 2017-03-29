# Continuul Kubernetes Deployment Tool

This tool wraps the entire, properly configured, kops and kubectl
tool in a Docker to simply use by removing all installation steps.

## Documentation

- https://kubernetes.io/docs/getting-started-guides/kops/

## Creating a Kubernetes Cluster

## Making sure you’re ready

Check that kubectl is properly configured by getting the cluster state:
$ kubectl cluster-info
If you see a url response, you are ready to go.

## Software Versions Included

The following is the list of installed software and their versions:

- Dig (9.10.3)
- Python (2.7.12)
- Python Pip (8.1.1)
- VirtualEnv (15.1.0)
- AWSCLI (1.11.68)
- Kubectl (1.6.0)
- Kops (1.4.1)

