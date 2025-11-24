import 'package:flutter/material.dart';
import 'package:traxx_wepapp/utils/enums/date_time_input_type.dart';
import 'package:traxx_wepapp/widgets/app_date_time_input_field.dart';

/// Example usage of AppDateTimeInputField widget
class DateTimeInputExample extends StatefulWidget {
  const DateTimeInputExample({super.key});

  @override
  State<DateTimeInputExample> createState() => _DateTimeInputExampleState();
}

class _DateTimeInputExampleState extends State<DateTimeInputExample> {
  DateTime? _selectedDateTime;
  DateTime? _selectedDate;
  DateTime? _selectedTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DateTime Input Examples')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DateTime example
            AppDateTimeInputField(
              label: 'Event DateTime',
              inputType: DateTimeInputType.dateTime,
              selectedDateTime: _selectedDateTime,
              hintText: 'Select event date and time',
              onChanged: (dateTime) {
                setState(() {
                  _selectedDateTime = dateTime;
                });
              },
              validator: (dateTime) {
                if (dateTime == null) {
                  return 'Please select a date and time';
                }
                if (dateTime.isBefore(DateTime.now())) {
                  return 'Please select a future date';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Date only example
            AppDateTimeInputField(
              label: 'Birth Date',
              inputType: DateTimeInputType.dateOnly,
              selectedDateTime: _selectedDate,
              lastDate: DateTime.now(),
              onChanged: (dateTime) {
                setState(() {
                  _selectedDate = dateTime;
                });
              },
            ),

            const SizedBox(height: 24),

            // Time only example
            AppDateTimeInputField(
              label: 'Meeting Time',
              inputType: DateTimeInputType.timeOnly,
              selectedDateTime: _selectedTime,
              initialTime: const TimeOfDay(hour: 9, minute: 0),
              onChanged: (dateTime) {
                setState(() {
                  _selectedTime = dateTime;
                });
              },
            ),

            const SizedBox(height: 32),

            // Display selected values
            if (_selectedDateTime != null)
              Text('Selected DateTime: $_selectedDateTime'),
            if (_selectedDate != null) Text('Selected Date: $_selectedDate'),
            if (_selectedTime != null) Text('Selected Time: $_selectedTime'),
          ],
        ),
      ),
    );
  }
}
