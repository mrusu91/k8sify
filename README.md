# k8sify

[Kubernetes](https://kubernetes.io/) cluster build tool for DevOps

This tool is intended for devops/infra engineers who want to build a Kubernetes cluster while being in control of every step.
This tool uses ansible to build the infrastructure needed to run the cluster.
Only [AWS](https://aws.amazon.com/) is supported for now.


If you just want a cluster running, there are other good tools [out there](https://kubernetes.io/docs/setup/pick-right-solution/)

By default running this tool you will end up with 3 Autoscaling groups, one for etcd, one for master and one for workers spanning across all availabitity zones, one ELB for Etcd and one for Kubernetes API, 

The bastion is running [CFSSL](https://cfssl.org/) CA PKI that will be used by instances to generate certificates at boot time

NOTE: Container Linux by CoreOS is used as source OS and we install python on it using [ansible-coreos-bootstrap](https://github.com/defunctzombie/ansible-coreos-bootstrap) role so we can provision it with ansible

## Kubernetes Network

This tool uses flannel [CNI](https://kubernetes.io/docs/concepts/cluster-administration/network-plugins/) for pods network which require flannel daemon on each instance. You need to run `provision_addons.yml` which will run flannel as a DaemonSet using host network namespace. If you miss this step any other pods will not run.

## Instructions

### Create the VPC
- Build the ansible environment by running `make build`
- Activate the ansible environment by running `source .ve/bin/activate`
- Ensure you have AWS secrets in the environment
- Update `vars/all.yml` variables if necessary
- Create the VPC and it's components by running `ansible-playbook vpc.yml`
- Update `vars/all.yml` variables with outputed values from previous step
- Create the bastion host by running `ansible-playbook provision_bastion.yml -t create`
- Ensure you can SSH into bastion (you may need security-group rules, or the key in ssh-agent)
- Maybe change CSRs from `templates/cfssl/` and `templates/certfetcher/`
- Provision the bastion host by running `ansible-playbook provision_bastion.yml -t bootstrap,provision`
- Update `vars/all.yml` variables with outputed values from previous step
- Update the `ssh.config` file with the actual `bastion_public_ip` value

### Create the AMIs
- Create the ami_build_etcd host by running `ansible-playbook ami_etcd.yml -t create`
- Provision the ani_build_etcd host by running `ansible-playbook ami_etcd.yml -t bootstrap,provision`
- Create the AMI for etcd by running  `ansible-playbook ami_etcd.yml -t ami`
- Update `vars/all.yml` variables with outputed values from previous step
- Make sure the ami_build_etcd instance is terminated


- Create service account key by running `ansible-playbook service_account.yml`
- Create the ami_build_master host by running `ansible-playbook ami_master.yml -t create`
- Provision the ani_build_master host by running `ansible-playbook ami_master.yml -t bootstrap,provision`
- Create the AMI for kubernetes master by running  `ansible-playbook ami_master.yml -t ami`
- Update `vars/all.yml` variables with outputed values from previous step
- Make sure the ami_build_master instance is terminated


- Create the ami_build_worker host by running `ansible-playbook ami_worker.yml -t create`
- Provision the ani_build_worker host by running `ansible-playbook ami_worker.yml -t bootstrap,provision`
- Create the AMI for kubernetes worker by running  `ansible-playbook ami_worker.yml -t ami`
- Update `vars/all.yml` variables with outputed values from previous step
- Make sure the ami_build_worker instance is terminated


### Lauch the instances

- Create the Lauch Configuration and the AutoscalingGroup for Etcd by running `ansible-playbook provision_etcd.yml`
- Create the Lauch Configuration and the AutoscalingGroup for Kubernetes Master by running `ansible-playbook provision_master.yml`
- Create the Lauch Configuration and the AutoscalingGroup for Kubernetes Worker by running `ansible-playbook provision_worker.yml`

### Kubernetes addons
- Make sure you have `kubectl` in your `PATH` and properly configured (You can test it by running `kubectl get node`)
- Run `ansible-playbook provision_addons.yml`

### Cluster access HACK
- You can SSH into any host by proxying through bastion host, example: `ssh -F ssh.config core@10.0.10.59`
- You can Download `kubectl` binary version `1.6.6` from [here](https://storage.googleapis.com/kubernetes-release/release/v1.6.6/bin/linux/amd64/kubectl)
- You can access kubernetes master by forwarding it's port to localhost(`ssh -F ssh.config -L 6443:localhost:6443 core@10.0.10.59`) and adding `127.0.0.1 kubernetes` into `/etc/hosts`
- You need to generate yourself a cert-key pair from the same CA (I usually steal thw worker's one)
- kubectl config example:
```
apiVersion: v1
kind: Config
clusters:
- name: default
  cluster:
    certificate-authority: ca.pem
    server: "https://kubernetes:6443"
users:
- name: marian
  user:
    client-certificate: marian.pem
    client-key: marian-key.pem
contexts:
- name: default-context
  context:
    cluster: default
    user: marian
current-context: default-context
```


## Useful links

 * [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
 * [CoreOS Tectonic](https://github.com/coreos/tectonic-installer)
 * [DigitalOcean Kubernetes TLS](https://www.digitalocean.com/company/blog/vault-and-kubernetes/)
 * [Kubernetes Cluster Administration](https://kubernetes.io/docs/tasks/administer-cluster/overview/)

