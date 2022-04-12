# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

{{/*
Expand the name of the chart.
*/}}
{{- define "wc-sites.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "wc-sites.fullname" -}}
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
{{- define "wc-sites.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wc-sites.labels" -}}
helm.sh/chart: {{ include "wc-sites.chart" . }}
{{ include "wc-sites.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "wc-sites.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wc-sites.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "wc-sites.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "wc-sites.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Build the database URL
*/}}
{{- define "wc-sites.databaseUrl" -}}
{{- if (.Values.oracledb.url) }}
{{- .Values.oracledb.url }}
{{- else }}
{{- .Release.Name }}-oracledb.{{ .Release.Namespace }}.svc.cluster.local:{{ .Values.oracledb.service.port }}/{{ .Values.oracledb.pdb }}.{{ .Values.oracledb.domain }}
{{- end }}
{{- end }}

