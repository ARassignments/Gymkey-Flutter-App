import '/utils/themes/themes.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '../models/shipping_model.dart';

class ShippingBottomSheet extends StatefulWidget {
  final ShippingModel? initial;
  const ShippingBottomSheet({super.key, this.initial});

  @override
  State<ShippingBottomSheet> createState() => _ShippingBottomSheetState();
}

class _ShippingBottomSheetState extends State<ShippingBottomSheet> {
  late ShippingModel? selected;

  final List<ShippingModel> shippingList = [
    ShippingModel(
      id: 'economy',
      title: 'Economy',
      minDays: 4,
      maxDays: 7,
      price: 10,
      icon: HugeIconsSolid.deliveryBox01,
    ),
    ShippingModel(
      id: 'regular',
      title: 'Regular',
      minDays: 2,
      maxDays: 4,
      price: 15,
      icon: HugeIconsSolid.packageDelivered,
    ),
    ShippingModel(
      id: 'cargo',
      title: 'Cargo',
      minDays: 1,
      maxDays: 2,
      price: 20,
      icon: HugeIconsSolid.shippingTruck01,
    ),
    ShippingModel(
      id: 'express',
      title: 'Express',
      minDays: 1,
      maxDays: 1,
      price: 30,
      icon: HugeIconsSolid.truckDelivery,
    ),
  ];

  @override
  void initState() {
    super.initState();
    selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        child: Wrap(
          children: [
            Column(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Choose Shipping Type",
                  textAlign: TextAlign.center,
                  style: AppTheme.textLabel(
                    context,
                  ).copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Divider(),
                ...shippingList.map((opt) {
                  final isSelected = selected?.id == opt.id;
                  return InkWell(
                    onTap: () {
                      setState(() => selected = opt);
                      // return immediately with the selection (close sheet)
                      Navigator.of(context).pop(opt);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.customListBg(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.cardDarkBg(context),
                            ),
                            child: Icon(
                              opt.icon,
                              color: AppTheme.iconColor(context),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt.title,
                                  style: AppTheme.textTitle(context),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  opt.getArrivalDate(),
                                  style: AppTheme.textLabel(context),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '\$${opt.price.toStringAsFixed(0)}',
                            style: AppTheme.textTitle(
                              context,
                            ).copyWith(fontSize: 18),
                          ),
                          const SizedBox(width: 10),
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
                }).toList(),
                const Divider(),
                ElevatedButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
