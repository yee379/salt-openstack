import salt
from re import match
from os.path import isfile

import logging
LOG = logging.getLogger(__name__)

def _keystone_services():
    # returns all openstack services with endpoint base on pillar services
    services = {}
    controller = __salt__['pillar.get']('controller')
    fqdn = __salt__['pillar.get']( 'hosts:%s' % (controller,) )
    for s, d in __salt__['pillar.get']('services', default={}).iteritems():
        if 'service_type' in d:
            services[s] = {
                'service_type': d['service_type'],
                'description': d['description'],
                'endpoint': {
                    'internalurl': _service_endpoint( d, fqdn, 'internal' ),
                    'publicurl': _service_endpoint( d, fqdn, 'public' ),
                    'adminurl': _service_endpoint( d, fqdn, 'admin' ),
                }
            }
            if 'version' in d:
                services[s]['version'] = d['version']
    # fall back
    if services == {}:
        return {'keystone': {'description': 'Openstack Identity',
                             'endpoint': {'adminurl': 'http://{0}:35357/v2.0',
                                          'internalurl': 'http://{0}:5000/v2.0',
                                          'publicurl': 'http://{0}:5000/v2.0'},
                             'service_type': 'identity'},
                'glance': {'description': 'OpenStack Image service',
                           'endpoint': {'adminurl': 'http://{0}:9292',
                                        'internalurl': 'http://{0}:9292',
                                        'publicurl': 'http://{0}:9292'},
                           'service_type': 'image'},
                'nova': {'description': 'nova compute service',
                         'endpoint': {'adminurl': 'http://{0}:8774/v2/%(tenant_id)s',
                                      'internalurl': 'http://{0}:8774/v2/%(tenant_id)s',
                                      'publicurl': 'http://{0}:8774/v2/%(tenant_id)s'},
                         'service_type': 'compute'},
                'neutron': {'description': 'OpenStack Networking',
                            'endpoint': {'adminurl': 'http://{0}:9696',
                                         'internalurl': 'http://{0}:9696',
                                         'publicurl': 'http://{0}:9696'},
                            'service_type': 'network'},
                'cinder': {'description': 'OpenStack Block Storage',
                           'endpoint': {'adminurl': 'http://{0}:8776/v1/%(tenant_id)s',
                                        'internalurl': 'http://{0}:8776/v1/%(tenant_id)s',
                                        'publicurl': 'http://{0}:8776/v1/%(tenant_id)s'},
                           'service_type': 'volume'},
                'cinderv2': {'description': 'OpenStack Block Storage V2',
                           'endpoint': {'adminurl': 'http://{0}:8776/v2/%(tenant_id)s',
                                        'internalurl': 'http://{0}:8776/v2/%(tenant_id)s',
                                        'publicurl': 'http://{0}:8776/v2/%(tenant_id)s'},
                           'service_type': 'volumev2'},
                'heat': {'description': 'Openstack Orchestration Service',
                         'endpoint': {'adminurl': 'http://{0}:8004/v1/%(tenant_id)s',
                                      'internalurl': 'http://{0}:8004/v1/%(tenant_id)s',
                                      'publicurl': 'http://{0}:8004/v1/%(tenant_id)s'},
                         'service_type': 'orchestration'},
                'heat-cfn': {'description': 'Orchestration CloudFormation',
                             'endpoint': {'adminurl': 'http://{0}:8000/v1',
                                          'internalurl': 'http://{0}:8000/v1',
                                          'publicurl': 'http://{0}:8000/v1'},
                             'service_type': 'cloudformation'}}
    return services

def _service_endpoint( service, fqdn, zone, local_or_service='service', include_path=True, path_is_version=False ):
    s = _service_dict( service, fqdn, zone, local_or_service=local_or_service )
    return pformat_service_endpoint( s, include_path=include_path, path_is_version=path_is_version )

