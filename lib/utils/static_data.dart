import 'package:traxx_wepapp/utils/enums/input_type.dart';

class StaticData {
  static const Map<String, Map<String, InputType>> guestProfileFields = {
    'Personal Info': {
      'First Name': InputType.text,
      'Last Name': InputType.text,
      'Date of Birth': InputType.date,
      'Phone Number': InputType.number,
      'Address': InputType.text,
      'City': InputType.text,
      'State': InputType.text,
      'Country': InputType.text,
      'Zip Code': InputType.text,
    },
    'Diet Info': {
      'Vegan': InputType.yesno,
      'Vegetarian': InputType.yesno,
    }
  };

  static const List<String> eventTypes = [
    'Wedding Reception',
    'Birthday Party',
    'Engagement Party',
    'Anniversary Celebration',
    'Graduation Party',
    'Baby Shower',
    'Bridal Shower',
    'Retirement Party',
    'Corporate Dinner',
    'Holiday Party',
    'Farewell Party',
    'Welcome Party',
    'Reunion',
    'Romantic Dinner',
    'Family Gathering',
    'Religious Celebration',
    'Banquet',
    'VIP Dinner',
    'Product Launch Dinner',
    'Networking Dinner',
    'Themed Party',
    'Surprise Party',
    'Prom Night Dinner',
    'Gala Dinner',
    'Charity Dinner',
  ];

  static const List<String> timezones = [
    'UTC',
    'UTC+1',
    'UTC+2',
    'UTC+3',
    'UTC+4',
    'UTC+5',
    'UTC-5',
    'UTC-4',
    'UTC-8',
  ];
}
