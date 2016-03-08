# definition of ports and uri endpoints for openstack instance
# architecture is that each controller node is fronted with a frontend agent that listens on the frontend port number (with ssl/tls).

# we use the service_port as the outside facing port number to use
# if proto is https (instead of http), then we need to set up an ssl/tls proxy too.
# in both cases, we proxy the requests from the outward facing service_port, decrypt if necessary, and reroute the query to the locally bounded local_port for the service

services:

  keystone:
    service_type: identity
    description: 'Openstack Identity'
    version: v2.0
    url:
      internal:
        https: True
        local_port: 15000
        service_port: 5000
        path: v2.0
      public:
        https: True
        local_port: 15000
        service_port: 5000
        path: v2.0
      admin:
        https: True
        local_port: 45357
        service_port: 35357
        path: v2.0

  # keystonev3:
  #   service_type: identity
  #   description: 'Identity Service v3'
  #   version: v3
  #   url:
  #     internal:
  #       https: False
  #       local_port: 15000
  #       service_port: 5000
  #       path: v3.0
  #     public:
  #       https: False
  #       local_port: 15000
  #       service_port: 5000
  #       path: v3.0
  #     admin:
  #       https: False
  #       local_port: 45357
  #       service_port: 35357
  #       path: v3.0

  
  # glance:
  #   service_type: image
  #   description: OpenStack Image service
  #   url:
  #     internal:
  #       https: False
  #       local_port: 9292
  #       service_port: 9292
  #     public:
  #       https: False
  #       local_port: 9292
  #       service_port: 9292
  #     admin:
  #       https: False
  #       local_port: 9292
  #       service_port: 9292
  #
  glance:
    service_type: image
    description: OpenStack Image service
    # version: v1
    url:
      internal:
        # https: True
        local_port: 19292
        service_port: 9292
        # path: v1
      public:
        # https: True
        local_port: 19292
        service_port: 9292
        # path: v1
      admin:
        # https: True
        local_port: 19292
        service_port: 9292
        # path: v1

  nova:
    service_type: compute
    description: nova compute service
    version: v2
    url:
      admin:
        https: False
        local_port: 8774
        service_port: 8774
        path: v2/%(tenant_id)s
      public:
        https: False
        local_port: 8774
        service_port: 8774
        path: v2/%(tenant_id)s
      internal:
        https: False
        local_port: 8774
        service_port: 8774
        path: v2/%(tenant_id)s

  # nova:
  #   service_type: compute
  #   description: nova compute service
  #   version: v2
  #   url:
  #     admin:
  #       https: True
  #       local_port: 18774
  #       service_port: 8774
  #       path: v2/%(tenant_id)s
  #     public:
  #       https: True
  #       local_port: 18774
  #       service_port: 8774
  #       path: v2/%(tenant_id)s
  #     internal:
  #       https: True
  #       local_port: 18774
  #       service_port: 8774
  #       path: v2/%(tenant_id)s
    
  neutron:
    service_type: network
    description: OpenStack Networking
    url:
      admin: 
        https: False
        local_port: 9696
        service_port: 9696
      internal: 
        https: False
        local_port: 9696
        service_port: 9696
      public:
        https: False
        local_port: 9696
        service_port: 9696

  cinder:
    service_type: volume
    description: OpenStack Block Storage
    version: v1
    url:
      admin:
        https: False
        local_port: 8776
        service_port: 8776
        path: v1/%(tenant_id)s
      internal:
        https: False
        local_port: 8776
        service_port: 8776
        path: v1/%(tenant_id)s
      public:
        https: False
        local_port: 8776
        service_port: 8776
        path: v1/%(tenant_id)s

  cinderv2:
    service_type: volumev2
    description: OpenStack Block Storage V2
    version: v2
    url:
      admin:
        https: False
        local_port: 8776
        service_port: 8776
        path: v2/%(tenant_id)s
      internal:
        https: False
        local_port: 8776
        service_port: 8776
        path: v2/%(tenant_id)s
      public:
        https: False
        local_port: 8776
        service_port: 8776
        path: v2/%(tenant_id)s

    
  heat:
    service_type: orchestration
    description: Openstack Orchestration Service
    version: v1
    url:
      admin:
        https: False
        local_port: 8004
        service_port: 8004
        path: v1/%(tenant_id)s
      internal:
        https: False
        local_port: 8004
        service_port: 8004
        path: v1/%(tenant_id)s
      public:
        https: False
        local_port: 8004
        service_port: 8004
        path: v1/%(tenant_id)s
      
  'heat-cfn':
    service_type: cloudformation
    description: Orchestration CloudFormation
    version: v1
    url:
      admin:
        https: False
        local_port: 8000
        service_port: 8000
        path: v1
      internal:
        https: False
        local_port: 8000
        service_port: 8000
        path: v1
      public:
        https: False
        local_port: 8000
        service_port: 8000
        path: v1
      
  novnc:
    url:
      admin:
        https: True
        local_port: 6082
        service_port: 6080
        path: vnc_auto.html
      internal:
        https: True
        local_port: 6082
        service_port: 6080
        path: vnc_auto.html
      public:
        https: True
        local_port: 6082
        service_port: 6080
        path: vnc_auto.html

  horizon:
    url:
      admin:
        https: True
        local_port: 80
        service_port: 443
      internal:
        https: True
        local_port: 80
        service_port: 443
      public:
        https: True
        local_port: 80
        service_port: 443
  
  # ceilometer:
  #   service_type: metering
  #   description: 'Telemetry Service'
  #   url:
  #     admin: https://:8777
  #     internal: https://:8777
  #     public: https://:8777
  #   port:
  #     backend: 9777
  #     frontend: 8777
  #
  # ironic:
  #   service_type: baremetal
  #   description: 'Ironic bare metal provisioning service'
  #   url:
  #     admin: https://:6385
  #     internal: https://:6385
  #     public: https://:6385
  #   port:
  #     backend: 6384
  #     frontend: 6385
  #
  # swift:
  #   service_type: object-storage
  #   frontend_vip: ""
  #   description: 'Object Storage Service'
  #   version: v1
  #   url:
  #     admin: https://:8090
  #     internal: https://:8090
  #     public: https://:8090
  #     path: v1/%(tenant_id)s
  #   port:
  #     frontend: 8090
  #     cinder_backup: 8091
  #     proxy_api: 8080
