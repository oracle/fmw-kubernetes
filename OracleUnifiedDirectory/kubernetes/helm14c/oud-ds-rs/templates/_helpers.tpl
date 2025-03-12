#
# Copyright (c) 2020, 2022, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl
#
{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "oud-ds-rs.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "oud-ds-rs.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "oud-ds-rs.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "oud-ds-rs.labels" -}}
helm.sh/chart: {{ include "oud-ds-rs.chart" . }}
{{ include "oud-ds-rs.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
PV labels
*/}}
{{- define "oud-ds-rs-pv.labels" -}}
{{ include "oud-ds-rs.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "oud-ds-rs.selectorLabels" -}}
app.kubernetes.io/name: {{ include "oud-ds-rs.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "oud-ds-rs.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "oud-ds-rs.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Generate Self-signed Certificates for oud-ds-rs
Ref: sprig's crypto
*/}}
{{- define "oud-ds-rs.gen-selfsigned-certs" -}}
{{- $altNames := list ( printf "%s.%s" (include "oud-ds-rs.name" .) .Release.Namespace ) ( printf "%s.%s.svc" (include "oud-ds-rs.name" .) .Release.Namespace ) ( printf "%s-admin" (include "oud-ds-rs.fullname" .) ) ( printf "%s-http" (include "oud-ds-rs.fullname" .) ) ( printf "%s" (.Values.ingress.admin.host) ) ( printf "%s" (.Values.ingress.http.host) ) ( printf "%s.%s" (.Values.ingress.admin.host) (.Values.ingress.admin.domain) ) ( printf "%s.%s" (.Values.ingress.http.host) (.Values.ingress.http.domain) ) -}}
{{- $certCN := default ( include "oud-ds-rs.fullname" . ) (.Values.ingress.certCN) -}}
{{- $cert := genSelfSignedCert $certCN nil $altNames (.Values.ingress.certValidityDays | int) -}}
tls.crt: {{ $cert.Cert | b64enc }}
tls.key: {{ $cert.Key | b64enc }}
{{- end -}}

{{- define "es-discovery-hosts" -}}
{{- $nodes := list -}}
{{- $fullname := ( include "oud-ds-rs.fullname" . ) -}}
{{- range int .Values.elk.elasticsearch.esreplicas | until -}}
{{- $nodes = ( printf "%s-es-cluster-%d.%s-elasticsearch" $fullname . $fullname ) | append $nodes -}}
{{- end -}}
{{- join "," $nodes -}}
{{- end -}}
