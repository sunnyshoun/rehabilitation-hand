import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../services/motion_storage_service.dart';
import '../widgets/motion_templates_tab.dart';
import '../widgets/custom_motion_tab.dart';

class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasAttemptedAutoConnect = false;
  String? _editingTemplateId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _attemptAutoConnect();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _attemptAutoConnect() async {
    if (_hasAttemptedAutoConnect) return;
    _hasAttemptedAutoConnect = true;

    final btService = Provider.of<BluetoothService>(context, listen: false);

    if (btService.connected || btService.lastConnectedDevice == null) {
      return;
    }

    final isEnabled = await btService.isBluetoothEnabled();
    if (!isEnabled) return;

    final hasPermissions = await btService.checkPermissions();
    if (!hasPermissions) return;

    await btService.tryReconnectLastDevice();
  }

  void _handleEditTemplate(String templateId) {
    setState(() {
      _editingTemplateId = templateId;
      _tabController.animateTo(1); // 切換到自訂控制頁籤
    });
  }

  void _clearEditingTemplate() {
    setState(() {
      _editingTemplateId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 移除 MultiProvider，使用 main.dart 中的全局 Provider
    return Column(
      children: [
        // Tab標籤
        Container(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: TabBar(
            controller: _tabController,
            tabs: const [Tab(text: '動作模板'), Tab(text: '自訂動作')],
          ),
        ),
        // Tab內容
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              MotionTemplatesTab(onEditTemplate: _handleEditTemplate),
              CustomMotionTab(
                editingTemplateId: _editingTemplateId,
                onEditComplete: _clearEditingTemplate,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
