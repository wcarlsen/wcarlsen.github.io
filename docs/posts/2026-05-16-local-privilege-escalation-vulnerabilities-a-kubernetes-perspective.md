---
date: 2026-05-16
tags:
  - aws
  - kubernetes
  - security
---

# Thoughts on local privilege escalation vulnerabilities from a Kubernetes perspective

We have recently been hit by a wave of Linux kernel local privilege escalation vulnerabilities Copy Fail ([CVE-2026-31431](https://nvd.nist.gov/vuln/detail/CVE-2026-31431)), Dirty Frag ([CVE-2026-43284](https://nvd.nist.gov/vuln/detail/CVE-2026-43284), [CVE-2026-43500](https://nvd.nist.gov/vuln/detail/CVE-2026-43500)) and Fragnesia. While the situation isn't ideal and discovery frequency is likely driven by improvements in AI, temporary mitigations have been relatively simple. SSH into a Linux box and apply temporary mitigation or do a system security update if available and in some cases reboot afterwards. This can be done too for Kubernetes cluster nodes, but when node autoscaling enters the situation changes. So how do we handle temporary mitigations of Kubernetes cluster nodes until an official patched image is released, when we constantly get new ones and our temporarily patched nodes disappear?

### Other options available

There are several paths to follow, some more passive than others. Let's go through some of the options. The most passive one is to do nothing and just wait for an upstream fix, in this case for AWS EKS, a new AMI release. I'm confident that this option is more popular than most people realises. Another less passive but manual approach is to temporarily patch the nodes, but as we already discussed this is probably not viable if node autoscaling is a thing. Here I'm also pretty sure that for many smaller clusters without node autoscaling this was the approach chosen. There are definitely other options such as building your own image or maybe patching via user data, but these require all existing nodes to be replaced, effectively leading to extra pod disruption. Plus user data is likely to touch Terraform/OpenTofu and in AWS also the launch template, giving developers slow feedback when testing.

### My preferred option (so far)

The best approach I've seen so far is to deploy a DaemonSet with high privilege on all nodes and run your patches there. This of course adds an extra attack vector, which isn't ideal, but it is fast to develop and apply and doesn't touch the launch template, making iterations fast and lightweight. The example below is heavily inspired by an implementation provided by the [Red Hat OpenShift team](https://access.redhat.com/solutions/7142250).

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: privilege-escalation-patch
  namespace: kube-system

---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: privilege-escalation-patch
  namespace: kube-system
  labels:
    app: privilege-escalation-patch
spec:
  selector:
    matchLabels:
      app: privilege-escalation-patch
  template:
    metadata:
      labels:
        app: privilege-escalation-patch
    spec:
      serviceAccountName: privilege-escalation-patch
      nodeSelector:
        kubernetes.io/os: linux
      tolerations:
        - operator: Exists
      terminationGracePeriodSeconds: 1
      containers:
        - name: privilege-escalation-patch
          image: debian:stable
          command:
            - /bin/sh
            - "-c"
            - |
              echo "YOUR PATCH SCRIPT GOES HERE"
              sleep infinity
          lifecycle:
            preStop:
              exec:
                command:
                  - /bin/sh
                  - "-c"
                  - |
                    echo "YOUR REMOVAL OF PATCH GOES HERE IF NEEDED"
          securityContext:
            privileged: true
          volumeMounts:
            - name: host-root
              mountPath: /host
      volumes:
        - name: host-root
          hostPath:
            path: /
```
