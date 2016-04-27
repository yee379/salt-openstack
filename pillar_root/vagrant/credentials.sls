#!yaml

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
  magnum:
    db_name: "magnum"
    username: "magnum"
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
        magnum:
          password: change_me
          roles:
            - "admin"
          email: "openstack@slac.stanford.edu"

horizon:
  secret_key: change_me

haproxy:
  admin_password: change_me
    
ssl_cert:
  dir: /etc/ssl/certs
  file: openstack
  crt: |
    -----BEGIN CERTIFICATE-----
    MIIESzCCAzOgAwIBAgIJAPDWsjg1lAtMMA0GCSqGSIb3DQEBCwUAMIG7MQswCQYD
    VQQGEwItLTESMBAGA1UECAwJU29tZVN0YXRlMREwDwYDVQQHDAhTb21lQ2l0eTEZ
    MBcGA1UECgwQU29tZU9yZ2FuaXphdGlvbjEfMB0GA1UECwwWU29tZU9yZ2FuaXph
    dGlvbmFsVW5pdDEeMBwGA1UEAwwVbG9jYWxob3N0LmxvY2FsZG9tYWluMSkwJwYJ
    KoZIhvcNAQkBFhpyb290QGxvY2FsaG9zdC5sb2NhbGRvbWFpbjAeFw0xNjA0MDEw
    NjE2MjRaFw0xNzA0MDEwNjE2MjRaMIG7MQswCQYDVQQGEwItLTESMBAGA1UECAwJ
    U29tZVN0YXRlMREwDwYDVQQHDAhTb21lQ2l0eTEZMBcGA1UECgwQU29tZU9yZ2Fu
    aXphdGlvbjEfMB0GA1UECwwWU29tZU9yZ2FuaXphdGlvbmFsVW5pdDEeMBwGA1UE
    AwwVbG9jYWxob3N0LmxvY2FsZG9tYWluMSkwJwYJKoZIhvcNAQkBFhpyb290QGxv
    Y2FsaG9zdC5sb2NhbGRvbWFpbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
    ggEBAK7z64pfcTqUeNKipaXYIbuWch+labI+fS2dKSNYkuXsyEsbFnUolhVF4KJ7
    RCWnPmfBrK/5hc7LAcUQJBxwJhXS+VkREugyNQHs7g88mvk7IPu1hGlxAO7yZhEh
    UPyrOEiVR4iQFaPN4XsYuYf+c8doXgRKi5n9o/ZqXVli45t9V3Re1lSNYl3vW7Fr
    rG+C9HUscPwHZUtjj4H3opg9vAXwMWM5nnTuHoIDUEucYvrCAxYL/lkRXEeHhlqx
    lEVxRas1XWpvRqANwHN3OG7ELacRJeToFQtspiXS7TjyTvyMR3qruDe1c4rrJsgx
    QEMPVuu2D/F4/oldXMDSSEl/IHsCAwEAAaNQME4wHQYDVR0OBBYEFLM4Bpn82VT4
    lAGSEqBA68pJ4pppMB8GA1UdIwQYMBaAFLM4Bpn82VT4lAGSEqBA68pJ4pppMAwG
    A1UdEwQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBAJUsckkmNGIBjPrHh/SvUcbT
    t3mNd4bbLhr0nRmgA24YHoa3wSzflnNs/kVa8dfxpmmZdSQImnDNZxN8gFS9p7IJ
    P8AZ2sm3w7p8XhxkkMuNqBcDviYcKSdA/jw22Z/fARiyB44Yq5jsEG7syx+VqROQ
    zTQow7xb5zaBZ0z1zN/N5HdrYgUtocL4Ir7C50NIKrwln7n+NgMX3kG+Q1rL/XH1
    5xHuGsSZJZCmskYGXqmJwkDMD0dc5iTvgChIwPUVhxoza1m36PhDNpIfq8MoBhJd
    fKAiillFeLI4r+CkEXSAf48G7369lVHhcpa9mmKeQF9QQOrrJy/4JqBLa0HmDOM=
    -----END CERTIFICATE-----
  key: |
    -----BEGIN PRIVATE KEY-----
    MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCu8+uKX3E6lHjS
    oqWl2CG7lnIfpWmyPn0tnSkjWJLl7MhLGxZ1KJYVReCie0Qlpz5nwayv+YXOywHF
    ECQccCYV0vlZERLoMjUB7O4PPJr5OyD7tYRpcQDu8mYRIVD8qzhIlUeIkBWjzeF7
    GLmH/nPHaF4ESouZ/aP2al1ZYuObfVd0XtZUjWJd71uxa6xvgvR1LHD8B2VLY4+B
    96KYPbwF8DFjOZ507h6CA1BLnGL6wgMWC/5ZEVxHh4ZasZRFcUWrNV1qb0agDcBz
    dzhuxC2nESXk6BULbKYl0u048k78jEd6q7g3tXOK6ybIMUBDD1brtg/xeP6JXVzA
    0khJfyB7AgMBAAECggEAcSPQ+QVL5kRJ9n20fhHNjtB2MTz5o4mBzlPKXM9VAFgm
    F1wHI/EBTfSIlsr8gRUs6FB5arwE6nyiQlxz3egw2QA8vHqsLXj6iqo8MaJR3kd8
    xwrV/JJVtjEQDJftFdlsZpQTVJ9JP0tPPBn7MZU+LoCx/DhxGz7KH/sdL0ciRlSv
    m2w5sBnaF0kMXkZaqIkO4VCgM2FbbGjNmRBwF2Ef2BRm451gywt6w/84kqYTAXua
    Ci80eo5fAgXWEZphLJC7GlVpXzcB9UWiPcW/+414eMsPvPv8wzG1d1bhJJN0JY1X
    UYFtr65rDCCMknt07cj4ehLW3uMtnRdX1Ky4sjNzkQKBgQDore95ptOdQIGCz5Im
    Zt1DzYF1+al9E2dTic0mwR3MqvRAQyrUqIN4gG8AMsoL/4SekIh3xh7PmDazKv+t
    3Rat/jv8r7JJCaM7ARpF8OmXkITR13zcv8EThnlOeb7GnEveESG4h2Z4wwDuMeZz
    Ruml4i6qWDpshP6yMhcPIbJDBQKBgQDAfNdL+zOKkMSNP+q+r7lAiFujVx1qf07L
    BD8P5rm84BlKuhiMBAi2UXG8GSsGihPA85Wtxum+1DqbsQDB6yOXbXmzI7dj4mfR
    cwol9Y0/Am/QnX5ksl1SnPS+gpPGRVnonamO5cO43amV6mKUMtlK0SQKUboag579
    Z/xLDagtfwKBgGtiStFUIvnCGYNrlMHQW3G9WHBAJu6ok9lEEcA/BCe/BjbaSNwY
    YYStkYz/46uh42ziu3i7oOCiGSybPaDaFmt6l+jIlXmLzx+eJKf+xW/DrOjDkMa4
    YL1IJJgJK/ixjXoRYgStyKcXKEjGEttE8PQz7OGFEoGe54UKBQZgwMqZAoGBAJOh
    LB8CUs17qsQKuaf2bkaoTmBAeDct3OioIRW5B8tstPkzMZBxp5ztaiWxx+YEEJJ0
    P+BAJxZM/4ZZgxM3nNyPAj/6rLTW+HkTmjzyz5n77HY71Ky2gAzUhIF49I2kswhN
    o7YNUsd+eoqYcXLobO+M5+9iLzIWsOH51u5ZUxtRAoGAQRKIf8r+zyG6aO2bLOu8
    e/8KrgQ4T6kHWvgkFh8JineEitoQL5PfKxJbqmOlPMpeKf1X2u5khj+sMVY1+n87
    3OGTBvuL+LQ4TCOjDttNqdrMETqNgb5Ho42MKMoDwFuLrdscVgm9SOsljrGgEdBL
    qGOAt5WkL9bIUmsI6oUzqxM=
    -----END PRIVATE KEY-----
