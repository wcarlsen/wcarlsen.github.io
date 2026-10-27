---
date: 2026-10-27
tags:
  - kubernetes
  - flux
  - helm
  - flate
  - gitops
---

# Working with FluxCD `HelmReleases`

If you have ever worked with FluxCD and `HelmReleases` you know that it is very easy to change a Helm charts values or update chart version, but the problem is that it very hard to get any feedback on that change client side. Flux doesn't have functionality to render the Helm chart for you, so you can see the actual changes to the underlying manifests. Overall it is not a very fun developer experience and personally I would like it to be free of any server side stuff.

### Flate to the rescue

[`flate`](https://github.com/home-operations/flate) is a go rewrite of the depricated tool [flux-local](https://github.com/allenporter/flux-local). It offers offline rendering and diffing of `HelmReleases` among other things. This means that can run `flate diff hr <NAME_OF_HELMRELEASE>` on a change and view the diff the rendered Helm chart compare to my main branch. If I want to render the full Helm chart I would run `flate build hr <NAME_OF_HELMRELEASE>` and inspect the manifests. Lastly we can also use it to extract CRDs by running `flate build hr <NAME_OF_HELMRELEASE> --only-crds`.

`flate` seems to solve so many of the issues with working with FluxCD `HelmReleases` and I highly recommend you take it for a spin.
