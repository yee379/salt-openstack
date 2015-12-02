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

open novnc on firewall:
  cmd.run:
    - name: iptables -I INPUT {{ count + 1 }} -t filter -m state --state NEW -p tcp --dport 6080 -j ACCEPT && service iptables save && true
    - unless: iptables -C INPUT -m state --state NEW -p tcp --dport 6080 -j ACCEPT

{% if grains['id'] in salt['pillar.get']('controller',[]) %}

open http on firewall:
  cmd.run:
    - name: iptables -I INPUT {{ count + 2 }} -t filter -m state --state NEW -p tcp --dport 80 -j ACCEPT && service iptables save && true
    - unless: iptables -C INPUT -m state --state NEW -p tcp --dport 80 -j ACCEPT

{% if salt['pillar.get']('horizon:https',False) %}
open https on firewall:
  cmd.run:
    - name: iptables -I INPUT {{ count + 3 }} -t filter -m state --state NEW -p tcp --dport 443 -j ACCEPT && service iptables save && true
    - unless: iptables -C INPUT -m state --state NEW -p tcp --dport 443 -j ACCEPT
    - require:
      - cmd: open http on firewall
{% endif %}

{% endif %}