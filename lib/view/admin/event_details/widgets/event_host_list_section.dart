import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/admin_controllers/event_hosts_controller.dart';
import 'package:traxx_wepapp/models/host_user_row.dart';
import 'package:traxx_wepapp/utils/data/us_data.dart';

// import your controller + HostUserRow
// import 'event_hosts_controller.dart';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Your project imports here:
// import '...controllers/event_hosts_controller.dart';
// import '...models/host_user_row.dart';
// import '...routes/app_route.dart';
// import '...helpers/navigation_helpers.dart';
// import '...dialogs/create_host_dialog.dart';
// import '...dialogs/edit_host_dialog.dart';
// import '...services/us_data.dart';

class EventHostsSection extends StatefulWidget {
  final String tag; // use eventId as tag
  const EventHostsSection({super.key, required this.tag});

  @override
  State<EventHostsSection> createState() => _EventHostsSectionState();
}

class _EventHostsSectionState extends State<EventHostsSection> {
  final ScrollController _hCtrl = ScrollController();

  @override
  void dispose() {
    _hCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Avoid crash if controller not registered for a frame
    if (!Get.isRegistered<EventHostsController>(tag: widget.tag)) {
      return const SizedBox.shrink();
    }

    final c = Get.find<EventHostsController>(tag: widget.tag);

    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 900;

    final titleStyle = GoogleFonts.poppins(
      fontSize: isMobile ? 14.5 : 16,
      fontWeight: FontWeight.w700,
    );

    final chipStyle = GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding:
          EdgeInsets.fromLTRB(isMobile ? 14 : 20, 16, isMobile ? 14 : 20, 20),
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
      child: Obx(() {
        final rows = c.filteredHosts;
        final total = c.hosts.length;
        final primary = c.primaryHostUserId.value;

        final primaryRow = c.hosts.firstWhereOrNull((x) => x.userId == primary);
        final primaryLabel = primaryRow == null
            ? 'Primary Host: —'
            : 'Primary Host: ${primaryRow.name?.trim().isNotEmpty == true ? primaryRow.name!.trim() : primaryRow.email}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ Responsive header
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 900;

                final searchBox = SizedBox(
                  height: 40,
                  child: TextField(
                    onChanged: (v) => c.search.value = v,
                    decoration: InputDecoration(
                      hintText: 'Search by name or email',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: Obx(() {
                        if (c.search.value.trim().isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => c.search.value = '',
                        );
                      }),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                    ),
                  ),
                );

                final addBtn = ElevatedButton.icon(
                  onPressed: () => _openCreateHostDialog(context, c),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(isNarrow ? 'Add' : 'Add Host'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text('Hosts', style: titleStyle),
                          const Spacer(),
                          addBtn,
                        ],
                      ),
                      const SizedBox(height: 10),
                      searchBox,
                    ],
                  );
                }

