{{/*
Expand the name of the chart.
*/}}
{{- define "openapi-servers.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "openapi-servers.fullname" -}}
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
{{- define "openapi-servers.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "openapi-servers.labels" -}}
helm.sh/chart: {{ include "openapi-servers.chart" . }}
{{ include "openapi-servers.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "openapi-servers.selectorLabels" -}}
app.kubernetes.io/name: {{ include "openapi-servers.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "openapi-servers.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "openapi-servers.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate the image pull secret
*/}}
{{- define "openapi-servers.imagePullSecret" -}}
{{- with .Values.imageCredentials }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}

{{/*
Get the image repository for a tool
*/}}
{{- define "openapi-servers.imageRepository" -}}
{{- $toolConfig := index .Values.tools .toolName -}}
{{- printf "%s/%s/%s" .Values.global.registry .Values.global.repository $toolConfig.image.repository }}
{{- end }}

{{/*
Get the image tag for a tool
*/}}
{{- define "openapi-servers.imageTag" -}}
{{- $toolConfig := index .Values.tools .toolName -}}
{{- $toolConfig.image.tag | default .Values.global.tag }}
{{- end }}

{{/*
Create a list of enabled tools
*/}}
{{- define "openapi-servers.enabledTools" -}}
{{- $tools := list -}}
{{- range $toolName, $toolConfig := .Values.tools -}}
{{- if $toolConfig.enabled -}}
{{- $tools = append $tools $toolName -}}
{{- end -}}
{{- end -}}
{{- $tools | join "," }}
{{- end }}
