---
date: 2025-07-23
tags:
  - kubernetes
---

# Client side validations of Kubernetes manifests

To be honest writing Kubernetes manifests can be tedius and it prone to misconfiguration. Of course it will in the end be validated server side, but we would like to avoid most errors before we hand off the manifests to the API server. This can be particular helpful when utilizing GitOps, since the changes will be consumed asynchronous. To achieve this will use the following tooling:


* [pre-commit](https://pre-commit.com/)
* [kustomize](https://kustomize.io/)
* [kubeconform](https://github.com/yannh/kubeconform)
* [CRDs catalog by Datree](https://github.com/datreeio/CRDs-catalog)
* [Github action pre-commit](https://github.com/pre-commit/action)[^1]

Let's start with `kustomize` and make sure that we can actually build our manifest bundle.

```bash
kustomize build path-to-kustomziation-file
```

We can now add this to `.pre-commit-config.yaml` file to the root of the project to have it run every time we commit.

```yaml
repos:
- repo: local
  hooks:
  - id: kustomize
    name: validate kustmoizations
    language: system
    entry: kustomize
    args:
    - build
    - path-to-kustomziation-file
    always_run: true
    pass_filenames: false
```

Now on to `kubeconform` for validating our manifests.

```bash
kubeconform -strict -skip CustomResourceDefinition,Kustomization \
  -kubernetes-version 1.33.0 \
  -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  path-to-your-manifests
```

We of course depend on the CRDs catalog having our CRs and them being updated, but it is relatively easy to contribute to the catalog see PRs [#453](https://github.com/datreeio/CRDs-catalog/pull/453) and [#600](https://github.com/datreeio/CRDs-catalog/pull/600).

We can now also add this to our pre-commit config file like so.

```yaml
repos:
...
- repo: local
  hooks:
  - id: kubeconform
    name: validate kubernetes manifests
    language: system
    entry: kubeconform
    args:
    - -strict
    - -skip
    - -kubernetes-version 1.33.0
    - CustomResourceDefinition,Kustomization
    - -schema-location
    - default
    - -schema-location
    - 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
    files: ^path-to-your-manifests/.*
```

Using `pre-commit` is nice to validate your commits, but it requires everybody to install it and running `pre-commit install`. So to enforce above validations we can add a CI step in the form of a Github action.


```yaml
name: Pre-commit
on:
  - pull_request
jobs:
  pre-commit:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-python@v5
    - uses: alexellis/arkade-get@master
      with:
        kustomize: latest
        kubeconform: latest
    - uses: pre-commit/action@v3.0.1
```

This setup is not bullet proof, but it do add some extra confidence and it is very low effort to get going.

[^1]: This action is in maintenance-only mode and you should support the project by using [pre-commit.ci](https://pre-commit.ci/) instead. But so that everyone can follow the other option is used.
