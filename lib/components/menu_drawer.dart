import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shimmer/shimmer.dart';
import '/screens/customers_screen.dart';
import '/screens/payments_screen.dart';
import '/screens/scraps_screen.dart';
import '/components/dialog_logout.dart';
import '/screens/auth/contact_no_screen.dart';
import '/utils/session_manager.dart';
import '/theme/theme.dart';

class MenuDrawer extends StatefulWidget {
  final Function(int) onItemSelected;
  final int currentIndex;

  const MenuDrawer({
    super.key,
    required this.onItemSelected,
    required this.currentIndex,
  });

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  final menus = [
    "Home",
    "Orders",
    "Ledgers",
    "Accounts",
    "Customers",
    "Payments",
    "Scraps",
  ];
  final icons = [
    [HugeIconsStroke.home11, HugeIconsSolid.home11],
    [HugeIconsStroke.shoppingBasket01, HugeIconsSolid.shoppingBasket01],
    [HugeIconsStroke.userMultiple02, HugeIconsSolid.userMultiple02],
    [HugeIconsStroke.user03, HugeIconsSolid.user03],
    [HugeIconsStroke.userGroup, HugeIconsSolid.userGroup],
    [HugeIconsStroke.moneyReceiveFlow01, HugeIconsSolid.moneyReceiveFlow01],
    [HugeIconsStroke.recycle02, HugeIconsSolid.recycle02],
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _slideAnimations = List.generate(
      menus.length,
      (i) =>
          Tween<Offset>(begin: const Offset(-1.0, 0), end: Offset.zero).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(i * 0.1, 1.0, curve: Curves.easeOut),
            ),
          ),
    );

    _fadeAnimations = List.generate(
      menus.length,
      (i) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(i * 0.1, 1.0, curve: Curves.easeIn),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await SessionManager.clearSession();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => LoginScreen(),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 🟣 Gradient Background
        // Container(
        //   decoration: BoxDecoration(
        //     gradient: LinearGradient(
        //       colors: [
        //         AppTheme.cardBg(context),
        //         AppTheme.cardDarkBg(context).withOpacity(0.8),
        //       ],
        //       begin: Alignment.topLeft,
        //       end: Alignment.bottomRight,
        //     ),
        //   ),
        // ),

        // 🟣 Frosted Glass Overlay
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          // child: Container(color: AppTheme.customListBg(context).withOpacity(1.0)),
        ),

        // 🟣 Menu Content
        Padding(
          padding: const EdgeInsets.only(
            bottom: 30,
            left: 20,
            right: 20,
            top: 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    AppTheme.appLogo(context),
                    height: 120,
                    width: 60,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "My",
                    style: AppTheme.textTitle(context).copyWith(
                      fontSize: 20,
                      fontFamily: AppFontFamily.poppinsBold,
                    ),
                  ),
                  Text(
                    "Dashboard",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.textTitle(context).copyWith(
                      fontSize: 20,
                      fontFamily: AppFontFamily.poppinsLight,
                    ),
                  ),
                  Text(
                    ".",
                    style: AppTheme.textTitleActive(
                      context,
                    ).copyWith(fontSize: 30),
                  ),
                ],
              ),
              // const SizedBox(height: 10),
              ...List.generate(menus.length, (index) {
                bool isActive = index == widget.currentIndex;
                return SlideTransition(
                  position: _slideAnimations[index],
                  child: FadeTransition(
                    opacity: _fadeAnimations[index],
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      // margin: const EdgeInsets.only(bottom: 5),
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.customListBg(context)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        onTap: () {
                          if (index <= 3) {
                            widget.onItemSelected(index);
                          } else {
                            switch (index) {
                              case 4:
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CustomersScreen(),
                                  ),
                                );
                                break;
                              case 5:
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PaymentsScreen(),
                                  ),
                                );
                                break;
                              case 6:
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ScrapsScreen(),
                                  ),
                                );
                                break;
                            }
                          }
                        },
                        child: Row(
                          spacing: 16,
                          children: [
                            Icon(
                              isActive ? icons[index][1] : icons[index][0],
                              color: isActive
                                  ? AppTheme.iconColor(context)
                                  : AppTheme.iconColorThree(context),
                            ),
                            Text(
                              menus[index],
                              style: AppTheme.textLabel(context).copyWith(
                                fontFamily: isActive
                                    ? AppFontFamily.poppinsMedium
                                    : AppFontFamily.poppinsLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              // Divider(color: AppTheme.dividerBg(context)),
              OutlineErrorButton(
                text: 'Log Out',
                onPressed: () {
                  DialogLogout().showDialog(context, _logout);
                },
              ),
              const SizedBox(height: 20),
              Shimmer(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.sliderHighlightBg(context),
                    AppTheme.iconColorThree(context),
                    AppTheme.sliderHighlightBg(context),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                direction: ShimmerDirection.rtl,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 12,
                  children: [
                    const Icon(HugeIconsStroke.swipeLeft01),
                    Text(
                      "Swipe left to close menu",
                      style: AppTheme.textLink(context).copyWith(
                        fontFamily: AppFontFamily.poppinsMedium,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
