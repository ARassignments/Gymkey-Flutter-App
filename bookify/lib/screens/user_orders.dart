import '/components/orderlist_tabview.dart';
import '/utils/themes/themes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

class UserOrders extends StatefulWidget {
  const UserOrders({super.key});

  @override
  State<UserOrders> createState() => _UserOrdersState();
}

class _UserOrdersState extends State<UserOrders>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TextEditingController searchController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Please log in.")));
    }

    return Scaffold(
      backgroundColor: AppTheme.screenBg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          "My Orders",
          style: AppTheme.textTitle(context).copyWith(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(HugeIconsStroke.arrowLeft01, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.iconColor(context),
          unselectedLabelColor: AppTheme.iconColorThree(context),
          labelStyle: AppTheme.textTitle(context),
          indicatorColor: AppTheme.iconColor(context),
          splashFactory: null,
          overlayColor: null,
          dividerColor: AppTheme.dividerBg(context),
          dividerHeight: 1.5,
          tabs: const [
            Tab(text: "Active"),
            Tab(text: "Completed"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          OrdersListTab(
            uid: uid,
            filterCompleted: false,
            filterCancelled: false,
          ),
          OrdersListTab(
            uid: uid,
            filterCompleted: true,
            filterCancelled: false,
          ),
          OrdersListTab(
            uid: uid,
            filterCompleted: false,
            filterCancelled: true,
          ),
        ],
      ),
    );
  }
}
