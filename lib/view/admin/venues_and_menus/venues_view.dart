import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/controller/venue_screen_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/theme/constants.dart';
import 'package:traxx_wepapp/utils/loader.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/create_venue_popup_view.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/venue_details_dialog.dart';
import 'package:traxx_wepapp/widgets/empty_state.dart';
import 'package:firebase_storage/firebase_storage.dart' as fs;

import 'package:flutter/foundation.dart';

class VenuesView extends StatefulWidget {
  const VenuesView({super.key});

  @override
  State<VenuesView> createState() => _VenuesViewState();
}

class _VenuesViewState extends State<VenuesView> {
  late final VenueScreenController controller;
  late final SnackbarMessageController snackbarMessageController;

  final venuesController = Get.find<VenuesController>();

  bool _ownsVenueScreenController = false;

  @override
  void initState() {
    super.initState();

    // ✅ avoid multiple controller instances on web route changes
    if (Get.isRegistered<VenueScreenController>()) {
      controller = Get.find<VenueScreenController>();
      _ownsVenueScreenController = false;
    } else {
      controller = Get.put(VenueScreenController());
      _ownsVenueScreenController = true;
    }

    snackbarMessageController = Get.find<SnackbarMessageController>();
  }

  @override
  void dispose() {
    // ✅ clean up only if we created it here
    if (_ownsVenueScreenController &&
        Get.isRegistered<VenueScreenController>()) {
      Get.delete<VenueScreenController>();
    }
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  String _readString(dynamic v) => (v ?? '').toString().trim();

  Map<String, dynamic> _safeVenueMap(dynamic venue) {
    try {
      final m = (venue as dynamic).toJson();
      if (m is Map<String, dynamic>) return m;
      if (m is Map) return Map<String, dynamic>.from(m);
    } catch (_) {}
    return <String, dynamic>{};
  }

  // First photo ref in your schema:
  // - model.photoPaths[0] or model.photoPath
  // - firestore photoPaths[0] or photoPath
  String _firstVenuePhotoRef(dynamic venue, Map<String, dynamic> m) {
    // 0) model fields first (most reliable)
    try {
      final list = (venue as dynamic).photoPaths;
      if (list is List && list.isNotEmpty) {
        final s = _readString(list.first);
        if (s.isNotEmpty) return s;
      }
    } catch (_) {}

    try {
      final single = (venue as dynamic).photoPath;
      final s = _readString(single);
      if (s.isNotEmpty) return s;
    } catch (_) {}

    // 1) firestore map fields
    final paths = m['photoPaths'];
    if (paths is List && paths.isNotEmpty) {
      final s = _readString(paths.first);
      if (s.isNotEmpty) return s;
    }

    final singlePath = _readString(m['photoPath']);
    if (singlePath.isNotEmpty) return singlePath;

    // 2) fallbacks
    return _readString(
      m['imageUrl'] ?? m['photoUrl'] ?? m['thumbnailUrl'] ?? m['coverUrl'],
    );
  }

  int _venuePhotoCount(dynamic venue, Map<String, dynamic> m) {
    try {
      final list = (venue as dynamic).photoPaths;
      if (list is List) return list.length;
    } catch (_) {}

    final paths = m['photoPaths'];
    if (paths is List) return paths.length;

    final single = _readString(m['photoPath']);
    return single.isEmpty ? 0 : 1;
  }

  String _fullAddressFromVenueMap(Map<String, dynamic> m) {
    final address = m['address'];
    if (address is Map) {
      final mm = Map<String, dynamic>.from(address);
      final parts = [
        _readString(mm['street']),
        _readString(mm['city']),
        _readString(mm['state']),
        _readString(mm['zip']),
        _readString(mm['country']),
      ].where((e) => e.isNotEmpty).toList();

      if (parts.isNotEmpty) return parts.join(', ');
    }

    return _readString(
      m['fullAddress'] ?? m['venueFullAddress'] ?? m['venueAddress'],
    );
  }

  String _cityStateFromVenue(dynamic venue, Map<String, dynamic> m) {
    // Prefer address map
    final address = m['address'];
    if (address is Map) {
      final mm = Map<String, dynamic>.from(address);
      final city = _readString(mm['city']);
      final state = _readString(mm['state']);
      final out = [city, state].where((e) => e.isNotEmpty).join(', ');
      if (out.isNotEmpty) return out;
    }

    // Try model fields if present
    try {
      final city = _readString((venue as dynamic).city);
      final state = _readString((venue as dynamic).state);
      final out = [city, state].where((e) => e.isNotEmpty).join(', ');
      if (out.isNotEmpty) return out;
    } catch (_) {}

    return '—';
  }

  String _capacityFromVenueMap(Map<String, dynamic> m) {
    final v = m['capacity'] ?? m['venueCapacity'] ?? m['maxCapacity'];
    return _readString(v);
  }

  String _phoneFromVenueMap(Map<String, dynamic> m) {
    return _readString(m['phone'] ?? m['phoneNumber'] ?? m['venuePhone']);
  }

  String _emailFromVenueMap(Map<String, dynamic> m) {
    return _readString(m['email'] ?? m['venueEmail'] ?? m['contactEmail']);
  }

  // ─────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: _buildVenuesCardsSection(context),
    );
  }

  Widget _buildVenuesCardsSection(BuildContext context) {
    return Obx(() {
      if (venuesController.venues.isEmpty) {
        return SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: EmptyState(
            title: 'Create your first venue',
            imageAsset: Constants.cartoonRestaurant,
            description: 'Create your first venue by tapping the button below.',
            buttonText: 'Add First Venue',
            onButtonPressed: () {
              showDialog(
                context: context,
                builder: (_) => CreateVenuePopupView(
                  controller: controller,
                  venuesController: venuesController,
                ),
              ).then((value) async {
                if (value == true) {
                  try {
                    showLoadingIndicator();
                    await controller.submitForm();
                  } finally {
                    hideLoadingIndicator();
                  }
                }
              });
            },
          ),
        );
      }

      final venues = venuesController.venues;
      final w = MediaQuery.sizeOf(context).width;
      final isNarrow = w < 900;

      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: EdgeInsets.fromLTRB(
          isNarrow ? 14 : 20,
          16,
          isNarrow ? 14 : 20,
          20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;

            int crossAxisCount;
            if (maxW < 650) {
              crossAxisCount = 1;
            } else if (maxW < 1050) {
              crossAxisCount = 2;
            } else if (maxW < 1450) {
              crossAxisCount = 3;
            } else {
              crossAxisCount = 4;
            }

            final spacing = maxW < 650 ? 12.0 : 16.0;
            final childAspectRatio = crossAxisCount == 1 ? 1.55 : 0.95;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: venues.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                final venue = venues[index];
                final m = _safeVenueMap(venue);

                final name =
                    _readString(m['name'] ?? m['venueName'] ?? m['title']);
                final displayName = name.isEmpty ? '—' : name;

                final cityState = _cityStateFromVenue(venue, m);
                final address = _fullAddressFromVenueMap(m);

                final imageRef = _firstVenuePhotoRef(venue, m);
                final photoCount = _venuePhotoCount(venue, m);

                final capacity = _capacityFromVenueMap(m);
                final phone = _phoneFromVenueMap(m);
                final email = _emailFromVenueMap(m);

                return _VenueVerticalCard(
                  name: displayName,
                  cityState: cityState,
                  address: address,
                  capacity: capacity,
                  phone: phone,
                  email: email,
                  photoCount: photoCount,
                  imageRef: imageRef,
                  onTapView: () {
                    showDialog(
                      context: context,
                      builder: (_) => VenueDetailsDialog(venue: venue),
                    );
                  },
                  onEdit: () {
                    controller.updateClassFields(venue);
                    showDialog(
                      context: context,
                      builder: (_) => CreateVenuePopupView(
                        controller: controller,
                        venuesController: venuesController,
                        isEditMode: true,
                      ),
                    ).then((value) async {
                      if (value == true) {
                        try {
                          showLoadingIndicator();
                          await controller.updateVenue();
                        } finally {
                          hideLoadingIndicator();
                        }
                      }
                    });
                  },
                  onDelete: () {
                    venuesController.removeVenue(venue.venueID!);
                  },
                );
              },
            );
          },
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────
// Card UI
// ─────────────────────────────────────────────

