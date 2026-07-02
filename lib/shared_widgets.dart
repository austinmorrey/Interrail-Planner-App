import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'constants.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const InfoCard({required this.title, required this.child, this.trailing, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDivider),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: kText, fontSize: 14)),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class EmptyLabel extends StatelessWidget {
  final String text;
  const EmptyLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(color: kSubtext, fontSize: 13));
}

class IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const IconBtn({required this.icon, this.onTap, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color ?? kSubtext),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: onTap,
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(color: kDivider, borderRadius: BorderRadius.circular(2)),
        ),
      ),
    );
  }
}

class CustomField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final void Function(String)? onChanged;

  const CustomField({required this.controller, required this.label, this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class CustomTimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;
  final BuildContext context;

  const CustomTimePicker({required this.label, required this.time, required this.onTap, required this.context, super.key});

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kSubtext)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: kLightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: kAccent),
                  const SizedBox(width: 10),
                  Text(
                    time?.format(ctx) ?? 'Select time',
                    style: TextStyle(color: time != null ? kText : kSubtext, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SaveButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  const SaveButton({this.label = 'Save', required this.onPressed, this.enabled = true, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kDivider,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      ),
    );
  }
}

class MarqueeTextWidget extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double maxWidth;

  const MarqueeTextWidget({required this.text, required this.style, required this.maxWidth, super.key});

  @override
  Widget build(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    return SizedBox(
      width: maxWidth,
      height: style.fontSize != null ? style.fontSize! + 8 : 22,
      child: painter.didExceedMaxLines
          ? Marquee(text: text, style: style, blankSpace: 20, velocity: 30)
          : Text(text, style: style),
    );
  }
}

class EditDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onSave;

  const EditDialog({required this.title, required this.child, required this.onSave, super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title),
      content: child,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () { onSave(); Navigator.pop(context); },
          child: const Text('Save', style: TextStyle(color: kAccent, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
