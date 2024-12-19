import 'package:app/screens/home/home_screen.dart';
import 'package:app/screens/products/products_screen.dart';
import 'package:app/utils/app_colors.dart';
import 'package:app/utils/app_text_styles.dart';
import 'package:flutter/material.dart';

class TabContainerScreen extends StatefulWidget {
  const TabContainerScreen({super.key});
  static const route = "Home";
  @override
  State<TabContainerScreen> createState() => _TabContainerScreenState();
}

class _TabContainerScreenState extends State<TabContainerScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
          body: const TabBarView(
            children: [HomeScreen(), ProductsScreen()],
          ),
          bottomNavigationBar: _bottomNavigation()),
    );
  }

  Widget _bottomNavigation() {
    return BottomAppBar(
      padding: const EdgeInsets.all(0),
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bottom.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: TabBar(
          indicator: null,
          indicatorPadding: EdgeInsets.zero,
          indicatorColor: Colors.transparent,
          dividerColor: Colors.transparent,
          labelPadding: EdgeInsets.zero,
          onTap: _onTabSelected,
          tabs: [
            _buildTab(Icons.home, "Home", 0),
            _buildTab(Icons.storage_sharp, "Products", 1),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return SizedBox(
      height: 45,
      child: Column(
        children: [
          Icon(icon, color: isSelected ? AppColors.orange : AppColors.white),
          Text(
            label,
            style: AppTextStyles.bold_12.copyWith(
              color: isSelected ? AppColors.orange : AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
