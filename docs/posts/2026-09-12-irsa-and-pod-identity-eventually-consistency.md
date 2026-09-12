---
date: 2026-09-12
tags:
  - aws
  - eks
  - kubernetes
  - irsa
  - pod-identity
---

# IRSA and Pod Identity compared for eventual consistency

While basically achieving the same IAM Roles for Service Accounts (IRSA) and Pod Identity namely, injecting an AWS context with temporary credentials into your Kubernetes Pod workloads. They do this in very different manner. In this post we will touch upon the differences, promises and the topic of eventually consistency.

### IRSA

When provisioning an AWS EKS cluster, an OIDC provider is associated with that particular cluster. The OIDC provider is unique to the cluster and commonly lives and dies with it. We use this OIDC provider to create a federated trust with our IAM Roles to allow EKS to fetch temporary credentials. It is important to note that the trust policy also has to be aware of the Namespace and ServiceAccount used, and the ServiceAccount needs a special annotation containing the IAM Role ARN. The last bit is important for our later discussion about eventual consistency, since we provide Kubernetes with some metadata related to our IAM Role to ServiceAccount mapping. A MutatingWebhook, hidden in the control plane, picks up workloads using a ServiceAccount annotated with the intention of consuming the IAM Role credentials and injects them.

We can already realise a few things here:

* IRSA cannot survive cluster recreation without us updating the IAM Role trust policy with the updated OIDC provider.
* We need to provide Kubernetes with some metadata in the form of a ServiceAccount annotation.
* EKS doesn't need to know anything about our IAM Role to ServiceAccount mapping.

### Pod Identity

Pod Identity takes a different approach than IRSA to address the "cannot survive cluster recreation" problem by replacing OIDC federation with an EKS-native exchange called an association. A Pod Identity Association is a record that maps an IAM Role to one Kubernetes ServiceAccount and the record lives entirely in EKS; hence we don't need to provide any metadata to Kubernetes. The IAM Role still needs a trust policy, but it is now independent of the OIDC provider, Namespace, and ServiceAccount. For Pod Identity to work we need to enable the EKS addon that provisions a DaemonSet and a MutatingWebhook. Once a Pod Identity Association has been added, the MutatingWebhook injects credentials into the Pod.

Again, we can realise a couple of things of interest:

* Pod Identity can survive cluster recreation, but it requires that EKS knows all the mappings between IAM Roles and ServiceAccounts.
* We do not need to provide any metadata to Kubernetes.
* EKS needs to know about our IAM Role to ServiceAccount mappings.

### Eventual consistency discussion

Since both methods essentially use MutatingWebhooks, I would argue that having Kubernetes metadata is an important advantage for eventual consistency. Let's sketch out the scenario for Pod Identity.

1. We create a ServiceAccount to be referenced in a Deployment and apply it to the cluster.
2. We then later create an IAM Role and add a Pod Identity Association.

If the Deployment's resulting Pods get scheduled before I add my Pod Identity Association, the MutatingWebhook will never pick up on this and my Pods never get AWS context injected. I would need to trigger a new Deployment rollout for the MutatingWebhook to take effect.

Let's sketch the same scenario for IRSA.

1. We create a ServiceAccount to be referenced in a Deployment. Because IRSA requires Kubernetes metadata in the form of an annotation referencing a Role ARN, we add this to the ServiceAccount up front even though the IAM Role doesn't exist yet. We apply this to the cluster.
2. We then later create an IAM Role referencing the OIDC provider, Namespace, and ServiceAccount.

In this case our MutatingWebhook has already picked up on our intent to consume an AWS context, so even though we didn't provision the IAM Role before our ServiceAccount and Deployment, the Pods will eventually get the credentials injected without us triggering a Deployment rollout. This is because the MutatingWebhook has already mutated our Pods. Kubernetes metadata provides us with the option of declaring intent up front, allowing ordering to become irrelevant and enabling eventual consistency. It should be stated that IRSA would have the same issue as Pod Identity if we do not annotate the ServiceAccount up front.

### Conclusion

It is important to stress that IRSA isn't better than Pod Identity or vice versa. They each have their strengths and weaknesses; you should consider reading [this article](https://hidekazu-konishi.com/entry/amazon_eks_pod_identity_and_irsa_decision_guide.html) to learn more on the topic. For this particular thought experiment, the Kubernetes metadata part becomes very handy, and I prefer relying on eventual consistency rather than relying on correct apply ordering.

Lastly, I hope that AWS will add some similar functionality to Pod Identity so that we can declare intent up front. My naive suggestion would be an optional ServiceAccount annotation that doesn't contain the IAM Role ARN, to keep the mapping lifecycle only in EKS as already implemented.
