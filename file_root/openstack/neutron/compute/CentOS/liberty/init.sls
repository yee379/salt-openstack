{% set neutron = salt['openstack_utils.neutron']() %}

include:
  - openstack.neutron.compute.CentOS.liberty

# TODO: how to we ensure that the neutron services restart if this changes?
ensure symlink for openvswitch_agent.ini:
  file.symlink:
    - name: /etc/neutron/plugins/ml2/openvswitch_agent.ini
    - target: {{ neutron['conf']['ml2'] }}
    - force: True
    - backupname: /etc/neutron/plugins/ml2/openvswitch_agent.ini.orig
