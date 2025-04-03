---
date: 2025-04-03
tags:
  - docker-hub
  - aws
  - kubernetes
  - renovate
---

# Docker Hub rate limits

Docker Hub recently announced 10 pulls/hour for unauthenticated users. This has pretty significant impact in container orchestration, e.g. Kubernetes. I will not cover whether it is fair or not, but give credit to Docker Hub for its contributions to the community.

So how does this rate limit impact Kubernetes?

It can be hard to predict how many images will be pulled when a new node joins the cluster from an operator/administrator perspective.

How could you solve it?

We've opted for implementing a AWS ECR pull through cache. It is easy to setup and works like a charm.

Where there any side effects?

1. All image references in manifests has to change from `nginx:latest` to `ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/docker-hub/nginx:latest` (don't use latest)

2. Flux GitOps ImageAutomationUpdate breaks for CRD resources that reference images

3. Renovate updates breaks because the cache doesn't have knowledge of new tags

I will try to cover possible solutions for above side effects in future posts.