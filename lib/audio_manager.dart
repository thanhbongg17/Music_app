// giúp điều khiển nhạc ở mọi nơi
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';


class AudioManager {
  // 1111111111111111111. Chỉ tạo một đối tượng duy nhất cho toàn App
  // đây là một Constructor nội bộ ( factory constructor)
  // factory constructor là tạo một đối tượng đã có thay vì tạo mới
  //Singleton đảm bảo trạng thái phát nhạc toàn App
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();


  final AudioPlayer player = AudioPlayer();//22222222222222.đối tượng từ just_audio: điều khiển nhạc từ package just_audio
  ValueNotifier<Map<String, dynamic>?> currentSongNotifier = ValueNotifier(null);//theo dõi thay đổi giữa các màn hình
  //ValueNotifier là object có thể thông báo khi giá trị thay đổi
  // có thể lắng nghe bằng ValueListenableBuilder

  List<Map<String, dynamic>> _playlist = [];// lưu danh sách các bài hát
  // int _currentIndex = 0;
  List<Map<String, dynamic>> get playlist => _playlist;

  //333333333333333. Gán Play_List và phát nhạc playlist
  Future<void> setPlaylist(List<Map<String, dynamic>> playlist, int index) async {
    _playlist = playlist;// gán playlist vào _playlist (lưu danh sách để dùng sau ( chuyển bài tiếp hoặc lùi)
    // _currentIndex = index;
    // chuyển tất cả link nhạc thành AudioSource.uri
    final sources = playlist.map((song) {
      final url = song['audio'];
      if (url == null || url is! String || url.isEmpty) {
        throw Exception('Bài hát thiếu URL hợp lệ: $song');
      }
      return AudioSource.uri(Uri.parse(url));
    }).toList();
    final playlistSource = ConcatenatingAudioSource(children: sources);// gộp thành danh sách duy nhất

    await player.setAudioSource(playlistSource, initialIndex: index);// gán danh sách phát nhạc cho player, bắt đầu từ vị trí index
    currentSongNotifier.value = playlist[index];// nạp vào player
    await player.play();// cập nhập để các widget biết (dùng ValueListenableBuilder để tự động cập nhập bài hát)
  }

  // 44444444444444Phát bài tiếp theo
  Future<void> playNext() async {
    if (_playlist.isEmpty) return;

    // _currentIndex = (_currentIndex + 1) % _playlist.length;
    // await player.seek(Duration.zero, index: _currentIndex);
    // await _playCurrent();
    if (player.hasNext) {
      await player.seekToNext();
    }
    else {
      await player.seek(Duration.zero, index: 0); // Quay lại bài đầu
    }
    await player.play();
    currentSongNotifier.value = currentSong;
  }

  // 55555555555555555555555555Phát bài trước
  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;
    if (player.hasPrevious) {
      await player.seekToPrevious();
      await player.play();
    }
    else{await player.seek(Duration.zero, index:  playlist.length -1);}//phát bài cuối
    currentSongNotifier.value = currentSong;
  }

  //666666666666 Dừng/phát
  void togglePlayPause() {
    if (player.playing) {
      player.pause();
    } else {
      player.play();
    }
  }

  // Getter để lấy thông tin bài hiện tại
  Map<String, dynamic>? get currentSong {
    final index = player.currentIndex; // lấy chỉ số của bài đang phát dạng int
    if (index != null && index >= 0 && index < _playlist.length) {
      return _playlist[index];
    }
    return null;
  }

}

