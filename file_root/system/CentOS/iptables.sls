
open httpd on firewall:
  iptables.insert:
    - position: 7
    - chain: INPUT
    - table: filter
    - jump: ACCEPT
    - match: state
    - connstate: NEW
    - dport: 80
    - proto: tcp
    - save: True
    - require:
      - service: system_iptables_running
      
open novnc on firewall:
  iptables.insert:
    - position: 8
    - chain: INPUT
    - table: filter
    - jump: ACCEPT
    - match: state
    - connstate: NEW
    - dport: 6080
    - proto: tcp
    - save: True
    - require:
      - iptables: open httpd on firewall
      