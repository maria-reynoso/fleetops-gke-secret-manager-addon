# fleetops-gke-secret-manager-addon

Using Secret Manager addon for GKE

## Requirments:
- Create your Venafi as a [Service account](https://vaas.venafi.com/jetstack) and copy the API key from your user preferences.

## Deploy cluster with secret manager addon enabled

```sh
gcloud beta container clusters create fleetops \
    --enable-secret-manager \
    --location=europe-west2-a \
    --cluster-version=1.29 \
    --workload-pool=jetstack-maria.svc.id.goog
```

## Create secret in Secret Manager 

```sh
SECRET_NAME="venafi-api"
gcloud secrets create $SECRET_NAME \
    --replication-policy="automatic"
```

```sh
FILE_NAME="api_key"
gcloud secrets versions add $SECRET_NAME --data-file=$FILE_NAME
```

## Grant access

Grant the IAM service account permission to access the secret

To grant the service account permission to access the secret, run the following command:

```sh
gcloud secrets add-iam-policy-binding $SECRET_NAME \
    --member=serviceAccount:fleetops@jetstack-maria.iam.gserviceaccount.com \
    --role=roles/secretmanager.secretAccessor
```

## Create SecretProviderClass

Create cert-manager namespace

```sh
kubectl create ns cert-manager
```

Deploy `SecretProviderClass`:

```sh
kubectl apply -f deploy/manifests/app-secrets.yaml
```

## Deploy cert-manager

Edit values.yaml

```yaml
...
serviceAccount:
  # Specifies whether a service account should be created.
  create: true
  # Workload identity
  annotations:
    iam.gke.io/gcp-service-account: fleetops@jetstack-maria.iam.gserviceaccount.com
...
# Additional volumes to add to the cert-manager controller pod.
volumes:
- name: cloudflare-api
  csi:
    driver: secrets-store-gke.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: fleet-secrets

# Additional volume mounts to add to the cert-manager controller container.
volumeMounts:
- mountPath: "/var/secrets"
  name: cloudflare-api
...
```

Install cert-manager
```sh
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.14.4 \
  -f deploy/values.yaml
```

Bind the IAM service account to cert-manager service account

```sh
gcloud iam service-accounts add-iam-policy-binding \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:jetstack-maria.svc.id.goog[cert-manager/cert-manager]" \
    fleetops@jetstack-maria.iam.gserviceaccount.com
```

Restart cert-manager controller:

```sh
kubectl delete pod -n cert-manager cert-manager-xxxx
```

## Deploying certmanager Issuer

Configure Venafi Issuer to obtain certificates from Venafi as a Service (VaaS) or Venafi Trust Protection Platform (TPP) instances.
