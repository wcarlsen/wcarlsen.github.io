---
date: 2026-01-10
tags:
  - grafana
---

# Cost savings Grafana Cloud follow up

In the previous post I wrote about our efforts reduce cost for Grafana Cloud metrics. Here I went over the 3 main things we implemented

* Reduced sample rates
* Filter/drop unused metrics (keep only used ones)
* Enable adaptive metrics

but I also ended up concluding that we lacked impact feedback and only had proxy indicators. Our goal was ambitious and more concrete we set out to save 80% on our metrics bill. This post serves as conclusion on our efforts.

### Conclusion

We now know that we almost reached that goal with a 78% reduction in metrics cost alone.

### Implementation aftermath

Enabling auto-mode for adaptive metrics was by far the most invasive and we saw some of the developers dashboards break, but also fewer than antisipated.
