---
date: 2025-12-06
tags:
  - grafana
---

# Cost savings efforts for metrics on Grafana Cloud

Grafana Cloud is an appealing option for an observability stack and offloading a selfhosted setup to a managed one gives me peace of mind. I only really have two main complains and it is all related to cost. Metrics and users cost are simply too high, with the metrics one being the worst offender. It forces you to not just enable metrics and be happy, but now you have to do heavy filtering up front on metrics and only keep the ones you think you need. You also have to consider if any of the metrics have a high cardinality label and dropping the labels or use Grafana Cloud's adaptive setup.

We have just gone through a week trying to reduced metrics cost and this post will describe our efforts attempted. It is still unclear exactly what the impact on cost will be, but we have seen a huge decline in active series, high cardinality labels and over sampling.

### Sample rate savings

In our efforts to save cost on metrics we took a look at our sample rates (scrape intervals) and saw that in some cases we had way to high resolution on metrics, 5 seconds in a few worst cases. Our default was 30 seconds, so we decided to be conservative and bump the resolution to 120 seconds. This strikes the perfect balance between enough resolution visualization, alerting and more, without our alerts being too much delayed. This is heavily inspired from learnings done in my old company Veo.

### Filter unused metrics

We went through all of our services and controllers and reviewed if the metrics we scraped was actually used for something. This process was time consuming and a bit error prone, but it also had pretty significant effort on active metrics series. This is probably somethings we should have done a long time ago, but never really got the time for it. Here is an example of doing it with a `ServiceMonitor`


```yaml
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
...
spec:
  endpoints:
    - path: /metrics
      port: metrics
      metricRelabelings:
        - action: keep
          sourceLabels: [__name__]
          regex: "your_cool_metric_0|your_cool_metrics_1"
...
```

### Enable adaptive metrics

As a last option we enable auto-mode for adaptive metrics, which means that it will automatically adjust the rules over time. This will remove a bunch of labels and most likely also useful ones. But we wanted to reduce cost a lot, so drastic measures where needed. Critically missing labels can always be put back in with excemptions or segments, but this approach could probably quickly become unmanageable in terms of rules exceptions.


### Lacking cost impact feedback

We quickly found out that the way Grafana Cloud does billing dashboards you are kind of flying blind and you are left with proxy dashboards such as active metrics series and sample rate. I will give a short update once we actually realise the savings achieved.
