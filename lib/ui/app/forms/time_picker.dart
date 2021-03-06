import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/utils/formatting.dart';

class TimePicker extends StatefulWidget {
  const TimePicker({
    Key key,
    @required this.labelText,
    @required this.onSelected,
    @required this.selectedDateTime,
    @required this.selectedDate,
    this.validator,
    this.autoValidate = false,
    this.allowClearing = false,
  }) : super(key: key);

  final String labelText;
  final DateTime selectedDate;
  final DateTime selectedDateTime;
  final Function(DateTime) onSelected;
  final Function validator;
  final bool autoValidate;
  final bool allowClearing;

  @override
  _TimePickerState createState() => new _TimePickerState();
}

class _TimePickerState extends State<TimePicker> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFoucsChanged);
  }

  @override
  void didChangeDependencies() {
    if (widget.selectedDateTime != null) {
      _textController.text = formatDate(
          widget.selectedDateTime.toIso8601String(), context,
          showDate: false, showTime: true);
    }

    super.didChangeDependencies();
  }

  void _onFoucsChanged() {
    if (!_focusNode.hasFocus) {
      _textController.text = formatDate(
          widget.selectedDateTime?.toIso8601String(), context,
          showDate: false, showTime: true);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.removeListener(_onFoucsChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _showTimePicker() async {
    final selectedDateTime = widget.selectedDateTime;
    final now = DateTime.now();

    final hour = selectedDateTime?.hour ?? now.hour;
    final minute = selectedDateTime?.minute ?? now.minute;

    final TimeOfDay selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      //initialEntryMode: TimePickerEntryMode.input,
    );

    if (selectedTime != null) {
      var dateTime =
      convertTimeOfDayToDateTime(selectedTime, widget.selectedDate);

      if (widget.selectedDate != null &&
          dateTime.isBefore(widget.selectedDate)) {
        dateTime = dateTime.add(Duration(days: 1));
      }

      _textController.text = formatDate(dateTime.toIso8601String(), context,
          showTime: true, showDate: false);

      widget.onSelected(dateTime.toLocal());
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: _focusNode,
      validator: widget.validator,
      autovalidateMode: widget.autoValidate
          ? AutovalidateMode.always
          : AutovalidateMode.onUserInteraction,
      controller: _textController,
      decoration: InputDecoration(
        labelText: widget.labelText,
        suffixIcon: widget.allowClearing && widget.selectedDateTime != null
            ? IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            _textController.text = '';
            widget.onSelected(null);
          },
        )
            : IconButton(
          icon: Icon(Icons.access_time),
          onPressed: () => _showTimePicker(),
        ),
      ),
      onChanged: (value) {
        if (value.isEmpty) {
          if (widget.allowClearing) {
            widget.onSelected(null);
          }
        } else {
          final initialValue = value;
          value = value.replaceAll(RegExp('[^\\d\:]'), '');
          value = value.toLowerCase().replaceAll('.', ':');

          final parts = value.split(':');
          String dateTimeStr = '';

          if (parts.length == 1) {
            dateTimeStr = parts[0] + ':00:00';
          } else {
            dateTimeStr = parts[0] + ':' + parts[1];
            if (parts[1].length == 1) {
              dateTimeStr += '0';
            }
            if (parts.length == 3) {
              dateTimeStr += ':' + parts[2];
            } else {
              dateTimeStr += ':00';
            }
          }

          if (initialValue.contains('a')) {
            dateTimeStr += ' AM';
          } else if (initialValue.contains('p')) {
            dateTimeStr += ' PM';
          } else {
            final store = StoreProvider.of<AppState>(context);
            if (!store.state.company.settings.enableMilitaryTime) {
              final hour = parseDouble(parts[0]);
              dateTimeStr += hour > 6 ? ' AM' : ' PM';
            }
          }

          final dateTime = parseTime(dateTimeStr, context);

          if (dateTime != null) {
            final date = widget.selectedDate;
            var selectedDate = DateTime(
              date.year,
              date.month,
              date.day,
              dateTime.hour,
              dateTime.minute,
              dateTime.second,
            );
            if (selectedDate.isBefore(date)) {
              selectedDate = selectedDate.add(Duration(hours: 24));
            }
            widget.onSelected(selectedDate);
          }
        }
      },
    );
  }
}
