{% set count = 4 %}

# open all ports for other nodes in cluster
# maybe open just for services?
{% for host in salt['pillar.get']( 'hosts' ) %}
  {% set host_ip = salt['openstack_utils.minion_ip']( host ) %}
  {% set count = count + 1 %}
open openstack node {{ host }} on firewall:
  # TODO: set to just the vxlan ports?
  cmd.run:
    - name: iptables -I INPUT {{ count }} -t filter -s {{ host_ip }} -m state --state NEW -j ACCEPT && service iptables save && true
    - unless: iptables -C INPUT -s {{ host_ip }} -m state --state NEW -j ACCEPT
{% endfor %}

{% set novnc_port = salt['pillar.get']('services:novnc:url:public:service_port', 6080 ) %}
open novnc on firewall:
  cmd.run:
    - name: iptables -I INPUT {{ count + 1 }} -t filter -m state --state NEW -p tcp --dport {{ novnc_port }} -j ACCEPT && service iptables save && true
    - unless: iptables -C INPUT -m state --state NEW -p tcp --dport {{ novnc_port }} -j ACCEPT

# open the ports for the public facing services
{% if grains['id'] in salt['pillar.get']('controller',[]) %}

{% for service in ( 'keystone', 'nova', 'neutron', 'cinder', 'glance', 'horizon' ) %}
{% set port = salt['openstack_utils.service_urls']( service, by_ip=True )['public_port'] %}
open {{ service }} service on firewall:
  cmd.run:
    - name: iptables -I INPUT {{ count + 2 + loop.index }} -t filter -m state --state NEW -p tcp --dport {{ port }} -j ACCEPT && service iptables save && true
    - unless: iptables -C INPUT -m state --state NEW -p tcp --dport {{ port }} -j ACCEPT

{% endfor %}

{% endif %}