mysql:
  root_password: change_me

rabbitmq:
  user_name: "openstack"
  user_password: change_me

databases:
  nova:
    db_name: "nova"
    username: "nova"
    password: change_me
  keystone:
    db_name: "keystone"
    username: "keystone"
    password: change_me
  cinder:
    db_name: "cinder"
    username: "cinder"
    password: change_me
  glance:
    db_name: "glance"
    username: "glance"
    password: change_me
  neutron:
    db_name: "neutron"
    username: "neutron"
    password: change_me
  heat:
    db_name: "heat"
    username: "heat"
    password: change_me

neutron:
  metadata_secret: change_me

keystone:
  admin_token: change_me
  roles:
    - "admin"
    - "heat_stack_owner"
    - "heat_stack_user"
  tenants:
    admin:
      users:
        admin:
          password: change_me
          roles:
            - "admin"
            - "heat_stack_owner"
          email: "openstack@slac.stanford.edu"
          keystonerc:
            create: True
            path: /root/keystonerc_admin
    service:
      users:
        cinder:
          password: change_me
          roles:
            - "admin"
          email: "openstack@slac.stanford.edu"
        glance:
          password: change_me
          roles:
            - "admin"
          email: "openstack@slac.stanford.edu"
        neutron:
          password: change_me
          roles:
            - "admin"
          email: "openstack@slac.stanford.edu"
        nova:
          password: change_me
          roles:
            - "admin"
          email: "openstack@slac.stanford.edu"
        heat:
          password: change_me
          roles:
            - "admin"
          email: "openstack@slac.stanford.edu"
        heat-cfn:
          password: change_me
          roles:
            - "admin"
          email: "openstack@slac.stanford.edu"