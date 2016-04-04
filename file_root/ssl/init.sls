
{% set ssl = salt['openstack_utils.ssl_cert']() %}

{% if 'crt' in salt['pillar.get']('ssl_cert') and 'key' in salt['pillar.get']('ssl_cert') %}
ensure system openstack certs:
  file.managed:
    - name: {{ ssl['pem'] }}
    - source: salt://ssl/cert.pem
    - template: jinja
        
{% else %}
make dummy certs:
  cmd.run:
    - name: ./make-dummy-cert {{ ssl['pem'] }}
    - cwd: /etc/pki/tls/certs/
    - unless: test -e {{ ssl['pem'] }}

##
# TOOD: copy back the dummy certs so we can distribute it to the other openstack nodes
##

ensure system openstack certs:
  file.exists:
    - name: {{ ssl['pem'] }}
    - require:
      - cmd: make dummy certs
{% endif %}

create ssl crt file:
  cmd.run:
    - name: openssl x509 -in {{ ssl['pem'] }} -out {{ ssl['crt'] }}
    - require: 
      - file: ensure system openstack certs
    - onchanges:
      - file: ensure system openstack certs

create ssl key file:
  cmd.run:
    - name: openssl pkey -in {{ ssl['pem'] }} -out {{ ssl['key'] }}
    - require: 
      - file: ensure system openstack certs
    - onchanges:
      - file: ensure system openstack certs

  