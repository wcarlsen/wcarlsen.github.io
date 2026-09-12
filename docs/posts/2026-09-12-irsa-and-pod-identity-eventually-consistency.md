---
date: 2026-09-12
tags:
  - aws
  - eks
  - kubernetes
  - irsa
  - pod-identity
---

# IRSA and Pod Identity compared for eventually consistency

While basically achieving the same IAM Roles for Service Accounts (IRSA) and Pod Identity namely, injecting an AWS context with temporary credentials into your Kubernetes Pod workloads. They do this in very different manner. In this post we will touch upon the differences, promises and the topic of eventually consistency.

### IRSA

When provisioning an AWS EKS cluster an OIDC provider is associated to that particular cluster. The OIDC provider is unique to the cluster and commonly lives and dies with it. We use this OIDC provider to create a federated trust with our IAM Roles to allow EKS to fetch temporary credentials. It is imporatant to note that the trust policy also has to be aware of the Namespace and ServiceAccount used and the ServiceAccount need a special annotation containing the IAM Role Arn. The last bit is important for our later discussion about eventually consistency, since we provide Kubernetes with some metadata related to our IAM Role to ServiceAccount mapping. A MutatingWebhook, hidden in the control plane, picks up workloads using a ServiceAccount annotated with the intend of consuming the IAM Role credentials and injects it.

We've can already realise a few things here:

* IRSA cannot survive cluster recreating without us updating the the IAM Role trust policy with the updated OIDC provider
* We need to provide Kubernetes with some metadata in form of a ServiceAccount annotation
* EKS doesn't need to know anything about our IAM Role to ServiceAccount mapping

### Pod Identity

Pod Identity takes a different approach than IRSA in order to solve the "cannot survive cluster recreation" problem, by replacing the OIDC federation with an EKS naitive exchange called association. A Pod Identity Association is record that maps an IAM Role to one Kubernetes ServiceAccount and the record lives entirely in EKS, hence we don't need to provide any metadata to Kubernetes. The IAM Role still need a trust policy, but it is now independent of the OIDC provider, Namespace and ServiceAccount. For Pod Identity to work we need to enable the EKS addon that provisions a DaemonSet and a MutatingWebhook. Once a Pod Identity Association has been added, the MutatingWebhook now inject credentials into the Pod.

Again we can realise a couple things of interest:

* Pod Identity can survive cluster recreating, but it requires that EKS know all the mappings between IAM Roles and ServiceAccounts
* We do not need to provide any metadata to Kuberentes
* EKS need to know about our IAM Role to ServiceAccount mappings

### Eventually consistency discussion

Since both methods essentially uses MutatingWebhooks I would argue that having Kubernetes metadata an important advantage for eventually consistency. Let's sketch out the scenario for Pod Identity.

1. We create a ServiceAccount to be referenced in a Deployment and apply it to the cluster
2. We then later create an IAM Role and add a Pod Identity Association

If the Deployments resulting Pods gets scheduled before I add my Pod Identity Association, the MutatingWebhook will never pick up on this and my Pods never gets AWS context injected. I would need to trigger a new Deployment rollout, for the MutatingWebhook to take effect.

Let's sketch out the same scenario, but for IRSA.

1. We create a ServiceAcccount to be referenced in a Deployment. But since IRSA requires Kubernetes metadata in form of an annotation referencing a Role Arn, we add this to the ServiceAccount up front eventhough the IAM Role doesn't exist yet. We apply this to the cluster
2. We then later create an IAM Role referencing the OIDC provider, Namepace and ServiceAccount

In this case our MutatingWebhook has already picked up on our intent to consume an AWS context, so eventhough we didn't provision the IAM Role before our ServiceAccount and Deployment, the Pods will eventually get the credentials injected without us triggering a Deployment rollout. This is because the MutatingWebhooks has already mutated our Pod. Kubernetes metadata provides us with the option of declaring intent up front allowing for ordering to become irrelevant and having eventually consistency. It should be stated that IRSA would have the same issue as Pod Identity if I don't annotate my ServiceAccount up front.

### Conclusion

It is extremely important to me to stress, that IRSA isn't better than Pod Identity or vice versa. They each have their strength and weaknesses and you should consider reading [this article](https://hidekazu-konishi.com/entry/amazon_eks_pod_identity_and_irsa_decision_guide.html) to learn more on the topic. But I will say that for this particular thought experiment, the Kubernetes metadata part becomes super handy and I would like to rely on eventually consistency than having to rely on correct ordering of apply.

Lastly I hope that AWS will add some sort of similar functionality to Pod Identity, so that we can declare intent up front. My naive suggestion would be an optional ServiceAccount annotation that doesn't contain the IAM Role Arn, to keep the mapping lifecycle only in EKS as already implemented.
