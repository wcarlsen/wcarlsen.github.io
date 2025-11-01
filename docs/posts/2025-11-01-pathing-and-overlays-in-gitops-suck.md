---
date: 2025-11-01
tags:
  - kubernetes
  - gitops
  - flux
---

# Patching and overlays in GitOps suck

Most implementations of Kubernetes clusters that I have come a cross, have migrated to using GitOps as the prefered method of deploying manifests, helm charts and others, and for good reason too. This isn't a rant about how great GitOps is, but rather a a discussion on how to share the same configuration across multiple clusters without extensive patching and lots of overlays.

### Why I don't like patching and overlays

If a configuration needs to be shared across many Kubernetes clusters we tend to use the pattern of creating a base configuration and then do individual patches using overlays referencing the base. I think this approach is pretty normal and probably works if you are really strict about what kind of patching you are allowing, but here also lies the pitfall. Patching allows for you to almost do anything to the base configuration, so not only is the interface potentially massive it is also not by definition well defined. You are constantly running the risk of changing something in the base that is patched somewhere in overlays anyway, so all overlays and patches must always be taken into account, probably leading to a small base and a massive overlay. With patching we also need to know the resource Kind, name and maybe namespace plus the yaml path in the spec. But remember we wanted to share as much configuration as possible, so we want as much as possible to go into base.

On top of all this I also find patches to be hard to read and not knowing your implementation up front has other drawbacks. I'm not saying that patches and overlays doesn't have their use cases, but limiting them can certainly help.

### `Envsubst` might be the solution

If you haven't heard of `envsubst`, it is a GNU package released in 1995, designed to substitute environment variable references in a given text file or string. In other words we can now parameterize e.g. a Kubernetes manifest. This means that we know where the manifest will change. Time to compare

```yaml
# base/sa.yaml for envsubst
---
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    eks.amazonaws.com/role-arn: ${KARPENTER_ROLE_ARN} # envsubst notation
  name: karpenter
  namespace: karpenter
```

and

```yaml
# base/sa.yaml for patching
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: karpenter
  namespace: karpenter

# kustomization
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ./base/sa.yaml
patches:
  - target:
      kind: ServiceAccount
      name: karpenter
      namespace: karpenter
    patch: |-
      - op: add
        path: /metadata/annotations/eks.amazonaws.com~1role-arn
        value: arn:aws:iam::1234:role/karpenter-role
```

The examples might not look so different on the surface and I also did the patching example a disfavor, but not using a placeholder and replacing that. But I wanted to show that from the base configurations point of view there is no knowledge of an annotionation, so if I where to add a similar annotation to the base it would eventually be overruled by the patch eventhough there are no indicators of it being a parameter. Also the overhead of knowing the exact resource and yaml path isn't great. Of course the envsubt example needs to be parsed through the envsubst command `KARPENTER_ROLE_ARN="arn:aws:iam::1234:role/karpenter-role" envsubst < base/sa.yaml`. But the difference is that my base configuration clearly expects a variable and I do not need to know the resource Kind, name, maybe namespace and yaml path to replace it.

### `postBuild.substitution` FluxCD equivalent of `envsubst`

FluxCD (and probably also ArgoCD) has a trick up their sleeve called `postBuild.substitution` see [here](https://fluxcd.io/flux/components/kustomize/kustomizations/#post-build-variable-substitution), which works like `envsubst`. Let take above example and try using this feature with the custom resource `Kustomization` provided by flux

```yaml
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: apps
spec:
  # ...omitted for simplicity
  postBuild:
    substitute:
      KARPENTER_ROLE_ARN: "arn:aws:iam::1234:role/karpenter-role"
```

We are anyway provisioning above resource if we are doing patching and overlays, so in my mind using post build variable substitution is just simpler and can certainly help minimizing the need for overlays and patching or even remove the need completely. I have run ~10 clusters at the same time all sharing the same configuration only using post build variable substitution and life was just so much simpler.