                return Row(
                  children: [
                    Text('Hosts', style: titleStyle),
                    const SizedBox(width: 14),
                    Expanded(child: searchBox),
                    const SizedBox(width: 12),
                    addBtn,
                  ],
                );
              },
            ),

            const SizedBox(height: 12),

            // Summary chips
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _chip(
                  bg: const Color(0xFFEEF2FF),
                  fg: const Color(0xFF3730A3),
                  icon: Icons.group,
                  text: 'Total Hosts: $total',
                  style: chipStyle,
                ),
                _chip(
                  bg: const Color(0xFFECFDF3),
                  fg: const Color(0xFF027A48),
                  icon: Icons.star,
                  text: primaryLabel,
                  style: chipStyle,
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (c.isLoading.value)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'No hosts assigned to this event yet.',
                  style: GoogleFonts.poppins(color: const Color(0xFF6B7280)),
                ),
              )
            else
              // ✅ Bottom scrollbar + horizontal scroll
              LayoutBuilder(
                builder: (context, constraints) {
                  final available = constraints.maxWidth;

                  // minimum readable width for host columns
                  const minTableWidth = 980.0;

                  // ✅ same "perfect width then scroll" behavior
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
                      child: Scrollbar(
                        controller: _hCtrl,
                        thumbVisibility: true,
                        trackVisibility: true,
                        interactive: true,
                        scrollbarOrientation: ScrollbarOrientation.bottom,
                        child: SingleChildScrollView(
                          controller: _hCtrl,
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: tableWidth),
                            child: DataTable(
                              showCheckboxColumn: false,
                              headingRowHeight: 48,
                              dataRowMinHeight: 56,
                              dataRowMaxHeight: 64,

                              // ✅ header background like Guest table
                              headingRowColor: MaterialStateProperty.all(
                                  const Color(0xFFF3F4F6)),
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

                              // ✅ full border + row dividers like Guest table
                              border: const TableBorder(
                                top: BorderSide(color: Color(0xFFE5E7EB)),
                                bottom: BorderSide(color: Color(0xFFE5E7EB)),
                                left: BorderSide(color: Color(0xFFE5E7EB)),
                                right: BorderSide(color: Color(0xFFE5E7EB)),
                                horizontalInside:
                                    BorderSide(color: Color(0xFFE5E7EB)),
                                verticalInside: BorderSide.none,
                              ),

                              columns: const [
                                DataColumn(label: Text('Name')),
                                DataColumn(label: Text('Email')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Primary')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: rows.map((h) {
                                final isPrimary =
                                    (c.primaryHostUserId.value == h.userId);

                                return DataRow(cells: [
                                  DataCell(Text(
                                    h.name?.trim().isNotEmpty == true
                                        ? h.name!.trim()
                                        : '—',
                                  )),
                                  DataCell(Text(h.email)),
                                  DataCell(_statusPill(
                                    h.isDisabled ? 'Disabled' : 'Enabled',
                                    h.isDisabled,
                                  )),
                                  DataCell(
                                    isPrimary
                                        ? _pill(
                                            'Primary',
                                            const Color(0xFFECFDF3),
                                            const Color(0xFF027A48))
                                        : TextButton(
                                            onPressed: () =>
                                                c.setPrimary(h.userId),
                                            child: const Text('Set Primary'),
                                          ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          tooltip: 'Send verification email',
                                          icon: const Icon(
                                              Icons.mark_email_unread_outlined),
                                          onPressed: () => _sendVerification(
                                              context, c, h.userId, h.email),
                                        ),
                                        IconButton(
                                          tooltip: 'Set Primary',
                                          icon: const Icon(Icons.star_outline),
                                          onPressed: () =>
                                              c.setPrimary(h.userId),
                                        ),
                                        IconButton(
                                          tooltip: 'Edit Host',
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () => _openEditHostDialog(
                                              context, c, h),
                                        ),
                                        IconButton(
                                          tooltip: 'Remove Host',
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => _confirmRemove(
                                              context, c, h.userId),
                                        ),
                                      ],
                                    ),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      }),
    );
  }

  // ---------------- UI helpers ----------------

  Widget _statusPill(String text, bool disabled) {
    return _pill(
      text,
      disabled ? const Color(0xFFFEF2F2) : const Color(0xFFF3F4F6),
      disabled ? const Color(0xFFB42318) : const Color(0xFF374151),
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _chip({
    required Color bg,
    required Color fg,
    required IconData icon,
    required String text,
    required TextStyle style,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bg.withOpacity(0.9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Text(text, style: style.copyWith(color: fg)),
        ],
      ),
    );
  }

  // ---------------- Actions ----------------

  Future<void> _sendVerification(
    BuildContext context,
    EventHostsController c,
    String hostUid,
    String hostEmail,
  ) async {
    try {
      final res = await c.resendVerificationEmail(
        hostUid,
        sendPasswordLink: true,
      );

      final alreadyVerified = res['alreadyVerified'] == true;
      final msg = alreadyVerified
          ? 'Host is already verified.'
          : 'Verification email sent to $hostEmail.';

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send email: $e')),
        );
      }
    }
  }

  // ---------------- Dialogs ----------------

  Future<void> _openCreateHostDialog(
    BuildContext context,
    EventHostsController c,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => CreateHostDialog(controller: c),
    );

    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Host created & assigned. Send verification from the table.'),
        ),
      );
    }
  }

  Future<void> _openEditHostDialog(
    BuildContext context,
    EventHostsController c,
    HostUserRow host,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => EditHostDialog(controller: c, host: host),
    );

    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Host updated')),
      );
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    EventHostsController c,
    String userId,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Host'),
        content: const Text('Are you sure you want to remove this host?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await c.removeHost(userId);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove host: $e')),
          );
        }
      }
    }
  }
}

// =======================================================
// Dialogs (unchanged from your version)
// =======================================================

class CreateHostDialog extends StatefulWidget {
  final EventHostsController controller;

  const CreateHostDialog({
    super.key,
    required this.controller,
  });

  @override
  State<CreateHostDialog> createState() => _CreateHostDialogState();
}

