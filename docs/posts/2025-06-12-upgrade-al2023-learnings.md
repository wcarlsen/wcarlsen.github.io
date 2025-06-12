---
date: 2025-06-12
tags:
  - aws
  - kubernetes
---

# Upgrade from AL2 to AL2023 learnings

Ever since AWS annouced that Amazon Linux 2023 (AL2023) AMI type is replacing Amazon Linux 2 (AL2), I have been excited about it. Mainly because of the cgroup v2 upgrade and the improved security with IMDSv2. To explain it quick

* cgroup v2 should provide more transparency when container sub-processes are OOM killed.
* IMDSv2 will block pods calling the metadata service on the nodes (getting an AWS context) due to a network hop limit.

The AMI upgrade is needed for upgrading worker nodes on EKS from 1.32 to 1.33, since no AL2 AMI is build for 1.33.

Upon testing we found a few things breaking, but nothing major. The [AWS load balancer controller broke](https://github.com/kubernetes-sigs/aws-load-balancer-controller), but only needed the `--aws-vpc-id` and `--aws-region` flag set to work again. We ended up removing the [spot-termination-exporter](https://github.com/gjtempleton/spot-termination-exporter) (supplying insight into spot-instance interruptions), since it realies heavily on the metadata service, which was now blocked. Sad, but we have lived without it before.

We then went on to upgrading all clusters and worker nodes to version 1.33. The upgrade went smooth except for one thing that we overlooked. We rely on [flux image-reflector-controller](https://fluxcd.io/flux/components/image/) to scan container registries and that also uses the metadata service to use get context of the nodes. Luckily this was a fairly easy fix, where we ended up [patching an IRSA role annotation to the image-reflector-controller ServiceAccount](https://fluxcd.io/flux/components/image/imagerepositories/#aws) in following way.

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - gotk-components.yaml
  - gotk-sync.yaml
patches:
  - patch: |
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: image-reflector-controller
        annotations:
          eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/eks_CLUSTER_NAME_flux-image-reflector
    target:
      kind: ServiceAccount
      name: image-reflector-controller
```

We are now enjoing AL2023 and are so far happy with the upgrade.
