// lib/view/admin/questions/question_sets_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/admin_controllers/question_sets_controller.dart';
import 'package:traxx_wepapp/models/question_set.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';

const Color _gfPurple = Color(0xFF673AB7);
const Color _gfBackground = Color(0xFFF4F0FB);
const Color _gfTextColor = Color(0xFF202124);

class QuestionSetsScreen extends StatefulWidget {
  const QuestionSetsScreen({super.key});

  @override
  State<QuestionSetsScreen> createState() => _QuestionSetsScreenState();
}

class _QuestionSetsScreenState extends State<QuestionSetsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController(); // NEW
  String _celebrationType = 'Birthday';

  bool _isSaving = false;
  late final QuestionSetsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QuestionSetsController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _createSet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final title = _titleCtrl.text.trim();
      final description = _descriptionCtrl.text.trim();

      final setId = await _controller.createQuestionSet(
        title: title,
        celebrationType: _celebrationType,
        description: description,
      );

      if (!mounted) return;

      final uri = Uri(
        path: AppRoute.hostQuestions.path,
        queryParameters: {
          'setId': setId,
          'setTitle': title.isEmpty ? 'Question set' : title,
          'setDescription': description,
        },
      );

      context.go(uri.toString());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create question set: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isPhone = w < 600;

    final horizontalPad = isPhone ? 16.0 : 40.0;
    final topPad = isPhone ? 16.0 : 24.0;
    final bottomPad = isPhone ? 24.0 : 40.0;

    // Slightly narrower on phone
    final maxWidth = isPhone ? 560.0 : 960.0;

    InputDecoration fieldDeco(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.black.withOpacity(0.18), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.black.withOpacity(0.18), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _gfPurple.withOpacity(0.9), width: 1.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: Colors.white,
      );
    }

    TextStyle labelStyle() => GoogleFonts.poppins(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: _gfTextColor,
        );

    return DefaultTextStyle(
      style: GoogleFonts.poppins(),
      child: Container(
        color: Colors.transparent,
        width: double.infinity,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              horizontalPad, topPad, horizontalPad, bottomPad),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtitle (responsive)
                  Text(
                    'Create and manage question sets to gather important information from your event guests.',
                    style: GoogleFonts.poppins(
                      fontSize: isPhone ? 16 : 22,
                      fontWeight: FontWeight.w600,
                      color: _gfTextColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ✅ Create Set Card (responsive + modern)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isPhone ? 14 : 20,
                        isPhone ? 16 : 20,
                        isPhone ? 14 : 20,
                        isPhone ? 14 : 16,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create a new question set',
                              style: GoogleFonts.poppins(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: _gfTextColor,
                              ),
                            ),
                            const SizedBox(height: 14),

                            Text('Question set title', style: labelStyle()),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _titleCtrl,
                              decoration: fieldDeco(
                                  'e.g. Questions for birthday dinner'),
                              style: GoogleFonts.poppins(fontSize: 14),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Please enter a title'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            // ✅ On phone: dropdown stacked. On wide: row layout.
                            LayoutBuilder(
                              builder: (context, c) {
                                final stack = c.maxWidth < 520;

                                final celebration = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Celebration type',
                                        style: labelStyle()),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      initialValue: _celebrationType,
                                      isExpanded: true,
                                      decoration: fieldDeco(''),
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'Birthday',
                                            child: Text('Birthday')),
                                        DropdownMenuItem(
                                            value: 'Wedding',
                                            child: Text('Wedding')),
                                        DropdownMenuItem(
                                            value: 'Engagement',
                                            child: Text('Engagement')),
                                        DropdownMenuItem(
                                            value: 'Anniversary',
                                            child: Text('Anniversary')),
                                        DropdownMenuItem(
                                            value: 'Baby shower',
                                            child: Text('Baby shower')),
                                        DropdownMenuItem(
                                            value: 'Ceremony',
                                            child: Text('Ceremony / Function')),
                                        DropdownMenuItem(
                                            value: 'Other',
                                            child: Text('Other')),
                                      ],
                                      style: GoogleFonts.poppins(
                                          fontSize: 14, color: _gfTextColor),
                                      onChanged: (v) {
                                        if (v != null)
                                          setState(() => _celebrationType = v);
                                      },
                                    ),
                                  ],
                                );

                                if (stack) return celebration;

                                return celebration; // (only one field here, keep simple)
                              },
                            ),

                            const SizedBox(height: 14),

                            Text('Short description (optional)',
                                style: labelStyle()),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _descriptionCtrl,
                              maxLines: isPhone ? 2 : 2,
                              decoration: fieldDeco(
                                'e.g. Questions we will ask all guests at the reception',
                              ),
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),

                            const SizedBox(height: 16),

                            // ✅ Buttons: full width on phone
                            Align(
                              alignment: isPhone
                                  ? Alignment.center
                                  : Alignment.centerRight,
                              child: SizedBox(
                                width: isPhone ? double.infinity : null,
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _createSet,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _gfPurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(
                                                Colors.white),
                                          ),
                                        )
                                      : Text(
                                          'Create & open',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Existing question sets',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _gfTextColor,
                    ),
                  ),
                  const SizedBox(height: 10),

                  StreamBuilder<List<QuestionSet>>(
                    stream: _controller.streamQuestionSets(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: _gfPurple,
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        final err = snapshot.error;
                        if (kDebugMode)
                          debugPrint('🔥 QuestionSets error: $err');

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Failed to load question sets: $err',
                            style: GoogleFonts.poppins(color: Colors.red),
                          ),
                        );
                      }

                      final sets = snapshot.data ?? [];
                      if (sets.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No question sets created yet.',
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: Colors.black54),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          for (final set in sets)
                            _QuestionSetTile(
                              set: set,
                              onTap: () =>
                                  context.go('/host-question-sets/${set.id}'),
                              isPhone: isPhone,
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionSetTile extends StatelessWidget {
  final QuestionSet set;
  final VoidCallback onTap;
  final bool isPhone;

  const _QuestionSetTile({
    required this.set,
    required this.onTap,
    required this.isPhone,
  });

  @override
  Widget build(BuildContext context) {
    final created = set.createdDate ?? DateTime.now();
    final dateText = '${created.day}/${created.month}/${created.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isPhone ? 14 : 16,
            vertical: isPhone ? 12 : 14,
          ),
          child: Row(
            children: [
              // Left content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      set.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: isPhone ? 14.5 : 15,
                        fontWeight: FontWeight.w700,
                        color: _gfTextColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      set.celebrationType,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    if (set.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        set.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Right meta
              if (!isPhone) ...[
                const SizedBox(width: 12),
                Text(
                  dateText,
                  style:
                      GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                ),
              ],

              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}
