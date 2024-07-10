import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../global/app_colors.dart';
import '../screens/favorite_page.dart';
import '../screens/home_page.dart';
import '../screens/profile_screen.dart';
import '../screens/upload_recipe_screen.dart';
import '../screens/video_feed_screen.dart';
import '../shimmer/shimmer_profile_screen.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;
  String? currentUserId;
  final PageController _pageController = PageController();
  final GlobalKey<VideoFeedScreenState> _videoFeedKey = GlobalKey<VideoFeedScreenState>();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isWideScreen = screenWidth > 600;

    final List<Widget> screens = [
      HomePage(),
      VideoFeedScreen(key: _videoFeedKey, ),
      UploadRecipeScreen(),
      FavoritesScreen(),
      if (currentUserId != null)
        ProfileScreen(userId: currentUserId!, currentUserId: currentUserId!)
      else
        Center(child: ShimmerProfileScreen()),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (selectedIndex == 1 && index != 1) {
            _videoFeedKey.currentState?.pauseAllVideos();
          }
          setState(() {
            selectedIndex = index;
          });
        },
        children: screens,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        buttonBackgroundColor: AppColors.mainColor,
        color: AppColors.mainColor,
        animationDuration: const Duration(milliseconds: 300),
        index: selectedIndex,
        onTap: (int index) {
          _pageController.jumpToPage(index);
        },
        items: [
          Icon(Icons.home, size: isWideScreen ? 30 : 26, color: Colors.white),
          ImageIcon(AssetImage('assets/Images/reels.png'), size: isWideScreen ? 30 : 26, color: Colors.white),
          ImageIcon(AssetImage('assets/Images/sign.png'), size: isWideScreen ? 30 : 26, color: Colors.white),
          Icon(Icons.favorite, size: isWideScreen ? 30 : 26, color: Colors.white),
          Icon(Icons.person, size: isWideScreen ? 30 : 26, color: Colors.white),
        ],
      ),
    );
  }
}
