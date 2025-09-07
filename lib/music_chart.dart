import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'audio_manager.dart';
import 'app_colors.dart';
import 'mini_player.dart';

Color hexToColor(String hex) {
  hex = hex.replaceAll('#', '').replaceAll('0x', '').trim();
  if (hex.length == 6) hex = 'FF$hex'; // Thêm alpha nếu thiếu
  return Color(int.parse(hex, radix: 16));
}

final player = AudioManager().player;

class Music_Chart extends StatefulWidget {
  List<Map<String, dynamic>> playlist = [];
  final int index;
  Music_Chart({Key? key, required this.playlist, required this.index})
    : super(key: key);

  @override
  State<Music_Chart> createState() => _MusicChart();
}

class _MusicChart extends State<Music_Chart> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _topSongs = [];
  @override
  void initState() {
    super.initState();
    fetchTopSongs().then((songs) => setState(() => _topSongs = songs));
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTopSongs() async {
    final response = await Supabase.instance.client
        .from('songs')
        .select()
        .order('rank', ascending: true)
        .limit(100);
    return List<Map<String, dynamic>>.from(response);
  }

  final List<Widget> _pages = [
    // Toàn bộ `Column` hiện tại bạn đang dùng => đặt thành 1 widget riêng
    // Hoặc tạm thời:
    Placeholder(), // Trang Thư viện
    Center(child: Text('khám phá')),
    Music_Chart(playlist: [], index: 0),
    Center(child: Text('Phòng nhạc')),
    Center(child: Text('Cá nhân')),
    Center(child: Text('Cá nhân')),
  ];
  Widget buildNavItem(IconData icon, String label, int index) {
    //icon: là biểu tượng của nút
    //label là tên bên dưới icon
    //index là số thứ tự của nút
    //Nếu index bằng _selectedIndex thì tab này đang được chọn
    final isSelected = _selectedIndex == index;
    //tạo hiệu ứng khi nhấn vào
    return InkWell(
      onTap: () {
        // khi nhấn vào nút, cập nhật _selectedIndex để hiển thị nút được chọn.
        setState(() {
          //gọi setState để cập nhật _selectedIndex => widget build lại.
          // 👉 Các tab khác vẫn hoạt động bình thường
          setState(() {
            _selectedIndex = index;
          });
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //icon
          Icon(icon, color: isSelected ? AppColors.menu3Color : Colors.white),
          SizedBox(height: 4),
          // text bên dưới
          Text(
            label,
            style: TextStyle(
              fontSize: 11.9,
              color: isSelected ? AppColors.menu3Color : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // hàm hiển thị trend_points
  LineChartData generateChart(List<int> points) {
    if (points.isEmpty) return LineChartData();

    final List<double> yVals = points.map((e) => e.toDouble()).toList();
    final double minY = yVals.reduce((a, b) => a < b ? a : b);
    final double maxY = yVals.reduce((a, b) => a > b ? a : b);

    // Tăng padding trên nhiều hơn để số trên cùng không bị tràn
    final double yPadding = (maxY - minY) == 0 ? 1.0 : (maxY - minY) * 0.2;
    final double chartMinY = minY - yPadding;
    final double chartMaxY = maxY + yPadding; // buffer trên
    final double yInterval = (chartMaxY - chartMinY) / 4;

    final int count = points.length;
    final int xStep = count <= 5 ? 1 : ((count / 5).ceil());
    final double xInterval = xStep.toDouble();

    return LineChartData(
      minX: 0,
      maxX: (count - 1).toDouble(),
      minY: chartMinY,
      maxY: chartMaxY,
      clipData: FlClipData.all(), // tránh label bị cắt
      titlesData: FlTitlesData(
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: yInterval,
            reservedSize: 30, // chừa chỗ rộng hơn cho số
            getTitlesWidget: (double value, TitleMeta meta) {
              return Padding(
                padding: const EdgeInsets.only(top: 10), // đẩy số xuống chút
                child: Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: xInterval,
            reservedSize: 28,
            getTitlesWidget: (double value, TitleMeta meta) {
              if (value % 1 != 0) return const SizedBox.shrink();
              final int i = value.toInt();
              if (i < 0 || i >= count) return const SizedBox.shrink();
              if (xStep > 1 && (i % xStep != 0)) return const SizedBox.shrink();
              return Text(
                i.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine:
            (v) => FlLine(color: Colors.white.withOpacity(0.06)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(
            count,
            (i) => FlSpot(i.toDouble(), points[i].toDouble()),
          ),
          isCurved: true,
          color: Colors.cyanAccent,
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: Colors.cyanAccent,
                strokeWidth: 0,
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
        ),
      ],
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.black87,
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots
                .map(
                  (s) => LineTooltipItem(
                    s.y.toStringAsFixed(1),
                    const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                )
                .toList();
          },
        ),
      ),
    );
  }

  //phát bài hát khi nhấn
  void playSong(Map<String, dynamic> song) async {
    final index = _topSongs.indexOf(song);
    if (index != -1) {
      AudioManager().setPlaylist(_topSongs, index);
    }
  }
  // hiển thị UI xếp hạng

  @override
  Widget build(BuildContext) {
    final song =
        widget.playlist.isNotEmpty
            ? widget.playlist.firstWhere(
              (item) => item['id'] == 1,
              orElse: () => widget.playlist.first, // fallback sang bài đầu tiên
            )
            : {
              'color_light': '#9B76AA',
              'color': '#52527A',
              'color_dark': '#362350',
            };
    final Color colorLight = hexToColor(song['color_light'] ?? '#9B76AA');
    final Color colorMedium = hexToColor(song['color'] ?? '#362350');
    final Color colorDark = hexToColor(song['color_dark'] ?? '#52527A');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        // Cho gradient chạy xuyên AppBar
        backgroundColor: colorDark,
        //column xếp các Widget con theo chiều dọc
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: AppColors.white),
        ),

        title: Text(
          "#MUSIC.CHART",
          style: TextStyle(
            fontSize: 24,
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorDark, colorMedium, colorLight],
            stops: [0.25, 0.90, 1.0],
          ),
        ),
        child: Column(
          children: [
            if (_topSongs.isNotEmpty && _topSongs[0]['trend_points'] != null)
              SizedBox(
                width: 320,
                height: 250,
                child: LineChart(
                  generateChart(
                    List<int>.from(_topSongs[0]['trend_points'] ?? []),
                  ),
                ),
              ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  border: Border(top: BorderSide(color: colorMedium, width: 1)),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: ListView.builder(
                  itemCount: _topSongs.length,
                  itemBuilder: (context, index) {
                    final song = _topSongs[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          song["cover"],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        song['title'],
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        song['artist'],
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: Text(
                        '#${song['rank']}',
                        style: TextStyle(color: Colors.yellowAccent),
                      ),
                      onTap: () => playSong(song), // phát nhạc
                    );
                  },
                ),
              ),
            ),
          ],
          // hiển thị UI xếp hạng
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ Gọi widget riêng
          //miniPage
          ValueListenableBuilder<Map<String, dynamic>?>(
            valueListenable: AudioManager().currentSongNotifier,
            builder: (context, currentSong, _) {
              return currentSong == null
                  ? const SizedBox.shrink()
                  : MiniPlayer(playlist: AudioManager().playlist);
            },
          ),
          //boton
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black87,
              boxShadow: [
                BoxShadow(
                  color: colorDark,
                  blurRadius: 5,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                buildNavItem(Icons.library_music, 'Thư viện', 0),
                buildNavItem(Icons.explore, 'Khám phá', 1),
                buildNavItem(Icons.show_chart, '#Musicchart', 2),
                buildNavItem(Icons.radio, 'Phòng nhạc', 3),
                buildNavItem(Icons.person, 'Cá nhân', 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
