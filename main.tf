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


locals {
  local_share_vmetrics_metadata = {
    sshKeys = "integer:${file("~/.ssh/id_rsa.pub")}"
  }

  local_vmetrics_select_metadata = {
    startup-script = "sleep 35; docker run -p 8481:8481 victoriametrics/vmselect:latest -storageNode=${google_compute_address.vmetrics_storage_internal_ip[0].address}:8401",
  }

  local_vmetrics_insert_metadata = {
    startup-script = "sleep 35; docker run -p 8480:8480 victoriametrics/vminsert:latest -storageNode=${google_compute_address.vmetrics_storage_internal_ip[0].address}:8400",
  }
  local_vmetrics_storage_metadata = {
    startup-script = "sleep 12; docker run -p 8400:8400 -p 8401:8401 -p 8482:8482 -v /mnt/stateful_partition/var/lib/vmetrics:/var/opt/vmetrics victoriametrics/vmstorage:latest -retentionPeriod 6 -storageDataPath /var/opt/vmetrics",
  }

}

data "google_compute_network" "data_network" {
  project = var.project_id
  name    = var.gcp_network
}

data "google_compute_subnetwork" "data_subnetwork" {
  project = var.project_id
  name    = var.gcp_subnet_name
  region  = var.gcp_instance_region
}

###vmetrics storage node
resource "google_compute_instance" "vmetrics_storage_vm" {
  project = var.project_id

  count        = var.vmetrics_storage_vm_count
  name         = "${var.vmetrics_storage_instance_name}${count.index}"
  machine_type = var.vmetrics_storage_machine_type
  zone         = var.gcp_instance_zone
  //  tags                      = ["healthcheck-vmetrics-external"]

  boot_disk {
    auto_delete = false
    source      = google_compute_disk.vmetrics_storage_vm_disk[count.index].name
  }

  metadata = merge(
    local.local_share_vmetrics_metadata,
    local.local_vmetrics_storage_metadata
  )

  network_interface {
    subnetwork = data.google_compute_subnetwork.data_subnetwork.self_link
    network_ip = google_compute_address.vmetrics_storage_internal_ip[count.index].address
  }

}

resource "google_compute_disk" "vmetrics_storage_vm_disk" {
  project = var.project_id

  count = var.vmetrics_storage_vm_count
  name  = "${var.vmetrics_storage_instance_name}${count.index}-disk"
  type  = var.vmetrics_storage_disk_type
  size  = var.vmetrics_storage_disk_size
  zone  = var.gcp_instance_zone
  image = var.vmetrics_storage_instance_image

  physical_block_size_bytes = 4096
}

resource "google_compute_address" "vmetrics_storage_internal_ip" {
  project = var.project_id

  count      = var.vmetrics_storage_vm_count
  name       = "${var.vmetrics_storage_instance_name}${count.index}-internal-ip"
  region     = var.gcp_instance_region
  subnetwork = data.google_compute_subnetwork.data_subnetwork.name

  address_type = "INTERNAL"
}

##select template
resource "google_compute_instance_template" "vmetrics_select_template" {
  project = var.project_id

  name_prefix = "vmetrics-select-template-"
  description = "This template is used to"

  tags = ["healthcheck-vmetrics-external"]

  labels = {
    environment = "select-vm"
  }

  instance_description = "description assigned to instances"
  machine_type         = var.vmetrics_select_machine_type
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image = var.vmetrics_select_instance_image
    disk_size_gb = var.vmetrics_select_disk_size
    disk_type    = var.vmetrics_select_disk_type

    auto_delete = true
    boot        = true
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.data_subnetwork.self_link
    //    network_ip = google_compute_address.vmetrics_internal_ip.address
  }

  metadata = merge(
    local.local_share_vmetrics_metadata,
    local.local_vmetrics_select_metadata
  )

  lifecycle {
    create_before_destroy = true
  }
}

##insert template
resource "google_compute_instance_template" "vmetrics_insert_template" {
  project = var.project_id

  name_prefix = "vmetrics-insert-template-"
  description = "This template is used to "

  tags = ["healthcheck-vmetrics-external"]

  labels = {
    environment = "insert-vm"
  }

  instance_description = "description assigned to instances"
  machine_type         = var.vmetrics_insert_machine_type
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image = var.vmetrics_insert_instance_image
    disk_size_gb = var.vmetrics_insert_disk_size
    disk_type    = var.vmetrics_insert_disk_type

    auto_delete = true
    boot        = true
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.data_subnetwork.self_link
  }

  metadata = merge(
    local.local_share_vmetrics_metadata,
    local.local_vmetrics_insert_metadata
  )

  lifecycle {
    create_before_destroy = true
  }
}

//resource "google_compute_firewall" "allow-vmetrics-ingress" {
//  project = project_id
//
//  name    = "external-vmetrics"
//  network = data.google_compute_network.data_network.name
//
//  allow {
//    protocol = "tcp"
//    ports    = ["8480", "8481", "8482"]
//  }
//  target_tags = ["vmetrics-external"]
//}


