neutron:
  
  integration_bridge: br-int
  external_bridge: br-ex

  # TODO: need to be able to have different configs per host, eg networking server needs lacp etc.
  single_nic:
    enable: True
    interface: eth1
    # lacp: True
    # interfaces:
    #   - em1
    #   - em2
    # set_up_script: "/root/br-proxy.sh"

  type_drivers:

    vlan:
     physnets:
        farm10-os-grid:
          bridge: br-proxy
          vlan_range: "238:238"
          hosts:
            controller.local: ~

    flat: 
      physnets: 
        openstack-mgmt: 
          bridge: br-ex
          hosts:
            controller.local: ~
            compute01.local: ~

    vxlan:
      physnets:
        vxlannet:
          bridge: br-tun
          hosts:
            controller.local: ~
            compute01.local: ~
      vxlan_group: 66666
      tunnels:
        tun0:
          vni_range: "60000:90000"

  tunneling:
    enable: True
    types:
      - vxlan
    bridge: br-tun

  networks:

    # management network for openstack servers and services
    OPENSTACK-MGMT:
      user: admin
      tenant: admin
      provider_physical_network: openstack-mgmt
      provider_network_type: flat
      shared: False
      admin_state_up: True
      router_external: True
      subnets:
        OPENSTACK-MGMT:
          cidr: 192.168.33.1/24
          allocation_pools:
            - start: 192.168.33.64
              end: 192.168.33.96
          enable_dhcp: False
          dns_nameservers:
            - 10.0.2.3

    # # tenant network for grid
    # FARM10-OS-GRID:
    #   user: admin
    #   tenant: admin
    #   provider_physical_network: farm10-os-grid
    #   provider_network_type: vlan
    #   shared: True
    #   admin_state_up: True
    #   router_external: True
    #   subnets:
    #     FARM10-OS-GRID:
    #       cidr: 134.79.238.0/23
    #       allocation_pools:
    #         - start: 134.79.238.10
    #           end: 134.79.238.253
    #       enable_dhcp: True
    #       dns_nameservers:
    #         - 134.79.111.111
    #         - 134.79.111.112
    #
    # tenant network for general
    VXLANNET:
      user: admin
      tenant: admin
      # not for vxlan
      # provider_physical_network: vxlannet
      provider_network_type: vxlan
      shared: True
      admin_state_up: True
      router_external: False
      subnets:
        VXLANNET:
          cidr: 10.0.0.0/24
          allocation_pools:
            - start: 10.0.0.10
              end: 10.0.0.254
          enable_dhcp: True
          dns_nameservers:
            - 134.79.111.111
            - 134.79.111.112

  routers:

    router01:
      user: admin
      tenant: admin
      gateway_network: OPENSTACK-MGMT
      interfaces:
        - VXLANNET

  security_groups:
    default:
      user: admin
      tenant: admin
      description: allow everything
      rules: 
        []
        # - direction: "<egress/ingress>"
        #   ethertype: "<IPv4/IPv6>"
        #   protocol: "<icmp/tcp/udp>"
        #   port_range_min: "<start_port>"
        #   port_range_max: "<end_port>"
        #   remote_ip_prefix: "<cidr>"
