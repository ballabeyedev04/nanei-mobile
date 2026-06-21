import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nanei/core/theme/app_color.dart';
import '../cubit/avis_cubit.dart';
import '../cubit/avis_state.dart';

Future<void> showRatingDialog(
    BuildContext context, String colisId, AvisCubit cubit) {
  return showDialog(
    context: context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _RatingDialog(colisId: colisId),
    ),
  );
}

class _RatingDialog extends StatefulWidget {
  final String colisId;
  const _RatingDialog({required this.colisId});

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _note = 0;
  final _commentaireCtrl = TextEditingController();

  @override
  void dispose() {
    _commentaireCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AvisCubit, AvisState>(
      listener: (context, state) {
        if (state is AvisEnvoye) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Merci pour votre avis !')),
          );
        }
        if (state is AvisError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final loading = state is AvisEnvoi;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              const Icon(Icons.star_rounded,
                  color: Color(0xFFFFB800), size: 40),
              const SizedBox(height: 8),
              Text(
                'Notez votre expérience',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800, fontSize: 17),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Comment s\'est passée votre livraison ?',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: AppColor.kGrayscale40),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Étoiles cliquables
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => _note = i + 1),
                    child: Icon(
                      i < _note ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 40,
                      color: const Color(0xFFFFB800),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentaireCtrl,
                maxLines: 3,
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Commentaire (optionnel)',
                  hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: AppColor.kGrayscale40),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFE5E9F2))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFE5E9F2))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFFFF7A00), width: 1.5)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: loading
                  ? null
                  : () => Navigator.of(context).pop(),
              child: Text('Plus tard',
                  style: GoogleFonts.plusJakartaSans(
                      color: AppColor.kGrayscale40)),
            ),
            ElevatedButton(
              onPressed: loading || _note == 0
                  ? null
                  : () => context.read<AvisCubit>().donnerAvis(
                        colisId: widget.colisId,
                        note: _note,
                        commentaire: _commentaireCtrl.text.trim().isEmpty
                            ? null
                            : _commentaireCtrl.text.trim(),
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Envoyer',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }
}
