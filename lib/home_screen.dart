import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'services/transaction_service.dart';
import 'add_transaction.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = 0; // 0 = All months

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 Budget Tracker'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: TransactionService.getTransactionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final allDocs = snapshot.data!.docs
              .map((d) => TransactionService.parseDoc(d))
              .toList();

          // Get available years
          final years = allDocs.map((d) => (d['date'] as DateTime).year).toSet().toList()..sort();
          if (!years.contains(_selectedYear) && years.isNotEmpty) {
            _selectedYear = years.last;
          }

          // Filter by year
          var filtered = allDocs.where((d) => (d['date'] as DateTime).year == _selectedYear).toList();

          // Filter by month
          List<Map<String, dynamic>> monthFiltered;
          if (_selectedMonth == 0) {
            monthFiltered = filtered;
          } else {
            monthFiltered = filtered.where((d) => (d['date'] as DateTime).month == _selectedMonth).toList();
          }

          return _buildDashboard(allDocs, filtered, monthFiltered, years);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransaction(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No transactions yet', style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.5))),
          const SizedBox(height: 8),
          Text('Tap + to add your first transaction', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
        ],
      ),
    );
  }

  Widget _buildDashboard(
    List<Map<String, dynamic>> allDocs,
    List<Map<String, dynamic>> yearFiltered,
    List<Map<String, dynamic>> monthFiltered,
    List<int> years,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F0C29), Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter row
            _buildFilterRow(years),
            const SizedBox(height: 20),

            // KPI Cards
            _buildKPICards(monthFiltered),
            const SizedBox(height: 24),

            // Monthly Bar Chart
            _buildSectionTitle('📊 Monthly Overview — $_selectedYear'),
            const SizedBox(height: 12),
            _buildMonthlyBarChart(yearFiltered),
            const SizedBox(height: 24),

            // Cumulative Trend Line
            _buildSectionTitle('📈 Cumulative Trend — $_selectedYear'),
            const SizedBox(height: 12),
            _buildCumulativeTrendChart(yearFiltered),
            const SizedBox(height: 24),

            // Category Pie Charts
            _buildSectionTitle('🍩 Category Breakdown'),
            const SizedBox(height: 12),
            _buildCategoryPieCharts(monthFiltered),
            const SizedBox(height: 24),

            // Last 10 Transactions
            _buildSectionTitle('📋 Recent Transactions'),
            const SizedBox(height: 12),
            _buildRecentTransactions(monthFiltered),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ─── Filters ──────────────────────────────────────────────────────────
  Widget _buildFilterRow(List<int> years) {
    final months = ['All Months', ...List.generate(12, (i) => DateFormat.MMMM().format(DateTime(2000, i + 1)))];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, color: Colors.white.withValues(alpha: 0.5), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedYear,
                dropdownColor: const Color(0xFF1A1A2E),
                style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14),
                icon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFFA0AEC0)),
                items: years.map((y) => DropdownMenuItem(value: y, child: Text('📅 $y'))).toList(),
                onChanged: (v) => setState(() => _selectedYear = v!),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedMonth,
                dropdownColor: const Color(0xFF1A1A2E),
                style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14),
                icon: const Icon(Icons.date_range, size: 16, color: Color(0xFFA0AEC0)),
                items: months.asMap().entries.map((e) => DropdownMenuItem(value: e.key, child: Text('🗓️ ${e.value}'))).toList(),
                onChanged: (v) => setState(() => _selectedMonth = v!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── KPI Cards ────────────────────────────────────────────────────────
  Widget _buildKPICards(List<Map<String, dynamic>> data) {
    double income = 0, expenses = 0, savings = 0;
    for (final d in data) {
      final amount = d['amount'] as double;
      switch (d['type']) {
        case 'Income':
          income += amount;
          break;
        case 'Expenses':
          expenses += amount;
          break;
        case 'Savings':
          savings += amount;
          break;
      }
    }
    final net = income - expenses;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: 2.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _kpiCard('💵 Income', income, const Color(0xFF48BB78)),
            _kpiCard('🔻 Expenses', expenses, const Color(0xFFFC8181)),
            _kpiCard('🏦 Net Savings', net, net >= 0 ? const Color(0xFF48BB78) : const Color(0xFFFC8181)),
            _kpiCard('💰 Tracked Savings', savings, const Color(0xFF63B3ED)),
          ],
        );
      },
    );
  }

  Widget _kpiCard(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
            style: TextStyle(color: const Color(0xFFA0AEC0), fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('€ ${NumberFormat('#,##0.00').format(value)}',
              style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ─── Monthly Bar Chart ────────────────────────────────────────────────
  Widget _buildMonthlyBarChart(List<Map<String, dynamic>> yearData) {
    // Aggregate by month & type
    final Map<int, Map<String, double>> monthlyTotals = {};
    for (int m = 1; m <= 12; m++) {
      monthlyTotals[m] = {'Income': 0, 'Expenses': 0, 'Savings': 0};
    }
    for (final d in yearData) {
      final month = (d['date'] as DateTime).month;
      final type = d['type'] as String;
      if (monthlyTotals[month]!.containsKey(type)) {
        monthlyTotals[month]![type] = monthlyTotals[month]![type]! + (d['amount'] as double);
      }
    }

    final maxVal = monthlyTotals.values
        .expand((m) => m.values)
        .fold(0.0, (a, b) => a > b ? a : b);

    return _chartContainer(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.15,
          barGroups: List.generate(12, (i) {
            final m = i + 1;
            final vals = monthlyTotals[m]!;
            final isActive = _selectedMonth == 0 || _selectedMonth == m;
            final opacity = isActive ? 1.0 : 0.2;
            return BarChartGroupData(
              x: m,
              barRods: [
                BarChartRodData(toY: vals['Income']!, color: const Color(0xFF48BB78).withValues(alpha: opacity), width: 8, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                BarChartRodData(toY: vals['Expenses']!, color: const Color(0xFFFC8181).withValues(alpha: opacity), width: 8, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                BarChartRodData(toY: vals['Savings']!, color: const Color(0xFF63B3ED).withValues(alpha: opacity), width: 8, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
              ],
            );
          }),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(months[value.toInt()], style: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 10)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text('€${NumberFormat.compact().format(value)}',
                    style: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 10));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.06), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF1A1A2E),
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final types = ['Income', 'Expenses', 'Savings'];
                final colors = [const Color(0xFF48BB78), const Color(0xFFFC8181), const Color(0xFF63B3ED)];
                return BarTooltipItem(
                  '${types[rodIndex]}\n€${NumberFormat('#,##0.00').format(rod.toY)}',
                  TextStyle(color: colors[rodIndex], fontSize: 12, fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ─── Cumulative Trend Chart ───────────────────────────────────────────
  Widget _buildCumulativeTrendChart(List<Map<String, dynamic>> yearData) {
    if (yearData.isEmpty) return const SizedBox.shrink();

    final lastMonth = yearData.map((d) => (d['date'] as DateTime).month).reduce((a, b) => a > b ? a : b);

    final List<Map<String, double>> cumData = [];
    for (int m = 1; m <= lastMonth; m++) {
      double cumIncome = 0, cumExpenses = 0, cumSavings = 0;
      for (final d in yearData) {
        if ((d['date'] as DateTime).month <= m) {
          switch (d['type']) {
            case 'Income': cumIncome += d['amount'] as double; break;
            case 'Expenses': cumExpenses += d['amount'] as double; break;
            case 'Savings': cumSavings += d['amount'] as double; break;
          }
        }
      }
      cumData.add({
        'month': m.toDouble(),
        'Income': cumIncome,
        'Expenses': cumExpenses,
        'Savings': cumSavings,
        'Net': cumIncome - cumExpenses,
      });
    }

    final maxVal = cumData
        .expand((m) => [m['Income']!, m['Expenses']!, m['Savings']!, m['Net']!])
        .fold(0.0, (a, b) => a.abs() > b.abs() ? a : b)
        .abs();

    final lines = [
      {'key': 'Income', 'color': const Color(0xFF48BB78), 'dash': false},
      {'key': 'Expenses', 'color': const Color(0xFFFC8181), 'dash': false},
      {'key': 'Savings', 'color': const Color(0xFF63B3ED), 'dash': false},
      {'key': 'Net', 'color': const Color(0xFFFFD700), 'dash': true},
    ];

    return _chartContainer(
      height: 280,
      child: LineChart(
        LineChartData(
          minX: 1,
          maxX: lastMonth.toDouble(),
          maxY: maxVal * 1.15,
          lineBarsData: lines.map((line) {
            return LineChartBarData(
              spots: cumData.map((d) => FlSpot(d['month']!, d[line['key']]!)).toList(),
              isCurved: true,
              color: line['color'] as Color,
              barWidth: 2.5,
              dotData: const FlDotData(show: true),
              dashArray: (line['dash'] as bool) ? [8, 4] : null,
              belowBarData: BarAreaData(show: false),
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                  if (value.toInt() >= 1 && value.toInt() <= 12) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(months[value.toInt()], style: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 10)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Text('€${NumberFormat.compact().format(value)}',
                    style: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 10));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.06), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF1A1A2E),
              tooltipRoundedRadius: 8,
              getTooltipItems: (spots) {
                final labels = ['Income', 'Expenses', 'Savings', 'Net'];
                final colors = [const Color(0xFF48BB78), const Color(0xFFFC8181), const Color(0xFF63B3ED), const Color(0xFFFFD700)];
                return spots.asMap().entries.map((e) {
                  return LineTooltipItem(
                    '${labels[e.key]}: €${NumberFormat('#,##0').format(e.value.y)}',
                    TextStyle(color: colors[e.key], fontSize: 11),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  // ─── Category Pie Charts ──────────────────────────────────────────────
  Widget _buildCategoryPieCharts(List<Map<String, dynamic>> data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _singlePieChart('Income', data, [const Color(0xFF48BB78), const Color(0xFF68D391), const Color(0xFF9AE6B4), const Color(0xFFC6F6D5), const Color(0xFFF0FFF4), const Color(0xFFB2F5EA)])),
              const SizedBox(width: 12),
              Expanded(child: _singlePieChart('Expenses', data, [const Color(0xFFFC8181), const Color(0xFFFEB2B2), const Color(0xFFFED7D7), const Color(0xFFE53E3E), const Color(0xFFC53030), const Color(0xFFFBD5D5)])),
              const SizedBox(width: 12),
              Expanded(child: _singlePieChart('Savings', data, [const Color(0xFF63B3ED), const Color(0xFF90CDF4), const Color(0xFFBEE3F8), const Color(0xFF4299E1), const Color(0xFF3182CE), const Color(0xFFD0E8F7)])),
            ],
          );
        }
        return Column(
          children: [
            _singlePieChart('Income', data, [const Color(0xFF48BB78), const Color(0xFF68D391), const Color(0xFF9AE6B4), const Color(0xFFC6F6D5), const Color(0xFFF0FFF4), const Color(0xFFB2F5EA)]),
            const SizedBox(height: 16),
            _singlePieChart('Expenses', data, [const Color(0xFFFC8181), const Color(0xFFFEB2B2), const Color(0xFFFED7D7), const Color(0xFFE53E3E), const Color(0xFFC53030), const Color(0xFFFBD5D5)]),
            const SizedBox(height: 16),
            _singlePieChart('Savings', data, [const Color(0xFF63B3ED), const Color(0xFF90CDF4), const Color(0xFFBEE3F8), const Color(0xFF4299E1), const Color(0xFF3182CE), const Color(0xFFD0E8F7)]),
          ],
        );
      },
    );
  }

  Widget _singlePieChart(String type, List<Map<String, dynamic>> data, List<Color> palette) {
    final typeData = data.where((d) => d['type'] == type).toList();
    final Map<String, double> catTotals = {};
    for (final d in typeData) {
      final cat = d['category'] as String;
      catTotals[cat] = (catTotals[cat] ?? 0) + (d['amount'] as double);
    }

    if (catTotals.isEmpty) {
      return _chartContainer(
        height: 240,
        child: Center(child: Text('No $type data', style: TextStyle(color: Colors.white.withValues(alpha: 0.4)))),
      );
    }

    // Sort and get top 5 + other
    final sorted = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();
    final otherSum = sorted.skip(5).fold(0.0, (s, e) => s + e.value);
    if (otherSum > 0) {
      top5.add(MapEntry('Other', otherSum));
    }
    final total = top5.fold(0.0, (s, e) => s + e.value);

    return _chartContainer(
      height: 280,
      child: Column(
        children: [
          Text(type, style: const TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Expanded(
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 30,
                sectionsSpace: 2,
                sections: top5.asMap().entries.map((e) {
                  final pct = (e.value.value / total * 100);
                  return PieChartSectionData(
                    value: e.value.value,
                    title: '${e.value.key}\n${pct.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600),
                    radius: 60,
                    color: palette[e.key % palette.length],
                    titlePositionPercentageOffset: 1.5,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Recent Transactions ──────────────────────────────────────────────
  Widget _buildRecentTransactions(List<Map<String, dynamic>> data) {
    final sorted = List<Map<String, dynamic>>.from(data);
    sorted.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    final recent = sorted.take(10).toList();

    if (recent.isEmpty) {
      return Center(child: Text('No transactions', style: TextStyle(color: Colors.white.withValues(alpha: 0.4))));
    }

    return _chartContainer(
      height: null,
      child: Column(
        children: recent.map((tx) {
          final date = DateFormat('yyyy-MM-dd').format(tx['date'] as DateTime);
          final type = tx['type'] as String;
          final isIncome = type == 'Income';
          final isSavings = type == 'Savings';
          final color = isIncome ? const Color(0xFF48BB78) : isSavings ? const Color(0xFF63B3ED) : const Color(0xFFFC8181);
          final icon = isIncome ? Icons.arrow_upward : isSavings ? Icons.savings : Icons.arrow_downward;

          return Dismissible(
            key: Key(tx['id']),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red.withValues(alpha: 0.3),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => TransactionService.deleteTransaction(tx['id']),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 20),
              ),
              title: Text(tx['category'] as String, style: const TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.w500)),
              subtitle: Text('$date${tx['details'] != '' ? ' · ${tx['details']}' : ''}',
                style: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 12)),
              trailing: Text(
                '€ ${NumberFormat('#,##0.00').format(tx['amount'])}',
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 18, fontWeight: FontWeight.w700));
  }

  Widget _chartContainer({required double? height, required Widget child}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }

  void _showAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const AddTransactionSheet(),
    );
  }
}