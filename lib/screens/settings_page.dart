import 'dart:io';

import 'package:astral/fun/reg.dart';
import 'package:astral/fun/route_fun.dart';
import 'package:astral/fun/up.dart';
import 'package:astral/k/app_s/aps.dart';
import 'package:astral/src/rust/api/hops.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14.0),

      children: [
        Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ExpansionTile(
              initiallyExpanded: false, // 默认折叠,
              leading: const Icon(Icons.info),
              title: const Text('软件设置'),
              children: [
              if (!Platform.isAndroid)
                SwitchListTile(
                  title: const Text('最小化'),
                  subtitle: const Text('是否点击关闭按钮最小化到托盘'),
                  value: Aps().closeMinimize.watch(context),
                  onChanged: (value) {
                    Aps().updateCloseMinimize(value);
                  },
                ),
              SwitchListTile(
                title: const Text('玩家列表卡片'),
                subtitle: const Text('是否简约显示'),
                value: Aps().userListSimple.watch(context),
                onChanged: (value) {
                  Aps().setUserListSimple(value);
                },
              ),
              SwitchListTile(
                title: const Text('参与内测版'),
                subtitle: const Text('加群分享你的bug'),
                value: Aps().beta.watch(context),
                onChanged: (value) {
                  Aps().setBeta(value);
                },
              ),
              if (!Aps().beta.watch(context))
                SwitchListTile(
                  title: const Text('自动更新'),
                  subtitle: const Text('享受最新bug'),
                  value: Aps().autoCheckUpdate.watch(context),
                  onChanged: (value) {
                    Aps().setAutoCheckUpdate(value);
                  },
                ),
              ListTile(
                title: const Text('下载加速'),
                subtitle: TextFormField(
                  decoration: const InputDecoration(
                    hintText: '启用下载加速功能',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: Aps().downloadAccelerate.watch(context),
                  onChanged: (value) {
                    Aps().setDownloadAccelerate(value);
                  },
                ),
              ),
            ],
          ),
        ),
        if (Platform.isWindows)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ExpansionTile(
              initiallyExpanded: false, // 默认折叠,
              leading: const Icon(Icons.broadcast_on_personal),
              title: const Text('广播管理'),
              children: [
                Builder(
                  builder: (context) {
                    final connections = Aps().connections.watch(context);
                    return Column(
                      children: [
                        ...List.generate(connections.length, (index) {
                          final manager = connections[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: ExpansionTile(
                              leading: Switch(
                                value: manager.enabled,
                                onChanged: (value) async {
                                  await Aps().updateConnectionEnabled(
                                    index,
                                    value,
                                  );
                                },
                              ),
                              title: Text(
                                manager.name.isEmpty ? '未命名分组' : manager.name,
                              ),
                              subtitle: Text(
                                '${manager.connections.length} 个连接',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    tooltip: '编辑',
                                    onPressed:
                                        () => editConnectionManager(
                                          context,
                                          index,
                                          manager,
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    tooltip: '删除',
                                    onPressed:
                                        () => deleteConnectionManager(
                                          context,
                                          index,
                                          manager.name,
                                        ),
                                  ),
                                ],
                              ),
                              children: [
                                ...manager.connections.map(
                                  (conn) => ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.link, size: 16),
                                    title: Text(
                                      '${conn.bindAddr} → ${conn.dstAddr}',
                                    ),
                                    subtitle: Text('协议: ${conn.proto}'),
                                  ),
                                ),
                                if (manager.connections.isEmpty)
                                  const ListTile(
                                    dense: true,
                                    title: Text('暂无连接配置'),
                                  ),
                              ],
                            ),
                          );
                        }),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: const Text('新增广播分组'),
                          onTap: () => addConnectionManager(context),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        if (Platform.isWindows)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ExpansionTile(
              initiallyExpanded: false, // 默认折叠
              leading: const Icon(Icons.network_check),
              title: const Text('网卡跃点设置'),
              children: [
                SwitchListTile(
                  title: const Text('自动设置跃点'),
                  subtitle: const Text('每次启动网卡自动设置跃点最小'),
                  value: Aps().autoSetMTU.watch(context),
                  onChanged: (value) {
                    Aps().setAutoSetMTU(value);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.list),
                  title: const Text('查看跃点列表'),
                  onTap: () async {
                    try {
                      final result = await getAllInterfacesMetrics();
                      if (!context.mounted) return;

                      await showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('网卡跃点列表'),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                      result
                                          .map((e) => Text('${e.$1}: ${e.$2}'))
                                          .toList(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('关闭'),
                                ),
                              ],
                            ),
                      );
                    } catch (e, s) {
                      await Sentry.captureException(e, stackTrace: s);
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('获取跃点列表失败')));
                    }
                  },
                ),
              ],
            ),
          ),

        if (!Platform.isAndroid)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ExpansionTile(
              initiallyExpanded: false, // 默认折叠
              leading: const Icon(Icons.launch),
              title: const Text('自启动相关'),
              children: [
                SwitchListTile(
                  title: const Text('开机自启动'),
                  subtitle: const Text('将程序添加到系统启动项，开机时自动运行'),
                  value: Aps().startup.watch(context),
                  onChanged: (value) {
                    Aps().setStartup(value);
                    handleStartupSetting(value);
                  },
                ),
                SwitchListTile(
                  title: const Text('启动后最小化'),
                  subtitle: const Text('程序启动后自动最小化到系统托盘'),
                  value: Aps().startupMinimize.watch(context),
                  onChanged: (value) {
                    Aps().setStartupMinimize(value);
                  },
                ),
                SwitchListTile(
                  title: const Text('启动后自动连接'),
                  subtitle: const Text('程序启动后自动连接到上次使用的服务器'),
                  value: Aps().startupAutoConnect.watch(context),
                  onChanged: (value) {
                    Aps().setStartupAutoConnect(value);
                  },
                ),
              ],
            ),
          ),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ExpansionTile(
            initiallyExpanded: false, // 默认折叠
            leading: const Icon(Icons.list_alt),
            title: const Text('监听列表'),
            children: [
              Builder(
                builder: (context) {
                  final listenList = Aps().listenList.watch(context);
                  return Column(
                    children: [
                      ...List.generate(listenList.length, (index) {
                        final item = listenList[index];
                        return ListTile(
                          title: Text(item),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                tooltip: '编辑',
                                onPressed: () async {
                                  final controller = TextEditingController(
                                    text: item,
                                  );
                                  final result = await showDialog<String>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text('编辑监听项'),
                                          content: TextField(
                                            controller: controller,
                                            autofocus: true,
                                            decoration: const InputDecoration(
                                              labelText: '监听项',
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(context),
                                              child: const Text('取消'),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    controller.text,
                                                  ),
                                              child: const Text('保存'),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (result != null &&
                                      result.trim().isNotEmpty &&
                                      result != item) {
                                    await Aps().updateListen(
                                      index,
                                      result.trim(),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                tooltip: '删除',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text('确认删除'),
                                          content: Text('确定要删除监听项 "$item" 吗？'),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: const Text('取消'),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: const Text('删除'),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (confirm == true) {
                                    await Aps().deleteListen(index);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                      ListTile(
                        leading: const Icon(Icons.add),
                        title: const Text('新增监听项'),
                        onTap: () async {
                          final controller = TextEditingController();
                          final result = await showDialog<String>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('新增监听项'),
                                  content: TextField(
                                    controller: controller,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      labelText: '监听项',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('取消'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(
                                            context,
                                            controller.text,
                                          ),
                                      child: const Text('添加'),
                                    ),
                                  ],
                                ),
                          );
                          if (result != null && result.trim().isNotEmpty) {
                            await Aps().addListen(result.trim());
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        if (!Platform.isAndroid)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ExpansionTile(
              initiallyExpanded: false,
              leading: const Icon(Icons.route),
              title: const Text('子网代理 (CIDR)'),
              children: [
                Builder(
                  builder: (context) {
                    final cidrList = Aps().cidrproxy.watch(context);
                    return Column(
                      children: [
                        ...List.generate(cidrList.length, (index) {
                          final cidr = cidrList[index];
                          return ListTile(
                            title: Text(cidr),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () async {
                                    final controller = TextEditingController(
                                      text: cidr,
                                    );
                                    final result = await showDialog<String>(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: const Text('编辑CIDR'),
                                            content: TextField(
                                              controller: controller,
                                              decoration: const InputDecoration(
                                                labelText:
                                                    'CIDR格式 (例: 192.168.1.0/24)',
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: const Text('取消'),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      controller.text,
                                                    ),
                                                child: const Text('保存'),
                                              ),
                                            ],
                                          ),
                                    );
                                    if (result != null && result.isNotEmpty) {
                                      await Aps().updateCidrproxy(
                                        index,
                                        result,
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: const Text('确认删除'),
                                            content: Text(
                                              '确定要删除CIDR "$cidr" 吗？',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                                child: const Text('取消'),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      true,
                                                    ),
                                                child: const Text('删除'),
                                              ),
                                            ],
                                          ),
                                    );
                                    if (confirm == true) {
                                      await Aps().deleteCidrproxy(index);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: const Text('添加CIDR代理'),
                          onTap: () async {
                            final controller = TextEditingController();
                            final result = await showDialog<String>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('添加CIDR代理'),
                                    content: TextField(
                                      controller: controller,
                                      decoration: const InputDecoration(
                                        labelText: 'CIDR格式 (例: 192.168.1.0/24)',
                                        hintText: '请输入CIDR网段',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(
                                              context,
                                              controller.text,
                                            ),
                                        child: const Text('添加'),
                                      ),
                                    ],
                                  ),
                            );
                            if (result != null && result.isNotEmpty) {
                              await Aps().addCidrproxy(result);
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        if (Platform.isAndroid)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ExpansionTile(
              initiallyExpanded: false,
              leading: const Icon(Icons.vpn_lock),
              title: const Text('自定义VPN网段'),
              children: [
                Builder(
                  builder: (context) {
                    final vpnList = Aps().customVpn.watch(context);
                    return Column(
                      children: [
                        ...List.generate(vpnList.length, (index) {
                          final vpn = vpnList[index];
                          return ListTile(
                            title: Text(vpn),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () async {
                                    final controller = TextEditingController(
                                      text: vpn,
                                    );
                                    final result = await showDialog<String>(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: const Text('编辑VPN网段'),
                                            content: TextField(
                                              controller: controller,
                                              decoration: const InputDecoration(
                                                labelText:
                                                    'VPN网段格式 (例: 10.0.0.0/8)',
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: const Text('取消'),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      controller.text,
                                                    ),
                                                child: const Text('保存'),
                                              ),
                                            ],
                                          ),
                                    );
                                    if (result != null && result.isNotEmpty) {
                                      await Aps().updateCustomVpn(
                                        index,
                                        result,
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: const Text('确认删除'),
                                            content: Text(
                                              '确定要删除VPN网段 "$vpn" 吗？',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                                child: const Text('取消'),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      true,
                                                    ),
                                                child: const Text('删除'),
                                              ),
                                            ],
                                          ),
                                    );
                                    if (confirm == true) {
                                      await Aps().deleteCustomVpn(index);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: const Text('添加VPN网段'),
                          onTap: () async {
                            final controller = TextEditingController();
                            final result = await showDialog<String>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('添加VPN网段'),
                                    content: TextField(
                                      controller: controller,
                                      decoration: const InputDecoration(
                                        labelText: 'VPN网段格式 (例: 10.0.0.0/8)',
                                        hintText: '请输入VPN网段',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(
                                              context,
                                              controller.text,
                                            ),
                                        child: const Text('添加'),
                                      ),
                                    ],
                                  ),
                            );
                            if (result != null && result.isNotEmpty) {
                              await Aps().addCustomVpn(result);
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ExpansionTile(
            initiallyExpanded: false, // 默认折叠
            leading: const Icon(Icons.network_wifi),
            title: const Text('网络设置'),
            children: [
              // 压缩算法下拉单选
              ListTile(
                title: const Text('P2P打洞'),
                subtitle: const Text('优先采用什么协议'),
                trailing: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        focusColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: DropdownButton<String>(
                        value:
                            Aps().defaultProtocol.watch(context).isEmpty
                                ? 'tcp'
                                : Aps().defaultProtocol.watch(context),
                        items: const [
                          DropdownMenuItem(
                            value: 'tcp',
                            child: Text('TCP', style: TextStyle(fontSize: 14)),
                          ),
                          DropdownMenuItem(
                            value: 'udp',
                            child: Text('UDP', style: TextStyle(fontSize: 14)),
                          ),
                          DropdownMenuItem(
                            value: 'ws',
                            child: Text(
                              'WebSocket',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'wss',
                            child: Text('WSS', style: TextStyle(fontSize: 14)),
                          ),
                          DropdownMenuItem(
                            value: 'quic',
                            child: Text('QUIC', style: TextStyle(fontSize: 14)),
                          ),
                        ],
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down),
                        onChanged: (value) {
                          if (value != null) {
                            Aps().updateDefaultProtocol(value);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),

              SwitchListTile(
                title: const Text('是否启用加密'),
                subtitle: const Text('会自动设置MTU'),
                value: Aps().enableEncryption.watch(context),
                onChanged: (value) {
                  Aps().updateEnableEncryption(value);
                },
              ),

              SwitchListTile(
                title: const Text('延迟优先'),
                subtitle: const Text('是否优先考虑延迟'),
                value: Aps().latencyFirst.watch(context),
                onChanged: (value) {
                  Aps().updateLatencyFirst(value);
                },
              ),

              SwitchListTile(
                title: const Text('魔术DNS'),
                subtitle: const Text('是否启用魔术DNS'),
                value: Aps().accept_dns.watch(context),
                onChanged: (value) {
                  Aps().updateAcceptDns(value);
                },
              ),
              SwitchListTile(
                title: const Text('TUN设备'),
                subtitle: const Text('是否禁用TUN设备'),
                value: Aps().noTun.watch(context),
                onChanged: (value) {
                  Aps().updateNoTun(value);
                },
              ),

              SwitchListTile(
                title: Row(
                  children: [
                    const Text('smoltcp网络栈'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '不推荐',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                subtitle: const Text('轻量级 TCP/IP 协议栈'),
                value: Aps().useSmoltcp.watch(context),
                onChanged: (value) {
                  Aps().updateUseSmoltcp(value);
                },
              ),

              SwitchListTile(
                title: const Text('禁用P2P'),
                subtitle: const Text('如果打洞困难可以禁用p2p'),
                value: Aps().disableP2p.watch(context),
                onChanged: (value) {
                  Aps().updateDisableP2p(value);
                },
              ),

              SwitchListTile(
                title: const Text('中继对等RPC'),
                subtitle: const Text('是否中继所有对等RPC'),
                value: Aps().relayAllPeerRpc.watch(context),
                onChanged: (value) {
                  Aps().updateRelayAllPeerRpc(value);
                },
              ),

              SwitchListTile(
                title: const Text('禁用UDP打洞'),
                subtitle: const Text('是否禁用UDP打洞'),
                value: Aps().disableUdpHolePunching.watch(context),
                onChanged: (value) {
                  Aps().updateDisableUdpHolePunching(value);
                },
              ),

              SwitchListTile(
                title: const Text('启用多线程'),
                subtitle: const Text('是否启用多线程'),
                value: Aps().multiThread.watch(context),
                onChanged: (value) {
                  Aps().updateMultiThread(value);
                },
              ),

              // 压缩算法下拉单选
              ListTile(
                title: const Text('压缩算法'),
                subtitle: const Text('选择数据压缩方式'),
                trailing: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        focusColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: DropdownButton<int>(
                        value: Aps().dataCompressAlgo.watch(context),
                        items: const [
                          DropdownMenuItem(
                            value: 1,
                            child: Text('不压缩', style: TextStyle(fontSize: 14)),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text(
                              '高性能压缩(Zstd)',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down),
                        onChanged: (value) {
                          if (value != null) {
                            Aps().updateDataCompressAlgo(value);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),

              SwitchListTile(
                title: const Text('绑定设备'),
                subtitle: const Text('只使用物理网卡,防止和其他虚拟网卡沟通'),
                value: Aps().bindDevice.watch(context),
                onChanged: (value) {
                  Aps().updateBindDevice(value);
                },
              ),

              SwitchListTile(
                title: const Text('启用KCP代理'),
                subtitle: const Text('是否启用 KCP 代理'),
                value: Aps().enableKcpProxy.watch(context),
                onChanged: (value) {
                  Aps().updateEnableKcpProxy(value);
                },
              ),

              SwitchListTile(
                title: const Text('用KCP输入'),
                subtitle: const Text('否接收 KCP 协议的数据'),
                value: Aps().disableKcpInput.watch(context),
                onChanged: (value) {
                  Aps().updateDisableKcpInput(value);
                },
              ),

              SwitchListTile(
                title: const Text('禁用中继KCP'),
                subtitle: const Text('是否为其他节点转发 KCP 流量'),
                value: Aps().disableRelayKcp.watch(context),
                onChanged: (value) {
                  Aps().updateDisableRelayKcp(value);
                },
              ),
            ],
          ),
        ),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              const ListTile(leading: Icon(Icons.info), title: Text('关于')),
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('官方QQ群 1025711103'),
                subtitle: const Text('点击复制群号'),
                onTap: () async {
                  const qqGroup = '1025711103'; // 替换为实际QQ群号
                  await Clipboard.setData(const ClipboardData(text: qqGroup));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('群号已复制到剪贴板')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.feedback),
                title: const Text('用户反馈'),
                onTap: _sendFeedback,
              ),
              ListTile(
                leading: const Icon(Icons.update),
                title: const Text('检查更新'),
                onTap: () {
                  final updateChecker = UpdateChecker(
                    owner: 'ldoubil',
                    repo: 'astral',
                  );
                  if (mounted) {
                    updateChecker.checkForUpdates(context);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendFeedback() async {
    final feedbackController = TextEditingController();
    final emailController = TextEditingController();
    final nameController = TextEditingController();

    final feedback = await showDialog<Map<String, String>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('用户反馈'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '姓名',
                    hintText: '请输入您的姓名',
                  ),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: '邮箱',
                    hintText: '请输入您的邮箱',
                  ),
                ),
                TextField(
                  controller: feedbackController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: '反馈内容',
                    hintText: '请输入您的反馈意见',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.pop(context, {
                      'name': nameController.text,
                      'email': emailController.text,
                      'feedback': feedbackController.text,
                    }),
                child: const Text('提交'),
              ),
            ],
          ),
    );

    if (feedback != null &&
        feedback['feedback']?.trim().isNotEmpty == true &&
        feedback['email']?.trim().isNotEmpty == true &&
        feedback['name']?.trim().isNotEmpty == true) {
      final sentryId = Sentry.captureMessage(
        "User Feedback from Settings Page",
      );

      final userFeedback = SentryUserFeedback(
        eventId: await sentryId,
        comments: feedback['feedback']!,
        email: feedback['email']!,
        name: feedback['name']!,
      );

      await Sentry.captureUserFeedback(userFeedback);
    }
  }
}
