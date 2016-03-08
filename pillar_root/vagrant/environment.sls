environment_name: "liberty"

openstack_series: "liberty"

db_engine: "mysql"

message_queue_engine: "rabbitmq"

reset: ~

debug_mode: True

system_upgrade: False

# add proxy for yum installs etc.
# http_proxy:
#   proto: http
#   server: sccs-ytl.slac.stanford.edu
#   port: 3128

# list of all hosts participating in openstack cluster
hosts:
  controller.local: 192.168.33.11

# assign roles to each host; please also refer to networking.sls
controller: controller.local
network: controller.local
storage:
  - controller.local
compute:
  - controller.local

# web ui frontend for openstack
horizon:
  secret_key: wyzFS4P9zBqiYe8Q2r9V
  https: False
  servername: controller.local
  SSLCertificateFile: /etc/pki/tls/certs/local.crt
  SSLCACertificateFile: /etc/pki/tls/certs/local.crt
  # SSLCertificateKeyFile: /etc/apache2/SSL/openstack.example.com.key

# authentication
keystone:
  https: True

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
        is_public: True
        protected: False

