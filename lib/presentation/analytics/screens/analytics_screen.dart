import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../state/providers/analytics_provider.dart';
import '../../../state/providers/auth_provider.dart';
import '../widgets/pie_chart_widget.dart';
import '../widgets/line_chart_widget.dart';
import 'package:intl/intl.dart';

/// Analytics screen with charts and statistics
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 0; // 0: This Month, 1: Last Month, 2: Last 6 Months
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  Future<void> _loadAnalytics() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUserId != null) {
      final analyticsProvider = context.read<AnalyticsProvider>();
      await analyticsProvider.loadAnalytics();
    }
  }

  Future<void> _handleRefresh() async {
    await _loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analyticsProvider = context.watch<AnalyticsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.analytics),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: analyticsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Selector
              _buildPeriodSelector(theme),
              const SizedBox(height: 24),

              // Monthly Summary Card
              _buildMonthlySummary(theme, analyticsProvider),
              const SizedBox(height: 24),

              // Category-wise Expense Pie Chart
              if (analyticsProvider.categoryWiseExpenses.isNotEmpty) ...[
                Text(
                  AppStrings.categoryWise,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                PieChartWidget(
                  data: analyticsProvider.categoryWiseExpenses,
                  title: 'Expenses',
                ),
                const SizedBox(height: 24),
              ],

              // Category-wise Income Pie Chart
              if (analyticsProvider.categoryWiseIncome.isNotEmpty) ...[
                PieChartWidget(
                  data: analyticsProvider.categoryWiseIncome,
                  title: 'Income',
                  isIncome: true,
                ),
                const SizedBox(height: 24),
              ],

              // Top Spending Categories
              if (analyticsProvider.categoryWiseExpenses.isNotEmpty) ...[
                Text(
                  'Top Spending Categories',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _buildTopCategories(theme, analyticsProvider),
                const SizedBox(height: 24),
              ],

              // Monthly Trend Line Chart
              if (analyticsProvider.monthlyTrend.isNotEmpty) ...[
                Text(
                  AppStrings.monthlyTrend,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                LineChartWidget(
                  data: analyticsProvider.monthlyTrend,
                ),
                const SizedBox(height: 24),
              ],

              // Empty State
              if (analyticsProvider.categoryWiseExpenses.isEmpty &&
                  analyticsProvider.categoryWiseIncome.isEmpty) ...[
                _buildEmptyState(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build period selector chips
  Widget _buildPeriodSelector(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPeriodChip(
            label: AppStrings.thisMonth,
            index: 0,
            theme: theme,
          ),
          const SizedBox(width: 12),
          _buildPeriodChip(
            label: AppStrings.lastMonth,
            index: 1,
            theme: theme,
          ),
          const SizedBox(width: 12),
          _buildPeriodChip(
            label: AppStrings.last6Months,
            index: 2,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip({
    required String label,
    required int index,
    required ThemeData theme,
  }) {
    final isSelected = _selectedPeriod == index;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPeriod = index;
          });
        }
      },
      selectedColor: theme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// Build monthly summary card
  Widget _buildMonthlySummary(
      ThemeData theme,
      AnalyticsProvider analyticsProvider,
      ) {
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return FutureBuilder<Map<String, double>>(
      future: analyticsProvider.getCurrentMonthSummary(),
      builder: (context, snapshot) {
        final income = snapshot.data?['income'] ?? 0.0;
        final expense = snapshot.data?['expense'] ?? 0.0;
        final balance = snapshot.data?['balance'] ?? 0.0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                theme.primaryColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This Month Summary',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem(
                    label: 'Income',
                    amount: income,
                    icon: Icons.arrow_upward,
                    theme: theme,
                    currencyFormatter: currencyFormatter,
                  ),
                  _buildSummaryItem(
                    label: 'Expense',
                    amount: expense,
                    icon: Icons.arrow_downward,
                    theme: theme,
                    currencyFormatter: currencyFormatter,
                  ),
                  _buildSummaryItem(
                    label: 'Balance',
                    amount: balance,
                    icon: Icons.account_balance_wallet,
                    theme: theme,
                    currencyFormatter: currencyFormatter,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required double amount,
    required IconData icon,
    required ThemeData theme,
    required NumberFormat currencyFormatter,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormatter.format(amount),
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build top spending categories list
  Widget _buildTopCategories(
      ThemeData theme,
      AnalyticsProvider analyticsProvider,
      ) {
    final topCategories = analyticsProvider.getTopSpendingCategories(limit: 5);
    final total = analyticsProvider.categoryWiseExpenses.values
        .fold(0.0, (sum, val) => sum + val);
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: topCategories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final percentage = total > 0 ? (category.value / total) * 100 : 0;

          return Column(
            children: [
              if (index > 0) const Divider(height: 24),
              Row(
                children: [
                  // Rank
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Category Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.key,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: theme.dividerColor,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Amount and Percentage
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormatter.format(category.value),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 80,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add some transactions to see analytics',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}