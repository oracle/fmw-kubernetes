# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
{{/*
Expand the name of the chart.
*/}}
{{- define "oracledb-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "oracledb-operator.fullname" -}}
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
{{- define "oracledb-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels that should be added on each resource
*/}}
{{- define "common.labels" -}}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- if eq (default "helm" .Values.creator) "helm" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}
{{- end -}}
{{- if ((.Values.global).commonLabels) }}
{{ toYaml ((.Values.global).commonLabels) }}
{{- end }}
{{- end -}}


{{/*
Create a default fully qualified app namespace.
We truncate at 63 chars because Kubernetes namespace fields are limited to this (by the DNS naming spec).
*/}}
{{- define "oracledb-operator.namespace" -}}
{{- if .Values.namespace -}}
{{- .Values.namespace | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Namespace -}}
{{- end }}
{{- end }}

