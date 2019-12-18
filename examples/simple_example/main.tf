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

provider "google" {
  version = "~> 2.0"
}

resource "google_compute_router" "default_router"{
  project = var.project_id

  name    = "router"
  network = var.network
  region = var.region
}

resource "google_compute_router_nat" "nat" {
  project = var.project_id

  region = var.region
  name                               = "router-nat"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  router                             = google_compute_router.default_router.name

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

module "VictoriaMetrics" {
  source = "../.."

  project_id  = var.project_id
  gcp_network = var.network
  gcp_instance_region = var.region
}
