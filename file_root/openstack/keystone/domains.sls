{% set keystone = salt['openstack_utils.keystone']() %}

enable selinux for ldap:
  cmd.run:
    - name: setsebool -P authlogin_nsswitch_use_ldap on

/etc/keystone/domains:
  file.directory:
    - user: keystone
    - group: keystone
    - mode: 700
    - makedirs: True
    
ensure identity section in keystone:
  ini.options_present:
    - name: {{ keystone['conf']['keystone'] }}
    - sections:
        identity:
          domain_specific_drivers_enabled: True
          domain_config_dir: /etc/keystone/domains
    - require:
      - file: /etc/keystone/domains
      
{% for domain, data in salt['pillar.get']('keystone:domains', {}).iteritems() %}

ensure {{ domain }} exists:
  cmd.run:
    - name:   source /root/keystonerc_token; openstack --insecure domain create {{ domain }}
    - unless: source /root/keystonerc_token; openstack --insecure domain show {{ domain }}

add admin to {{ domain }} domain:
  cmd.run:
    - name: source /root/keystonerc_token; openstack --insecure role add --domain {{ domain }} --user admin --user-domain default admin
    - require:
      - cmd: ensure {{ domain }} exists
    - unless: source /root/keystonerc_token; openstack --insecure role list --domain {{ domain }} --user admin --user-domain default -f csv | tail -n -1 | awk -F"," '{if ($2 == "\"admin\""){ exit 0 }else{ exit 1 }}'

ensure {{ domain }} domain configuration exists:
  ini.options_present:
    - name: /etc/keystone/domains/keystone.{{ domain }}.conf
    - sections:
      {% for section, options in data.iteritems() %}
        {{ section }}:
          {% for key, value in options.iteritems() %}
          {{ key }}: {{ value }}
          {% endfor %}
      {% endfor %}
    - require:
      - file: /etc/keystone/domains
      - ini: ensure identity section in keystone
      - cmd: ensure {{ domain }} exists
      - cmd: add admin to {{ domain }} domain
    - watch_in:
      - service: restart keystone service
      
{% endfor %}


restart keystone service:
  service.running:
    - name: httpd
