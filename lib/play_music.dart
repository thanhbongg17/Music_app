import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'audio_manager.dart';


Color hexToColor(String hex) {
  hex = hex.replaceAll('#', '').replaceAll('0x', '').trim();
  if (hex.length == 6) hex = 'FF$hex'; // Thêm alpha nếu thiếu
  return Color(int.parse(hex, radix: 16));
}
final player = AudioManager().player; // ✅ Dùng global player


//StatefulWidget phù hợp để quản lý trạng thái (play/pause, vị trí bài hát).(dùng để nối màn hình)
// Thuộc tính required bắt buộc truyền giá trị khi Navigator.push() sang màn hình này.
class PlayMusicPage extends StatefulWidget {
  final String title; //Tên bài hát
  final String artist; //nghệ sĩ
  final String coverUrl; //ảnh bìa
  final String category;
  final List<Map<String, dynamic>> playlist;
  final int index;
  const PlayMusicPage({
    Key? key,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.category,
    required this.playlist,
    required this.index,
  }) : super(key: key);

  //PlayMusicPage là một StatefulWidget.
  // createState() trả về một instance của class _PlayMusicPageState.
  // _PlayMusicPageState chứa toàn bộ logic, UI, và state
  //Cách nó hoạt động
  // Khi bạn mở PlayMusicPage, Flutter gọi createState() để tạo ra một đối tượng State.
  // Sau đó, build() trong _PlayMusicPageState chạy và vẽ UI.
  // Khi bạn bấm play/pause, gọi setState() => Flutter rebuild lại UI trong State.
  @override
  State<PlayMusicPage> createState() => _PlayMusicPageState();
}

//Viết toàn bộ giao diện & điều khiển trạng thái
class _PlayMusicPageState extends State<PlayMusicPage> with SingleTickerProviderStateMixin {
  //Lưu giá trị vị trí thanh slider
  double _currentSliderValue = 0.0;
  //Trạng thái bật/tắt nhạc
  bool _isPlaying = true;
  // Trạng thái nút repeat
  bool _isRepeat = false;
  //trạng thái quay của ảnh khi phát nhạc
  late AnimationController _rotationController;
  //danh sách bài khai báo play_list
  List<Map<String, dynamic>> playlist = [];
  int _currentIndex = 0;

  final supabase = Supabase.instance.client;

