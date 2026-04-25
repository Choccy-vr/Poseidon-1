import 'package:multicast_dns/multicast_dns.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoonrakerDNSInstance {
  final String ip;
  final int port;
  final String? hostname;

  MoonrakerDNSInstance({required this.ip, required this.port, this.hostname});
}

class DiscoveryService {
  static Future<MoonrakerDNSInstance> discover() async {
    const String name = '_moonraker._tcp';
    final MDnsClient client = MDnsClient();
    await client.start();

    try {
      await for (final PtrResourceRecord ptr
          in client.lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer(name),
          )) {
        await for (final SrvResourceRecord srv
            in client.lookup<SrvResourceRecord>(
              ResourceRecordQuery.service(ptr.domainName),
            )) {
          final String? resolvedIp = await _resolveServiceIp(
            client,
            srv.target,
          );
          if (resolvedIp != null) {
            return MoonrakerDNSInstance(
              ip: resolvedIp,
              port: srv.port,
              hostname: srv.target,
            );
          }

          // Fallback to hostname if no A/AAAA record is found.
          return MoonrakerDNSInstance(
            ip: _normalizedHost(srv.target),
            port: srv.port,
            hostname: srv.target,
          );
        }
      }
    } finally {
      client.stop();
    }

    throw StateError('No Moonraker instance found.');
  }

  static Future<String?> _resolveServiceIp(
    MDnsClient client,
    String target,
  ) async {
    final String host = _normalizedHost(target);

    await for (final IPAddressResourceRecord ipv4
        in client.lookup<IPAddressResourceRecord>(
          ResourceRecordQuery.addressIPv4(host),
        )) {
      return ipv4.address.address;
    }

    await for (final IPAddressResourceRecord ipv6
        in client.lookup<IPAddressResourceRecord>(
          ResourceRecordQuery.addressIPv6(host),
        )) {
      return ipv6.address.address;
    }

    return null;
  }

  static String _normalizedHost(String host) {
    return host.endsWith('.') ? host.substring(0, host.length - 1) : host;
  }

  static Future<List<MoonrakerDNSInstance>> discoverAll() async {
    const String name = '_moonraker._tcp';
    final MDnsClient client = MDnsClient();
    await client.start();

    final List<MoonrakerDNSInstance> instances = [];

    try {
      await for (final PtrResourceRecord ptr
          in client.lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer(name),
          )) {
        await for (final SrvResourceRecord srv
            in client.lookup<SrvResourceRecord>(
              ResourceRecordQuery.service(ptr.domainName),
            )) {
          final String? resolvedIp = await _resolveServiceIp(
            client,
            srv.target,
          );
          if (resolvedIp != null) {
            instances.add(
              MoonrakerDNSInstance(
                ip: resolvedIp,
                port: srv.port,
                hostname: srv.target,
              ),
            );
          } else {
            // Fallback to hostname if no A/AAAA record is found.
            instances.add(
              MoonrakerDNSInstance(
                ip: _normalizedHost(srv.target),
                port: srv.port,
                hostname: srv.target,
              ),
            );
          }
        }
      }
    } finally {
      client.stop();
    }

    return instances;
  }

  static Future<void> saveInstance(MoonrakerDNSInstance instance) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('moonraker_ip', instance.ip);
    await prefs.setInt('moonraker_port', instance.port);
    if (instance.hostname != null) {
      await prefs.setString('moonraker_hostname', instance.hostname!);
    }
  }

  static Future<MoonrakerDNSInstance?> loadSavedInstance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString('moonraker_ip');
    int? port = prefs.getInt('moonraker_port');
    String? hostname = prefs.getString('moonraker_hostname');

    if (ip != null && port != null) {
      return MoonrakerDNSInstance(ip: ip, port: port, hostname: hostname);
    }
    return null;
  }

  static Future<void> clearSavedInstance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('moonraker_ip');
    await prefs.remove('moonraker_port');
    await prefs.remove('moonraker_hostname');
  }
}
