# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

{{/*
Expand the name of the chart.
*/}}
{{- define "soa-suite.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "soa-suite.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "soa-suite.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "soa-suite.labels" -}}
helm.sh/chart: {{ include "soa-suite.chart" . }}
{{ include "soa-suite.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "soa-suite.selectorLabels" -}}
app.kubernetes.io/name: {{ include "soa-suite.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "soa-suite.serviceAccountName" -}}
{{- if .Values.domain.serviceAccount.create }}
{{- default (include "soa-suite.fullname" .) .Values.domain.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.domain.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the imagePullSecret for soa suite images
*/}}
{{- define "soa-suite.imagePullSecret" -}}
{{- with .Values.domain.imageCredentials }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}

{{/*
Update database namespace
*/}}
{{- define "soa-suite.oracledb.namespace" -}}
{{- if (.Values.oracledb.namespaceOverride) }}
{{- .Values.oracledb.namespaceOverride }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Create the imagePullSecret for Database images
*/}}
{{- define "soa-suite.oracledb.imagePullSecret" -}}
{{- with .Values.oracledb.imageCredentials }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}

{{/*
Build the database URL
*/}}
{{- define "soa-suite.databaseUrl" -}}
{{- if (.Values.oracledb.url) }}
{{- .Values.oracledb.url }}
{{- else }}
{{- .Release.Name }}-oracledb.{{( include "soa-suite.oracledb.namespace" .)}}.svc.cluster.local:1521/{{ .Values.oracledb.oracle_pdb }}
{{- end }}
{{- end }}

