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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已恢复默认配置')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '网络配置说明',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• 同一局域网：输入电脑的局域网IP，如 http://192.168.1.25:8080\n'
                    '• 异地访问：需要配置路由器端口映射和DDNS\n'
                    '• 默认端口：8080',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
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
                    '异地访问设置',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. 登录路由器管理后台\n'
                    '2. 找到端口映射/虚拟服务器设置\n'
                    '3. 添加规则：外部端口8080 → 内部IP:8080\n'
                    '4. 注册DDNS服务（如花生壳）获取域名\n'
                    '5. 在App中输入 http://你的域名:8080',
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