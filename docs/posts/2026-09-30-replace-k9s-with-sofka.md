---
date: 2026-09-30
tags:
  - sofka
  - k9s
  - gitops
  - flux
  - kubernetes
---

# Replace k9s with sofka

[`K9s`](https://github.com/derailed/k9s) has for a long time been a tool stable tool in my toolbox. It enables easy browsing and exploraiton without too much hassle. The core functionality is decent and it is extendable through plugins, eventhough it is a little bit clunky to be honest.

Recently [`sofka`](https://github.com/nklmilojevic/sofka) came onto my radar, and initially I thought it was just another Rust rewrite, but to my surprise it has some killer features that I've been missing. Let's go over some of them:

* Argo CD and Flux CD built-in capabilities for suspend, resume, and reconcile/sync their respective CustomResources with `t`. No requirement for the binaries.
* Bulk actions. Use `space` to mark multiple resources and perform an action.
* Deterministic, evidence-based incident view (no AI). If you press `X` on a broken resource it tells you why something is wrong.

I strongly recommend you take a look at this tool and see if it can replace `k9s` for you.
