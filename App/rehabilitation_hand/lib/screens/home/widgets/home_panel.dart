import 'package:flutter/material.dart';
import 'feature_card.dart';

class HomePanel extends StatelessWidget {
  const HomePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
                children: const [
                  FeatureCard(
                    icon: Icons.timeline,
                    title: '今日進度',
                    subtitle: '已完成 0/5 個練習',
                    color: Colors.blue,
                  ),
                  FeatureCard(
                    icon: Icons.calendar_today,
                    title: '訓練計劃',
                    subtitle: '查看本週計劃',
                    color: Colors.green,
                  ),
                  FeatureCard(
                    icon: Icons.bar_chart,
                    title: '統計數據',
                    subtitle: '查看進步情況',
                    color: Colors.orange,
                  ),
                  FeatureCard(
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
}