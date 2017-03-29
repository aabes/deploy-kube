# Continuul Kubernetes Deployment Tool

This tool wraps the entire, properly configured, kops and kubectl
tool in a Docker to simply use by removing all installation steps.

## Documentation

- [Kubernetes Operations (kops)](https://kubernetes.io/docs/getting-started-guides/kops)
- [Tutorial for launching a Kubernetes cluster hosted on AWS](https://github.com/kubernetes/kops/blob/master/docs/aws.md)
- [Exporting Config for Kube Ctl](https://github.com/kubernetes/kops/blob/master/docs/tips.md#create-kubecfg-settings-for-kubectl)
- [Kubernetes on AWS (Daemonza)](https://daemonza.github.io/2017/01/15/kubernetes-on-aws/)

## Creating a Kubernetes Cluster

### 0. Set up an Alias

We're going to be using Docker as a tool to deploy Kubernetes. To keep the command line
simpler let's set up an alias after our favorite beer:

```
alias chimay='docker run -e KOPS_STATE_STORE=s3://clusters.dev.continuul.io --privileged -it -v /etc/localtime:/etc/localtime:ro -v $(pwd)/aws:/root/.aws -v $(pwd)/r53-ns-batch.json:/tmp/r53-ns-batch.json -v $(pwd)/kube:/root/.kube -v $(pwd)/ssh:/root/.ssh:ro continuul/deploy-kube:0.1.0'
```

### 0. Set up AWS Credentials

```
$ mkdir aws kube ssh
$ chimay aws configure
$ cat aws/config 
 [default]
 region = us-east-1
$ cat aws/credentials 
 [default]
 aws_access_key_id = ****
 aws_secret_access_key = ****
```


### 1. Create a Route53 Domain for your Cluster

```
$ chimay aws route53 create-hosted-zone --name dev.continuul.io --caller-reference 1
```

Sample Output:

```text
{
    "HostedZone": {
        "ResourceRecordSetCount": 2, 
        "CallerReference": "1", 
        "Config": {
            "PrivateZone": false
        }, 
        "Id": "/hostedzone/****", 
        "Name": "dev.continuul.io."
    }, 
    "DelegationSet": {
        "NameServers": [
            "ns-1692.awsdns-19.co.uk", 
            "ns-1100.awsdns-09.org", 
            "ns-721.awsdns-26.net", 
            "ns-458.awsdns-57.com"
        ]
    }, 
    "Location": "https://route53.amazonaws.com/2013-04-01/hostedzone/****", 
    "ChangeInfo": {
        "Status": "PENDING", 
        "SubmittedAt": "2017-03-29T14:09:17.554Z", 
        "Id": "/change/****"
    }
}
```

Note the name servers for the next step...

Create a file named r53-ns-batch.json:

```json
{
  "Comment": "reference subdomain of dev.continuul.io cluster",
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "dev.continuul.io",
        "Type": "NS",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "ns-1100.awsdns-09.org"
          },
          {
            "Value": "ns-1692.awsdns-19.co.uk"
          },
          {
            "Value": "ns-721.awsdns-26.net"
          },
          {
            "Value": "ns-458.awsdns-57.com"
          }
        ]
      }
    }
  ]
}
```

Then list your hosted zones:

```bash
$ chimay aws route53 list-hosted-zones
```

FATAL:

```text
An error occurred (InvalidChangeBatch) when calling the ChangeResourceRecordSets operation: RRSet with DNS name dev.continuul.io. is not permitted in zone k8s.continuul.io.
```

Sample output is:

```text
{
    "HostedZones": [
        {
            "ResourceRecordSetCount": 2, 
            "CallerReference": "152EEF11-D57E-4B74-8016-D9D6E204DF67", 
            "Config": {
                "PrivateZone": false
            }, 
            "Id": "/hostedzone/****", 
            "Name": "test-cluster.continuul.io."
        }, 
        {
            "ResourceRecordSetCount": 2, 
            "CallerReference": "C3D11DD7-AC47-45AC-8AD4-F75B9CDD2FBB", 
            "Config": {
                "PrivateZone": false
            }, 
            "Id": "/hostedzone/****", 
            "Name": "k8s.continuul.io."
        }, 
        {
            "ResourceRecordSetCount": 4, 
            "CallerReference": "1", 
            "Config": {
                "PrivateZone": false
            }, 
            "Id": "/hostedzone/****", 
            "Name": "dev.continuul.io."
        }
    ]
}
```

Using the parent zone, above, apply the change:

```bash
$ chimay aws route53 change-resource-record-sets --hosted-zone-id Z1A77WSH128J3T --change-batch file:///tmp/r53-ns-batch.json
```

### 2. Create an S3 Bucket to Store Clusters State

```
$ chimay aws s3 mb s3://clusters.dev.continuul.io
 make_bucket: clusters.dev.continuul.io
```

### Build your Cluster Configuration

```
chimay kops create cluster --zones=us-east-1c useast1.dev.continuul.io
```

Sample Output:

```
I0329 14:20:01.706476       1 create_cluster.go:331] Inferred --cloud=aws from zone "us-east-1c"
I0329 14:20:01.713819       1 cluster.go:391] Assigned CIDR 172.20.96.0/19 to zone us-east-1c
I0329 14:20:02.760829       1 populate_cluster_spec.go:196] Defaulting DNS zone to: ****
W0329 14:20:02.772546       1 channel.go:84] Multiple matching images in channel for cloudprovider "aws"
W0329 14:20:02.772598       1 channel.go:84] Multiple matching images in channel for cloudprovider "aws"
Previewing changes that will be made:

I0329 14:20:04.235422       1 executor.go:68] Tasks: 0 done / 51 total; 26 can run
I0329 14:20:04.738209       1 executor.go:68] Tasks: 26 done / 51 total; 10 can run
I0329 14:20:05.058728       1 executor.go:68] Tasks: 36 done / 51 total; 13 can run
I0329 14:20:06.389860       1 executor.go:68] Tasks: 49 done / 51 total; 2 can run
I0329 14:20:07.580127       1 executor.go:68] Tasks: 51 done / 51 total; 0 can run
Will create resources:
  ManagedFile         	managedFile/useast1.dev.continuul.io-addons-bootstrap-core
  	Location            	addons/core/v1.4.0.yaml

  Keypair             	keypair/kubecfg
  	Subject             	cn=kubecfg
  	Type                	client

  DHCPOptions         	dhcpOptions/useast1.dev.continuul.io
  	DomainName          	ec2.internal
  	DomainNameServers   	AmazonProvidedDNS

  ManagedFile         	managedFile/useast1.dev.continuul.io-addons-bootstrap-dns-controller
  	Location            	addons/dns-controller/v1.4.1.yaml

  Secret              	secret/system-dns

  SSHKey              	sshKey/kubernetes.useast1.dev.continuul.io-d7:94:71:7f:fa:ea:a0:a7:c1:23:7d:25:9d:16:ce:b8
  	KeyFingerprint      	2d:b3:92:35:3a:13:7d:f7:ab:8f:69:2b:21:7d:a9:79

  EBSVolume           	ebsVolume/us-east-1c.etcd-main.useast1.dev.continuul.io
  	AvailabilityZone    	us-east-1c
  	VolumeType          	gp2
  	SizeGB              	20
  	Encrypted           	false
  	Tags                	{k8s.io/role/master: 1, Name: us-east-1c.etcd-main.useast1.dev.continuul.io, KubernetesCluster: useast1.dev.continuul.io, k8s.io/etcd/main: us-east-1c/us-east-1c}

  EBSVolume           	ebsVolume/us-east-1c.etcd-events.useast1.dev.continuul.io
  	AvailabilityZone    	us-east-1c
  	VolumeType          	gp2
  	SizeGB              	20
  	Encrypted           	false
  	Tags                	{k8s.io/etcd/events: us-east-1c/us-east-1c, k8s.io/role/master: 1, Name: us-east-1c.etcd-events.useast1.dev.continuul.io, KubernetesCluster: useast1.dev.continuul.io}

  Secret              	secret/admin

  Keypair             	keypair/master
  	Subject             	cn=kubernetes-master
  	Type                	server
  	AlternateNames      	[100.64.0.1, api.internal.useast1.dev.continuul.io, api.useast1.dev.continuul.io, kubernetes, kubernetes.default, kubernetes.default.svc, kubernetes.default.svc.cluster.local]

  Secret              	secret/system-logging

  Secret              	secret/system-controller_manager

  ManagedFile         	managedFile/useast1.dev.continuul.io-addons-bootstrap-kube-dns
  	Location            	addons/kube-dns/v1.4.0.yaml

  Secret              	secret/kube-proxy

  VPC                 	vpc/useast1.dev.continuul.io
  	CIDR                	172.20.0.0/16
  	EnableDNSHostnames  	true
  	EnableDNSSupport    	true
  	Shared              	false

  Keypair             	keypair/kubelet
  	Subject             	cn=kubelet
  	Type                	client

  IAMRole             	iamRole/masters.useast1.dev.continuul.io

  IAMRole             	iamRole/nodes.useast1.dev.continuul.io

  Secret              	secret/kube

  Secret              	secret/kubelet

  Secret              	secret/system-monitoring

  IAMInstanceProfile  	iamInstanceProfile/nodes.useast1.dev.continuul.io

  IAMInstanceProfile  	iamInstanceProfile/masters.useast1.dev.continuul.io

  ManagedFile         	managedFile/useast1.dev.continuul.io-addons-bootstrap
  	Location            	addons/bootstrap-channel.yaml

  Secret              	secret/system-scheduler

  IAMInstanceProfileRole	iamInstanceProfileRole/masters.useast1.dev.continuul.io
  	InstanceProfile     	id:masters.useast1.dev.continuul.io

  SecurityGroup       	securityGroup/nodes.useast1.dev.continuul.io
  	Description         	Security group for nodes
  	RemoveExtraRules    	true

  SecurityGroup       	securityGroup/masters.useast1.dev.continuul.io
  	Description         	Security group for masters
  	RemoveExtraRules    	true

  VPCDHCPOptionsAssociation	vpcDHDCPOptionsAssociation/useast1.dev.continuul.io

  IAMInstanceProfileRole	iamInstanceProfileRole/nodes.useast1.dev.continuul.io
  	InstanceProfile     	id:nodes.useast1.dev.continuul.io

  IAMRolePolicy       	iamRolePolicy/nodes.useast1.dev.continuul.io

  IAMRolePolicy       	iamRolePolicy/masters.useast1.dev.continuul.io

  RouteTable          	routeTable/useast1.dev.continuul.io

  InternetGateway     	internetGateway/useast1.dev.continuul.io
  	Shared              	false

  Subnet              	subnet/us-east-1c.useast1.dev.continuul.io
  	AvailabilityZone    	us-east-1c
  	CIDR                	172.20.96.0/19
  	Shared              	false

  SecurityGroupRule   	securityGroupRule/all-master-to-master

  Route               	route/0.0.0.0/0
  	CIDR                	0.0.0.0/0

  SecurityGroupRule   	securityGroupRule/all-node-to-master

  SecurityGroupRule   	securityGroupRule/master-egress
  	CIDR                	0.0.0.0/0
  	Egress              	true

  SecurityGroupRule   	securityGroupRule/https-external-to-master
  	CIDR                	0.0.0.0/0
  	Protocol            	tcp
  	FromPort            	443
  	ToPort              	443

  SecurityGroupRule   	securityGroupRule/node-egress
  	CIDR                	0.0.0.0/0
  	Egress              	true

  SecurityGroupRule   	securityGroupRule/all-node-to-node

  SecurityGroupRule   	securityGroupRule/ssh-external-to-node
  	CIDR                	0.0.0.0/0
  	Protocol            	tcp
  	FromPort            	22
  	ToPort              	22

  SecurityGroupRule   	securityGroupRule/all-master-to-node

  RouteTableAssociation	routeTableAssociation/us-east-1c.useast1.dev.continuul.io

  SecurityGroupRule   	securityGroupRule/ssh-external-to-master
  	CIDR                	0.0.0.0/0
  	Protocol            	tcp
  	FromPort            	22
  	ToPort              	22

  LaunchConfiguration 	launchConfiguration/nodes.useast1.dev.continuul.io
  	ImageID             	kope.io/k8s-1.4-debian-jessie-amd64-hvm-ebs-2016-10-21
  	InstanceType        	t2.medium
  	SSHKey              	id:kubernetes.useast1.dev.continuul.io-d7:94:71:7f:fa:ea:a0:a7:c1:23:7d:25:9d:16:ce:b8
  	SecurityGroups      	[id:<nil>]
  	AssociatePublicIP   	true
  	IAMInstanceProfile  	id:nodes.useast1.dev.continuul.io
  	RootVolumeSize      	20
  	RootVolumeType      	gp2

  LaunchConfiguration 	launchConfiguration/master-us-east-1c.masters.useast1.dev.continuul.io
  	ImageID             	kope.io/k8s-1.4-debian-jessie-amd64-hvm-ebs-2016-10-21
  	InstanceType        	m3.medium
  	SSHKey              	id:kubernetes.useast1.dev.continuul.io-d7:94:71:7f:fa:ea:a0:a7:c1:23:7d:25:9d:16:ce:b8
  	SecurityGroups      	[id:<nil>]
  	AssociatePublicIP   	true
  	IAMInstanceProfile  	id:masters.useast1.dev.continuul.io
  	RootVolumeSize      	20
  	RootVolumeType      	gp2

  AutoscalingGroup    	autoscalingGroup/nodes.useast1.dev.continuul.io
  	MinSize             	2
  	MaxSize             	2
  	Subnets             	[id:<nil>]
  	Tags                	{k8s.io/role/node: 1, Name: nodes.useast1.dev.continuul.io, KubernetesCluster: useast1.dev.continuul.io}

  AutoscalingGroup    	autoscalingGroup/master-us-east-1c.masters.useast1.dev.continuul.io
  	MinSize             	1
  	MaxSize             	1
  	Subnets             	[id:<nil>]
  	Tags                	{k8s.io/role/master: 1, Name: master-us-east-1c.masters.useast1.dev.continuul.io, KubernetesCluster: useast1.dev.continuul.io}


Cluster configuration has been created.

Suggestions:
 * list clusters with: kops get cluster
 * edit this cluster with: kops edit cluster useast1.dev.continuul.io
 * edit your node instance group: kops edit ig --name=useast1.dev.continuul.io nodes
 * edit your master instance group: kops edit ig --name=useast1.dev.continuul.io master-us-east-1c

Finally configure your cluster with: kops update cluster useast1.dev.continuul.io --yes
```

### Create the Cluster

```text
chimay kops update cluster useast1.dev.continuul.io --yes
```

### Export the Kube Config

```text
chimay kops export kubecfg useast1.dev.continuul.io
```

Now lets test this...

```text
$ chimay kubectl get pods
 The connection to the server api.useast1.dev.continuul.io was refused - did you specify the right host or port?
```

ISSUE: We need a named route for route53 and DNS entries to resolve that host.

## Making sure you’re ready

Check that kubectl is properly configured by getting the cluster state:
$ kubectl cluster-info
If you see a url response, you are ready to go.

### Deleting the Cluster

```bash
$ chimay kops delete cluster useast1.dev.continuul.io --yes
```

## Software Versions Included

The following is the list of installed software and their versions:

- dig (9.10.3)
- python (2.7.12)
- python pip (8.1.1)
- virtualenv (15.1.0)
- awscli (1.11.68)
- kubectl (1.6.0)
- kops (1.5.3)
