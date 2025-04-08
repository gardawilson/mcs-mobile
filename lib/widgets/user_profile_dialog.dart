import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/user_profile_view_model.dart';
import '../models/user_profile_model.dart';

class UserProfileDialog extends StatefulWidget {
  UserProfileDialog({Key? key}) : super(key: key);

  @override
  _UserProfileDialogState createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<UserProfileDialog> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _oldPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  void _validateForm() {
    setState(() {
      _oldPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validasi jika field kosong
    if (oldPassword.isEmpty) {
      _oldPasswordError = 'Password lama harus diisi!';
    }
    if (newPassword.isEmpty) {
      _newPasswordError = 'Password baru harus diisi!';
    }
    if (confirmPassword.isEmpty) {
      _confirmPasswordError = 'Konfirmasi password baru harus diisi!';
    }
    if (newPassword != confirmPassword) {
      _confirmPasswordError = 'Password baru dan konfirmasi password tidak cocok!';
    }

    if (_oldPasswordError == null && _newPasswordError == null && _confirmPasswordError == null) {
      // Jika tidak ada error, lakukan proses change password
      _changePassword(oldPassword, newPassword, confirmPassword);
    }
  }

  void _changePassword(String oldPassword, String newPassword, String confirmPassword) async {
    final userProfile = UserProfileModel(
      oldPassword: oldPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    // Panggil ViewModel untuk mengganti password
    await context.read<UserProfileViewModel>().changePassword(
      userProfile: userProfile,
    );

    final viewModel = context.read<UserProfileViewModel>();
    if (viewModel.errorMessage.isNotEmpty) {
      setState(() {
        _oldPasswordError = viewModel.errorMessage;
      });
    } else if (viewModel.successMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.successMessage)),
      );
      Navigator.of(context).pop(); // Tutup dialog setelah sukses
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(20.0), // Memberikan jarak lebih besar ke seluruh dialog
      child: Container(
        width: 400, // Menetapkan lebar dialog
        padding: EdgeInsets.all(24.0), // Menambahkan padding untuk memberi ruang lebih
        child: Column(
          mainAxisSize: MainAxisSize.min, // Membuat dialog mengikuti ukuran kontennya
          children: [
            const Text(
              'Ganti Password',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password Lama',
                prefixIcon: const Icon(Icons.lock),
                errorText: _oldPasswordError, // Menampilkan pesan error di bawah field
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _oldPasswordError != null ? Colors.red : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password Baru',
                prefixIcon: const Icon(Icons.lock_outline),
                errorText: _newPasswordError, // Menampilkan pesan error di bawah field
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _newPasswordError != null ? Colors.red : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Password Baru',
                prefixIcon: const Icon(Icons.lock_outline),
                errorText: _confirmPasswordError, // Menampilkan pesan error di bawah field
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _confirmPasswordError != null ? Colors.red : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: _validateForm,
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
