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

# before restart
# openstack --insecure domain create SLAC
# ensure domain {{ domain }} exists:
#  


# openstack --insecure role add --domain SLAC --user admin admin


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
    - watch_in:
      - service: restart keystone service


      
{% endfor %}


restart keystone service:
  service.running:
    - name: httpd
