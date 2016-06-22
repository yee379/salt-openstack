{% set neutron = salt['openstack_utils.neutron'](grains['id']) %}


openvswitch_bridge_single_nic_br-proxy_create:
  cmd.run:
    - name: "ovs-vsctl add-br br-proxy"
    - unless: "ovs-vsctl br-exists br-proxy"


openvswitch_bridge_single_nic_br-proxy_up:
  cmd.run:
    - name: "ip link set br-proxy promisc on mtu {{ neutron['mtu'] }}"
    - require: 
      - cmd: openvswitch_bridge_single_nic_br-proxy_create


openvswitch_{{ neutron['single_nic']['interface'] }}_up:
  cmd.run:
    - name: "ip link set {{ neutron['single_nic']['interface'] }} promisc on"
    - require:
      - cmd: openvswitch_bridge_single_nic_br-proxy_up


{% set index = 1 %}
{% for bridge in neutron['bridges'] %}
openvswitch_bridge_{{ bridge }}_create:
  cmd.run:
    - name: "ovs-vsctl add-br {{ bridge }}"
    - unless: "ovs-vsctl br-exists {{ bridge }}"
    - require:
      - cmd: openvswitch_{{ neutron['single_nic']['interface'] }}_up


openvswitch_bridge_{{ bridge }}_up:
  cmd.run:
    - name: "ip link set {{ bridge }} up mtu {{ neutron['mtu'] }}"
    - require:
      - cmd: openvswitch_bridge_{{ bridge }}_create


  {% if bridge not in [ neutron['tunneling']['bridge'], neutron['integration_bridge'], 'br-proxy' ] %}
openvswitch_veth_{{ bridge }}_create:
  cmd.run:
    - name: "ip link add veth-proxy-{{ index }} type veth peer name veth-{{ index }}-proxy mtu {{ neutron['mtu'] }}"
    - unless: "ip link list | egrep veth-proxy-{{ index }}"
    - require:
      - cmd: openvswitch_bridge_{{ bridge }}_up


openvswitch_veth-{{ index }}-proxy_add:
  cmd.run:
    - name: "ovs-vsctl add-port {{ bridge }} veth-{{ index }}-proxy"
    - unless: "ovs-vsctl list-ports {{ bridge }} | grep veth-{{ index }}-proxy"
    - require:
      - cmd: openvswitch_veth_{{ bridge }}_create


openvswitch_veth-{{ index }}-proxy_up:
  cmd.run:
    - name: "ip link set veth-{{ index }}-proxy up promisc on mtu {{ neutron['mtu'] }}"
    - require:
      - cmd: openvswitch_veth-{{ index }}-proxy_add


openvswitch_veth-proxy-{{ index }}_add:
  cmd.run:
    - name: "ovs-vsctl add-port br-proxy veth-proxy-{{ index }}"
    - unless: "ovs-vsctl list-ports br-proxy | grep veth-proxy-{{ index }}"
    - require:
      - cmd: openvswitch_veth_{{ bridge }}_create


openvswitch_veth-proxy-{{ index }}_up:
  cmd.run:
    - name: "ip link set veth-proxy-{{ index }} up promisc on"
    - require:
      - cmd: openvswitch_veth-proxy-{{ index }}_add
  {% endif %}
  {% set index = index + 1 %}
{% endfor %}

###
# create the patch ports between the proxy bridge and the internal bridge
###
openvswitch proxy-int bridge patch ports:
  cmd.run:
    - name: ovs-vsctl add-port br-proxy phy-br-proxy -- set Interface  phy-br-proxy type=patch options:peer=int-br-proxy
    - unless: ovs-vsctl list-ports br-proxy | grep phy-br-proxy
    - require:
      - cmd:  openvswitch_bridge_single_nic_br-proxy_create
      
openvswitch int-proxy bridge patch ports:
  cmd.run:
    - name: ovs-vsctl add-port br-int int-br-proxy -- set Interface  int-br-proxy type=patch options:peer=phy-br-proxy
    - unless: ovs-vsctl list-ports br-int | grep int-br-proxy
    - require:
      - cmd:  openvswitch_bridge_single_nic_br-proxy_create

