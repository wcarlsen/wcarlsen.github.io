---
date: 2025-04-09
tags:
  - kubernetes
---

# Vertical pod autoscaler flush historical data

We recently had to roll out a new release of DCGM exporter, a tool that monitors Nvidia GPU performance and outputs metrics. It runs as a DaemonSet on all GPU Kubernetes nodes. With the new release there is a significant increase in memory resource consumption, normally this would be easy to handle through increasing resource requests and limits. But what happens if you decided to have Vertical Pod Autoscaler (VPA) manage resources through it's auto mode.

## Introduction to Vertical Pod Autoscaler

Have you ever deployed a new and shiny thing, no matter if its custom or something off the shelf, and felt like choosing resource requests and limits was totally unqualified. This is where Vertical Pod Autoscaler comes into the picture, it can free users from setting or guessing resource requests and limits on containers in their pods and updating them if requirements changes.

VPA can run in two modes recommendation or auto mode. Recommendation mode has a lot of value by it self by analysis current and historical resource usage, but requires you to manual changes to follow the recommended resources settings. Auto mode uses the recommendation, but can also adjust resources on the fly. This is great and has a lot of benefits among them to not waste resources on services that fluctuate and cannot scale horizontally.

We run a lot services in VPA auto mode, among them the DCGM exporter.

## Roll out new release of DCGM exporter

We already knew from testing that the DCGM exporter had a significant increase in memory resource consumption, so we changed the `maxAllowed.memory` specification on the `VerticalPodAutoscaler` custom resource. The hope was that VPA would automatically adjust resources for the DCGM exporter rather quickly, but that didn't happen. DCGM exporter went into OOMKill crashlooping mode while the recommended memory from the VPA slowly crawled upwards. The OOmKill was expected but the slow adjustment from VPA was a surprise. There where probably many contributing factors, but the crashloop backoff didn't help.

So how did we solve it?

## Flushing VPA historical data

In the end we ended up deleting the appropiate `VPACheckpoint` resource and flushing memory on the VPA recommender component.

```bash
kubectl delete vpaceckpoint -n dcgm-exporter dcgm-exporter
kubectl delete pod -n kube-system -l app=vpa-recommender
```

This almost immidiatly got the dcgm-exporter to the appropiate resources and out of OOMKill crashlooping.
