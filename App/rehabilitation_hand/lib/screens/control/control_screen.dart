import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rehabilitation_hand/services/bluetooth_service.dart';
import 'package:rehabilitation_hand/config/themes.dart';
import 'widgets/motion_templates_tab.dart';
import 'widgets/custom_motion_tab.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen>
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
    if (!mounted || !isEnabled) return;

    final hasPermissions = await btService.checkPermissions();
    if (!mounted || !hasPermissions) return;

    await btService.tryReconnectLastDevice();
  }

  void _handleEditTemplate(String templateId) {
    setState(() {
      _editingTemplateId = templateId;
      _tabController.animateTo(1);
    });
  }

  void _clearEditingTemplate() {
    setState(() {
      _editingTemplateId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).appBarTheme.backgroundColor ??
                Theme.of(context).primaryColor,
            border: Border(
              bottom: BorderSide(
                color: AppColors.divider(context), // 使用主題分隔線顏色
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: const [Tab(text: '動作模板'), Tab(text: '自訂動作')],
            indicatorColor: Theme.of(context).primaryColor,
            labelColor:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Theme.of(context).primaryColor,
            unselectedLabelColor:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
          ),
        ),
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
