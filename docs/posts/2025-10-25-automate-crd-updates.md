---
date: 2025-10-25
tags:
  - kubernetes
  - gitops
  - flux
  - helm
  - github
---

# Automate CRD updates

In the previous post about **Handle CRDs with GitOps** I showed that CRDs for a helm chart can be generated using the `helm` cli and this enabled us to manage the full lifecycle of CRDs. In this post I will show automation around this, so that a helm chart version update triggers updates to the CRDs aswell.


### Requirements

* helm
* yq

### Creating recipies for CRD generation

Considering our previous example for a `HelmRelease` for cert-manager

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

we can create the following recipe for generating CRDs using `Makefiles` (other technologies can be used)

```make
version := $(shell yq '. | select(.kind == "HelmRelease") | .spec.chart.spec.version' helm.yaml)
url := $(shell yq '. | select(.kind == "HelmRepository") | .spec.url' helm.yaml)
chart := $(shell yq '. | select(.kind == "HelmRelease") | .spec.chart.spec.chart' helm.yaml)
kube_version := v1.22.0 # required >= 1.22.0
release_name := $(shell yq '. | select(.kind == "HelmRelease") | .metadata.name' helm.yaml)

crds.yaml: helm.yaml
	helm template $(release_name) $(chart) --repo $(url) --version $(version) --set installCRDs=true --kube-version $(kube_version) | yq '. | select(.kind == "CustomResourceDefinition")' > $@
```

now any updates made to `helm.yaml` will trigger a generation and overwrite of `crds.yaml` if `make` is run.

### Creating a Github action

I have now showed that we can update CRDs manually if our helm chart version changes using `make`. Now the choice of choosing `make` makes our life a little bit difficult. In the root of our project I will create one `Makefile` to call `make` on all other `Makefile`'s


```make
base_dir := apps # path to our collection of HelmReleases
charts_with_crds := $(shell find $(base_dir) -name 'Makefile' -printf "%h\n")

all: $(charts_with_crds)

$(charts_with_crds):
	@$(MAKE) -C $@

.PHONY: all $(charts_with_crds)
```

above `Makefile` is really complex and wasn't fun to write at all. Let's finish with the Github Action

```yaml
# .github/workflows/update-crds.yaml
name: Update CRDs
on:
  pull_request:
    paths:
      - "apps/*/**.yaml"
      - "apps/*/**.yml"
jobs:
  update-crds:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
      with:
        ref: ${{ github.event.pull_request.head.ref }}

    - uses: alexellis/arkade-get@master
      with:
        helm: latest
        yq: latest

    - name: Get changed helm files
      id: changed-files
      uses: tj-actions/changed-files@v46
      with:
        files: |
          apps/*/helm.yaml

    - name: Touch all changed helm files
      env:
        ALL_CHANGED_FILES: ${{ steps.changed-files.outputs.all_changed_files }}
      run: |
        for file in ${ALL_CHANGED_FILES}; do
          echo "touching file: ${file}"
          touch ${file}
        done

    - name: Update CRDs
      run: make

    - uses: EndBug/add-and-commit@v9
      with:
        add: ./apps/*/crds.yaml
        message: "Update CRDs"
```

So now when updates are made to our `helm.yaml` files updated `crds.yaml` are commited back by above workflow. The benefit is that changes to CRDs becomes really transparent.