def pformat_service_endpoint( d, include_path=True, path_is_version=False ):
    path = ''
    if not path_is_version and include_path and d['path']:
        path = '/'+d['path']
    elif path_is_version and include_path and d['version']:
        path = '/'+d['version']
    return '%s://%s:%s%s' % ( d['protocol'], d['fqdn'], d['port'], path )
    
def _service_dict( service, fqdn, zone, local_or_service='service' ):
    d = service['url'][zone]
    # if we have https, then spit out the service_port
    # we enforce that all openstack services listen on localhost bounded ports and that a ssl proxy 
    # is used in front of the service
    if 'https' in d and d['https']:
        proto = 'https'
        # local_or_service = 'local'
    else:
        proto = 'http'
    # set path
    path = ''
    return {
        'protocol': proto,
        'fqdn': fqdn,
        'port': d['local_port'] if local_or_service == 'local' else d['service_port'],
        'local_port': d['local_port'],
        'path': d['path'] if 'path' in d and d['path'] else None,
        'version': service['version'] if 'version' in service and service['version'] else None,
    }

def controller( by_ip=False ):
    # TODO: support HA
    c = __salt__['pillar.get']('controller')
    if by_ip:
        c = minion_ip( c )
    return c

def keystone_auth( by_ip=False ):
    ks = __salt__['pillar.get']('services')['keystone']
    ks_version = ks['version']
    c = controller( by_ip=by_ip )
    context = {}
    for z,d in ks['url'].iteritems():
        context[z] = _service_endpoint( ks, c, z, local_or_service='service', include_path=False )
        context['%s_with_path'%(z,)] = _service_endpoint( ks, c, z, local_or_service='service', include_path=True )
        context['%s_with_version'%(z,)] = _service_endpoint( ks, c, z, local_or_service='service', path_is_version=True )
    # create dynamic variable based on keystone version requested
    context['auth_url'] = context['admin'] if ks_version == 'v2.0' else context['admin_with_path']
    return context
    
def service_urls( service, fqdn=controller, by_ip=False ):
    s = __salt__['pillar.get']('services')[service]
    if hasattr(fqdn,'__call__'):
        fqdn = fqdn( by_ip=by_ip )
    context = {}
    for z,d in s['url'].iteritems():
        d = _service_dict( s, fqdn, z, local_or_service='service' )
        context[z] = pformat_service_endpoint( d, include_path=False )
        context[z+'_protocol'] = d['protocol']
        context[z+'_port'] = d['port']
        context[z+'_local_port'] = d['local_port']
        context['%s_with_path'%(z,)] = pformat_service_endpoint( d, include_path=True, path_is_version=False )
        context['%s_with_version'%(z,)] = pformat_service_endpoint( d, include_path=True, path_is_version=True )
    # assume all version numbers are same
    if 'version' in d:
        context['version'] = d['version']
    return context

def _openstack_service_context(openstack_service):
    series = openstack_series()
    context = __salt__['pillar.get']('resources:%s:openstack_series:%s' % \
                                                (openstack_service, series))
    context.update({
        'database': __salt__['pillar.get']('databases:%s' % openstack_service)
    })
    return context


def _append_values_to_list(list_var, var):
    if type(var) is dict:
        list_var += var.values()
    if type(var) is list:
        list_var += var


