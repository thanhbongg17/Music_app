import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:thanh/my_tabs.dart';
import 'app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'my_home_page.dart';
import 'play_music.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://hyrywygninaerwuxkyaq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh5cnl3eWduaW5hZXJ3dXhreWFxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU1OTk0MjQsImV4cCI6MjA2MTE3NTQyNH0.TkHwOX16A1f_aU8BanHrSoU0W9O7uUFx7lMgIywT7dQ', // thay đúng key của bạn
  );
  runApp(const MyApp());
}
final supabase = Supabase.instance.client;
//Đây là widget gốc (root widget)
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    //MaterialApp là widget bao ngoài toàn bộ app
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      //Chủ đề của app, định nghĩa màu sắc, kiểu chữ
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // home: MusicPlayerPage(
      //   title: 'Tên bài hát',
      //   artist: 'Tên ca sĩ',
      //   audioUrl: 'https://link-file-mp3.mp3',
      //   coverUrl: 'https://link-ảnh-cover.jpg',
      // ),
      home: MyHomePage(title: 'Xin chào Thành!'),
      // home: const PlayMusicPage(
      //   title: 'Nụ Cười 18 20',
      //   artist: 'Doãn Hiếu, BMZ',
      //   coverUrl: 'assets/img/logo.jpg',
      //     audioUrl:'',
      // ),
    );
  }
}
