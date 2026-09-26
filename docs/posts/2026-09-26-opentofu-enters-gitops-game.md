---
date: 2026-09-26
tags:
  - opentofu
  - terraform
  - tofu-controller
  - gitops
  - flux
  - kubernetes
---

# OpenTofu enters the GitOps game

It has long been established that OpenTofu/Terraform is a strong tool for managing infrastructure and for great reason. Write your changes, review the plan and apply once you’re happy with the outcome. The wide landscape of providers and modules makes it hard to overlook for complex setups. Then Kubernetes controllers and GitOps entered the arena, with their fancy reconciliation loops, pull based approach and a different lifecycle than the rest. Suddenly Terraform and OpenTofu felt ancient and slow. In this post we will see if we can make OpenTofu catch up to Crossplane, ACK and their likes using [tofu-controller](https://flux-iac.github.io/tofu-controller/).

### Introduction of tofu-controller

Tofu-controller should be considered as an extension of FluxCD version 2, because FluxCD is a requirement. It brings OpenTofu/Terraform capabilities to FluxCD, by adding a `Terraform` CustomResourceDefinition and adding a tofu-controller Deployment to your cluster. A `Terraform` custom resource is very similar to FluxCD’s `Kustomization`. In its core we need to reference source like a git repository, a path to find our OpenTofu code and a reconciliation interval. The FluxCD’s source controller will then pull your repository and tofu-controller will create a pod that will run ‘tofu apply’ automatically at the given path at a given reconciliation interval. There is of course more complexity and configuration options to it than discussed here, but for now it will do. But in this simple example we have extended OpenTofu with pull based apply and drift detection (reconciliation). By default tofu-controller uses Kubernetes Secrets as remote state backend, but it can be overwritten. It also stores its plan in a Secret. Below I have borrowed a high level diagram it works from their own documentation.

![tofu-controller](../assets/images/tofu-controller.png)

Lastly lets inspect a simple example of a minimal `Terrafrom` resource:

```yaml
apiVersion: infra.contrib.fluxcd.io/v1alpha2
kind: Terraform
metadata:
  name: example
  namespace: flux-system
spec:
  interval: 5m
  approvePlan: auto
  path: ./
  sourceRef:
    kind: GitRepository
    name: example-repository
    namespace: flux-system
```

### Conclusion

In conclusion this probably makes OpenTofu/Terraform somewhat relevant as an alternative to Crossplane, ACK and others. Tofu-controller isn't perfect in any way and should also be considered relative as a relative immature project. Personally I was positively surprised by the simplicity of the project and I would also consider it an viable option.
