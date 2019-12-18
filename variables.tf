/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "project_id" {
  description = "The project ID to deploy to"
}

###gcp common
variable "gcp_network" {
  description = "Network to use in GCP"
  default     = "default"
}

variable "gcp_subnet_name" {
  description = "GCP subnetwork name for a given network"
  default     = "default"
}

variable "gcp_instance_zone" {
  description = "Zone for instances to use"
  default     = "europe-west3-b"
}

variable "gcp_instance_region" {
  description = "GCP region to deploy instances"
  default     = "europe-west3"
}

###vmetrics storage
variable "vmetrics_storage_vm_count" {
  description = "Count of nodes that will be used as VictoriaMetrics Storage"
  default = "1"
}
variable "vmetrics_storage_instance_name" {
  description = "Storage node instance name"
  default = "vmetrics-storage-node"
}
variable "vmetrics_storage_machine_type" {
  description = "Storage node machine type"
  default = "g1-small"
}
variable "vmetrics_storage_disk_type" {
  description = "Storage node disk type"
  default = "pd-standard"
}
variable "vmetrics_storage_disk_size" {
  description = "Storage node disk size"
  default = "10"
}
variable "vmetrics_storage_instance_image" {
  description = "Storage instance disk image"
  default = "cos-cloud/cos-stable"
}

###vmetrics reader
variable "vmetrics_select_vm_count" {
  description = "Count of nodes that will be used as VictoriaMetrics Select"
  default = "2"
}
variable "vmetrics_select_machine_type" {
  description = "Select node machine type"
  default = "g1-small"
}
variable "vmetrics_select_disk_type" {
  description = "Select node disk type"
  default = "pd-standard"
}
variable "vmetrics_select_disk_size" {
  description = "Select node disk size"
  default = "10"
}
variable "vmetrics_select_instance_image" {
  description = "Reader instance disk image"
  default = "cos-cloud/cos-stable"
}

###vmetrics writer
variable "vmetrics_insert_vm_count" {
  description = "Count of nodes that will be used as VictoriaMetrics Insert"
  default = "2"
}
variable "vmetrics_insert_machine_type" {
  description = "Insert node machine type"
  default = "g1-small"
}
variable "vmetrics_insert_disk_type" {
  description = "Insert node disk type"
  default = "pd-standard"
}
variable "vmetrics_insert_disk_size" {
  description = "Insert node disk size"
  default = "10"
}
variable "vmetrics_insert_instance_image" {
  description = "Writer instance disk image"
  default = "cos-cloud/cos-stable"
}

