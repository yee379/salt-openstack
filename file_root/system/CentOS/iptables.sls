{% set count = 4 %}

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

{% if grains['id'] in salt['pillar.get']('controller',[]) %}

{% set http = salt['pillar.get']('services:horizon:url:public:local_port', 80 ) %}
open http on firewall:
  cmd.run:
    - name: iptables -I INPUT {{ count + 2 }} -t filter -m state --state NEW -p tcp --dport {{ http }} -j ACCEPT && service iptables save && true
    - unless: iptables -C INPUT -m state --state NEW -p tcp --dport {{ http }} -j ACCEPT

{% if salt['pillar.get']('horizon:https',False) %}
open https on firewall:
  cmd.run:
    - name: iptables -I INPUT {{ count + 3 }} -t filter -m state --state NEW -p tcp --dport 443 -j ACCEPT && service iptables save && true
    - unless: iptables -C INPUT -m state --state NEW -p tcp --dport 443 -j ACCEPT
    - require:
      - cmd: open http on firewall
{% endif %}

{% endif %}