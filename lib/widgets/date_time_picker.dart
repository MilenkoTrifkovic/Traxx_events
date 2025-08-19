import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimePicker extends StatefulWidget {
  final String label;
  final void Function(DateTime?) onDateTimeChanged;
  final DateTime? initialDateTime;

  const DateTimePicker({
    super.key,
    required this.label,
    required this.onDateTimeChanged,
    this.initialDateTime,
  });

  @override
  State<DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<DateTimePicker> {
  final TextEditingController _controller = TextEditingController();
  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime;
    _updateDisplayText();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateDisplayText() {
    if (_selectedDateTime != null) {
      _controller.text =
          DateFormat('MMM dd, yyyy hh:mm a').format(_selectedDateTime!);
    } else {
      _controller.text = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: '${widget.label} *',
        suffixIcon: const Icon(Icons.calendar_today),
        hintText: 'Select date and time',
      ),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDateTime ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );

        if (picked != null) {
          final TimeOfDay? time = await showTimePicker(
            context: context,
            initialTime: _selectedDateTime != null
                ? TimeOfDay.fromDateTime(_selectedDateTime!)
                : TimeOfDay.now(),
          );

          if (time != null) {
            setState(() {
              _selectedDateTime = DateTime(
                picked.year,
                picked.month,
                picked.day,
                time.hour,
                time.minute,
              );
              _updateDisplayText();
            });
            widget.onDateTimeChanged(_selectedDateTime);
          }
        }
      },
      validator: (value) {
        if (_selectedDateTime == null) {
          return 'Please select a date and time';
        }
        return null;
      },
    );
  }
}
