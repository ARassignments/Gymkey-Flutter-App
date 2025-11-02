import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/Models/customer_model.dart';
import '/theme/theme.dart';

class CustomerSearchField extends StatefulWidget {
  final List<Customer> customers;
  final Function(Customer) onSelected;
  final VoidCallback onDateRangeTap;
  final int ledgerLength;
  final VoidCallback onWhatsappTap;

  const CustomerSearchField({
    super.key,
    required this.customers,
    required this.onSelected,
    required this.onDateRangeTap,
    required this.ledgerLength,
    required this.onWhatsappTap,
  });

  @override
  State<CustomerSearchField> createState() => _CustomerSearchFieldState();
}

class _CustomerSearchFieldState extends State<CustomerSearchField>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  List<Customer> _filtered = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _filtered = widget.customers;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(_fadeAnimation);

    _controller.addListener(() {
      final query = _controller.text.toLowerCase();
      _filtered = widget.customers.where((cust) {
        return cust.UserName.toLowerCase().contains(query) ||
            cust.CityName.toLowerCase().contains(query);
      }).toList();
      _updateOverlay();
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 100), _showOverlay);
      } else {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!_focusNode.hasFocus) _removeOverlay();
        });
      }
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward(from: 0);
  }

  void _removeOverlay() async {
    if (_overlayEntry != null) {
      await _animController.reverse();
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0.0, size.height + 5.0),
            child: Material(
              color: Colors.transparent,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Material(
                    elevation: 0,
                    borderRadius: BorderRadius.circular(16),
                    child: _filtered.isNotEmpty
                        ? ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 250),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final cust = _filtered[index];
                                return InkWell(
                                  onTap: () {
                                    Future.delayed(
                                      const Duration(milliseconds: 100),
                                      () {
                                        _controller.text = cust.UserName;
                                        widget.onSelected(cust);
                                        _focusNode.unfocus();
                                        _removeOverlay();
                                      },
                                    );
                                  },
                                  child: ListTile(
                                    leading: Text(
                                      (index + 1).toString().padLeft(2, '0'),
                                      style: const TextStyle(
                                        fontFamily: AppFontFamily.poppinsMedium,
                                      ),
                                    ),
                                    title: Text(
                                      cust.UserName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.textLabel(context)
                                          .copyWith(
                                            fontFamily:
                                                AppFontFamily.poppinsSemiBold,
                                          ),
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Icon(
                                          HugeIconsStroke.mapsLocation02,
                                          size: 14,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          cust.CityName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily:
                                                AppFontFamily.poppinsRegular,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              labelText: 'Search Here',
              hintText: 'Search by name or city',
              counter: const SizedBox.shrink(),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                child: Icon(HugeIconsSolid.search01),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(HugeIconsSolid.arrowDown01),
                    onPressed: () {
                      FocusScope.of(context).requestFocus(_focusNode);
                      _filtered = widget.customers;
                      _updateOverlay();
                    },
                  ),
                  IconButton(
                    icon: const Icon(HugeIconsSolid.calendar03),
                    onPressed: widget.onDateRangeTap,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      icon: const Icon(HugeIconsSolid.whatsapp),
                      onPressed: widget.onWhatsappTap,
                    ),
                  ),
                ],
              ),
            ),
            style: AppInputDecoration.inputTextStyle(context),
            keyboardType: TextInputType.name,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Must Select The Customer';
              } else if (!RegExp(r'^[a-zA-Z0-9&()/ ]+$').hasMatch(value)) {
                return 'Must contain only letters or digits';
              }
              return null;
            },
            maxLength: 20,
          ),

          // 🔍 Show result info
          if (_controller.text.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppTheme.textSearchInfo(context),
                    children: [
                      const TextSpan(text: 'Result for "'),
                      TextSpan(
                        text: _controller.text,
                        style: AppTheme.textSearchInfoLabeled(context),
                      ),
                      const TextSpan(text: '"'),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: AppTheme.textSearchInfoLabeled(context),
                    children: [
                      TextSpan(text: widget.ledgerLength.toString()),
                      const TextSpan(text: ' found'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
