import 'package:flutter/material.dart';
import 'audio_manager.dart';
import 'play_music.dart';

class MiniPlayer extends StatefulWidget {
  final List<Map<String, dynamic>> playlist;

  const MiniPlayer({required this.playlist, super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final _player = AudioManager().player;

  @override
  void initState() {
    super.initState();
    _player.currentIndexStream.listen((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _player.playingStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        final currentIndex = _player.currentIndex;

        if (currentIndex == null || widget.playlist.isEmpty) {
          return const SizedBox();
        }

        // final song = widget.playlist[currentIndex];
        final song = AudioManager().currentSong;
        if (song == null) return const SizedBox();

        return GestureDetector(
          //ấn quay trở lại màn hình Play_music
          onTap: () {
            final currentIndex = _player.currentIndex;
            final playlist = AudioManager().playlist;
            if (currentIndex != null && playlist.isNotEmpty) {
              final song = widget.playlist[currentIndex];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => PlayMusicPage(
                        title: song['title'],
                        artist: song['artist'],
                        coverUrl: song['cover'],
                        category: song['category'],
                        playlist: widget.playlist,
                        index: currentIndex,
                      ),
                ),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    song['cover'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song['title'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        song['artist'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13.9,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => AudioManager().playPrevious(),
                      ),
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        iconSize: 24,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed:
                            () => isPlaying ? _player.pause() : _player.play(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => AudioManager().playNext(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
