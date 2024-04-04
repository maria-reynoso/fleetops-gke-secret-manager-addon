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
SECRET_NAME="alertmanager-config"
gcloud secrets create $SECRET_NAME \
    --replication-policy="automatic"
```

```sh
FILE_NAME="alertmanager/alertmanager-config.yaml"
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

Create monitoring namespace

```sh
kubectl create namespace monitoring
```

Deploy `SecretProviderClass`:

```sh
kubectl apply -f deploy/manifests/app-secrets.yaml
```

Create alertmanager service account Bind the IAM service account to alertmanager service account

```sh
kubectl apply -f alertmanager/service-account.yaml

gcloud iam service-accounts add-iam-policy-binding \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:jetstack-maria.svc.id.goog[monitoring/alertmanager-secret-sa]" \
    fleetops@jetstack-maria.iam.gserviceaccount.com
```

## Deploy Prometheus and Alertmanager

```sh
make deploy
```