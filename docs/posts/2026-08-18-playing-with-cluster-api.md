---
date: 2026-08-25
tags:
  - aws
  - kubernetes
  - capi
---

# Playing with Cluster API

I have for a long time wanted to play around with Cluster API (CAPI) and I finally got around to test it at work recently. This post will mainly cover how to quickly get up and running using a local Kubernetes distribution as management cluster and provisioning an AWS EKS cluster with CAPI.

### Bootstrapping

CAPI requires a CloudFormation stack to be provisioned and by using [`clusterawsadm`](https://github.com/kubernetes-sigs/cluster-api-provider-aws) we can first output a bootstrap config file for us to tweak and then create the stack.

```bash
# Output bootstrap config
clusterawsadm bootstrap iam print-config > bootstrap-config.yaml

# Create CloudFormation stack
clusterawsadm bootstrap iam create-cloudformation-stack --config bootstrap-config.yaml
```

Up front the `bootstrap-config.yaml` file doesn't need any tweaking, but it's good to have if we need to do changes at a later stage.

```bash
# Update CloudFormation stack
clusterawsadm bootstrap iam update-cloudformation-stack --config bootstrap-config.yaml
```

### Local management cluster

For some reason I like [`minikube`](https://minikube.sigs.k8s.io/), but you can choose any other local Kubernetes distribution like k3s, kind etc.. Let's start the cluster.

```bash
# Start local Kubernetes cluster and wait for it to be ready
minikube start --wait=all
```

We now need to initialize CAPI with an AWS provider on our local management cluster using [`clusterctl`](https://github.com/kubernetes-sigs/cluster-api).

```bash
# Initialize CAPI with AWS specific provider
AWS_B64ENCODED_CREDENTIALS=$(shell clusterawsadm bootstrap credentials encode-as-profile --profile ${AWS_PROFILE}) \
  EXP_MACHINE_POOL=true \
  EXP_CLUSTER_RESOURCE_SET=true \
  CAPA_EKS_IAM=true \
  CAPA_EKS_ADD_ROLES=true \
  clusterctl init --infrastructure aws
```

We set a bunch of feature flags that are good defaults and I find enablement of **EXP_MACHINE_POOL** absolutely essential for simplification.

* **EXP_MACHINE_POOL** enables the experimental Machine Pool feature, allowing you to manage groups of machines as a single unit with common configurations.
* **EXP_CLUSTER_RESOURCE_SET** enables experimental ClusterResourceSet support, which lets you automatically apply resources to clusters when they're created.
* **CAPA_EKS_IAM** enables IAM role management for EKS clusters, allowing Cluster API to create and configure IAM roles needed by EKS.
* **CAPA_EKS_ADD_ROLES** enables automatic addition of required IAM roles to worker nodes, ensuring they have proper permissions to join and operate in the EKS cluster

The above command will install cert-manager and the following Cluster API providers: cluster-api, bootstrap-kubeadm, control-plane-kubeadm and infrastructure-aws.

### Provision workload cluster

Before we begin provisioning, an SSH key pair is required, so we'll provision one using the AWS CLI.

```bash
# Create SSH key pair
aws ec2 create-key-pair --key-name workload --output json
```

We are now ready to generate the manifests for our new cluster.

```bash
# Create directory for cluster manifests
mkdir k8s/

# Generate cluster manifests
AWS_REGION=${AWS_REGION} \
  AWS_SSH_KEY_NAME=workload \
  AWS_CONTROL_PLANE_MACHINE_TYPE=t3.large \
  AWS_NODE_MACHINE_TYPE=t3.large \
  WORKER_MACHINE_COUNT=1 \
  CLUSTER_NAME=workload \
  CLUSTER_VERSION=1.36 \
  clusterctl generate cluster ${CLUSTER_NAME} --kubernetes-version ${CLUSTER_VERSION} --flavor eks-managedmachinepool > k8s/manifests.yaml
```

It is advised that you inspect the manifests before applying them.

```bash
# Apply workload cluster manifests
kubectl apply -f k8s/
```

We can now watch progress on workload cluster provisioning.

```bash
# Watch workload cluster provisioning
clusterctl describe cluster workload
```

It will take some time to provision, so go grab something to drink. Once provisioned we can gain access to our new workload cluster using the following command.

```bash
# Get kubeconfig of workload cluster
clusterctl get kubeconfig workload
```

### Backup and restore

We can easily backup and restore using the following commands.

```bash
# Create backup folder
mkdir backup/

# Take backup
clusterctl move --to-directory backup/

# Restore from backup
clusterctl move --from-directory backup/
```

This means that our management cluster can potentially become ephemeral, assuming we can live without reconciliation.

### Clean up

We can easily clean up. But it is important that we wait for the CAPI controllers to clean up AWS resources and that takes time.

```bash
# Take backup (just to be sure)
clusterctl move --to-directory backup/

# Delete workload cluster (IMPORTANT: this will take some time since the controllers need to do cleanup, so be patient)
kubectl delete -f k8s/

# Delete SSH key pair
aws ec2 delete-key-pair --key-name default

# Delete management cluster
minikube delete

# Delete CloudFormation stack
clusterawsadm bootstrap iam delete-cloudformation-stack
```
