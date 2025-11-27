import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/controller/admin_controllers/question_sets_controller.dart';
import 'package:traxx_wepapp/models/question_set.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    super.dispose();
  }

  Future<void> _createSet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final setId = await _controller.createQuestionSet(
        title: _titleCtrl.text.trim(),
        celebrationType: _celebrationType,
      );

      if (!mounted) return;

      // After creating, open the questions page for that set
      final encodedTitle = Uri.encodeComponent(_titleCtrl.text.trim().isEmpty
          ? 'Question set'
          : _titleCtrl.text.trim());

      context.go(
        '${AppRoute.hostQuestions.path}?setId=$setId&setTitle=$encodedTitle',
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
    return Container(
      color: _gfBackground,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Question Sets',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: _gfTextColor,
                  ),
                ),
                const SizedBox(height: 16),

                // CREATE SET CARD
                Card(
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
                          const Text(
                            'Create a new question set',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _gfTextColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Question set title',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _gfTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _titleCtrl,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Questions for birthday dinner',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter a title'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Celebration type',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _gfTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: _celebrationType,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
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
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _celebrationType = v);
                              }
                            },
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
                                  : const Text(
                                      'Create & open',
                                      style: TextStyle(
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

                const Text(
                  'Existing question sets',
                  style: TextStyle(
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

                      // 🔹 Print full Firestore error and index link in debug console
                      if (kDebugMode) {
                        if (err is FirebaseException) {
                          debugPrint(
                              '🔥 QuestionSets Firestore error: ${err.code} – ${err.message}');
                          debugPrint('🔥 Full error object: $err');
                        } else {
                          debugPrint('🔥 QuestionSets unknown error: $err');
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Failed to load question sets: $err',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final sets = snapshot.data ?? [];
                    if (sets.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No question sets created yet.',
                          style: TextStyle(
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
                              context.go(
                                '${AppRoute.hostQuestions.path}?setId=${set.id}&setTitle=$encodedTitle',
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
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _gfTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      set.celebrationType,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${created.day}/${created.month}/${created.year}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
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
