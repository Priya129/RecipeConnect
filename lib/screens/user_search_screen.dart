import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../ad/ad_manager.dart';
import '../global/app_colors.dart';
import 'profile_screen.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  SearchUserScreenState createState() => SearchUserScreenState();
}

class SearchUserScreenState extends State<SearchUserScreen> {
  String currentId = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  final AdManager _adManager = AdManager();
  final Duration debounceDuration = const Duration(milliseconds: 300);
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adManager.initializeAds(context);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _adManager.disposeAds();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _searchUsers() async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String searchText = _searchController.text.trim();
      QuerySnapshot querySnapshot = await firestore
          .collection('user')
          .where('username', isGreaterThanOrEqualTo: searchText)
          .where('username', isLessThanOrEqualTo: searchText + '\uf8ff')
          .get();

      setState(() {
        _searchResults = querySnapshot.docs;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while searching: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchTextChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      _searchUsers();
    });
  }

  Future<void> _followUnfollowUser(String followeeUid) async {
    String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      await firestore.runTransaction((transaction) async {
        DocumentReference currentUserRef = firestore.collection('user').doc(currentUserUid);
        DocumentReference followeeRef = firestore.collection('user').doc(followeeUid);

        DocumentSnapshot currentUserSnapshot = await transaction.get(currentUserRef);
        DocumentSnapshot followeeSnapshot = await transaction.get(followeeRef);

        if (!currentUserSnapshot.exists || !followeeSnapshot.exists) {
          throw Exception('User data not found');
        }

        List<String> currentFollowings = List<String>.from(currentUserSnapshot['following']);
        List<String> followeeFollowers = List<String>.from(followeeSnapshot['followers']);

        if (currentFollowings.contains(followeeUid)) {
          currentFollowings.remove(followeeUid);
          followeeFollowers.remove(currentUserUid);
        } else {
          currentFollowings.add(followeeUid);
          followeeFollowers.add(currentUserUid);
        }

        transaction.update(currentUserRef, {'following': currentFollowings});
        transaction.update(followeeRef, {'followers': followeeFollowers});
      });
    } catch (e) {
      print('Failed to follow/unfollow user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: AppColors.mainColor),
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search users...',
            hintStyle: TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.mainColor,
              fontSize: 16,
            ),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            _onSearchTextChanged();
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          var userData = _searchResults[index].data() as Map<String, dynamic>;
          String userId = _searchResults[index].id;
          String username = userData['username'] ?? 'Unknown';
          String imageUrl = userData['imageUrl'] ?? '';
          bool isFollowing = (userData['followers'] as List<dynamic>)
              .contains(FirebaseAuth.instance.currentUser!.uid);

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl.isEmpty ? const Icon(Icons.person) : null,
            ),
            title: Text(username),
            trailing: GestureDetector(
              onTap: () {
                _followUnfollowUser(userId);
              },
              child: Container(
                height: 40,
                width: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.mainColor,
                ),
                child: Center(
                  child: Text(
                    isFollowing ? 'Unfollow' : 'Follow',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    userId: userId,
                    currentUserId: currentId,
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _adManager.getLargeBannerAdWidget(),
    );
  }
}
