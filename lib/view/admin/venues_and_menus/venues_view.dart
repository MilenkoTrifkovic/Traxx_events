import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/controller/venue_screen_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/constants.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/loader.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/create_venue_popup_view.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/venue_card.dart';
import 'package:traxx_wepapp/view/admin/venues_and_menus/widgets/venue_details_dialog.dart';
import 'package:traxx_wepapp/widgets/bottom_scrollbar.dart';
import 'package:traxx_wepapp/widgets/empty_state.dart';

class VenuesView extends StatefulWidget {
  const VenuesView({super.key});

  @override
  State<VenuesView> createState() => _VenuesViewState();
}

class _VenuesViewState extends State<VenuesView> {
  late VenueScreenController controller;
  late final SnackbarMessageController snackbarMessageController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(VenueScreenController());
    snackbarMessageController = Get.find<SnackbarMessageController>();
  }

  // Access the global VenuesController
  final venuesController = Get.find<VenuesController>();

  String _readString(dynamic v) => (v ?? '').toString().trim();

  Map<String, dynamic>? _tryToMap(dynamic v) {
    if (v == null) return null;

    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);

    // custom object with toJson()
    try {
      final j = (v as dynamic).toJson();
      if (j is Map<String, dynamic>) return j;
      if (j is Map) return Map<String, dynamic>.from(j);
    } catch (_) {}

    return null;
  }

  String _extractCityStateFromString(String raw) {
    final s = raw.replaceAll('\n', ' ');

    // JSON style: "city":"X"
    String? city = RegExp(r'"city"\s*:\s*"([^"]+)"', caseSensitive: false)
        .firstMatch(s)
        ?.group(1);
    String? state = RegExp(r'"state"\s*:\s*"([^"]+)"', caseSensitive: false)
        .firstMatch(s)
        ?.group(1);

    // Map style: city: X
    city ??= RegExp(r'\bcity\s*[:=]\s*([^,}]+)', caseSensitive: false)
        .firstMatch(s)
        ?.group(1);
    state ??= RegExp(r'\bstate\s*[:=]\s*([^,}]+)', caseSensitive: false)
        .firstMatch(s)
        ?.group(1);

    final c = (city ?? '').trim();
    final st = (state ?? '').trim();
    final out = [c, st].where((e) => e.isNotEmpty).join(', ');
    return out;
  }

  String _cityStateFromAny(dynamic value) {
    // 1) Map-like
    final mm = _tryToMap(value);
    if (mm != null) {
      final city = _readString(mm['city'] ?? mm['town'] ?? mm['locality']);
      final state = _readString(mm['state'] ?? mm['province'] ?? mm['region']);
      final out = [city, state].where((e) => e.isNotEmpty).join(', ');
      if (out.isNotEmpty) return out;

      // Sometimes nested inside "address"
      if (mm['address'] != null) {
        final nested = _cityStateFromAny(mm['address']);
        if (nested != '—') return nested;
      }
    }

    // 2) String-like
    if (value is String) {
      final out = _extractCityStateFromString(value);
      if (out.isNotEmpty) return out;
    }

    // 3) Fallback: try parsing toString() if it contains city/state words
    final s = value?.toString() ?? '';
    if (s.toLowerCase().contains('city') || s.toLowerCase().contains('state')) {
      final out = _extractCityStateFromString(s);
      if (out.isNotEmpty) return out;
    }

    return '—';
  }

  String _cityStateFromVenue(dynamic venue, Map<String, dynamic> m) {
    // A) Direct model props (if they exist)
    try {
      final city = _readString((venue as dynamic).city);
      final state = _readString((venue as dynamic).state);
      final out = [city, state].where((e) => e.isNotEmpty).join(', ');
      if (out.isNotEmpty) return out;
    } catch (_) {}

    // B) Common keys (we try many)
    final candidates = [
      m['location'],
      m['venueLocation'],
      m['address'],
      m['venueAddress'],
      m['fullAddress'],
      m['venueFullAddress'],
    ];

    for (final c in candidates) {
      final out = _cityStateFromAny(c);
      if (out != '—') return out;
    }

    // C) Last resort: scan ALL fields for something address-like
    for (final e in m.entries) {
      final k = e.key.toString().toLowerCase();
      if (k.contains('location') || k.contains('address')) {
        final out = _cityStateFromAny(e.value);
        if (out != '—') return out;
      }
    }

    return '—';
  }

  Map<String, dynamic> _safeVenueMap(dynamic venue) {
    try {
      final v = venue;
      final m = v.toJson();
      if (m is Map<String, dynamic>) return m;
      if (m is Map) return Map<String, dynamic>.from(m);
    } catch (_) {}
    return <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVenuesTableSection(context, venuesController),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the venue creation form

  Widget _buildVenuesTableSection(
      BuildContext context, VenuesController venuesController) {
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
        padding:
            EdgeInsets.fromLTRB(isNarrow ? 14 : 20, 16, isNarrow ? 14 : 20, 20),
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
            final available = constraints.maxWidth;

            // ✅ Like GuestListSection: keep a minimum readable width, otherwise expand.
            final minTableWidth = isNarrow ? 640.0 : 980.0;
            final tableWidth =
                available > minTableWidth ? available : minTableWidth;

            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: BottomHScrollbar(
                  minWidth: tableWidth,
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowHeight: 48,
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 72,
                    horizontalMargin: isNarrow ? 14 : 18,
                    columnSpacing: isNarrow ? 16 : 22,

                    headingRowColor: MaterialStateProperty.all(
                      const Color(0xFFF3F4F6),
                    ),
                    headingTextStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                    dataTextStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF111827),
                    ),

                    // ✅ full border + row separators (same as guest list)
                    border: const TableBorder(
                      top: BorderSide(color: Color(0xFFE5E7EB)),
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                      left: BorderSide(color: Color(0xFFE5E7EB)),
                      right: BorderSide(color: Color(0xFFE5E7EB)),
                      horizontalInside: BorderSide(color: Color(0xFFE5E7EB)),
                      verticalInside: BorderSide.none,
                    ),

                    columns: isNarrow
                        ? const [
                            DataColumn(label: Text('Venue')),
                            DataColumn(label: Text('Actions')),
                          ]
                        : const [
                            DataColumn(label: Text('Venue')),
                            DataColumn(label: Text('Location')),
                            DataColumn(label: Text('Actions')),
                          ],

                    rows: venues.map((venue) {
                      final m = _safeVenueMap(venue);

                      final name = (m['venueName'] ??
                              m['name'] ??
                              m['title'] ??
                              m['venue_title'] ??
                              '—')
                          .toString();

                      final location = _cityStateFromVenue(venue, m);

                      final img = (m['imageUrl'] ??
                              m['photoUrl'] ??
                              m['thumbnailUrl'] ??
                              m['coverUrl'] ??
                              '')
                          .toString();

                      final venueCell = InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => VenueDetailsDialog(venue: venue),
                          );
                        },
                        child: Row(
                          children: [
                            _VenueThumb(url: img),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: isNarrow ? 360 : 260,
                              child: isNarrow
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          location,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );

                      final locationCell = ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      );

                      final actionsCell = Row(
                        children: [
                          IconButton(
                            tooltip: 'View',
                            icon:
                                const Icon(Icons.visibility_outlined, size: 18),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) =>
                                    VenueDetailsDialog(venue: venue),
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () {
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
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.redAccent),
                            onPressed: () {
                              venuesController.removeVenue(venue.venueID!);
                            },
                          ),
                        ],
                      );

                      return DataRow(
                        cells: isNarrow
                            ? [
                                DataCell(venueCell),
                                DataCell(actionsCell),
                              ]
                            : [
                                DataCell(venueCell),
                                DataCell(locationCell),
                                DataCell(actionsCell),
                              ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

class _VenueThumb extends StatelessWidget {
  final String url;
  const _VenueThumb({required this.url});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        color: const Color(0xFFF1F5F9),
        child: hasUrl
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.location_on),
              )
            : const Icon(Icons.location_on),
      ),
    );
  }
}