def _openstack_resources(resources_type, minion_role):
    resources = []
    series = openstack_series_persist()
    if minion_role == 'controller':
        for project in ['mysql', 'rabbitmq', 'horizon']:
            _append_values_to_list(
                resources, __salt__['pillar.get']('resources:%s:%s' % \
                                        (project, resources_type), default=[])
            )
        for project in ['nova', 'neutron', 'cinder']:
            pillar_key = 'resources:%s:openstack_series:%s:%s:controller'
            _append_values_to_list(
                resources, __salt__['pillar.get'](pillar_key % \
                            (project, series, resources_type), default=[]))
        for project in ['keystone', 'glance', 'heat']:
            pillar_key = 'resources:%s:openstack_series:%s:%s'
            _append_values_to_list(
                resources, __salt__['pillar.get'](pillar_key % \
                            (project, series, resources_type), default=[]))
    elif minion_role == 'network':
        pillar_key = 'resources:neutron:openstack_series:%s:%s:network'
        _append_values_to_list(
            resources, __salt__['pillar.get'](pillar_key % \
                                    (series, resources_type), default=[]))
    elif minion_role == 'compute':
        for project in ['nova', 'neutron']:
            pillar_key = 'resources:%s:openstack_series:%s:%s:compute:kvm'
            _append_values_to_list(
                resources, __salt__['pillar.get'](pillar_key % \
                            (project, series, resources_type), default=[]))
    elif minion_role == 'storage':
        pillar_key = 'resources:cinder:openstack_series:%s:%s:storage'
        _append_values_to_list(
            resources, __salt__['pillar.get'](pillar_key % \
                                    (series, resources_type), default=[]))
    return resources


def _remove_list_duplicates(list_var):
    if type(list_var) is list:
        return list(set(list_var))
    return list_var


def _rpm_repo_name(rpm_repo_url=None):
    '''
        returns the rpm repo name by parsing the rpm repository url
        Example:
        "http://rdo.fedorapeople.org/openstack-juno/rdo-release-juno.rpm"
        returns "rdo-release-juno".
    '''
    if not rpm_repo_url:
        return None
    name = rpm_repo_url.split('/')[-1].split('.')[0]
    m = match( r'^(?P<name>.*)-\d+-\d+$', name )
    if m:
        return m.groupdict()['name']
    else:
        return name


def _unquote_str(str_var):
    if (not str_var) or (type(str_var) is not str):
        return str_var
    if str_var.startswith('"') and str_var.endswith('"') or \
       str_var.startswith("'") and str_var.endswith("'"):
        return str_var[1:-1]
    return str_var


def icehouse_keystone_services():
    return _keystone_services()


def juno_keystone_services():
    return _keystone_services()


def kilo_keystone_services():
    # services = _keystone_services()
    # services['cinder']['endpoint'] = services['cinderv2']['endpoint']
    # return services
    return _keystone_services()

def liberty_keystone_services():
    # return kilo_keystone_services()
    return _keystone_services()


def openstack_series():
    return __salt__['pillar.get']('openstack_series')


def openstack_series_persist():
    pillar_key = 'resources:system:conf:series_persist_file'
    file_path = __salt__['pillar.get'](pillar_key)
    if __salt__['file.file_exists'](file_path):
        return __salt__['cmd.run']('cat %s' % file_path)
    return None


def openstack_users(tenant_name=None):
    if not tenant_name:
        return []
    pillar_key = 'keystone:tenants:%s:users'
    return __salt__['pillar.get'](pillar_key % tenant_name, default=[])


def openstack_parameters():
    controller_minion_id = __salt__['pillar.get']('controller')
    parameters = {
        'debug_mode': __salt__['pillar.get']('debug_mode', default=False),
        'verbose_mode': __salt__['pillar.get']('verbose_mode', default=False),
        'controller_ip': minion_ip(controller_minion_id),
        'controller_name': controller_minion_id,
        'reset': __salt__['pillar.get']('reset'),
        'message_queue': __salt__['pillar.get']('message_queue_engine'),
        'series': openstack_series(),
        'system_upgrade': __salt__['pillar.get']('system_upgrade'),
        'database': __salt__['pillar.get']('db_engine'),
        'series_persist': openstack_series_persist(),
        'series_persist_file': __salt__['pillar.get']('resources:system:conf:'
                                                      'series_persist_file')
    }
    return parameters


def boolean_value(variable=None):
    if type(variable) is str:
        return variable.lower() == "true"
    try:
        return bool(variable)
    except:
        return False


