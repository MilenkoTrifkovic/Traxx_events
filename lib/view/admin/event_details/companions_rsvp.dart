import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/response_flow_helper.dart';

class CompanionRsvpPage extends StatefulWidget {
  final String invitationId;
  final String token;
  final int companionIndex;

  const CompanionRsvpPage({
    super.key,
    required this.invitationId,
    required this.token,
    required this.companionIndex,
  });

  @override
  State<CompanionRsvpPage> createState() => _CompanionRsvpPageState();
}

class _CompanionRsvpPageState extends State<CompanionRsvpPage> {
  bool _submitting = false;
  String? _error;

  Future<void> _submit(bool attending) async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final fn =
          FirebaseFunctions.instance.httpsCallable("submitCompanionAttendance");
      await fn.call({
        "invitationId": widget.invitationId,
        "token": widget.token,
        "companionIndex": widget.companionIndex,
        "isAttending": attending,
      });

      if (!mounted) return;

      if (!attending) {
        context.go(
          '${AppRoute.guestResponse.path}?invitationId=${Uri.encodeComponent(widget.invitationId)}'
          '&token=${Uri.encodeComponent(widget.token)}'
          '&view=details',
        );
        return;
      }

// ✅ attending=true → go to the next step based on latest invitation state
      final snap = await FirebaseFirestore.instance
          .collection('invitations')
          .doc(widget.invitationId)
          .get();

      final data = snap.data();
      if (data == null) {
        context.go(
          '${AppRoute.guestResponse.path}?invitationId=${Uri.encodeComponent(widget.invitationId)}'
          '&token=${Uri.encodeComponent(widget.token)}',
        );
        return;
      }

      final flow = ResponseFlowState.fromInvitation(
        data,
        widget.token,
        invitationIdOverride: widget.invitationId,
      );

      final next = flow.getNextStep();
      context.go(next.buildUrl(widget.invitationId, widget.token));
    } on FirebaseFunctionsException catch (e) {
      setState(() => _error = e.message ?? "Failed to submit");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Will you attend the event?",
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitting ? null : () => _submit(true),
                          child: _submitting
                              ? const CircularProgressIndicator()
                              : const Text("Yes"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting ? null : () => _submit(false),
                          child: const Text("No"),
                        ),
                      ),
                    ],
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
