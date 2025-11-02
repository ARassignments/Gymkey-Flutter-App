import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:intl/intl.dart';
import '../components/loading_screen.dart';
import '../utils/session_manager.dart';
import '../theme/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? token;
  Map<String, dynamic>? user;
  String? localAvatar;
  String? localGender;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final t = await SessionManager.getUserToken();
    final u = await SessionManager.getUser();
    final avatarData = await SessionManager.getAvatarAndGender();
    setState(() {
      token = t;
      user = u;
      localAvatar = avatarData["avatar"];
      localGender = avatarData["gender"];
      isLoading = false;
    });
  }

  String _formatDate(String dateString) {
    try {
      final inputFormat = DateFormat("dd/MMM/yyyy");
      final dateTime = inputFormat.parse(dateString);
      final outputFormat = DateFormat("MMMM dd, yyyy");
      return outputFormat.format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  String formatInternationalPhone(String number) {
    if (number.startsWith("0")) {
      return "+92 ${number.substring(1, 4)} ${number.substring(4, 7)} ${number.substring(7)}";
    }
    return number;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "paid":
        return Colors.green;
      case "inprogress":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return HugeIconsSolid.clock01;
      case "paid":
        return HugeIconsSolid.checkmarkCircle01;
      case "inprogress":
        return HugeIconsSolid.loading02;
      default:
        return Icons.info;
    }
  }

  Future<void> _showAvatarBottomSheet(BuildContext context) async {
    final savedData = await SessionManager.getAvatarAndGender();
    String selectedGender = savedData["gender"] ?? "male";
    String? selectedAvatar = savedData["avatar"];
    final maleAvatars = [
      "assets/images/avatars/boy_1.png",
      "assets/images/avatars/boy_2.png",
      "assets/images/avatars/boy_3.png",
      "assets/images/avatars/boy_4.png",
      "assets/images/avatars/boy_5.png",
      "assets/images/avatars/boy_6.png",
      "assets/images/avatars/boy_7.png",
      "assets/images/avatars/boy_8.png",
      "assets/images/avatars/boy_9.png",
      "assets/images/avatars/boy_10.png",
      "assets/images/avatars/boy_11.png",
      "assets/images/avatars/boy_12.png",
      "assets/images/avatars/boy_13.png",
      "assets/images/avatars/boy_14.png",
      "assets/images/avatars/boy_15.png",
      "assets/images/avatars/boy_16.png",
      "assets/images/avatars/boy_17.png",
      "assets/images/avatars/boy_18.png",
    ];
    final femaleAvatars = [
      "assets/images/avatars/girl_1.png",
      "assets/images/avatars/girl_2.png",
      "assets/images/avatars/girl_3.png",
      "assets/images/avatars/girl_4.png",
      "assets/images/avatars/girl_5.png",
      "assets/images/avatars/girl_6.png",
      "assets/images/avatars/girl_7.png",
      "assets/images/avatars/girl_8.png",
      "assets/images/avatars/girl_9.png",
      "assets/images/avatars/girl_10.png",
      "assets/images/avatars/girl_11.png",
      "assets/images/avatars/girl_12.png",
      "assets/images/avatars/girl_13.png",
      "assets/images/avatars/girl_14.png",
      "assets/images/avatars/girl_15.png",
      "assets/images/avatars/girl_16.png",
      "assets/images/avatars/girl_17.png",
      "assets/images/avatars/girl_18.png",
      "assets/images/avatars/girl_19.png",
      "assets/images/avatars/girl_20.png",
    ];

    List<String> currentList = selectedGender == "male"
        ? maleAvatars
        : femaleAvatars;

    await showModalBottomSheet(
      showDragHandle: true,
      isScrollControlled: true,
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              child: Wrap(
                children: [
                  Column(
                    spacing: 16,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Choose Profile Image",
                        textAlign: TextAlign.center,
                        style: AppTheme.textLabel(context).copyWith(
                          fontSize: 16,
                          fontFamily: AppFontFamily.poppinsBold,
                        ),
                      ),
                      Divider(color: AppTheme.dividerBg(context)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: Text("Male"),
                            labelStyle: AppTheme.textLabel(context).copyWith(
                              color: AppTheme.iconColorThree(context),
                              fontSize: 12,
                            ),
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            backgroundColor: AppTheme.customListBg(context),
                            side: BorderSide(color: Colors.transparent),
                            selectedColor: AppTheme.customListBg(context),
                            checkmarkColor: AppTheme.iconColorThree(context),
                            selected: selectedGender == "male",
                            onSelected: (_) {
                              setModalState(() {
                                selectedGender = "male";
                                currentList = maleAvatars;
                              });
                            },
                          ),
                          const SizedBox(width: 10),
                          ChoiceChip(
                            label: Text("Female"),
                            labelStyle: AppTheme.textLabel(context).copyWith(
                              color: AppTheme.iconColorThree(context),
                              fontSize: 12,
                            ),
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            backgroundColor: AppTheme.customListBg(context),
                            side: BorderSide(color: Colors.transparent),
                            selectedColor: AppTheme.customListBg(context),
                            checkmarkColor: AppTheme.iconColorThree(context),
                            selected: selectedGender == "female",
                            onSelected: (_) {
                              setModalState(() {
                                selectedGender = "female";
                                currentList = femaleAvatars;
                              });
                            },
                          ),
                        ],
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: currentList.length,
                        itemBuilder: (context, index) {
                          final avatar = currentList[index];
                          final isSelected = avatar == selectedAvatar;
                          return InkWell(
                            onTap: () async {
                              await SessionManager.saveAvatarAndGender(
                                selectedGender,
                                avatar,
                              );
                              setState(() {
                                localAvatar = avatar;
                                localGender = selectedGender;
                              });
                              Navigator.pop(context);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Image.asset(avatar, fit: BoxFit.cover),
                                  if (isSelected)
                                    Container(
                                      color: Colors.blue.withOpacity(0.5),
                                      child: const Center(
                                        child: Icon(
                                          HugeIconsSolid.checkmarkBadge02,
                                          color: Colors.white,
                                          size: 50,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      OutlineErrorButton(
                        text: "Cancel",
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          "My Profile",
          style: AppTheme.textTitle(
            context,
          ).copyWith(fontSize: 20, fontFamily: AppFontFamily.poppinsLight),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(HugeIconsStroke.arrowLeft01, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? const Center(child: LoadingLogo())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Divider(height: 1, color: AppTheme.dividerBg(context)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Center(
                            child: Stack(
                              children: [
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: AppTheme.customListBg(context),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: localAvatar != null
                                      ? Image.asset(
                                          localAvatar!,
                                          fit: BoxFit.cover,
                                        )
                                      : CachedNetworkImage(
                                          imageUrl:
                                              "https://firebasestorage.googleapis.com/v0/b/urban-harmony-8fd99.appspot.com/o/ProfileImages%2Fboy_14.png?alt=media&token=7e4a25da-ffca-4374-b9aa-727b28b7bf0c",
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(
                                                HugeIconsSolid.user03,
                                                size: 50,
                                              ),
                                        ),
                                ),

                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: InkWell(
                                    onTap: () {
                                      _showAvatarBottomSheet(context);
                                    },
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        HugeIconsStroke
                                            .imageDone02, // your edit icon
                                        size: 18,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Icon(HugeIconsStroke.userAccount, size: 24),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "Display Name",
                                  style: AppTheme.textLabel(context),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "${user!["FullName"]}",
                                  style: AppTheme.textLabel(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: AppTheme.dividerBg(context)),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Icon(HugeIconsStroke.mail02, size: 24),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "Email Address",
                                  style: AppTheme.textLabel(context),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "${user!["Email"]}",
                                  style: AppTheme.textLabel(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: AppTheme.dividerBg(context)),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Icon(HugeIconsStroke.call, size: 24),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "Phone Number",
                                  style: AppTheme.textLabel(context),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  formatInternationalPhone(
                                    "${user!["PhoneNumber"]}",
                                  ),
                                  style: AppTheme.textLabel(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: AppTheme.dividerBg(context)),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Icon(HugeIconsStroke.mapPin, size: 24),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "Address",
                                  style: AppTheme.textLabel(context),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "${user!["Address"]}",
                                  style: AppTheme.textLabel(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: AppTheme.dividerBg(context)),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Icon(HugeIconsStroke.userStory, size: 24),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "User Type",
                                  style: AppTheme.textLabel(context),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "${user!["UserType"]}",
                                  style: AppTheme.textLabel(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: AppTheme.dividerBg(context)),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Icon(HugeIconsStroke.userSwitch, size: 24),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "Role",
                                  style: AppTheme.textLabel(context),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "${user!["Role"]}",
                                  style: AppTheme.textLabel(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: AppTheme.dividerBg(context)),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