class _VenueVerticalCard extends StatefulWidget {
  final String name;
  final String cityState;
  final String address;
  final String capacity;
  final String phone;
  final String email;

  final int photoCount;
  final String imageRef; // storage path OR url

  final VoidCallback onTapView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VenueVerticalCard({
    required this.name,
    required this.cityState,
    required this.address,
    required this.capacity,
    required this.phone,
    required this.email,
    required this.photoCount,
    required this.imageRef,
    required this.onTapView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_VenueVerticalCard> createState() => _VenueVerticalCardState();
}

class _VenueVerticalCardState extends State<_VenueVerticalCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hover ? 0.06 : 0.02),
              blurRadius: _hover ? 22 : 14,
              offset: Offset(0, _hover ? 12 : 8),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onTapView,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 160,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _VenueCoverImage(refOrUrl: widget.imageRef),
                      ),
                      if (widget.photoCount > 1)
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${widget.photoCount} photos',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Row(
                          children: [
                            _IconCircleButton(
                              tooltip: 'View',
                              icon: Icons.visibility_outlined,
                              onPressed: widget.onTapView,
                            ),
                            const SizedBox(width: 8),
                            _IconCircleButton(
                              tooltip: 'Edit',
                              icon: Icons.edit_outlined,
                              onPressed: widget.onEdit,
                            ),
                            const SizedBox(width: 8),
                            _IconCircleButton(
                              tooltip: 'Delete',
                              icon: Icons.delete_outline,
                              iconColor: Colors.redAccent,
                              onPressed: widget.onDelete,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (widget.address.trim().isNotEmpty)
                          _DetailLine(
                              icon: Icons.place_outlined, text: widget.address),
                        if (widget.cityState.trim().isNotEmpty &&
                            widget.cityState != '—')
                          _DetailLine(
                              icon: Icons.location_on_outlined,
                              text: widget.cityState),
                        if (widget.capacity.trim().isNotEmpty)
                          _DetailLine(
                            icon: Icons.groups_2_outlined,
                            text: 'Capacity: ${widget.capacity}',
                          ),
                        if (widget.phone.trim().isNotEmpty)
                          _DetailLine(
                              icon: Icons.call_outlined, text: widget.phone),
                        if (widget.email.trim().isNotEmpty)
                          _DetailLine(
                              icon: Icons.mail_outline, text: widget.email),
                        const SizedBox(height: 10),
                        Row(
                          children: const [
                            _MiniPill(
                                icon: Icons.meeting_room_outlined,
                                text: 'Venue'),
                            SizedBox(width: 8),
                            _MiniPill(
                                icon: Icons.info_outline, text: 'Details'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Image: accepts storage path ("uploads/...jpg") OR http url
// Caches resolved download URLs so it works after reload
// ─────────────────────────────────────────────

class _VenueCoverImage extends StatefulWidget {
  final String refOrUrl;
  const _VenueCoverImage({required this.refOrUrl});

  @override
  State<_VenueCoverImage> createState() => _VenueCoverImageState();
}

class _VenueCoverImageState extends State<_VenueCoverImage> {
  static final Map<String, String> _cache = {};
  late Future<String?> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolve(widget.refOrUrl);
  }

  @override
  void didUpdateWidget(covariant _VenueCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refOrUrl != widget.refOrUrl) {
      _future = _resolve(widget.refOrUrl);
    }
  }

  Future<String?> _resolve(String input) async {
    final s = input.trim();
    if (s.isEmpty) return null;

    if (s.startsWith('http://') || s.startsWith('https://')) return s;

    final cached = _cache[s];
    if (cached != null) return cached;

    try {
      final path = s.startsWith('/') ? s.substring(1) : s;
      final url = await fs.FirebaseStorage.instance.ref(path).getDownloadURL();
      _cache[s] = url;
      return url;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _future,
      builder: (context, snap) {
        final url = snap.data?.trim() ?? '';

        if (snap.connectionState != ConnectionState.done) {
          return const ColoredBox(
            color: Color(0xFFF1F5F9),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (url.isEmpty) {
          return const ColoredBox(
            color: Color(0xFFF1F5F9),
            child: Center(child: Icon(Icons.image_outlined, size: 36)),
          );
        }

        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Color(0xFFF1F5F9),
            child: Center(child: Icon(Icons.broken_image_outlined, size: 34)),
          ),
        );
      },
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onPressed;

  const _IconCircleButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: Colors.white.withOpacity(0.95),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child:
              Icon(icon, size: 18, color: iconColor ?? const Color(0xFF111827)),
        ),
      ),
    );

    // ✅ Tooltip on web was causing OverlayPortal sizing asserts
    if (kIsWeb) return btn;

    return Tooltip(message: tooltip, child: btn);
  }
}

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