  //ảnh quay
  @override
  void initState() {
    //hàm khởi tạo initState của lớp cha State
    super.initState();
    //AnimationController quản lý animation quay.
    _rotationController = AnimationController(
      vsync: this, //để tối ưu hiệu năng, tránh animation chạy ngầm không cần thiết.
      duration: Duration(seconds: 25), // thoi gian quay hết 1 vòng
    )..repeat(); //giúp quay liên tục
    // loadPlaylist(); // Tải playlist từ Supabase

    // Xử lý tự động phát tiếp khi hết bài
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        if(_isRepeat){
          // Nếu repeat thì phát lại bài hiện tại
          player.seek(Duration.zero);
          player.play();
        }
        else{
          //// Nếu không repeat thì chuyển bài tiếp
          AudioManager().playNext();
        }

      }
    });
    final current = AudioManager().currentSong;
    final isSameSong = current != null && current['title'] == widget.title;
    // Gọi AudioManager để phát nhạc
    if (!isSameSong) {
      AudioManager().setPlaylist(widget.playlist, widget.index);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose(); //ngừng quay//ngừng phát nhạc
    super.dispose(); // gọi hàm dispose() từ cha
  }

  @override
  //build _PlayMusicPageState cho màn hình phát nhạc


  Widget build(BuildContext context) {
    final song = AudioManager().currentSong ?? widget.playlist[widget.index];
    final Color colorLight  = hexToColor(song['color_light'] ?? '#F0F0F0');
    final Color colorMedium = hexToColor(song['color'] ?? '#AAAAAA');
    final Color colorDark   = hexToColor(song['color_dark'] ?? '#333333');
    // Scaffold khung cơ bản màn hình
    return Scaffold(
      // AppBar
      appBar: AppBar(
        backgroundColor: colorLight, // Cho gradient chạy xuyên AppBar
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);// trở về màn hình trước đó
          },
          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.white),
        ),
        //column xếp các Widget con theo chiều dọc
        title: Column(
          //children danh sách các widget con
          children: [
            Text(
              "PHÁT TỪ",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            //theo category bài hát từ bảng supabase
            Text(
              widget.category,
              style: TextStyle(fontSize: 14, color: AppColors.white),
            ),
          ],
        ),
        //mặc định ở AppBar title căn lề trái => centerTitle giúp căn giữa
        centerTitle: true,
        //icon nút ba chấm trên AppBar
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.white),
            onPressed: () {},
          ),
        ],
      ),
      //body
      body: Container(
        // Nền gradient
        //decoration là thuộc tính widget của Container: dùng để tạo kiểu, trang trí....
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorLight,
              colorMedium,
              colorDark,
            ],
            stops: [0.25, 0.65, 1.0],
          ),
        ),
        //child: widget con bên trong widget cha, mỗi widget chỉ có 1 child
        //child: dùng với Container,center, padding...
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.spaceAround, // giúp phân bố, tạo bố cục đều đẹp
          children: [
            // Disc Cover
            // Ảnh bìa bài hát
            RotationTransition(
              turns: _rotationController,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image:NetworkImage(AudioManager().currentSong?['cover'] ?? widget.coverUrl),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: AppColors.white, width: 2),
                ),
              ),
            ),

            // Title & Artist
            Column(
              children: [
                Text(
                AudioManager().currentSong?['title'] ?? widget.title, style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AudioManager().currentSong?['artist'] ?? widget.artist,
                  style: TextStyle(color: AppColors.white, fontSize: 14),
                ),
              ],
            ),

            //thanh chạy thời gian
            //Duration: lấy tổng thời lượng của file nhạc
            //Stream thường để cap nhập trạng thái trực tiếp:phát nhạc, gps....
            StreamBuilder<Duration?>(
              stream: player.durationStream,// cung cấp thời lượng tổng của bài nhạc
              //builder  là tham số bắt buộc  của StreamBuilder
              //context: Ngữ cảnh build hiện tại
              //snapshot chứa trạng thái dữ liệu
              builder: (context, snapshot) {
                //snapshot.data là giá trị mới nhất mà StreamBuilder nhận được từ stream
                //nếu snapshot khác null => dùng giá trị đó
                // nếu snapshot = null => dùng duration.zero
                //duration là tổng thời lượng bài hát
                final duration = snapshot.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: player.positionStream, // liên tục phát
                  builder: (context, snapshot) {
                    //position: thời gian hiện tại
                    final position = snapshot.data ?? Duration.zero;
                    return Column(
                      children: [
                        Slider(
                          activeColor: AppColors.white,
                          inactiveColor: AppColors.white.withOpacity(0.4),
                          //inSeconds biến Dration => int (số giây)
                          //ép kiểu do thanh shilder chỉ chấp nhận kiểu Double
                          //clamp đảm bảo trong khoảng thời gian chạy(ép giá trị nằm trong min, max)
                          value: position.inSeconds.toDouble().clamp(
                            0.0,
                            duration.inSeconds.toDouble(),
                          ),
                          min: 0,
                          max:
                              duration.inSeconds.toDouble() > 0
                                  ? duration.inSeconds.toDouble()
                                  : 1,
                          //onChanged là hàm Callback: cập nhập trạng thái phát nhạc đến đâu rồi
                          onChanged: (value) {
                            //seek(): tua tới thời điểm mong muốn
                            player.seek(Duration(seconds: value.toInt()));
                          },
                        ),
                        //dùng padding bọc để tạo khoảng cách
                        Padding(
                          //cách đều trái phải 30
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                //_formatTime: trả về chuổi dạng mm:ss
                                _formatTime(
                                  position,
                                ), //laasys tời gian hiện tại
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatTime(
                                  duration - position,
                                ), //lấy tổng thời gian
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.shuffle, color: Colors.purpleAccent),
                ),
                IconButton(
                  onPressed: () async {
                    await AudioManager().playPrevious();
                    setState(() {

                    });
                    },
                  icon: Icon(
                    Icons.skip_previous,
                    color: AppColors.white,
                    size: 40,
                  ),
                ),
                //Nút Pause, play
                //GestureDetector: Widget bắt sự kiện onTap
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isPlaying = !_isPlaying;
                      if (_isPlaying) {
                        _rotationController.repeat();
                        player.play(); //phát nhạc
                      } else {
                        _rotationController.stop();
                        player.pause();
                      }
                    });
                  },
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: AppColors.white,
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.black,
                      size: 40,
                    ),
                  ),
                ),
                //nút next
                IconButton(
                  onPressed: () async {
                    await AudioManager().playNext();
                    setState(() {
                    });
                    },
                  icon: Icon(
                      Icons.skip_next,
                      color: AppColors.white,
                      size: 40
                  ),
                ),
                // nút phát lại
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isRepeat = !_isRepeat; // bật/tắt repeat
                    });
                  },
                  icon: Icon(
                    Icons.repeat,
                    color: _isRepeat ? Colors.purple : AppColors.white, // đổi màu khi bật
                  ),
                )
              ],
            ),

            // Extra buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.share, color: AppColors.white),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.favorite, color: AppColors.menu2Color),
                ),
                Text(
                  "320 Kbps",
                  style: TextStyle(color: AppColors.white, fontSize: 12),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.file_download_outlined,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),

            // Banner (Optional)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(10),
            ),
          ],
        ),
      ),
    );
  }
}

// hàm hiển thị thời gian chạy
String _formatTime(Duration duration) {
  String twoDigits(int n) =>
      n.toString().padLeft(2, '0'); //chuyển thành dạng ss:mm
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return "$minutes:$seconds";
}
