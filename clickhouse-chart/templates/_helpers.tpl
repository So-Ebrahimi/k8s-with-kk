{{- define "clickhouse.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "clickhouse.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "clickhouse.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
