import 'package:flutter/material.dart';

import 'user_storage.dart';

/// Вторая страница: показывает данные, прочитанные из SharedPreferences.
class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  // Читаем сохранённые данные один раз при открытии страницы
  late final Future<UserData?> _future = UserStorage.load();

  Future<void> _deleteData() async {
    await UserStorage.clear();
    if (!mounted) return;
    Navigator.of(context).pop(true); // true = данные удалены
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontSize: 13)),
      subtitle: Text(
        value.isEmpty ? '-' : value,
        style: const TextStyle(fontSize: 17, color: Colors.black87),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Info',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<UserData?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('No saved data'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 36, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      _infoTile(Icons.person, 'Full Name', user.name),
                      _infoTile(Icons.phone, 'Phone Number', user.phone),
                      _infoTile(Icons.mail, 'Email Address', user.email),
                      _infoTile(Icons.notes, 'Life Story', user.story),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    onPressed: _deleteData,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete saved data'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