def compare_ignore_case(str1=None, str2=None):
    if type(str1) is str and type(str2) is str:
        return str1.lower() == str2.lower()
    else:
        return False


def minion_ip(minion_id=None):
    '''
        returns the minion_ip of a minion as defined in the pillar
    '''
    return  __salt__['pillar.get']('hosts:%s' % minion_id, default='localhost')


def ml2_type_drivers():
    '''
        returns an array with neutron ml2 type drivers defined in pillar
    '''
    pillar_type_drivers = __salt__['pillar.get']('neutron:type_drivers',
                                                                default=[])
    type_drivers = []
    for type_driver in pillar_type_drivers:
        if type_driver.lower() in ['local', 'flat', 'vlan', 'gre', 'vxlan']:
            type_drivers.append(type_driver.lower())
    return type_drivers


def tenant_network_types():
    '''
        returns an array with neutron tenant network types defined in pillar
    '''
    type_drivers = ml2_type_drivers()
    if 'flat' in type_drivers:
        type_drivers.remove('flat')
    return type_drivers


def gre_tunnel_id_ranges():
    '''
        returns an array with gre tunnel_id ranges defined in pillar
    '''
    gre_tunnel_id_ranges = []
    gre_tunnels = __salt__['pillar.get']('neutron:type_drivers:gre:tunnels',
                                                                default=[])
    for tunnel in gre_tunnels:
        tunnel_id_range = gre_tunnels[tunnel]['tunnel_id_ranges']
        if tunnel_id_range not in gre_tunnel_id_ranges:
            gre_tunnel_id_ranges.append(tunnel_id_range)
    return gre_tunnel_id_ranges


def vxlan_tunnels_vni_ranges():
    '''
        returns an array with vxlan tunnels vni ranges defined in pillar
    '''
    pillar_key = 'neutron:type_drivers:vxlan:tunnels'
    vxlan_tunnels = __salt__['pillar.get'](pillar_key, default=[])
    vxlan_tunnels_vni_ranges = []
    for tunnel in vxlan_tunnels:
        vni_range = vxlan_tunnels[tunnel]['vni_range']
        if vni_range not in vxlan_tunnels_vni_ranges:
            vxlan_tunnels_vni_ranges.append(vni_range)
    return vxlan_tunnels_vni_ranges


def bridge_mappings():
    '''
        returns an array with "<physnet_name>:<bridge_name>" mappings defined
        in pillar. Used to configure openvswitch.
    '''
    bridge_mappings = []
    for network_type in ('flat', 'vlan', 'gre', 'vxlan'):
        physnets = __salt__['pillar.get']('neutron:type_drivers:%s:physnets' \
                                                % network_type, default=[])
        for physnet in physnets:
            if __salt__['grains.get']('id') in physnets[physnet]['hosts']:
                br_mapping = ':'.join([physnet, physnets[physnet]['bridge']])
                bridge_mappings.append(br_mapping)
    return bridge_mappings


def vlan_networks():
    '''
        returns an array with vlan networks configurations defined in pillar
    '''
    vlan_networks = []
    vlan_physnets = __salt__['pillar.get']('neutron:type_drivers:'
                                           'vlan:physnets', default=[])
    for physnet in vlan_physnets:
        # if this is the controller, then add all networks
        add = __salt__['grains.get']('id') in vlan_physnets[physnet]['hosts']
        if __salt__['grains.get']('id') in __salt__['pillar.get']('network'):
            add = True
        if add:
            if 'vlan_range' in vlan_physnets[physnet]:
                network = ':'.join([physnet, vlan_physnets[physnet]['vlan_range']])
                vlan_networks.append(network)
            if 'vlan_ranges' in vlan_physnets[physnet]:
                for r in vlan_physnets[physnet]['vlan_ranges']:
                    network = ':'.join([physnet, r])
                    vlan_networks.append(network)
    return vlan_networks


