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

      final encodedTitle =
          Uri.encodeComponent(title.isEmpty ? 'Question set' : title);
      final encodedDescription = Uri.encodeComponent(description);

      context.go(
        '${AppRoute.hostQuestions.path}?setId=$setId'
        '&setTitle=$encodedTitle'
        '&setDescription=$encodedDescription',
      );
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
    return DefaultTextStyle(
      // Force Poppins for everything on this page
      style: GoogleFonts.poppins(),
      child: Container(
        color: Colors
            .transparent, // ContentWrapper already painted the lavender background
        width: double.infinity,
        child: Center(
          // Center the content column
          child: ConstrainedBox(
            // 🔹 Reduce width of content on this page only
            constraints: const BoxConstraints(maxWidth: 960),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🚫 REMOVE this duplicate big heading – header bar already shows it
                  // Text(
                  //   'Demographic Questions',
                  //   style: GoogleFonts.poppins(
                  //     fontSize: 28,
                  //     fontWeight: FontWeight.w700,
                  //     color: _gfTextColor,
                  //   ),
                  // ),
                  // const SizedBox(height: 16),

                  Text(
                    'Create and manage question sets to gather important information from your event guests.',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: _gfTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CREATE SET CARD – pure white
                  Card(
                    color: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: AppColors.borderSubtle),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create a new question set',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _gfTextColor,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Title label
                            Text(
                              'Question set title',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _gfTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Title field – darker outline
                            TextFormField(
                              controller: _titleCtrl,
                              decoration: InputDecoration(
                                hintText: 'e.g. Questions for birthday dinner',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: Colors.black.withOpacity(0.45),
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: Colors.black.withOpacity(0.45),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(4),
                                  ),
                                  borderSide: BorderSide(
                                    color: Colors.black,
                                    width: 1.3,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              style: GoogleFonts.poppins(fontSize: 14),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Please enter a title'
                                  : null,
                            ),
                            const SizedBox(height: 12),

                            // Celebration type label
                            Text(
                              'Celebration type',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _gfTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Celebration type dropdown – same darker border
                            DropdownButtonFormField<String>(
                              initialValue: _celebrationType,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: Colors.black.withOpacity(0.45),
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: Colors.black.withOpacity(0.45),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(4)),
                                  borderSide: BorderSide(
                                    color: Colors.black,
                                    width: 1.3,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Birthday',
                                  child: Text('Birthday'),
                                ),
                                DropdownMenuItem(
                                  value: 'Wedding',
                                  child: Text('Wedding'),
                                ),
                                DropdownMenuItem(
                                  value: 'Engagement',
                                  child: Text('Engagement'),
                                ),
                                DropdownMenuItem(
                                  value: 'Anniversary',
                                  child: Text('Anniversary'),
                                ),
                                DropdownMenuItem(
                                  value: 'Baby shower',
                                  child: Text('Baby shower'),
                                ),
                                DropdownMenuItem(
                                  value: 'Ceremony',
                                  child: Text('Ceremony / Function'),
                                ),
                                DropdownMenuItem(
                                  value: 'Other',
                                  child: Text('Other'),
                                ),
                              ],
                              style: GoogleFonts.poppins(fontSize: 14),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _celebrationType = v);
                                }
                              },
                            ),
                            const SizedBox(height: 12),

                            // Description
                            Text(
                              'Short description (optional)',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _gfTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _descriptionCtrl,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText:
                                    'e.g. Questions we will ask all guests at the reception',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: Colors.black.withOpacity(0.45),
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: Colors.black.withOpacity(0.45),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(4)),
                                  borderSide: BorderSide(
                                    color: Colors.black,
                                    width: 1.3,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            const SizedBox(height: 16),

                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _createSet,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _gfPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
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
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Existing question sets',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _gfTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),

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
                        if (kDebugMode) {
                          debugPrint('🔥 QuestionSets error: $err');
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Failed to load question sets: $err',
                            style: GoogleFonts.poppins(
                              color: Colors.red,
                            ),
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
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          for (final set in sets)
                            _QuestionSetTile(
                              set: set,
                              onTap: () {
                                final encodedTitle =
                                    Uri.encodeComponent(set.title);
                                final encodedDescription =
                                    Uri.encodeComponent(set.description);
                                context.go(
                                  '${AppRoute.hostQuestions.path}'
                                  '?setId=${set.id}'
                                  '&setTitle=$encodedTitle'
                                  '&setDescription=$encodedDescription',
                                );
                              },
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

  const _QuestionSetTile({
    required this.set,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final created = set.createdDate ?? DateTime.now();

    return Card(
      color: Colors.white, // ✅ ensure white background
      elevation: 0,
      margin:
          const EdgeInsets.only(bottom: 12), // ✅ a bit more space between items
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.borderSubtle),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      set.title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _gfTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      set.celebrationType,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    if (set.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
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
              const SizedBox(width: 12),
              Text(
                '${created.day}/${created.month}/${created.year}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
