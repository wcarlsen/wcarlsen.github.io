---
date: 2026-11-14
tags:
  - kubernetes
  - kubectl
  - flux
  - gitops
---

# Kubectl patch and field manager

These days it is rather rare that I in my day-to-day work discover things I didn't already know about Kubernetes. But this week I did and this is a story about that.

### The thing I didn't understand

While working on a project where we needed to suspend a specific Flux `Kustomization` resource to pause its reconciliation loop, to allow for manual intervention, we saw a discrepancy between using a specific Flux cli command `flux suspend kustomization` and a regular patch `kubectl patch kustomization` to add `spec.suspend = true`. The Flux cli preserved the suspended state of the `Kustomization` resource over time, where the `kubectl patch` approach eventually lost the suspended state. At first glance there seems to be no real noticeable difference between the approaches, when inspecting the resource. I also read through the source code of what Flux cli does and apart from a deep copy, the two approaches do the exact same thing. So what is going on here?

### Why are `flux suspend` and `kubectl patch` not the same

When getting a resource with and outputting it `kubectl get <name> -o yaml`, we are actually missing something from the output called managed fields. It is disabled by default, but can be turned on with the `--show-managed-fields=true` flag. When knowing this we can actually spot the discrepancy between the two approaches. Under `metadata.managedFields` there is a field called manager and this is preserved as `'flux'` when using `flux suspend`, but when using `kubectl patch` it is changed to `'kubectl-patch'`. It seems like the reconciler can spot this difference and hence kicks the `Kustomization` resource back into place and that resumes the resource. If we take a look at the `kubectl patch --help` command we can also see that it has a flag `--field-manager='kubectl-patch'`, so maybe it isn't that surprising after all. If we set this flag to `'flux'` when patching it then preserves the suspended state over time.

### Conclusion

We need to be super careful when using `kubectl patch`, when there are controllers and reconcilers involved. It was of course AI that suggested using `kubectl patch` instead of the native Flux cli in this case for a colleague. Luckily we learned something here, so the wasted time wasn't totally in vain.
