environment_name: "farm10"
openstack_series: "kilo"
db_engine: "mysql"
message_queue_engine: "rabbitmq"

debug_mode: False
# ignore certificate validation checks
ssl_insecure: True

system_upgrade: False
reset: ~

# add proxy for yum installs etc.
# http_proxy:
#   proto: http
#   server: sccs-ytl.slac.stanford.edu
#   port: 3128

# list of all hosts participating in openstack cluster
hosts:
  controller.local: 192.168.33.11
  compute01.local: 192.168.33.12

# assign roles to each host; please also refer to networking.sls
controller: controller.local
# TODO: HA controllers
# controllers:
  # - controller01.local
  # - controller02.local
network: controller.local
# TODO: Multiple network nodes
# network:
  # - controller01.local
  # - controller02.local
storage:
  - controller.local
compute:
  - controller.local
  - compute01.local
  

# block file storage
cinder:
  volumes_group_name: "cinder-volumes"
  volumes_path: "/var/lib/cinder/cinder-volumes"
  volumes_group_size: 2
  loopback_device: "/dev/loop0"

# compute configurations
nova:
  cpu_allocation_ratio: "16"
  ram_allocation_ratio: "1.5"

# vm images
glance:
  images:
    cirros-0.3.4-x86_64:
      user: "admin"
      tenant: "admin"
      parameters:
        min_disk: 1
        min_ram: 512
        copy_from: "http://www.slac.stanford.edu/~ytl/cirros-0.3.4-x86_64-disk.img"
        user: admin
        tenant: admin
        disk_format: qcow2
        container_format: bare
        # visibility: public
        protected: False

