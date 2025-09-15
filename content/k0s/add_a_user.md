In this tutorial, you will give a new user access to your cluster.

## Prerequisite

To illustrate this example, make sure to have access to a single node cluster created following [this previous tutorial](./single_node_multipass.md). 

Note: if you have access to a k0s cluster created differently, you will just have to adapt the commands to your context.

## Get the default kubeconfig

First you need to get the *kubeconfig* file automatically generated during the creation of the cluster (this file provides the *cluster-admin* access to the cluster), save this file into *admin.kubeconfig* and make sure to replace *localhost* with the IP address of the node:

```
multipass exec node-1 -- sudo cat /var/lib/k0s/pki/admin.conf > admin.kubeconfig
IP=$(multipass info node-1 | grep IP | awk '{print $2}')
sed -i '' "s/localhost/$IP/" admin.kubeconfig
```

In the following, you will use the *admin.kubeconfig* file to perform some administrative actions on the cluster.
In the next step you will create a new kubeconfig file that will be provided to a user, this kubeconfig file allowing restricted access to the cluster (more on that in a bit).

## Definition of a new user

k0s' *kubeconfig* subcommand allows to create a kubeconfig for an additional user/group.

:fire: In Kubernetes, users and groups are managed by an administrator outside the cluster, that means there’s no users nor groups resources in K8s.

Let's consider that within your company there is a team named *development* and a user named *dave* within that team.
Use the following command to create a new kubeconfig for that particular user:

```
$ multipass exec node-1 -- sudo k0s kubeconfig create dave --groups development > dave.kubeconfig
```

:fire: if you use a multi-node cluster, make sure to run the above command from a controller node. Indeed, the worker nodes do not have the key required to approve a Certificate Signin Request.

To get a better understanding, extract the client’s certificate from this kubeconfig file and decode it from its base64 representation:

```
$ cat dave.kubeconfig | grep client-certificate-data | awk '{print $2}' | base64 --decode > dave.crt
```

You can use the following openssl command to get the content of this certificate:

```
$ openssl x509 -in dave.crt -noout -text
```

You should get an output similar to the following one:

```
openssl x509 -in dave.crt -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            76:6b:0c:24:13:8e:a7:d6:67:c5:d7:f1:42:35:16:09:29:cc:6b:9a
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN=kubernetes-ca
        Validity
            Not Before: Jun 25 19:43:00 2021 GMT
            Not After : Jun 25 19:43:00 2022 GMT
        Subject: O=development, CN=dave
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:a2:69:e4:82:7b:13:08:51:22:6e:1b:9e:89:49:
                    0d:52:00:de:b1:97:a8:d4:e9:e1:6e:bc:f4:02:35:
                    09:cc:74:e2:71:ae:4b:39:80:f0:a6:6b:69:3d:11:
                    4e:8f:a5:f3:9b:c0:58:60:3e:9d:db:58:0b:44:58:
                    24:02:a4:a4:0c:55:a8:a9:45:ea:d2:d7:51:5b:34:
...
```

There are several important things to note:
- The issuer property is *kubernetes-ca*, which is the certification authority of our k0s cluster
- The Subject is *O = development, CN = dave*: that part is important as this is the place where the name and the group of the user appear

Because the certificate is signed by the cluster’s CA, a plugin within the api-server is able to authenticate the user/group from the common name (CN) and organisation (O) in this certificate’s subject.

## Testing the authentication of the user

First, configure your local *kubectl* with this new kubeconfig file:

```
$ export KUBECONFIG=$PWD/dave.kubeconfig
```

From this point, each time a request is sent to the API server, the user's certificate (present in the kubeconfig) is sent alongside the request.

Next, use the following imperative command to launch, in the *development* namespace, a Pod based on the *mongo* container image:

```
$ kubectl -n development run db --image=mongo:4.4
```

You should get the following error:

```
Error from server (Forbidden): pods is forbidden: User "dave" cannot create resource "pods" in API group "" in the namespace "development"
```

This error message was expected. Even if the user has been authenticated by the api-server (the certificate sent alongside the user’s request has been signed by the cluster certificate authority), he does not have the right to perform any actions in the cluster.

Additional rights could easily be added through the creation of Role/ClusterRole and bound to the user with RoleBinding/ ClusterRoleBinding.

## Adding rights to the user

As Dave is still quite new, you only want him to be able to manipulate Pods and Services within the *development* namespace. 

First use the admin.kubeconfig to create a namespace named *development*

```
export KUBECONFIG=$PWD/admin.kubeconfig
kubectl create ns development
```

Next define the following *Role* and *RoleBinding* resources in the corresponding yaml files:

- role.yaml:
```
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
 namespace: development
 name: dave
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["create", "get", "list", "delete"]
```

- role-binding.yaml
```
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
 name: dave
 namespace: development
subjects:
- kind: User
  name: dave
  apiGroup: rbac.authorization.k8s.io
roleRef:
 kind: Role
 name: dave
 apiGroup: rbac.authorization.k8s.io
```

Create those resources (still using *admin.kubeconfig* as the *dave.kubeconfig* does not allow to create RBAC related ressources, obviously :) ).

```
kubectl apply -f role.yaml -f role-binding.yaml
role.rbac.authorization.k8s.io/dave created
rolebinding.rbac.authorization.k8s.io/dave created
```

## Testing the authorization of the user

Once again, as user *dave*, try to create a Pod in the *development* namespace:

```
export KUBECONFIG=$PWD/dave.kubeconfig
kubectl -n development run db --image=mongo:4.4
```

You should no get the following result:

```
pod/db created
```

The new user can now manipulate Pods and Services through the roles that have been bound to his profile.