def flat_networks():
    '''
        returns an array with flat networks physnets defined in pillar
    '''
    flat_networks = []
    flat_physnets = __salt__['pillar.get']('neutron:type_drivers:'
                                           'flat:physnets', default=[])
    for physnet in flat_physnets:
        if __salt__['grains.get']('id') in flat_physnets[physnet]['hosts']:
            flat_networks.append(physnet)
    return flat_networks


def bridges(minion_id):
    '''
        returns a dictionary that with bridges and the bridged interfaces
        defined in pillar
    '''
    br_int = __salt__['pillar.get']('neutron:integration_bridge',
                                                    default='br-int')
    bridges = { br_int: None }
    tunneling = __salt__['pillar.get']('neutron:tunneling')
    if boolean_value(tunneling['enable']):
        tunnel_bridge = tunneling['bridge']
        if not tunnel_bridge:
            tunnel_bridge = 'br-tun'
        bridges.update({tunnel_bridge: None})
    for network_type in ('flat', 'vlan', 'gre', 'vxlan'):
        physnets = __salt__['pillar.get']('neutron:'
                        'type_drivers:%s:physnets' % network_type, default=[])
        for physnet in physnets:
            if minion_id in physnets[physnet]['hosts']:
                bridges.update({ physnets[physnet]['bridge']:
                                 physnets[physnet]['hosts'][minion_id]})
    return bridges


def subnets(network_name=None):
    if not network_name:
        return []
    return __salt__['pillar.get']('neutron:'
                            'networks:%s:subnets' % network_name, default=[])


def networks():
    return __salt__['pillar.get']('neutron:networks', default=[])


def routers():
    return __salt__['pillar.get']('neutron:routers', default=[])


def security_groups():
    return __salt__['pillar.get']('neutron:security_groups', default=[])


def libvirt_virt_type():
    nested_virt = __salt__['cmd.run']("egrep -c '(vmx|svm)' /proc/cpuinfo")
    if nested_virt != "0":
        return 'kvm'
    return 'qemu'


def hard_reset_states():
    minion_id = __salt__['grains.get']('id')
    roles = minion_roles()
    states = []
    for role in roles:
        states.append("reset.hard.%s" % role)
    return states


def os_services(minion_role=None):
    '''
        returns a list with the OpenStack OS services from a minion with
        an assigned role
    '''
    if not minion_role:
        return []
    services = _openstack_resources('services', minion_role)
    unique_services = _remove_list_duplicates(services)
    keystone_service_name = keystone()['services']['keystone']
    if openstack_series_persist() == 'kilo' and \
       keystone_service_name in unique_services:
        unique_services.remove(keystone_service_name)
    return unique_services


def os_packages(minion_role=None):
    '''
        returns a list with the OpenStack OS packages from a minion with
        an assigned role
    '''
    if not minion_role:
        return []
    packages = _openstack_resources('packages', minion_role)
    return _remove_list_duplicates(packages)


def minion_resources(minion_role=None):
    '''
        returns a list of resources that are installed on the minion with the
        role given as parameter
    '''
    if type(minion_role) is not str:
        return []
    if compare_ignore_case(minion_role, 'controller'):
        return ['mysql', 'rabbitmq', 'keystone', 'glance', 'nova', 'neutron',
                'horizon', 'cinder', 'heat']
    elif compare_ignore_case(minion_role, 'network'):
        return ['neutron']
    elif compare_ignore_case(minion_role, 'compute'):
        return ['nova', 'neutron']
    elif compare_ignore_case(minion_role, 'storage'):
        return ['cinder']
    else:
        return ['nova', 'neutron']


def minion_roles():
    minion_id = __salt__['grains.get']('id')
    roles = []
    if minion_id == __salt__['pillar.get']('controller'):
        roles.append('controller')
    if minion_id == __salt__['pillar.get']('network'):
        roles.append('network')
    if minion_id in __salt__['pillar.get']('compute'):
        roles.append('compute')
    if minion_id in __salt__['pillar.get']('storage'):
        roles.append('storage')
    return roles


