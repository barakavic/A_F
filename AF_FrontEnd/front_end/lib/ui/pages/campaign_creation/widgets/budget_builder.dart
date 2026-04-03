import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_end/core/constants/app_colors.dart';
import 'package:front_end/core/utils/currency_formatter.dart';
import 'package:front_end/providers/campaign_wizard_provider.dart';

class BudgetBuilder extends ConsumerStatefulWidget {
  const BudgetBuilder({super.key});

  @override
  ConsumerState<BudgetBuilder> createState() => _BudgetBuilderState();
}

class _BudgetBuilderState extends ConsumerState<BudgetBuilder> {
  final List<TextEditingController> _activityControllers = [];
  final List<TextEditingController> _costControllers = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _syncWithState());
  }

  void _syncWithState() {
    final items = ref.read(campaignWizardProvider).budgetItems;
    if (items.isEmpty) {
      _addItem();
    } else {
      for (var item in items) {
        _activityControllers.add(TextEditingController(text: item['activity']));
        _costControllers.add(TextEditingController(text: item['amount']));
      }
    }
  }

  void _addItem() {
    setState(() {
      _activityControllers.add(TextEditingController());
      _costControllers.add(TextEditingController());
    });
    _onChanged();
  }

  void _removeItem(int index) {
    if (_activityControllers.length <= 1) return;
    setState(() {
      _activityControllers[index].dispose();
      _costControllers[index].dispose();
      _activityControllers.removeAt(index);
      _costControllers.removeAt(index);
    });
    _onChanged();
  }

  void _onChanged() {
    final List<Map<String, dynamic>> items = [];
    for (int i = 0; i < _activityControllers.length; i++) {
      if (_activityControllers[i].text.isNotEmpty || _costControllers[i].text.isNotEmpty) {
        items.add({
          'activity': _activityControllers[i].text,
          'amount': _costControllers[i].text,
        });
      }
    }
    ref.read(campaignWizardProvider.notifier).updateBudgetItems(items);
  }

  @override
  void dispose() {
    for (var c in _activityControllers) {
      c.dispose();
    }
    for (var c in _costControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(campaignWizardProvider);
    final totalBudget = _calculateTotal();
    final difference = state.goalAmount - totalBudget;
    final isOver = difference < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Budget Breakdown",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _activityControllers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _activityControllers[index],
                    decoration: InputDecoration(
                      labelText: "Activity/Item",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                    onChanged: (_) => _onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _costControllers[index],
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyFormatter.inputFormatter],
                    decoration: InputDecoration(
                      labelText: "Cost",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                    onChanged: (_) => _onChanged(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                  onPressed: () => _removeItem(index),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add, size: 18),
          label: const Text("Add Budget Item", style: TextStyle(fontWeight: FontWeight.bold)),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        const SizedBox(height: 24),
        _buildSummaryBox(totalBudget, difference, isOver),
      ],
    );
  }

  double _calculateTotal() {
    double total = 0;
    for (var controller in _costControllers) {
      total += CurrencyFormatter.parse(controller.text);
    }
    return total;
  }

  Widget _buildSummaryBox(double total, double diff, bool isOver) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Current Total", style: TextStyle(color: Colors.pink.shade300, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("KES ${CurrencyFormatter.format(total)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(
            isOver 
                ? "Over by KES ${CurrencyFormatter.format(diff.abs())}"
                : "Under by KES ${CurrencyFormatter.format(diff)}",
            style: TextStyle(
              color: isOver ? Colors.red : Colors.green.shade400,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
