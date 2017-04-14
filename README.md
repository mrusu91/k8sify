# k8sify

[Kubernetes](https://kubernetes.io/) cluster build tool

If you just want a cluster running, this tool is not for you, there are other good tools [out there](https://kubernetes.io/docs/setup/pick-right-solution/)

This tool is intended for devops/infra engineers who want to build a Kubernetes cluster while being in control of every step.

Usage: clone, customize to fit your environment, run

This tool uses ansible to build the infrastructure needed to run the cluster.
Only [AWS](https://aws.amazon.com/) is supported for now.

By default running this tool you will end up with 2 Autoscaling groups, one for master and one for workers spanning across all availabitity zones, [Etcd](https://coreos.com/etcd/docs/latest/) running alongside master components, no persistent volumes, one ELB for Etcd and one for Kubernetes API, 

You are expected tu understand ansible, systemd units, kubernetes components, aws,

Customize the `vars/all.yml` variables (NOTE: some of the needed values you will get by running playbooks)

`vpc.yml` will create a VPC, some instance IAM roles with some policies, an EC2 keypair and and 2 ELB, one for etcd and one for k8s API, and maybe other things.

`provision_bastion.yml` will create an EC2 instance running [CFSSL](https://cfssl.org/) CA PKI that will be used by Kubernetes instances to generate certificates

`service_account.yml` will generate a RSA key that will be used by Kubernetes to sign tokens

`ami_master.yml` will create an EC2 instance, provision it with Kubernetes master components and create an AMI of it

`ami_worker.yml` will create an EC2 instance, provision it with Kubernetes worker components and create an AMI of it

`ami_worker.yml` will create an EC2 instance, provision it with Kubernetes worker components and create an AMI of it

NOTE: Container Linux by CoreOS is used as source OS and we install python on it using [ansible-coreos-bootstrap](https://github.com/defunctzombie/ansible-coreos-bootstrap) role so we can provision it with ansible

`provision_master.yml` and `provision_worker.yml` will create an EC2 Launch Configuration and an AutoscalingGroup running the AMI generated at previous steps

`provision_addons.yml` needs you to have a [kubectl](https://kubernetes.io/docs/user-guide/kubectl-overview/) set up with access to the cluster in your PATH. Will install the basic Kubernetes addons: [kube-dns](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/dns), [heapster](https://github.com/kubernetes/heapster), [dashboard](https://github.com/kubernetes/dashboard) as well as [flannel](https://github.com/coreos/flannel).

## Kubernetes Network

This tool uses flannel [CNI](https://kubernetes.io/docs/concepts/cluster-administration/network-plugins/) for pods network which require flannel daemon on each instance. You need to run `provision_addons.yml` which will run flannel as a DaemonSet using host network namespace. If you miss this step the pods will not run.

## Recommendations

* Use persistent volumes for etcd at least.
* Use [helm](https://github.com/kubernetes/helm)
* Run [cluster autoscaller](https://github.com/kubernetes/contrib/tree/master/cluster-autoscaler) pointing to the workers AutoscalingGroup, this way the cluster will manage it's size based on load. See [helm chart](https://github.com/kubernetes/charts/tree/master/stable/aws-cluster-autoscaler)


## Useful links

 * [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
 * [CoreOS Tectonic](https://github.com/coreos/tectonic-installer)
 * [DigitalOcean Kubernetes TLS](https://www.digitalocean.com/company/blog/vault-and-kubernetes/)
 * [Kubernetes Cluster Administration](https://kubernetes.io/docs/tasks/administer-cluster/overview/)