def minion_packages_dirs(minion_role=None):
    '''
        returns a list of dirs from the packages installed on a minion with
        the role given as parameter
    '''
    if not minion_role:
        return []
    packages = minion_resources(minion_role)
    dirs = []
    for pkg in packages:
        pkg_dirs = __salt__['pillar.get']('resources:%s:dirs' % pkg)
        if pkg_dirs:
            dirs += pkg_dirs
    return dirs


def systemd_service_name(systemd_service_script=None):
    if not systemd_service_script or type(systemd_service_script) is not str:
        return ""
    base_name = systemd_service_script.split('/')[-1]
    # remove ".service" suffix
    return base_name[:-8]


def network_script_ip_configs(interface_name=None):
    if not interface_name:
        return []
    network_scripts = '/etc/sysconfig/network-scripts'
    config_file = '%s/ifcfg-%s' % (network_scripts, interface_name)
    if not isfile( config_file ):
        raise SystemError( "interface name '%s' not defined on system: please correct single_nic interface definition" % (interface_name,))
    bootproto = _unquote_str(__salt__['ini.get_option'](
                config_file,
                'DEFAULT_IMPLICIT', 'BOOTPROTO'))
    context = {}

    if compare_ignore_case(bootproto, "dhcp") or compare_ignore_case(bootproto, "none"):
        context.update( { 'OVSBOOTPROTO': 'dhcp', 'OVSDHCPINTERFACES': interface_name, 'BOOTPROTO': 'dhcp' } )
        return context

    elif compare_ignore_case(bootproto, "static"):
        context.update( { 'BOOTPROTO': bootproto } )
        configs = ['IPADDR', 'NETMASK', 'PREFIX', 'GATEWAY', 'DNS1', 'DNS2']
        for config in configs:
            config_value = _unquote_str(__salt__['ini.get_option'](
                            '%s/ifcfg-%s' % (network_scripts, interface_name),
                            'DEFAULT_IMPLICIT', config))
            if config_value:
                context.update({ config: config_value })
    return context


def ntp():
    return {
        'packages': __salt__['pillar.get']('resources:ntp:packages',
                                                                default=[]),
        'services': __salt__['pillar.get']('resources:ntp:services',
                                                                default=[])
    }


def apt_repository():
    series = openstack_series()
    return {
        'packages': __salt__['pillar.get']('resources:'
                                           'system:packages', default=[]),
        'path': __salt__['pillar.get']('resources:system:conf:cloudarchive'),
        'deb_repo': __salt__['pillar.get']('resources:'
                    'system:repositories:openstack:series:%s' % series)
    }


def yum_repository():
    series = openstack_series()
    series_persist = openstack_series_persist()
    openstack_repo_url = __salt__['pillar.get']('resources:system:'
                                'repositories:openstack:series:%s' % series)
    epel_repo_url = __salt__['pillar.get']('resources:system:repositories'
                                                                    ':epel')
    this = {
        'repositories': {
            'epel': {
                'url': epel_repo_url,
                'name': _rpm_repo_name(epel_repo_url)
            },
            'openstack': {
                'url': openstack_repo_url,
                'name': _rpm_repo_name(openstack_repo_url),
                'name_persist': _rpm_repo_name(__salt__['pillar.get'](
                                    'resources:system:repositories'
                                    ':openstack:series:%s' % series_persist))
            }
        },
        'packages': __salt__['pillar.get']('resources:'
                                        'system:repo_packages', default=[])
    }
    
    # add ovirt?
    ovirt_repo_url = __salt__['pillar.get']('resources:system:repositories:ovirt', default=None)
    if ovirt_repo_url:
        this['repositories']['ovirt'] = {
            'url': ovirt_repo_url,
            'name': _rpm_repo_name(ovirt_repo_url)
        }
    return this

