import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'play_music.dart';

// Hàm chuyển HEX sang Color (đặt ở đầu file)
Color hexToColor(String hex) {
  hex = hex.replaceAll('#', '').replaceAll('0x', '').trim();
  if (hex.length == 6) hex = 'FF$hex'; // Thêm alpha nếu thiếu
  return Color(int.parse(hex, radix: 16));
}

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();// quản lý nội dung nhập vào của Text
  String _searchQuery = '';// lưu text người dùng đang gõ
  List<Map<String, dynamic>> _results = [];// danh sách kết quả  hiển thị sau khi lọc từ _songs thep _searchQuery
  List<Map<String, dynamic>> _songs = []; // Danh sách tất cả các bài hát lấy từ Supabase
  // quản lý nội dung gợi ý
  final List<String> _suggestions = [
    "Sơn Tùng MTP",
    "Vợ yêu LyLy",
    "Nhạc Nhẹ",
    "Nhạc Hot",
    "Học Trò",
  ];
  bool _isLoading = false; // Trạng thái đang tải dữ liệu
  // hàm chính để tìm kiếm bài hát
  Future<void> _searchSongs(String query) async {
    if (query.trim().isEmpty) return;//nếu người dùng để trống, không tìm

    setState(() => _isLoading = true);

    final response = await Supabase.instance.client
        .from('songs')
        .select()
        .or('title.ilike.%$query%,artist.ilike.%$query%,category.ilike.%$query%'); //Sử dụng ILIKE của Supabase để tìm chuỗi gần đúng, có chứa query.

    setState(() {
      _results = List<Map<String, dynamic>>.from(response);// chuyển sang dạng List và 	Lưu danh sách kết quả vào biến _results.
      _isLoading = false; // Dừng loading
    });
  }
//Khi người dùng chạm vào gợi ý tìm kiếm
  void _onSuggestionTap(String suggestion) {
    setState(() {
      _searchController.text = suggestion;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: suggestion.length),
      );
    });

    _searchSongs(suggestion);// gọi hàm để thực hiện tìm kiếm
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController, // quản lý text nhập vào
          onSubmitted: _searchSongs,// thực hiện tiìm kiếm
          // trường Input
          onChanged: (value) async {
            setState(() {
              _searchQuery = value;
            });

            final query = value.toLowerCase();

            final response = await Supabase.instance.client
                .from('songs')
                .select()
                .or('title.ilike.%$query%,artist.ilike.%$query%,category.ilike.%$query%');

            if (mounted) {
              setState(() {
                _songs = List<Map<String, dynamic>>.from(response);
              });
            }
          },
          decoration: InputDecoration(
            hintText: 'Tìm kiếm bài hát, nghệ sĩ...',
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
            prefixIcon: Icon(Icons.search, size: 20),
            filled: true,
            fillColor: Colors.grey[200], // màu nền xám
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30), // 👈 Bo tròn giống ảnh
              borderSide: BorderSide.none,
            ),
          ),
        ),
        leading: BackButton(),

      ),
      body: _searchQuery.isEmpty
          ? SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GỢI Ý TÌM KIẾM
            // ĐỀ XUẤT
            if (_suggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Đề xuất cho bạn', style: TextStyle(fontSize:14,fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _suggestions.map((s) {
                        return GestureDetector(
                          onTap: () => _onSuggestionTap(s),
                          child: Chip(label: Text(s)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            // TÌM KIẾM GẦN ĐÂY
            Padding(
              padding: const EdgeInsets.symmetric( horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ví dụ 1 item gần đây
                  if (_results.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tìm kiếm gần đây', style: TextStyle(fontSize:14,fontWeight: FontWeight.bold)),
                              TextButton(
                                  onPressed: () {/* xóa lịch sử */},
                                  child: Text('XÓA')),
                            ],
                          ),
                          ListTile(
                            leading: _results[0]['cover'] != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _results[0]['cover'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                                : Icon(Icons.music_note),
                            title: Text(_results[0]['title'] ?? ''),
                            subtitle: Text(_results[0]['artist'] ?? ''),
                            trailing: Icon(Icons.more_vert),
                            onTap: () {
                              final song = _results[0];
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlayMusicPage(
                                    title: song["title"],
                                    artist: song["artist"],
                                    coverUrl: song["cover"],
                                    category: song["category"],
                                    playlist: _songs,
                                    index: 0,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                ],
              ),
            ),
          ],
        ),
      )
          : _songs.isEmpty
          ? Center(child: Text('Không tìm thấy bài hát nào'))
          : ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:Image.network(
                song['cover']??'',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.image_not_supported), // Nếu ảnh lỗi,
              ),
            ),
            title: Text(song['title']),
            subtitle: Text('${song['artist']}'),
            //${song['category']}
            trailing: Icon(Icons.more_vert),
            onTap: () {
              // TODO: mở màn phát nhạc
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PlayMusicPage(
                        title: song["title"],
                        artist: song["artist"],
                        coverUrl: song["cover"],
                        category: song["category"],
                        playlist: _songs,
                        // playlist: playlist,
                        index: index,
                      )
                  )
              );
            },
          );
        },
      ),
      // hiển thị danh sách sau khi tìm kiếm

    );
  }
}
