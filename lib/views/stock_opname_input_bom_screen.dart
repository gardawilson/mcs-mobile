import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../view_models/stock_opname_input_bom_view_model.dart';
import '../view_models/master_data_view_model.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/add_manual_dialog.dart';
import '../views/barcode_qr_scan_screen.dart';
import '../views/asset_bom_view.dart';
import '../models/company_model.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';


class StockOpnameInputBOMScreen extends StatefulWidget {
  final String noSO;
  final String tgl;

  const StockOpnameInputBOMScreen({Key? key, required this.noSO, required this.tgl}) : super(key: key);

  @override
  _StockOpnameInputBOMScreenState createState() => _StockOpnameInputBOMScreenState();
}

class _StockOpnameInputBOMScreenState extends State<StockOpnameInputBOMScreen> {
  Set<String> _selectedCompanies = {};
  Set<String> _selectedCategories = {};
  Set<String> _selectedLocations = {};

  final TextEditingController _locationController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<StockOpnameInputBOMViewModel>(context, listen: false);

    // Memanggil fetchData() untuk memuat data lokasi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.fetchAssets(widget.noSO).then((_) {
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.tgl} ( ${widget.noSO} ) BOM',
          style: const TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF7a1b0c),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.filter_list, color: Colors.white),
        //     onPressed: () => _showFilterModal(context), // Memanggil modal saat tombol ditekan
        //   ),
        // ],
      ),
      body: Column(
        children: [
          Material(
            elevation: 1,  // Menambahkan efek bayangan
            child: Padding(
              padding: const EdgeInsets.all(1.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Filter Button
                  ElevatedButton.icon(
                    onPressed: () => _showFilterModal(context), // Memanggil modal saat tombol ditekan
                    icon: Icon(Icons.filter_list, color: Colors.black, size: 24),
                    label: Text(
                      'Filters',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,  // Membuat tombol transparan
                      elevation: 0,  // Tanpa bayangan
                      minimumSize: Size(100, 40),  // Ukuran minimum tombol agar tidak terlalu kecil
                    ),
                  ),
                  SizedBox(width: 16),
                  _buildCountText(),  // Menampilkan count di sebelah kanan
                ],
              ),
            ),
          ),
          Expanded(
            child: Consumer<StockOpnameInputBOMViewModel>(
              builder: (context, viewModel, child) {
                // Jika daftar asset kosong, tampilkan pesan data kosong
                if (viewModel.assetList.isEmpty) {
                  // Jika tidak ada data, beri pesan seperti "Data Kosong"
                  if (viewModel.errorMessage.contains("404")) {
                    return const Center(
                      child: Text(
                        'Tidak ada data ditemukan',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  // Jika ada error, tampilkan pesan error
                  return Center(
                    child: Text(
                      viewModel.errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: viewModel.assetList.length + (viewModel.hasMore ? 2 : 1), // 1 for header, 1 for loading
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          '📋 Daftar Asset',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      );
                    }

                    if (index == viewModel.assetList.length + 1) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        viewModel.loadMoreAssets(
                          widget.noSO,
                          companyFilters: _selectedCompanies.toList(), // ⬅️ kirim filter
                          categoryFilters: _selectedCategories.toList(), // ⬅️ kirim filter
                          locationFilters: _selectedLocations.toList(), // ⬅️ kirim filter
                        );
                      });

                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final asset = viewModel.assetList[index - 1];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssetBOMPage(
                                noSO: widget.noSO,
                                assetCode: asset.assetCode,
                                hasSubmitted: asset.username != null && asset.username!.isNotEmpty,
                              ),
                            ),
                          );

                          if (result == true) {
                            await viewModel.fetchAssets(
                              widget.noSO,
                              companyFilters: _selectedCompanies.toList(),
                              categoryFilters: _selectedCategories.toList(),
                              locationFilters: _selectedLocations.toList(),
                            );
                          }
                        },

                        title: Text(
                          asset.assetName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(asset.assetCode),
                            if (asset.username != null && asset.username.isNotEmpty)
                              Text(
                                'Submitted by ${asset.username}',
                                style: const TextStyle(fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                        leading: const Icon(Icons.inventory, color: Colors.blue),
                        trailing: asset.username != null && asset.username.isNotEmpty
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: const Color(0xFF7a1b0c),
        foregroundColor: Colors.white,
        visible: true,
        curve: Curves.linear,
        spaceBetweenChildren: 16,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.qr_code),
            label: 'Scan QR',
            onTap: () {
              _showScanBarQRCode(context);
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.edit_note),
            label: 'Input Manual',
            onTap: () {
              // _showAddManualDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showFilterModal(BuildContext context) {
    final masterViewModel = Provider.of<MasterDataViewModel>(context, listen: false);
    masterViewModel.fetchMasterData(); // Ganti dari fetchCompanies()

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer<MasterDataViewModel>(
                builder: (context, vm, _) {
                  if (vm.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (vm.errorMessage.isNotEmpty) {
                    return Center(child: Text('❌ ${vm.errorMessage}'));
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Company',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: vm.companies.map((company) {
                          final isSelected = _selectedCompanies.contains(company.companyId);
                          return ChoiceChip(
                            label: Text(company.companyName),
                            selected: isSelected,
                            selectedColor: Colors.blue.shade100,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.blue : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  _selectedCompanies.add(company.companyId);
                                } else {
                                  _selectedCompanies.remove(company.companyId);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Category',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: vm.categories.map((category) {
                          final isSelected = _selectedCategories.contains(category.categoryCode);
                          return ChoiceChip(
                            label: Text(category.categoryName),
                            selected: isSelected,
                            selectedColor: Colors.green.shade100,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.green : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  _selectedCategories.add(category.categoryCode);
                                } else {
                                  _selectedCategories.remove(category.categoryCode);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 24),
                      // Location Section - Scrollable & Responsive
                      Text(
                        'Location',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      MultiSelectDialogField(
                        items: vm.locations
                            .map((loc) => MultiSelectItem(loc.locationCode, loc.locationName))
                            .toList(),
                        title: Text("Pilih Lokasi"),
                        buttonText: Text("Klik untuk pilih lokasi"),
                        initialValue: _selectedLocations.toList(),
                        searchable: true,
                        listType: MultiSelectListType.CHIP,
                        onConfirm: (values) {
                          setModalState(() {
                            _selectedLocations = values.toSet().cast<String>();
                          });
                        },
                        chipDisplay: MultiSelectChipDisplay(
                          scroll: true, // Aktifkan scroll
                          height: 50, // Batasi tinggi untuk area scroll
                          chipColor: Colors.orange.shade100, // Warna latar belakang chip yang tidak dipilih
                          textStyle: TextStyle(
                            color: Colors.orange,
                          ),
                        ),
                        selectedColor: Colors.orange.shade100,
                        selectedItemsTextStyle: TextStyle(
                          color: Colors.orange,
                        ),
                        cancelText: Text("Batal"), // Mengubah teks tombol Cancel
                        confirmText: Text("Pilih"), // Mengubah teks tombol Confirm (OK)
                      ),


                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            print("📦 Company: ${_selectedCompanies.join(', ')}");
                            print("📂 Category: ${_selectedCategories.join(', ')}");
                            print("📂 Location: ${_selectedLocations.join(', ')}");

                            final viewModel = Provider.of<StockOpnameInputBOMViewModel>(context, listen: false);
                            viewModel.fetchAssets(
                              widget.noSO,
                              companyFilters: _selectedCompanies.toList(),
                              categoryFilters: _selectedCategories.toList(),
                              locationFilters: _selectedLocations.toList(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7a1b0c),
                            minimumSize: Size(double.infinity, 48),  // Lebar penuh dan tinggi tombol
                            padding: EdgeInsets.symmetric(vertical: 14),  // Padding vertikal yang lebih besar
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),  // Sudut tombol yang lebih membulat
                            ),
                          ),
                          child: Text(
                            'Terapkan Filter',  // Teks tombol
                            style: TextStyle(
                              fontSize: 16,  // Ukuran font
                              fontWeight: FontWeight.bold,  // Menambah ketebalan teks
                              color: Colors.white,  // Teks berwarna putih
                            ),
                          ),

                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildCountText() {
    // Asumsi count didapatkan dari jumlah item yang ada di blokList
    final count = Provider.of<StockOpnameInputBOMViewModel>(context).totalAssets;
    return Text(
      '$count Assets', // Menampilkan jumlah item
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }


  void _showScanBarQRCode(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeQrScanScreen(
            noSO: widget.noSO
        ),
      ),
    );
  }

}
