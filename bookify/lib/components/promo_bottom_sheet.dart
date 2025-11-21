import '/utils/themes/themes.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/models/promo_model.dart';
import 'package:flutter/material.dart';

class PromoBottomSheet extends StatefulWidget {
  final PromoModel? initialPromo;
  const PromoBottomSheet({super.key, this.initialPromo});

  @override
  State<PromoBottomSheet> createState() => _PromoBottomSheetState();
}

class _PromoBottomSheetState extends State<PromoBottomSheet> {
  PromoModel? selectedPromo;

  final List<PromoModel> promos = [
    PromoModel(
      id: "p1",
      title: "Special 25% Off",
      description: "Special promo only today!",
      discount: 25,
    ),
    PromoModel(
      id: "p2",
      title: "Discount 30% Off",
      description: "New user special promo",
      discount: 30,
    ),
    PromoModel(
      id: "p3",
      title: "Special 20% Off",
      description: "Valid today only!",
      discount: 20,
    ),
    PromoModel(
      id: "p4",
      title: "Discount 40% Off",
      description: "Valid today only!",
      discount: 40,
    ),
  ];

  @override
  void initState() {
    selectedPromo = widget.initialPromo;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        height: MediaQuery.of(context).size.height * 0.80,
        child: Column(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              "Add Promo",
              textAlign: TextAlign.center,
              style: AppTheme.textLabel(
                context,
              ).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            // LIST
            Expanded(
              child: ListView.builder(
                itemCount: promos.length,
                itemBuilder: (context, index) {
                  final promo = promos[index];
                  final isSelected = selectedPromo?.id == promo.id;

                  return InkWell(
                    onTap: () => setState(() => selectedPromo = promo),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.customListBg(context),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.cardDarkBg(context),
                            ),
                            child: Icon(
                              HugeIconsSolid.couponPercent,
                              color: AppTheme.iconColor(context),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Title + Description
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  promo.title,
                                  style: AppTheme.textTitle(context),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  promo.description,
                                  style: AppTheme.textLabel(context),
                                ),
                              ],
                            ),
                          ),

                          // Discount %
                          Text(
                            "%${promo.discount.toString().padLeft(2, '0')}",
                            style: AppTheme.textTitle(
                              context,
                            ).copyWith(fontSize: 18),
                          ),
                          const SizedBox(width: 10),

                          // Radio Button
                          Icon(
                            isSelected
                                ? HugeIconsSolid.radioButton
                                : HugeIconsStroke.radioButton,
                            color: AppTheme.iconColor(context),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(),

            // APPLY BUTTON
            ElevatedButton(
              onPressed: selectedPromo != null
                  ? () => Navigator.pop(context, selectedPromo)
                  : null,
              child: Text("Apply"),
            ),
          ],
        ),
      ),
    );
  }
}
