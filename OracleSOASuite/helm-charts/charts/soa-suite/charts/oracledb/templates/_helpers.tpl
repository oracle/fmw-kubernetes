# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#

{{/*
Expand the name of the chart.
*/}}
{{- define "oracledb-name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "oracledb-fullname" -}}
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
Create a default fully qualified app namespace.
We truncate at 63 chars because Kubernetes namespace fields are limited to this (by the DNS naming spec).
*/}}
{{- define "oracledb-namespace" -}}
{{- if .Values.namespaceOverride -}}
{{- .Values.namespaceOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Namespace -}}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "oracledb-chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "oracledb-labels" }}
labels:
  app: {{ template "oracledb-fullname" . }}
  chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
  release: {{ .Release.Name }}
  heritage: {{ .Release.Service }}
{{- end }}

{{/* Expand Variables using a template for 12c*/}}
{{- define "oracledb-env-12c" }}
env:
  - name: SVC_HOST
    value: "{{ template "oracledb-fullname" . }}"
  - name: SVC_PORT
    value: "1521"
  - name: DB_SID
    value: {{ default "ORCLCDB" .Values.oracle_sid | quote }}
  - name: DB_PDB
    value: {{ default "ORCLPDB1" .Values.oracle_pdb | quote }}
  - name: DB_PASSWD
    valueFrom:
      secretKeyRef:
        {{- if .Values.credentials.secretName }}
        name: {{ .Values.credentials.secretName }}
        {{- else }}
        name: {{ template "oracledb-fullname" . }}
        {{- end }}
        key: password
{{- end }}

{{/* Expand Variables using a template */}}
{{- define "oracledb-env" }}
env:
  - name: SVC_HOST
    value: "{{ template "oracledb-fullname" . }}"
  - name: SVC_PORT
    value: "1521"
  - name: ORACLE_SID
    value: {{ default "ORCLCDB" .Values.oracle_sid | quote }}
  - name: ORACLE_PDB
    value: {{ default "ORCLPDB1" .Values.oracle_pdb | quote }}
  - name: ORACLE_PWD
    valueFrom:
      secretKeyRef:
        {{- if .Values.credentials.secretName }}
        name: {{ .Values.credentials.secretName }}
        {{- else }}
        name: {{ template "oracledb-fullname" . }}
        {{- end }}
        key: password
  - name: ORACLE_CHARACTERSET
    value: {{ default "ORCLPDB1" .Values.oracle_characterset | quote }}
  - name: ORACLE_EDITION
    value: {{ default "enterprise" .Values.oracle_edition | quote }}
  - name: ENABLE_ARCHIVELOG
    value: {{ default false .Values.enable_archivelog | quote}}
{{- end }}