def __http_proxy_args():
    proto = __salt__['pillar.get']('http_proxy:proto', default=None)
    server = __salt__['pillar.get']('http_proxy:server', default=None)
    port = __salt__['pillar.get']('http_proxy:port', default=None)
    return proto, server, port

def rpm_http_proxy_args():
    proto, server, port = __http_proxy_args()
    if proto and server and port:
        return '--httpproxy %s --httpport  %s' % (server, port) 
    return ''
    
def curl_http_proxy_args():
    proto, server, port = __http_proxy_args()
    if proto and server and port:
        return '--proxy %s://%s:%s' % (proto,server, port) 
    return ''
    
def system():
    return __salt__['pillar.get']('resources:system')


def mysql():
    context = __salt__['pillar.get']('resources:mysql')
    context.update({
        'root_password': __salt__['pillar.get']('mysql:root_password'),
        'databases': __salt__['pillar.get']('databases', default=[])
    })
    return context

def ssl_cert():
    dir = __salt__['pillar.get']('ssl_cert:dir')
    name = __salt__['pillar.get']('ssl_cert:file')
    context = {
        'dir': dir,
        'name': name,
    }
    for i in ( 'pem', 'crt', 'key', 'ca' ):
        context[i] = dir + '/' + name + '.' + i
    return context
    
def rabbitmq():
    context = __salt__['pillar.get']('resources:rabbitmq')
    context.update({
        'user_name': __salt__['pillar.get']('rabbitmq:user_name'),
        'user_password': __salt__['pillar.get']('rabbitmq:user_password'),
        'port': __salt__['pillar.get']('services:rabbitmq:url:internal:local_port',5672),
        'service_port': __salt__['pillar.get']('services:rabbitmq:url:internal:local_port',5672),
        'ssl_enable': __salt__['pillar.get']('services:rabbitmq:url:internal:ssl', False),
    })
    if context['ssl_enable']:
        ssl = ssl_cert()
        context.update({
            'ssl_port': __salt__['pillar.get']('services:rabbitmq:url:internal:service_port',5671),
            'service_port': __salt__['pillar.get']('services:rabbitmq:url:internal:service_port',5671),
            'ssl_pem_path': ssl['pem'],
            'ssl_ca_path': ssl['ca'],
            'ssl_crt_path': ssl['crt'],
            'ssl_key_path': ssl['key']
        })
    return context


def keystone():
    context = _openstack_service_context('keystone')
    series = openstack_series()
    keystone_parameters = {
        'admin_token': __salt__['pillar.get']('keystone:admin_token'),
        'openstack_services': __salt__['openstack_utils'
                                       '.%s_keystone_services' % series](),
        'openstack_roles': __salt__['pillar.get']('keystone:roles',
                                                            default=[]),
        'openstack_tenants': __salt__['pillar.get']('keystone:tenants',
                                                            default=[]),
    }
    context.update(keystone_parameters)
    return context


def glance():
    context = _openstack_service_context('glance')
    context.update({
        'images': __salt__['pillar.get']('glance:images', default=[])
    })
    return context


def nova( minion_id=None ):
    context = _openstack_service_context('nova')
    context.update({
        'cpu_allocation_ratio': __salt__['pillar.get']('nova'
                                    ':cpu_allocation_ratio', default=16.0),
        'ram_allocation_ratio': __salt__['pillar.get']('nova'
                                    ':ram_allocation_ratio', default=1.5),
        'preallocate_images': __salt__['pillar.get']('nova'
                                    ':preallocate_images', default='none'),
        'libvirt_virt_type': libvirt_virt_type(),
        'live_migration_progress_timeout': __salt__['pillar.get']('nova:live_migration_progress_timeout', default=150)
    })
    # overwrite with minion defaults
    if minion_id:
        host_agg = __salt__['pillar.get']('nova:host_aggregates', default={} )
        for name, agg in host_agg.iteritems():
            if 'hosts' in agg and minion_id in agg['hosts']:
                if isinstance(agg['hosts'][minion_id], dict):
                    for k,v in agg['hosts'][minion_id].iteritems():
                        context.update( { k: v } )
    LOG.debug("NOVA CONTEXT: %s" % (context,))
    return context