resource "google_compute_firewall" "allow_healthcheck_ingress" {
  project = var.project_id
  ## firewall rules enabling the load balancer health checks
  name    = "vmetrics-external-healthcheck"
  network = data.google_compute_network.data_network.name

  description = "allow Google health checks and network load balancers access"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["8480-8482"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
  target_tags   = ["healthcheck-vmetrics-external"]
}

#lb external address
resource "google_compute_global_address" "external_lb_address_vmetrics" {
  project = var.project_id
  name    = "vmetrics-lb-external-address"

  address_type = "EXTERNAL"
}

#lb internal storage address
//resource "google_compute_address" "internal_lb_storage_vmetrics_ip" {
//  name                      = "vmetrics-storage-lb-internal-ip"
//  region = var.region
//  subnetwork = google_compute_subnetwork.internal_subnet.name
//  address_type = "INTERNAL"
//}

#forward 8480
resource "google_compute_global_forwarding_rule" "vmetrics_forward_8480" {
  project = var.project_id

  name       = "forward-8480"
  ip_address = google_compute_global_address.external_lb_address_vmetrics.address
  port_range = "80"
  target     = google_compute_target_http_proxy.lb_vmetrics_insert.self_link
}
#forward 8481
resource "google_compute_global_forwarding_rule" "vmetrics_forward_8481" {
  project = var.project_id

  name       = "forward-8481"
  ip_address = google_compute_global_address.external_lb_address_vmetrics.address
  port_range = "8080"
  target     = google_compute_target_http_proxy.lb_vmetrics_select.self_link
}

##select pool manager
resource "google_compute_instance_group_manager" "vmetrics_select_group_manager" {
  project = var.project_id

  //  provider = "google-beta"

  name = "vmetrics-select-group-manager"
  zone = var.gcp_instance_zone

  base_instance_name = "vmetrics-select-node"
  instance_template  = google_compute_instance_template.vmetrics_select_template.self_link
  target_size        = var.vmetrics_select_vm_count
  update_strategy    = "NONE"

  named_port {
    name = "select"
    port = 8481
  }

  //
  //  auto_healing_policies {
  //    health_check = google_compute_health_check.vmetrics_health_check_reader.self_link
  //    initial_delay_sec = 60
  //  }
}

##insert pool manager
resource "google_compute_instance_group_manager" "vmetrics_insert_group_manager" {
  project = var.project_id

  //  provider = "google-beta"

  name = "vmetrics-insert-group-manager"
  zone = var.gcp_instance_zone

  base_instance_name = "vmetrics-insert-node"
  instance_template  = google_compute_instance_template.vmetrics_insert_template.self_link
  target_size        = var.vmetrics_insert_vm_count
  update_strategy    = "NONE"

  named_port {
    name = "insert"
    port = 8480
  }

  //
  //  auto_healing_policies {
  //    health_check = google_compute_health_check.vmetrics_health_check_reader.self_link
  //    initial_delay_sec = 60
  //  }
}

#select backend
resource "google_compute_backend_service" "vmetrics_select_backend" {
  project = var.project_id

  name                            = "vmetrics-select-backend"
  session_affinity                = "NONE"
  protocol                        = "HTTP"
  timeout_sec                     = 5
  connection_draining_timeout_sec = 10

  port_name = "select"

  backend {
    group = google_compute_instance_group_manager.vmetrics_select_group_manager.instance_group
  }

  health_checks = [google_compute_health_check.vmetrics_health_check_select.self_link]
}

#insert backend
resource "google_compute_backend_service" "vmetrics_insert_backend" {
  project = var.project_id

  name                            = "vmetrics-insert-backend"
  session_affinity                = "NONE"
  protocol                        = "HTTP"
  timeout_sec                     = 5
  connection_draining_timeout_sec = 10

  port_name = "insert"

  backend {
    group = google_compute_instance_group_manager.vmetrics_insert_group_manager.instance_group
  }

  health_checks = [google_compute_health_check.vmetrics_health_check_insert.self_link]
}

#lb for insert
resource "google_compute_target_http_proxy" "lb_vmetrics_insert" {
  project = var.project_id

  name    = "insert-lb"
  url_map = google_compute_url_map.vmetrics_map_insert.self_link
}
resource "google_compute_url_map" "vmetrics_map_insert" {
  project = var.project_id

  name            = "map-vmetrics-insert"
  default_service = google_compute_backend_service.vmetrics_insert_backend.self_link

  lifecycle {
    create_before_destroy = true
  }
}

#lb for select
resource "google_compute_target_http_proxy" "lb_vmetrics_select" {
  project = var.project_id

  name    = "select-lb"
  url_map = google_compute_url_map.vmetrics_map_select.self_link
}
resource "google_compute_url_map" "vmetrics_map_select" {
  project = var.project_id

  name            = "map-vmetrics-select"
  default_service = google_compute_backend_service.vmetrics_select_backend.self_link

  lifecycle {
    create_before_destroy = true
  }
}

#internal backend-lb for storage
//resource "google_compute_region_backend_service" "vmetrics_storage_backend" {
//  name                            = "region-backend-vmetrics-storage"
//  region                          = var.region
//  connection_draining_timeout_sec = 15
//  session_affinity                = "CLIENT_IP"
//
//  backend {
//    group = google_compute_instance_group.vmetrics_storage_group.self_link
//  }
//
//  health_checks                   = [google_compute_health_check.vmetrics_health_check_storage.self_link]
//
//}



#healthchecks
resource "google_compute_health_check" "vmetrics_health_check_insert" {
  project = var.project_id

  name = "vmetrics-insert-health-check"
  http_health_check {
    request_path = "/health"
    port         = 8480
  }
}
resource "google_compute_health_check" "vmetrics_health_check_select" {
  project = var.project_id

  name = "vmetrics-select-health-check"

  check_interval_sec = 5
  timeout_sec        = 5
  healthy_threshold  = 4

  http_health_check {
    request_path = "/health"
    port         = 8481
  }
}
resource "google_compute_health_check" "vmetrics_health_check_storage" {
  project = var.project_id

  name = "vmetrics-storage-health-check"
  http_health_check {
    request_path = "/health"
    port         = 8482
  }
}