import 'package:flutter/material.dart';
import 'package:appwrite/models.dart';
import 'package:provider/provider.dart';
import 'package:myapp/theme/theme_tokens.dart';
import 'package:myapp/services/appwrite_service.dart';

class DailyWearScreen extends StatefulWidget {
  const DailyWearScreen({super.key});

  @override
  State<DailyWearScreen> createState() => _DailyWearScreenState();
}

class _DailyWearScreenState extends State<DailyWearScreen> {
  bool _isLoading = true;
  List<Document> _boards = [];

  @override
  void initState() {
    super.initState();
    _fetchOfficeBoards();
  }

  Future<void> _fetchOfficeBoards() async {
    try {
      final appwrite = Provider.of<AppwriteService>(context, listen: false);
      // 🔥 Fetching specifically 'Office' occasion boards!
      final boards = await appwrite.getSavedBoardsByOccasion('Dailywear');
      
      if (mounted) {
        setState(() {
          _boards = boards;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching office boards: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;

    return Scaffold(
      backgroundColor: t.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Office Fits',
          style: TextStyle(
            color: t.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: t.accent.primary),
            )
          : _boards.isEmpty
              ? _buildEmptyState(t)
              : _buildBoardsGrid(t),
    );
  }

  Widget _buildEmptyState(AppThemeTokens t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: t.panel,
              shape: BoxShape.circle,
              border: Border.all(color: t.cardBorder),
            ),
            child: Icon(Icons.business_center_rounded, size: 48, color: const Color(0xFFFFC956)),
          ),
          const SizedBox(height: 24),
          Text(
            "No Office Fits Yet!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Generate professional style boards with\nAHVI and they will appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: t.mutedText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardsGrid(AppThemeTokens t) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, 
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65, 
      ),
      itemCount: _boards.length,
      itemBuilder: (context, index) {
        final board = _boards[index];
        final imageUrl = board.data['imageUrl'] ?? '';
        
        return GestureDetector(
          onTap: () {
            // TODO: Fullscreen image viewer
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.cardBorder),
              color: t.panel,
              image: imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl.isEmpty
                ? Center(child: Icon(Icons.image_not_supported, color: t.mutedText))
                : null,
          ),
        );
      },
    );
  }
}