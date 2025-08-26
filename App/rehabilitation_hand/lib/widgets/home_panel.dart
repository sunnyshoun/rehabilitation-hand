import 'package:flutter/material.dart';

class HomePanel extends StatelessWidget {
  const HomePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 響應式設計
        final isTablet = constraints.maxWidth > 600;
        final crossAxisCount = isTablet ? 3 : 2;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '歡迎使用復健手控制系統',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    icon: Icons.timeline,
                    title: '今日進度',
                    subtitle: '已完成 0/5 個練習',
                    color: Colors.blue,
                  ),
                  _buildFeatureCard(
                    icon: Icons.calendar_today,
                    title: '訓練計劃',
                    subtitle: '查看本週計劃',
                    color: Colors.green,
                  ),
                  _buildFeatureCard(
                    icon: Icons.bar_chart,
                    title: '統計數據',
                    subtitle: '查看進步情況',
                    color: Colors.orange,
                  ),
                  _buildFeatureCard(
                    icon: Icons.history,
                    title: '歷史記錄',
                    subtitle: '查看過往訓練',
                    color: Colors.purple,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          // TODO: 實作功能
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
