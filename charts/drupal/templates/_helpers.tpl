{{- define "drupal.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "drupal.fullname" -}}
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

{{- define "drupal.labels" -}}
app.kubernetes.io/name: {{ include "drupal.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: {{ .Release.Name }}
app.kubernetes.io/component: app
{{- end }}

{{- define "drupal.selectorLabels" -}}
app: {{ include "drupal.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "drupal.dbHost" -}}
{{- if .Values.db.host }}
{{- .Values.db.host }}
{{- else if .Values.mariadb.enabled }}
{{- include "mariadb.fullname" (dict "Chart" (dict "Name" "mariadb") "Release" .Release "Values" .Values.mariadb) }}
{{- else }}
{{- fail "db.host est requis lorsque mariadb.enabled vaut false" }}
{{- end }}
{{- end }}

{{- define "drupal.dbSecret" -}}
{{- if .Values.db.existingSecret }}
{{- .Values.db.existingSecret }}
{{- else if .Values.mariadb.enabled }}
{{- include "mariadb.secretName" (dict "Chart" (dict "Name" "mariadb") "Release" .Release "Values" .Values.mariadb) }}
{{- else }}
{{- fail "db.existingSecret est requis lorsque mariadb.enabled vaut false" }}
{{- end }}
{{- end }}
