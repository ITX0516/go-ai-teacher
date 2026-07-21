import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/config_service.dart';
import '../services/game_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _urlController;
  bool _isSaving = false;
  bool _isTesting = false;
  String _testResult = '';

  @override
  void initState() {
    super.initState();
    final configService = Provider.of<ConfigService>(context, listen: false);
    _urlController = TextEditingController(text: configService.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveUrl() async {
    setState(() => _isSaving = true);
    final configService = Provider.of<ConfigService>(context, listen: false);
    await configService.setBaseUrl(_urlController.text);
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已保存，重启应用生效')),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = '';
    });
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _isTesting = false;
        _testResult = '请输入后端地址';
      });
      return;
    }
    try {
      final gameService = Provider.of<GameService>(context, listen: false);
      await gameService.getGame('test');
      setState(() {
        _isTesting = false;
        _testResult = '✓ 连接成功';
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testResult = '✗ 连接失败: $e';
      });
    }
  }

  Future<void> _resetToDefault() async {
    final configService = Provider.of<ConfigService>(context, listen: false);
    await configService.resetToDefault();
    _urlController.text = configService.baseUrl;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已恢复默认配置')),
    );
  }

  Future<void> _toggleMode(bool value) async {
    final configService = Provider.of<ConfigService>(context, listen: false);
    await configService.setOfflineMode(value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value ? '已切换到离线模式' : '已切换到连接本地后端模式，重启应用生效')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configService = Provider.of<ConfigService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '运行模式',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('离线模式'),
                    subtitle: const Text('使用内置Dart引擎，无需后端服务'),
                    value: configService.isOfflineMode,
                    onChanged: _toggleMode,
                    activeColor: const Color(0xFF2D5016),
                  ),
                  const SizedBox(height: 8),
                  if (!configService.isOfflineMode)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        '⚠️ 已切换到连接本地后端模式',
                        style: TextStyle(color: Colors.orange[600], fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '后端服务地址',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '在非离线模式下，手机需要与电脑连接同一WLAN',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'http://192.168.1.25:8080',
                      labelText: 'Base URL',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveUrl,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D5016),
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('保存'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isTesting ? null : _testConnection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: _isTesting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('测试连接'),
                        ),
                      ),
                    ],
                  ),
                  if (_testResult.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _testResult,
                        style: TextStyle(
                          color: _testResult.contains('✓') ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _resetToDefault,
                    child: const Text('恢复默认'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '使用说明',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '【离线模式】\n'
                    '• 使用内置纯Dart围棋引擎\n'
                    '• AI难度较低，但无需任何后端\n'
                    '• 随时随地可用，无需网络\n\n'
                    '【连接本地后端】\n'
                    '• 使用电脑上的KataGo强AI\n'
                    '• 分析更准确，AI水平更高\n'
                    '• 需要手机与电脑连接同一WLAN\n'
                    '• 需要在电脑上运行Go后端服务\n\n'
                    '【如何获取电脑IP】\n'
                    'Windows: cmd → ipconfig\n'
                    'macOS/Linux: terminal → ifconfig 或 ip addr',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}