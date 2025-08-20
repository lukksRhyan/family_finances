import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visão Geral')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('R\$ 2.150,00', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildBalanceSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('Depesas'),
            _buildInfoRow('3.050,0', '3.050,00'),
            const Divider(height: 32),
            _buildSectionTitle('Relatórios'),
            _buildInfoRow('Alimentação', 'R\$ 1.200,00'),
            _buildInfoRow('Morádia', 'R\$ 1.000,00'),
            _buildInfoRow('Transporte', 'R\$ 50,00'),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('R\$ 5.200,000', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
        SizedBox(
          height: 80,
          width: 80,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(color: Color(0xFF2A8782), value: 60, radius: 15, showTitle: false),
                PieChartSectionData(color: Colors.teal, value: 40, radius: 15, showTitle: false),
              ],
              centerSpaceRadius: 25,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey));
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}