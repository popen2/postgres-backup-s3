# Postgres Backup to S3

A Docker image for backing up a Postgres database to an S3 bucket.

## Environment Variables

The image expects the following environment varialbes:

| Variable       | Description                                                                                                                                                                                           |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| BUCKET_NAME    | S3 bucket name                                                                                                                                                                                        |
| BUCKET_REGION  | S3 bucket region                                                                                                                                                                                      |
| S3_PREFIX      | S3 bucket prefix for storing the backups. Each backup object is stored in an object named by the current time under the prefix. For example: `s3://${PREFIX}/2022-11-24T11:40:31+00:00.pgdump.bz2.nc` |
| ENCRYPTION_KEY | Key used to encrypt the backup using `mcrypt`.                                                                                                                                                        |


## Image Tags

Image tags are formatted by `vXX.Y` where `XX` matches the Postgres major version.

For example, the `v14.0` image is based on `postgres:14`.

## Using in a Kubernetes CronJob

For reference, this Helm template creates a Kubernetes CronJob that backs up a database every hour:

In `values.yaml`:

```yaml
dbBackup:
  config:
    bucketName: ""
    bucketRegion: ""
  image:
    repository: popen2/postgres-backup-s3
    pullPolicy: IfNotPresent
    tag: v14.0
  serviceAccount:
    create: true
    annotations: {}
    name: ""
```

Then create `templates/backup/cronjob.yaml` and fill `PGHOST` etc. variables from actual values or secrets:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ .Release.Name }}-db-backup
spec:
  schedule: "0 * * * *"
  concurrencyPolicy: Replace
  successfulJobsHistoryLimit: 1
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      backoffLimit: 0
      template:
        spec:
          serviceAccountName: {{ .Release.Name }}-db-backup
          containers:
            - name: db-backup
              image: "{{ .Values.dbBackup.image.repository }}:{{ .Values.dbBackup.image.tag }}"
              imagePullPolicy: IfNotPresent
              env:
                - name: PGHOST
                  value: ""  # TODO
                - name: PGPORT
                  value: "5432"
                - name: PGDATABASE
                  value: ""  # TODO
                - name: PGUSER
                  value: ""  # TODO
                - name: PGPASSWORD
                  valueFrom:
                    secretKeyRef:
                      name: ""  # TODO
                      key: ""  #TODO
                - name: BUCKET_NAME
                  value: {{ .Values.dbBackup.config.bucketName }}
                - name: BUCKET_REGION
                  value: {{ .Values.dbBackup.config.bucketRegion }}
              volumeMounts:
                - name: homedir
                  mountPath: /home/user
          restartPolicy: Never
          volumes:
            - name: homedir
              emptyDir: {}
```

And the corresponding `ServiceAccount` under `templates/backup/serviceaccount.yaml`:

```yaml
{{- if .Values.dbBackup.serviceAccount.create -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ .Release.Name }}-db-backup
  labels:
    {{- include "chart.labels" . | nindent 4 }}
  {{- with .Values.dbBackup.serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
```
