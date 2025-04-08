import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../view_models/stock_opname_input_view_model.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/add_manual_dialog.dart';
import '../views/barcode_qr_scan_screen.dart';
import 'package:searchfield/searchfield.dart';
import 'package:flutter_searchable_dropdown/flutter_searchable_dropdown.dart';  // Import package



class StockOpnameInputScreen extends StatefulWidget {
  final String noSO;
  final String tgl;

  const StockOpnameInputScreen({Key? key, required this.noSO, required this.tgl}) : super(key: key);

  @override
  _StockOpnameInputScreenState createState() => _StockOpnameInputScreenState();
}

class _StockOpnameInputScreenState extends State<StockOpnameInputScreen> {
  final Set<String> _selectedFilters = {}; // Menggunakan Set untuk menyimpan filter yang dipilih

  final TextEditingController _locationController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedLocation;
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<StockOpnameInputViewModel>(context, listen: false);

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
          '${widget.tgl} ( ${widget.noSO} )',
          style: const TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF7a1b0c),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Ganti pemanggilan langsung dengan tombol atau widget interaktif
                ElevatedButton(
                  onPressed: () => _showFilterModal(context), // Memanggil modal saat tombol ditekan
                  child: Text('Company'),
                ),
                SizedBox(width: 16),
                // _buildLocationDropdown(),  // Menggunakan SearchableDropdown
                SizedBox(width: 16),
                _buildCountText(),  // Menampilkan count di sebelah kanan
              ],
            ),
          ),

          Expanded(
            child: Consumer<StockOpnameInputViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.assetList.isEmpty) {
                  return const LoadingSkeleton();
                }

                if (viewModel.errorMessage.isNotEmpty) {
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
                        viewModel.loadMoreAssets(widget.noSO);
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
                        title: Text('Asset Code: ${asset.assetCode}', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Scanned By: ${asset.username}'),
                        leading: const Icon(Icons.inventory, color: Colors.blue),
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
              _showAddManualDialog(context);
            },
          ),
        ],
      ),
    );
  }

  // Daftar pilihan filter
  final List<Map<String, String>> filterOptions = [
    {'value': 'st', 'label': 'Company 1'},
    {'value': 's4s', 'label': 'Company 2'},
    {'value': 'fj', 'label': 'Company 3'},
  ];

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pilih Filter',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  // Membuat daftar pilihan filter menggunakan Checkbox
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: filterOptions.length,
                    itemBuilder: (context, index) {
                      final filter = filterOptions[index];
                      return CheckboxListTile(
                        title: Text(filter['label']!),
                        value: _selectedFilters.contains(filter['value']!),  // Memastikan value checkbox sesuai dengan status filter
                        onChanged: (bool? selected) {
                          setModalState(() {
                            if (selected == true) {
                              _selectedFilters.add(filter['value']!); // Tambahkan filter jika dicentang
                            } else {
                              _selectedFilters.remove(filter['value']!); // Hapus filter jika tidak dicentang
                            }
                          });
                        },
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);  // Menutup modal setelah filter dipilih
                      // Lakukan aksi setelah memilih filter, misalnya fetch data
                    },
                    child: Text('Terapkan Filter'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCountText() {
    // Asumsi count didapatkan dari jumlah item yang ada di blokList
    final count = Provider.of<StockOpnameInputViewModel>(context).totalAssets;

    return Text(
      '$count Label', // Menampilkan jumlah item
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

  void _showAddManualDialog(BuildContext context) {
    if (_selectedLocation == null || _selectedLocation == 'Semua') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fitur Dalam Tahap Pengembangan!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddManualDialog(
          noSO: widget.noSO,
          selectedFilter: 'all',
          idLokasi: _selectedLocation!,
        );
      },
    );
  }
}
