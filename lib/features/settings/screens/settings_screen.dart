import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('프로필'),
            subtitle: Text('사용자 정보 관리'),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text('알림 설정'),
            subtitle: Text('알림 옵션 관리'),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
          const ListTile(
            leading: Icon(Icons.dark_mode),
            title: Text('테마'),
            subtitle: Text('다크 모드 설정'),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('앱 정보'),
            subtitle: Text('버전 1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              // TODO: 로그아웃 기능 구현
            },
          ),
        ],
      ),
    );
  }
}

