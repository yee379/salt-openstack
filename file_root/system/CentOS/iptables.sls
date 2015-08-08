{% set count = 4 %}

{% for host in salt['pillar.get']( 'hosts' ) %}
  {% set host_ip = salt['openstack_utils.minion_ip']( host ) %}
  {% set count = count + 1 %}
open openstack node {{ host }} on firewall:
  iptables.insert:
    - position: {{ count }}
    - chain: INPUT
    - table: filter
    - jump: ACCEPT
    - match: state
    - connstate: NEW
    - source: {{ host_ip }}
    - save: True
{% endfor %}

open novnc on firewall:
  iptables.insert:
    - position: {{ count + 1 }}
    - chain: INPUT
    - table: filter
    - jump: ACCEPT
    - match: state
    - connstate: NEW
    - dport: 6080
    - proto: tcp
    - save: True
      
open http on firewall:
  iptables.insert:
    - position: {{ count + 2 }}
    - chain: INPUT
    - table: filter
    - jump: ACCEPT
    - match: state
    - connstate: NEW
    - dport: 80
    - proto: tcp
    - save: True
    - require:
      - iptables: open novnc on firewall

{% if salt['pillar.get']('horizon:https',False) %}
open https on firewall:
  iptables.insert:
    - position: {{ count + 3 }}
    - chain: INPUT
    - table: filter
    - jump: ACCEPT
    - match: state
    - connstate: NEW
    - dport: 443
    - proto: tcp
    - save: True
    - require:
      - iptables: open http on firewall
{% endif %}