def neutron( minion_id=None ):
    context = _openstack_service_context('neutron')
    context.update({
        'ml2_type_drivers': ml2_type_drivers(),
        'tenant_network_types': tenant_network_types(),
        'gre_tunnel_id_ranges': gre_tunnel_id_ranges(),
        'vxlan_tunnels_vni_ranges': vxlan_tunnels_vni_ranges(),
        'bridge_mappings': bridge_mappings(),
        'vlan_networks': vlan_networks(),
        'flat_networks': flat_networks(),
        'bridges': bridges( minion_id ),
        'tunneling': __salt__['pillar.get']('neutron:tunneling'),
        'vxlan_group': __salt__['pillar.get']('neutron:type_drivers:'
                                              'vxlan:vxlan_group'),
        'external_bridge': __salt__['pillar.get']('neutron'
                                        ':external_bridge', default='br-ex'),
        'integration_bridge': __salt__['pillar.get']('neutron'
                                    ':integration_bridge', default='br-int'),
        'single_nic': __salt__['pillar.get']('neutron:single_nic'),
        'metadata_secret': __salt__['pillar.get']('neutron:metadata_secret'),
        'networks': networks(),
        'routers': routers(),
        'security_groups': security_groups()
    })
    # overwrite the single_nic settings if local definition exists
    for b, d in context['bridges'].iteritems():
        if d and 'single_nic' in d:
            context['single_nic'] = d['single_nic']
    # mtu
    context['mtu'] = context['single_nic']['mtu'] if 'mtu' in context['single_nic'] else 1500
    if not 'disable_interfaces' in context['single_nic']:
        context['single_nic']['disable_interfaces'] = ()
    return context


def openvswitch():
    return __salt__['pillar.get']('resources:openvswitch')


def horizon():
    return __salt__['pillar.get']('resources:horizon')

def horizon_https():
    for z,d in __salt__['pillar.get']('services')['horizon']['url'].iteritems():
        if 'https' in d and d['https']:
            return True
    return False

def cinder():
    context = _openstack_service_context('cinder')
    context.update({
        'volumes_group_name': __salt__['pillar.get']('cinder'
                            ':volumes_group_name', default='cinder-volumes'),
        'volumes_path': __salt__['pillar.get']('cinder'
                ':volumes_path', default='/var/lib/cinder/cinder-volumes'),
        'volumes_group_size': __salt__['pillar.get']('cinder'
                                                     ':volumes_group_size'),
        'loopback_device': __salt__['pillar.get']('cinder'
                                    ':loopback_device', default='/dev/loop0')
    })
    return context


def heat():
    return _openstack_service_context('heat')

def magnum():
    context = _openstack_service_context('magnum')
    return context

def haproxy_services( ):
    seen_ports = {}
    for s, d in __salt__['pillar.get']('services').iteritems():
        # work out if we have different port numbers like with keystone
        ports = []
        for z,data in d['url'].iteritems():
            if not 'https' in data:
                data['https'] = False
            # only bother proxying if the ports are different
            noproxy = data['noproxy'] if 'noproxy' in data and data['noproxy'] else False
            if not noproxy and \
                ( 'local_port' in data and 'service_port' in data \
                and not data['local_port'] == data['service_port'] \
                and not data in ports ): # if port spec has not already been seen
                    ports.append( data )
        for p in ports:
            if not p['service_port'] in seen_ports:
                seen_ports[p['service_port']] = True
                yield s, '%s-%s'%(s,p['service_port']), p['local_port'], p['service_port'], p['https']
