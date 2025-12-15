import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DemographicResponsePage extends StatefulWidget {
  final String invitationId;
  const DemographicResponsePage({super.key, required this.invitationId});

  @override
  State<DemographicResponsePage> createState() =>
      _DemographicResponsePageState();
}

class _DemographicResponsePageState extends State<DemographicResponsePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool loading = true;
  Map<String, dynamic>? invitation;
  Map<String, dynamic>? questionSet;
  List<Map<String, dynamic>> questions = [];
  final Map<String, dynamic> answers = {}; // questionId -> value

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final invDoc =
        await _db.collection('invitations').doc(widget.invitationId).get();
    if (!invDoc.exists) {
      setState(() {
        loading = false;
        invitation = null;
      });
      return;
    }
    invitation = invDoc.data();

    // Optional: if your link carries token param, validate it
    final uri = Uri
        .base; // If running as web; on mobile you'll pass token as param to page
    final tokenFromLink = uri.queryParameters['token'] ?? invitation!['token'];

    if (tokenFromLink == null || tokenFromLink != invitation!['token']) {
      // token invalid
      setState(() {
        loading = false;
        invitation = null;
      });
      return;
    }

    // check expiry
    final expiresTimestamp = invitation!['expiresAt'] as Timestamp?;
    final expires = expiresTimestamp?.toDate();
    if (expires != null && expires.isBefore(DateTime.now())) {
      setState(() {
        loading = false;
        invitation = null;
      });
      return;
    }

    if (invitation!['used'] == true) {
      setState(() {
        loading = false;
        invitation = null;
      });
      return;
    }
    // fetch event
    final eventId = invitation!['eventId'] as String?;
    if (eventId == null) {
      setState(() {
        loading = false;
      });
      return;
    }
    final eventDoc = await _db.collection('events').doc(eventId).get();
    final eventData = eventDoc.data();
    final qsId = eventData?['selectedDemographicQuestionSetId'] as String?;
    if (qsId == null) {
      setState(() {
        loading = false;
      });
      return;
    }
    // fetch question set (assume collection 'demographicQuestionSets')
    final qsDoc =
        await _db.collection('demographicQuestionSets').doc(qsId).get();
    if (!qsDoc.exists) {
      setState(() {
        loading = false;
      });
      return;
    }
    questionSet = qsDoc.data();
    questions =
        List<Map<String, dynamic>>.from(questionSet!['questions'] ?? []);
    // init empty answers depending on question type
    for (final q in questions) answers[q['id']] = null;
    setState(() {
      loading = false;
    });
  }

  Future<void> _submit() async {
    // validate (simple)
    final filled = questions.every((q) =>
        answers[q['id']] != null &&
        answers[q['id']].toString().trim().isNotEmpty);
    if (!filled) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please answer all questions')));
      return;
    }
    final respDoc = _db.collection('demographicQuestionsResponses').doc();
    await respDoc.set({
      'eventId': invitation!['eventId'],
      'organisationId': invitation!['organisationId'],
      'invitationId': widget.invitationId,
      'guestId': invitation!['guestId'],
      'guestEmail': invitation!['guestEmail'],
      'questionSetId': questionSet!['id'],
      'answers': questions
          .map((q) => {
                'questionId': q['id'],
                'type': q['type'],
                'answer': answers[q['id']]
              })
          .toList(),
      'createdAt': FieldValue.serverTimestamp()
    });
    // mark invitation used
    await _db.collection('invitations').doc(widget.invitationId).update({
      'used': true,
      'usedAt': FieldValue.serverTimestamp(),
    });
    // show success
    if (mounted) {
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                  title: const Text('Thanks'),
                  content: const Text('Your responses are submitted'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'))
                  ]));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (invitation == null)
      return const Center(child: Text('Invalid or expired invitation'));
    return Scaffold(
      appBar:
          AppBar(title: Text(questionSet?['title'] ?? 'Demographic Questions')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (_, idx) {
                  final q = questions[idx];
                  // Render based on q['type'] (text, single_choice, multi_choice)
                  if (q['type'] == 'text') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q['label'],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        TextField(onChanged: (v) => answers[q['id']] = v),
                        const SizedBox(height: 12),
                      ],
                    );
                  } else if (q['type'] == 'single_choice') {
                    final opts = List<String>.from(q['options'] ?? []);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q['label'],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        ...opts.map((opt) => RadioListTile<String>(
                              value: opt,
                              groupValue: answers[q['id']],
                              title: Text(opt),
                              onChanged: (v) =>
                                  setState(() => answers[q['id']] = v),
                            ))
                      ],
                    );
                  } else if (q['type'] == 'multi_choice') {
                    final opts = List<String>.from(q['options'] ?? []);
                    final current =
                        (answers[q['id']] ?? <String>[]) as List<String>;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q['label'],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        ...opts.map((opt) => CheckboxListTile(
                              value: current.contains(opt),
                              title: Text(opt),
                              onChanged: (v) {
                                setState(() {
                                  if (v == true)
                                    current.add(opt);
                                  else
                                    current.remove(opt);
                                  answers[q['id']] = current;
                                });
                              },
                            )),
                      ],
                    );
                  } else {
                    return const SizedBox();
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
