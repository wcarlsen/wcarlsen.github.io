---
date: 2025-10-25
tags:
  - kubernetes
  - gitops
  - flux
---

# Handle CRDs with GitOps

In this post we will discuss caveats with full lifecycle management of Custom Resource Definitions (CRDs) with Helm in a GitOps context and give a possible solution.

### Helm caveats with CRDs lifecycle management

Helm is very good getting CRDs into the cluster at install, but updating and deleting them is where problems tend to arrise. There are solutions in place, like seperate chart for CRDs, but it is very much dependent on how the chart is structured and implemented. Helm documentation has a full section on this [here](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/). In summary they write

> There is no support at this time for upgrading or deleting CRDs using Helm. This was an explicit decision after much community discussion due to the danger for unintentional data loss. Furthermore, there is currently no community consensus around how to handle CRDs and their lifecycle. As this evolves, Helm will add support for those use cases

This means that for some charts it might work and for some it might be more challenging, leading to an incoherent experience that could be error prone.

### A possible solution

Seperating handling the CRDs out from Helm and just referencing the manifests directly via kustomize seems like an obvious solution and it works great. In GitOps with FluxCD the `HelmRelease` has the options `.spec.install.crds` and `.spec.upgrade.crds`, the latters default is `Skip` so we really only have to add it to the install portion. Some charts exposes a `installCRDs` or similar in its values, so we will also set this to `false` for clarity even though strictly not nessecary. Let's see an example of the `HelmRelease` custom resource

```yaml
# helm.yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: jetstack
  namespace: cert-manager
spec:
  interval: 15m
  url: https://charts.jetstack.io

---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: cert-manager
  namespace: cert-manager
spec:
  interval: 5m
  targetNamespace: cert-manager
  chart:
    spec:
      chart: cert-manager
      version: "v1.18.2"
      sourceRef:
        kind: HelmRepository
        name: jetstack
      interval: 15m
  install:
    crds: Skip
  values:
    installCRDs: false
    ...
```

and the kustomization file

```yaml
# kustomization.yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespaces.yaml
  - crds.yaml # the file containing all crds
  - helm.yaml
  ...
```

The CRDs can normally be generated in one of the two following ways using `helm` cli

```bash
helm show crds CHART --repo URL --version VERSION > crds.yaml
# or
helm template RELEASE_NAME CHART --repo URL --version VERSION --set installCRDs=true --kube-version KUBE_VERSION | yq '. | select(.kind == "CustomResourceDefinition")' > crds.yaml
```

for above cert-manager example the latter option works, but it is rare that it is the complex option of the two. Since we now have documented how to generate the CRDs, automation can be easily added and how I have done it will be show in later post.

To quickly conclude. A solution have been presented that manages the full lifecycle (install, update and deletion) of CRDs for helm charts with GitOps assuming pruning of resources is enabled.