class _CreateHostDialogState extends State<CreateHostDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;

  String? _selectedCountry;
  bool _isDisabled = false;
  bool _isSubmitting = false;
  String? _errorText;

  OutlineInputBorder get _border => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
      );

  OutlineInputBorder get _focusedBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.6),
      );

  InputDecoration _decoration({
    required String hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      border: _border,
      enabledBorder: _border,
      focusedBorder: _focusedBorder,
      errorBorder: _border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: _border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _onCreate() async {
    if (_isSubmitting) return;

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      setState(() => _errorText = 'Please fix validation errors');
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    try {
      await widget.controller.createHostAndAssign(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        country: (_selectedCountry ?? '').trim(),
        isDisabled: _isDisabled,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString().replaceFirst('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      backgroundColor: const Color(0xFFF3F4F6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
                child: Column(
                  children: [
                    const Icon(Icons.person_add, size: 28),
                    const SizedBox(height: 10),
                    Text(
                      'Create Host',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fill in the host information below.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Full Name *'),
                          TextFormField(
                            controller: _nameCtrl,
                            enabled: !_isSubmitting,
                            textCapitalization: TextCapitalization.words,
                            decoration: _decoration(
                              hintText: 'Enter host full name',
                              prefixIcon:
                                  const Icon(Icons.person_outline, size: 18),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          _label('Email Address *'),
                          TextFormField(
                            controller: _emailCtrl,
                            enabled: !_isSubmitting,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _decoration(
                              hintText: 'Enter host email address',
                              prefixIcon:
                                  const Icon(Icons.email_outlined, size: 18),
                            ),
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return 'Email is required';
                              if (!s.contains('@'))
                                return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _label('Address (Optional)'),
                          TextFormField(
                            controller: _addressCtrl,
                            enabled: !_isSubmitting,
                            decoration: _decoration(
                              hintText: 'Enter street address',
                              prefixIcon: const Icon(Icons.location_on_outlined,
                                  size: 18),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _label('Country *'),
                          DropdownButtonFormField<String>(
                            value: _selectedCountry,
                            decoration: _decoration(
                              hintText: 'Select country',
                              prefixIcon: const Icon(Icons.public, size: 18),
                            ),
                            items: USData.countries
                                .map((c) =>
                                    DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: _isSubmitting
                                ? null
                                : (v) => setState(() => _selectedCountry = v),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Country is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Text(
                                'Status',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Switch.adaptive(
                                value: !_isDisabled,
                                onChanged: _isSubmitting
                                    ? null
                                    : (val) =>
                                        setState(() => _isDisabled = !val),
                              ),
                              const Spacer(),
                              Text(
                                _isDisabled ? 'Disabled' : 'Enabled',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (_errorText != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _errorText!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _onCreate,
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Text('Create Host'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, size: 24),
                tooltip: 'Close',
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(false),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.grey.shade700,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style:
                GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      );
}

class EditHostDialog extends StatefulWidget {
  final EventHostsController controller;
  final HostUserRow host;

  const EditHostDialog({
    super.key,
    required this.controller,
    required this.host,
  });

  @override
  State<EditHostDialog> createState() => _EditHostDialogState();
}

class _EditHostDialogState extends State<EditHostDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;

  String? _selectedCountry;
  bool _isDisabled = false;
  bool _isSubmitting = false;
  String? _errorText;

  OutlineInputBorder get _border => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
      );

  OutlineInputBorder get _focusedBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.6),
      );

  InputDecoration _decoration({
    required String hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      border: _border,
      enabledBorder: _border,
      focusedBorder: _focusedBorder,
      errorBorder: _border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: _border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  void initState() {
    super.initState();

    _nameCtrl = TextEditingController(text: widget.host.name ?? '');
    _emailCtrl = TextEditingController(text: widget.host.email); // read-only
    _addressCtrl = TextEditingController(text: widget.host.address ?? '');

    _selectedCountry =
        (widget.host.country ?? '').trim().isEmpty ? null : widget.host.country;

    _isDisabled = widget.host.isDisabled;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_isSubmitting) return;

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      setState(() => _errorText = 'Please fix validation errors');
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    try {
      await widget.controller.updateHostProfile(
        hostUid: widget.host.userId,
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        country: (_selectedCountry ?? '').trim(),
        isDisabled: _isDisabled,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString().replaceFirst('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      backgroundColor: const Color(0xFFF3F4F6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
                child: Column(
                  children: [
                    const Icon(Icons.edit, size: 28),
                    const SizedBox(height: 10),
                    Text(
                      'Edit Host',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Update the host information below.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Full Name *'),
                          TextFormField(
                            controller: _nameCtrl,
                            enabled: !_isSubmitting,
                            textCapitalization: TextCapitalization.words,
                            decoration: _decoration(
                              hintText: 'Enter host full name',
                              prefixIcon:
                                  const Icon(Icons.person_outline, size: 18),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          _label('Email Address'),
                          TextFormField(
                            controller: _emailCtrl,
                            enabled: false,
                            decoration: _decoration(
                              hintText: 'Email',
                              prefixIcon:
                                  const Icon(Icons.email_outlined, size: 18),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _label('Address (Optional)'),
                          TextFormField(
                            controller: _addressCtrl,
                            enabled: !_isSubmitting,
                            decoration: _decoration(
                              hintText: 'Enter street address',
                              prefixIcon: const Icon(Icons.location_on_outlined,
                                  size: 18),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _label('Country *'),
                          DropdownButtonFormField<String>(
                            value: _selectedCountry,
                            decoration: _decoration(
                              hintText: 'Select country',
                              prefixIcon: const Icon(Icons.public, size: 18),
                            ),
                            items: USData.countries
                                .map((c) =>
                                    DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: _isSubmitting
                                ? null
                                : (v) => setState(() => _selectedCountry = v),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Country is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Text(
                                'Status',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Switch.adaptive(
                                value: !_isDisabled,
                                onChanged: _isSubmitting
                                    ? null
                                    : (val) =>
                                        setState(() => _isDisabled = !val),
                              ),
                              const Spacer(),
                              Text(
                                _isDisabled ? 'Disabled' : 'Enabled',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (_errorText != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _errorText!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _onSave,
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Text('Save Changes'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, size: 24),
                tooltip: 'Close',
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(false),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.grey.shade700,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style:
                GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      );
}
