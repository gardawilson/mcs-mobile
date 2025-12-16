import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/asset_bom_view_model.dart';
import 'package:flutter/services.dart';

class AssetBOMPage extends StatelessWidget {
  final String noSO;
  final String assetCode;
  final bool hasSubmitted;

  const AssetBOMPage({Key? key, required this.noSO, required this.assetCode, required this.hasSubmitted}) : super(key: key);

  static const Color redPrimary = Color(0xFF7a1b0c);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = AssetBOMViewModel();
        vm.fetchBOM(noSO, assetCode);
        return vm;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: redPrimary,
          foregroundColor: Colors.white,
          title: Text('Parts BOM - $assetCode'),
        ),
        body: Consumer<AssetBOMViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage.isNotEmpty) {
              return Center(child: Text(viewModel.errorMessage));
            }

            if (viewModel.bomList.isEmpty) {
              return const Center(child: Text('Tidak ada data BOM.'));
            }

            // Group items by relationship headers
            List<Map<String, dynamic>> groupedItems = _groupBOMItems(viewModel.bomList);

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 32, top: 8),
                    itemCount: groupedItems.length,
                    itemBuilder: (context, index) {
                      final group = groupedItems[index];
                      final header = group['header'] as String;
                      final items = group['items'] as List;
                      final isExpanded = viewModel.isSectionExpanded(header);
                      final isLoading = viewModel.isSectionLoading(header);

                      return Column(
                        children: [
                          // Expandable Header
                          InkWell(
                            onTap: () => _handleSectionTap(viewModel, header, items),
                            child: Container(
                              width: double.infinity,
                              color: redPrimary.withOpacity(0.08),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  if (isLoading)
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(redPrimary),
                                      ),
                                    )
                                  else
                                    Icon(
                                      isExpanded ? Icons.expand_less : Icons.expand_more,
                                      color: redPrimary,
                                      size: 24,
                                    ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      header,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: redPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${items.length} items',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: redPrimary.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Expandable Content with lazy loading
                          if (isExpanded && !isLoading)
                            _buildExpandedSection(context, items, viewModel, header),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: ElevatedButton.icon(
                      onPressed: hasSubmitted
                          ? null // Disable button jika hasSubmitted true
                          : () async {
                        final success = await viewModel.submitBOM(noSO, assetCode);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? '✅ Data BOM berhasil disimpan'
                                  : '❌ ${viewModel.errorMessage}',
                            ),
                          ),
                        );
                        if (success) Navigator.pop(context, true); // Kirim sinyal berhasil
                      },
                      label: Text(
                        hasSubmitted ? 'Sudah Disubmit' : 'Submit', // Ubah teks jika sudah submit
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasSubmitted ? Colors.grey : redPrimary, // Ubah warna jika disabled
                        minimumSize: const Size(double.infinity, 48),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey, // Warna saat disabled
                      ),
                      icon: hasSubmitted
                          ? Icon(Icons.check_circle, color: Colors.white)
                          : Icon(Icons.send, color: Colors.white),
                    )
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Handle section tap with loading state
  void _handleSectionTap(AssetBOMViewModel viewModel, String header, List items) async {
    if (viewModel.isSectionLoading(header)) return;

    final isCurrentlyExpanded = viewModel.isSectionExpanded(header);

    if (!isCurrentlyExpanded) {
      // Show loading for large datasets
      if (items.length > 30) {
        viewModel.setSectionLoading(header, true);

        // Small delay to show loading indicator
        await Future.delayed(const Duration(milliseconds: 100));

        // Process in chunks to avoid blocking UI
        await _processItemsInChunks(items, viewModel);

        viewModel.setSectionLoading(header, false);
      }
    }

    viewModel.toggleSectionExpansion(header);
  }

  // Process items in chunks to avoid UI blocking
  Future<void> _processItemsInChunks(List items, AssetBOMViewModel viewModel) async {
    const chunkSize = 20;
    for (int i = 0; i < items.length; i += chunkSize) {
      final end = (i + chunkSize < items.length) ? i + chunkSize : items.length;
      final chunk = items.sublist(i, end);

      // Simulate processing time
      await Future.delayed(const Duration(milliseconds: 10));

      // You can add any pre-processing logic here if needed
    }
  }

  // Build expanded section with optimized rendering
  Widget _buildExpandedSection(BuildContext context, List items, AssetBOMViewModel viewModel, String header) {
    // For large lists, use a more efficient approach
    if (items.length > 50) {
      return _buildLargeListSection(context, items, viewModel);
    } else {
      return Column(
        children: items.map((item) => _buildPartItem(context, item, viewModel)).toList(),
      );
    }
  }

  // Build large list with better performance
  Widget _buildLargeListSection(BuildContext context, List items, AssetBOMViewModel viewModel) {
    return ListView.builder(
      shrinkWrap: true, // penting kalau ada di dalam scroll lain
      physics: const NeverScrollableScrollPhysics(), // biar ikut scroll parent
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildPartItem(context, items[index], viewModel);
      },
    );
  }


  // Helper method to group BOM items by relationship headers
  List<Map<String, dynamic>> _groupBOMItems(List bomList) {
    List<Map<String, dynamic>> grouped = [];
    String currentHeader = '';
    List currentItems = [];

    for (var item in bomList) {
      if (item.level == 'relationship') {
        // Save previous group if exists
        if (currentHeader.isNotEmpty && currentItems.isNotEmpty) {
          grouped.add({
            'header': currentHeader,
            'items': List.from(currentItems),
          });
        }
        // Start new group
        currentHeader = item.header;
        currentItems = [];
      } else {
        // Add item to current group
        currentItems.add(item);
      }
    }

    // Add last group if exists
    if (currentHeader.isNotEmpty && currentItems.isNotEmpty) {
      grouped.add({
        'header': currentHeader,
        'items': List.from(currentItems),
      });
    }

    return grouped;
  }

  // Helper method to build individual part items with optimization and color coding
  Widget _buildPartItem(BuildContext context, dynamic item, AssetBOMViewModel viewModel) {
    // Get quantities for comparison
    final qtyOnHand = int.tryParse(item.qtyOnHand.toString()) ?? 0;
    final qtyFound = int.tryParse(item.qtyFound.toString()) ?? 0;

    // Determine card color based on quantity match
    Color cardColor;
    Color? cardShadowColor;

    if (qtyFound == qtyOnHand && qtyFound > 0) {
      // Matching quantities - Green shade
      cardColor = Colors.green.shade50;
      cardShadowColor = Colors.green.shade100;
    } else if (qtyFound != qtyOnHand && qtyFound > 0) {
      // Non-matching quantities - Red shade
      cardColor = Colors.red.shade50;
      cardShadowColor = Colors.red.shade100;
    } else {
      // Default - White (no quantity found yet)
      cardColor = Colors.white;
      cardShadowColor = null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(12),
        color: cardColor,
        shadowColor: cardShadowColor,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: qtyFound > 0
                ? Border.all(
              color: qtyFound == qtyOnHand
                  ? Colors.green.shade200
                  : Colors.red.shade200,
              width: 1.5,
            )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title with status indicator
                Row(
                  children: [
                    // Status indicator icon
                    if (qtyFound > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Icon(
                          qtyFound == qtyOnHand ? Icons.check_circle : Icons.warning,
                          color: qtyFound == qtyOnHand ? Colors.green.shade600 : Colors.red.shade600,
                          size: 20,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        item.part,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // System quantity
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Jumlah Sistem: ',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    Expanded(
                      child: Text(
                        '${item.qtyOnHand} ${item.uom}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Status summary badge
                if (qtyFound > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: qtyFound == qtyOnHand
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          qtyFound == qtyOnHand ? Icons.check : Icons.info_outline,
                          size: 14,
                          color: qtyFound == qtyOnHand
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          qtyFound == qtyOnHand
                              ? 'Sesuai'
                              : qtyFound > qtyOnHand
                              ? 'Lebih ${qtyFound - qtyOnHand}'
                              : 'Kurang ${qtyOnHand - qtyFound}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: qtyFound == qtyOnHand
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                // Quantity found controls
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    const Text('Jumlah Ditemukan:'),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: redPrimary),
                      onPressed: () {
                        final current = int.tryParse(item.qtyFound) ?? 0;
                        if (current > 0) {
                          viewModel.updateQtyFound(item.id, (current - 1).toString());
                        }
                      },
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        controller: viewModel.qtyControllers[item.id],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 6),
                        ),
                        onChanged: (value) {
                          final safeValue = int.tryParse(value) ?? 0;
                          viewModel.updateQtyFound(item.id, safeValue.toString());
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: redPrimary),
                      onPressed: () {
                        final current = int.tryParse(item.qtyFound) ?? 0;
                        viewModel.updateQtyFound(item.id, (current + 1).toString());
                      },
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Remarks button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: redPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    onPressed: () {
                      viewModel.toggleRemarkVisibility(item.id);
                    },
                    icon: Icon(
                      viewModel.isRemarkVisible(item.id)
                          ? Icons.comment
                          : Icons.comment_outlined,
                      size: 20,
                    ),
                    label: Text(
                      viewModel.isRemarkVisible(item.id)
                          ? 'Sembunyikan Catatan'
                          : 'Tambahkan Catatan',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                // Remarks field
                if (viewModel.isRemarkVisible(item.id))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextFormField(
                      controller: viewModel.remarkControllers[item.id],
                      decoration: const InputDecoration(
                        labelText: 'Catatan',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (value) => viewModel.updateRemark(item.id, value),
                      maxLines: 3,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}