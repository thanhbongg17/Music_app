import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:thanh/music_chart.dart';
import 'app_colors.dart';
import 'play_music.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'audio_manager.dart';
import 'mini_player.dart';
import 'search_page.dart';

// Hàm chuyển HEX sang Color (đặt ở đầu file)
Color hexToColor(String hex) {
  hex = hex.replaceAll('#', '').replaceAll('0x', '').trim();
  if (hex.length == 6) hex = 'FF$hex'; // Thêm alpha nếu thiếu
  return Color(int.parse(hex, radix: 16));
}

//Đây là widget gốc (root widget)
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    //MaterialApp là widget bao ngoài toàn bộ app
    return MaterialApp(
      title: 'My Music_App',
      debugShowCheckedModeBanner: false,
      //Chủ đề của app, định nghĩa màu sắc, kiểu chữ
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
      ),
      home: const MyHomePage(title: 'Thành'),
    );
  }
}

// Màn hình chính của ứng dụng
//StatefulWidget có trạng thái
// là cái gốc của app => từ đây mở rộng ra
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState(); //trả về 1 lớp state để gắn với widget _MyHomePageState()
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _SliverHeaderDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  bool shouldRebuild(covariant _SliverHeaderDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight;
  }
}

//_MyHomepageState Phần logic xử lý trạng thái
//with SingleTickerProviderStateMixin//thành phần điều khiển thời gian cho các animation
//Bắt buộc nếu sử dụng AnimationController,TabController, vsycn
class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex =
      0; //cách Flutter biết người dùng đang bấm vào tab nào, từ đó hiển thị đúng trang tương ứng.
  List<dynamic> _songs = []; // danh sách chứa tất cả bài hát
  final _player = AudioManager().player; // ✅
  bool _isPlaying = false;
  int _currentIndex = 0; // bài đầu tiên trong danh sách
  List<Map<String, dynamic>> playlist = []; // danh sách bài hát
  List<Map<String, dynamic>> selectedSongs = [];
  final manager = AudioManager();
  late ScrollController _scrollController;
  late TabController _tabController;

  String? selectedCategory;
  Future<List<Map<String, dynamic>>>? _songsFuture;
  Map<String, List<Map<String, dynamic>>> _groupedSongs = {};
  List<String> _categories = [];

  // void _onItemTapped(int index) {
  //   setState(() {
  //     _selectedIndex = index;
  //   });
  // }
  Map<String, List<Map<String, dynamic>>> groupSongsByCategory(
    List<Map<String, dynamic>> songs,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var song in songs) {
      final category = song['category']?.toString().trim();
      if (category != null && category.isNotEmpty) {
        grouped[category] = grouped[category] ?? [];
        grouped[category]!.add(song);
      }
    }

    return grouped;
  }

  //Chuyển đổi giữa trạng thái “đang phát” và “tạm dừng”
  void togglePlayPause() {
    if (_player.playing) {
      _player.pause(); // Nếu đang phát thì tạm dừng
    } else {
      _player.play(); // Nếu đang tạm dừng thì phát tiếp
    }
  }

  //Chuyển sang phát bài hát kế tiếp trong danh sách nhạc
  // là 1 hàm không trả về giá trị, dùng để xử lý logic, chuyển bài
  void playNext() {
    // (_currentIndex + 1) % playlist.length:
    // Nếu đang ở cuối (ví dụ: 4 + 1 = 5, 5 % 5 = 0) → quay lại bài đầu tiên.
    // Nếu đang ở giữa (ví dụ: 2 + 1 = 3, 3 % 5 = 3) → phát bài kế tiếp như bình thường.
    _currentIndex =
        (_currentIndex + 1) %
        playlist.length; // phát hết bài trong danh sách quay lại bài đầu tiên
    _player.seek(
      Duration.zero,
      index: _currentIndex + 1,
    ); //chuyển đến bài hát mới ở giây thứ 0
    //seek() là để tua
  }

  //Navigation
  //để tạo giao diện menu
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
  // VoidCallback onTap, tạo nút (hành động bấm trong navigation)
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
          if (index == 2) {
            // 👉 Nếu là nút #Musicchart thì mở trang riêng
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        Music_Chart(playlist: [], index: _selectedIndex),
              ),
            );
          } else {
            // 👉 Các tab khác vẫn hoạt động bình thường
            setState(() {
              _selectedIndex = index;
            });
          }
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //icon
          Icon(icon, color: isSelected ? AppColors.menu3Color : Colors.black),
          SizedBox(height: 4),
          // text bên dưới
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppColors.menu3Color : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  //lấy danh sách theo JSON
  List popularBooks = [];
  List books = [];
  ReadData() async {
    //DefaultAssetBundle.of(context).loadString(): load file JSON từ assets
    //Trả về Future<Sting>, dùng then để nhận dữ liệu
    String popularJson = await DefaultAssetBundle.of(
      context,
    ).loadString("json/popularBooks.json");
    String booksJson = await DefaultAssetBundle.of(
      context,
    ).loadString("json/books.json");
    //thông báo dữ liệu thay đổi
    setState(() {
      popularBooks = json.decode(popularJson);
      books = json.decode(booksJson);
    });
  }

  //load dữ liệu và khởi tạo các controller khi widget được tạo ra
  @override
  // khởi tạo trạng thái và logic cần thiết  trước khi widget được hiển thị lần đầu tiên
  // Đây là nơi lý tưởng để:
  // ✅ Khởi tạo controller,
  // ✅ Gọi hàm tải dữ liệu,
  // ✅ Lắng nghe stream,
  // ✅ Setup logic ban đầu.
  Future<void> loadAllSongs() async {
    final allSongsRaw = await Supabase.instance.client.from('songs').select();
    final allSongs = List<Map<String, dynamic>>.from(allSongsRaw);

    setState(() {
      chillSongs =
          allSongs
              .where(
                (s) =>
                    (s['category']?.toString().toLowerCase().trim() ?? '') ==
                    'nhạc chill',
              )
              .toList();
      lightSongs =
          allSongs
              .where(
                (s) =>
                    (s['category']?.toString().toLowerCase().trim() ?? '') ==
                    'nhạc nhẹ',
              )
              .toList();
      hotSongs =
          allSongs
              .where(
                (s) =>
                    (s['category']?.toString().toLowerCase().trim() ?? '') ==
                    'nhạc hot',
              )
              .toList();
      loveSongs =
          allSongs
              .where(
                (s) =>
                    (s['category']?.toString().toLowerCase().trim() ?? '') ==
                    'tình yêu',
              )
              .toList();
      studentSongs =
          allSongs
              .where(
                (s) =>
                    (s['category']?.toString().toLowerCase().trim() ?? '') ==
                    'học trò',
              )
              .toList();
      lovelifeSongs =
          allSongs
              .where(
                (s) =>
                    (s['category']?.toString().toLowerCase().trim() ?? '') ==
                    'yêu đời',
              )
              .toList();
    });
  }

  void initState() {
    super.initState();
    selectedCategory = 'Nhạc Nhẹ'; // mặc đinh mở app sẽ hiện nhạc Chill
    _songsFuture = Supabase.instance.client
        .from('songs')
        .select()
        .eq('category', selectedCategory!); // ✅ gán future hiển thị ban đầu
    loadAllSongs();
    // Lắng nghe xem đang phát hay không
    _player.playingStream.listen((isPlaying) {
      setState(() {
        _isPlaying = isPlaying;
      });
    });

    // Lắng nghe bài hát hiện tại của bài hát
    _player.currentIndexStream.listen((index) {
      if (index != null) {
        setState(() {
          _currentIndex = index;
        });
      }
    });

    //hàm tải dữ liệu
    _tabController = TabController(length: 6, vsync: this);
    _scrollController = ScrollController();
    ReadData(); //Đọc dữ liệu cấu hình/người dùng
    loadSongs(); //	Tải danh sách bài hát cho từng loại
    loadChillSongs(); // ✅ GỌI TẢI DỮ LIỆU CHILL
    loadLightSongs(); // ✅ GỌI TẢI DỮ LIỆU NHẸ
    loadHotSongs(); // ✅ GỌI TẢI DỮ LIỆU HOT
    loadLoveSongs();
    loadStudentSongs();
    loadLoveLifeSongs();
  }

  //hàm dispose() tránh chạy ngầm
  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // List theo supabase
  List chillSongs = [];
  List lightSongs = [];
  List hotSongs = [];
  List loveSongs = [];
  List studentSongs = [];
  List lovelifeSongs = [];
  //loadSongs() để tải dữ liệu ở songs từ Supabase
  //response: kết quả trả về
  String normalizeCategory(String? raw) {
    if (raw == null) return '';
    return raw
        .trim()
        .toLowerCase()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  Future<void> loadSongs() async {
    List<Map<String, dynamic>> uniqueCategories = [];
    Set<String> seenCategories = {};

    for (var song in _songs) {
      if (!seenCategories.contains(song['category'])) {
        seenCategories.add(song['category']);
        uniqueCategories.add(song);
      }
    }
    try {
      final response =
          await Supabase.instance.client
              .from('songs')
              .select(); // Không cần .execute()

      if (response != null) {
        final fetchedSongs = List<Map<String, dynamic>>.from(response);
        final grouped = groupSongsByCategory(fetchedSongs);
        setState(() {
          _songs = fetchedSongs;
          _groupedSongs = grouped;
          _categories = grouped.keys.toList();
        });
      }
    } catch (e) {
      print('Lỗi khi load bài hát: $e');
    }
  }

  //tạo hàm load từ Supabase
  // theo nhạc chill ( gọi bằng categoryid)
  Future<void> loadChillSongs() async {
    final response = await Supabase.instance.client
        .from('songs')
        .select()
        .eq('category', 'Nhạc Chill');
    if (response != null) {
      setState(() {
        chillSongs = response;
      });
    }
  }

  //theo nhạc nhẹ
  Future<void> loadLightSongs() async {
    final response = await Supabase.instance.client
        .from('songs')
        .select()
        .eq('category', 'Nhạc Nhẹ');
    if (response != null) {
      setState(() {
        lightSongs = response;
      });
    }
  }

  // theo nhạc Hot
  Future<void> loadHotSongs() async {
    final response = await Supabase.instance.client
        .from('songs')
        .select()
        .eq('category', 'Nhạc Hot');
    if (response != null) {
      setState(() {
        hotSongs = response;
      });
    }
  }

  //theo Tình Yêu
  Future<void> loadLoveSongs() async {
    final response = await Supabase.instance.client
        .from('songs')
        .select()
        .eq('category', 'Tình Yêu');
    if (response != null) {
      setState(() {
        loveSongs = response;
      });
    }
  }

  //theo Học Trò
  Future<void> loadStudentSongs() async {
    final response = await Supabase.instance.client
        .from('songs')
        .select()
        .eq('category', 'Học Trò');
    if (response != null) {
      setState(() {
        studentSongs = response;
      });
    }
  }

  //theo yêu đời
  Future<void> loadLoveLifeSongs() async {
    final response = await Supabase.instance.client
        .from('songs')
        .select()
        .eq('category', 'Học Trò');
    if (response != null) {
      setState(() {
        studentSongs = response;
      });
    }
  }

  // chỉ nên để những gì liên quan đến UI: widget, điều kiện hiển thị, các giá trị đã chuẩn bị từ trước
  @override
  //context chứa thông tin vị trí widget trong cây UI
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      //SafeArea → đảm bảo UI không tràn vào tai thỏ/notch
      child: SafeArea(
        //Scaffold → khung chuẩn Flutter: chứa body + bottomNavigationBar.
        child: Scaffold(
          body: Stack(
            children: [
              Column(
                children: [
                  //tên + logo + search + notifications
                  Container(
                    margin: const EdgeInsets.only(left: 3, right: 3),
                    //header
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(left: 20),
                              child: Row(
                                children: [
                                  //logo
                                  Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.2),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        "assets/img/logo.jpg",
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 0),
                                  //tên App
                                  TextButton(
                                    onPressed: () {},
                                    child: Text(
                                      "Thành.Music",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.search),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SearchPage(),
                                  ),
                                );
                                //xử lý nút search
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.notifications),
                              onPressed: () {
                                // xử lý nút thông báo
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  //VIEW
                  Expanded(
                    child: NestedScrollView(
                      controller: _scrollController,
                      headerSliverBuilder: (
                        BuildContext context,
                        bool isScroll,
                      ) {
                        return [
                          SliverAppBar(
                            pinned: true,
                            backgroundColor: Colors.white,
                            bottom: PreferredSize(
                              preferredSize: Size.fromHeight(
                                165,
                              ), // Chiều cao lớn hơn để chứa ảnh
                              child: FutureBuilder(
                                future: Supabase.instance.client
                                    .from('songs')
                                    .select()
                                    .limit(40), // giới hạn theo số bài
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData)
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  final data = snapshot.data as List;
                                  final categories =
                                      <String, Map<String, dynamic>>{};
                                  for (var song in data) {
                                    final cat =
                                        (song['category'] ?? '')
                                            .toString()
                                            .toLowerCase()
                                            .trim();
                                    if (!categories.containsKey(cat)) {
                                      categories[cat] =
                                          song; // chỉ lấy bài đầu tiên của mỗi loại
                                    }
                                  }
                                  final uniqueSongs =
                                      categories.values.toList();

                                  final normalized = {
                                    'nhạc chill': 'Nhạc Chill',
                                    'nhạc nhẹ': 'Nhạc Nhẹ',
                                    'nhạc hot': 'Nhạc Hot',
                                    'tình yêu': 'Tình Yêu',
                                    'học trò': 'Học Trò',
                                    'yêu đời': 'Yêu Đời',
                                  };
                                  final categoryMap =
                                      <String, Map<String, dynamic>>{};
                                  for (var song in data) {
                                    final rawCat =
                                        (song['category'] ?? '')
                                            .toString()
                                            .toLowerCase()
                                            .trim();
                                    if (normalized.containsKey(rawCat) &&
                                        !categoryMap.containsKey(rawCat)) {
                                      categoryMap[rawCat] = song;
                                    }
                                  }
                                  //bọc 3 phần
                                  return SizedBox(
                                    height:
                                        220, // Tăng một chút nếu muốn ảnh rõ hơn
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: uniqueSongs.length,
                                      itemBuilder: (context, index) {
                                        final song = uniqueSongs[index];
                                        final rawCat =
                                            (song['category'] ?? '')
                                                .toString()
                                                .toLowerCase()
                                                .trim();
                                        final displayCat =
                                            normalized[rawCat] ?? '';
                                        final String hexColor =
                                            song['color'] ?? '#D3D3D3';
                                        final Color colorLight = hexToColor(
                                          song['color_light'] ?? '#F0F0F0',
                                        );
                                        final Color colorMedium = hexToColor(
                                          song['color'] ?? '#AAAAAA',
                                        );
                                        final Color colorDark = hexToColor(
                                          song['color_dark'] ?? '#333333',
                                        );

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedCategory = displayCat;
                                              _songsFuture = Supabase
                                                  .instance
                                                  .client
                                                  .from('songs')
                                                  .select()
                                                  .eq('category', displayCat)
                                                  .then(
                                                    (value) => List<
                                                      Map<String, dynamic>
                                                    >.from(value),
                                                  ); // chỉ khi chắc chắn trả về Future<List>
                                            });
                                          },
                                          child: Container(
                                            width: 150,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 10,
                                            ),
                                            padding: const EdgeInsets.all(8),
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.black12,
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(
                                                          0.2,
                                                        ), // nền cố định
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    "CÓ THỂ BẠN THÍCH",
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    song['cover'],
                                                    width: 155,
                                                    height: 134,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  displayCat,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _SliverHeaderDelegate(
                              minHeight: 48,
                              maxHeight: 48,
                              child: Container(
                                color: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Gợi ý bài hát',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            // TODO: Xử lý phát tất cả
                                          },
                                          icon: Icon(
                                            Icons.play_arrow,
                                            color: Colors.black,
                                            size: 22,
                                          ),
                                          // theo thể loại
                                          label: Text(
                                            selectedCategory ?? 'Thể loại',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            shape: StadiumBorder(),
                                            side: BorderSide(
                                              color: Colors.black12,
                                            ),
                                            backgroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 0,
                                            ),
                                            minimumSize: Size(0, 36), // gọn hơn
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {
                                            // TODO: Reload danh sách bài hát
                                          },
                                          icon: Icon(Icons.refresh, size: 20),
                                          color: Colors.black,
                                          splashRadius: 20,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ];
                      },
                      body: ListView(
                        children: [
                          if (selectedCategory == null)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text("Hãy chọn một thể loại ở phía trên."),
                            )
                          else
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: _songsFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return SizedBox.shrink(); // Không hiện gì cả khi loading
                                }

                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Lỗi khi tải dữ liệu'),
                                  );
                                }

                                final data = snapshot.data ?? [];
                                if (data.isEmpty) {
                                  return Center(
                                    child: Text(
                                      "Không có bài hát nào trong thể loại này.",
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: data.length,
                                  itemBuilder:
                                      (_, i) => buildSongItem(data[i], data, i),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          //footer
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
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
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
        ),
      ),
    );
  }

  Widget buildSongItem(
    Map song,
    List<Map<String, dynamic>> playlist,
    int index,
  ) {
    return InkWell(
      onTap: () async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => PlayMusicPage(
                  title: song["title"],
                  artist: song["artist"],
                  coverUrl: song["cover"],
                  category: song["category"],
                  playlist: playlist,
                  index: index,
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 2,
              offset: Offset(0, 0),
              color: Colors.white.withOpacity(0.3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(song["cover"]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song["title"],
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: "Avenir",
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  song["artist"],
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: "Avenir",
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: 50,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: AppColors.menu3Color,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "love",
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: "Avenir",
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Hiện popup menu chẳng hạn
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMiniPlayer() {
    if (playlist.isEmpty) return const SizedBox.shrink();

    final song = playlist[_currentIndex]; // Lấy bài hát đang phát

    return GestureDetector(
      onTap: () {
        final indexInPlaylist = playlist.indexWhere(
          (s) => s['title'] == song['title'],
        );

        print("🔍 Đang mở bài: ${song['title']}");
        print("🎯 Index trong playlist: $indexInPlaylist");
        print("📻 Playlist gồm: ${playlist.map((s) => s['title'])}");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => PlayMusicPage(
                  title: song["title"],
                  artist: song["artist"],
                  coverUrl: song["cover"],
                  category: song["category"],
                  playlist: List<Map<String, dynamic>>.from(playlist),
                  index: indexInPlaylist >= 0 ? indexInPlaylist : 0,
                ),
          ),
        );
      },
      ////////mini page
      child: MiniPlayer(playlist: playlist),
    );
  }
}
