ensure nginx is installed:
  pkg.installed:
    - name: nginx

# should merge in with the haproxy one
{% set ssl_cert_path = salt['pillar.get']('haproxy:ssl_cert:dir') + salt['pillar.get']('haproxy:ssl_cert:file') %}
ensure ssl certs:
  cmd.run:
    - name: ./make-dummy-cert {{ ssl_cert_path }}
    - cwd: /etc/pki/tls/certs/
    - unless: test -e {{ ssl_cert_path }}

{% set dhparam_file = salt['pillar.get']( 'resources:nginx:conf:dhparam' ) %}
dhparam for nginx:
  cmd.run:
    - name: openssl dhparam -out {{ dhparam_file }} 4096
    - unless: test -e {{ dhparam_file }}
    
      
nginx configuration file:
  file.managed:
    - name: {{ salt['pillar.get']( 'resources:nginx:conf:nginx' ) }}
    - source: salt://nginx/nginx.conf.jinja2
    - template: jinja
    - defaults:
        ssl_cert_path: {{ ssl_cert_path }}
        dhparam: {{ dhparam_file }}
        controllers:
          - {{ salt['pillar.get']( 'controller' ) }}
    - user: root
    - group: root
    - mode: 644
    
ensure nginx is running:
  service.running:
    - name: nginx
    - requires:
      - pkg: ensure nginx is installed
      - file: nginx configuration file
    - watch:
      - file: nginx configuration file