import 'package:flutter/material.dart';
import '../view_models/user_profile_view_model.dart';
import '../widgets/user_profile_dialog.dart'; // Impor UserProfileDialog
// import 'mapping_lokasi_screen.dart'; // Impor MappingLokasiScreen

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Tampilkan dialog konfirmasi sebelum menutup layar
        bool? confirmExit = await _showExitDialog(context);
        return confirmExit ?? false; // Mengembalikan true jika keluar, false jika tidak
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Home',
            style: TextStyle(
              color: Colors.white, // Menetapkan warna teks menjadi putih
            ),
          ),
          backgroundColor: const Color(0xFF7a1b0c),
          elevation: 0,
          automaticallyImplyLeading: false, // Menonaktifkan tombol back otomatis
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              color: Colors.white,
              onPressed: () {
                // Tindakan logout atau navigasi ke halaman login
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header yang elegan
                Text(
                  'MCS Mobile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7a1b0c),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'What would you like to do today?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // Card untuk menu pilihan
                _buildMenuCard(
                  context,
                  title: 'Stock Opname',
                  icon: Icons.checklist_rtl_rounded,
                  onTap: () {
                    Navigator.pushNamed(context, '/dashboard');
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuCard(
                  context,
                  title: 'Mapping Lokasi',
                  icon: Icons.location_on_outlined,
                  onTap: () {
                    // Navigasi ke MappingLokasiScreen
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (context) => MappingLokasiScreen()),
                    // );
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuCard(
                  context,
                  title: 'Pengaturan Akun',
                  icon: Icons.account_circle,
                  onTap: () {
                    // _showChangePasswordDialog(context);
                  },
                ),
                const SizedBox(height: 24),

                // Add more options as needed
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Example: Navigate to another screen
                      Navigator.pushNamed(context, '/example');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7a1b0c),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: const Text(
                      'Explore More',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget untuk Card Menu
  Widget _buildMenuCard(BuildContext context,
      {required String title, required IconData icon, required Function onTap}) {
    return Card(
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => onTap(),
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Color(0xFF7a1b0c),
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFF7a1b0c),
        ),
      ),
    );
  }

  // Fungsi untuk menampilkan dialog ganti password
  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return UserProfileDialog();
      },
    );
  }

  // Fungsi untuk menampilkan dialog konfirmasi keluar
  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Tidak keluar
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Ya, keluar
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );
  }
}
