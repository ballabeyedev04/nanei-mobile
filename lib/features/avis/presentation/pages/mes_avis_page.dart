import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nanei/core/theme/app_color.dart';
import '../cubit/avis_cubit.dart';
import '../cubit/avis_state.dart';
import '../widgets/star_rating.dart';

class MesAvisPage extends StatefulWidget {
  const MesAvisPage({super.key});

  @override
  State<MesAvisPage> createState() => _MesAvisPageState();
}

class _MesAvisPageState extends State<MesAvisPage> {
  @override
  void initState() {
    super.initState();
    context.read<AvisCubit>().chargerMesAvis();
  }

  Future<void> _refresh() async {
    context.read<AvisCubit>().chargerMesAvis();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          'Mes Avis',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        backgroundColor: AppColor.kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<AvisCubit, AvisState>(
        builder: (context, state) {
          if (state is AvisChargement) {
            return const Center(
              child: CircularProgressIndicator(color: AppColor.kPrimary),
            );
          }

          if (state is AvisError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded,
                      size: 56, color: AppColor.kGrayscale20),
                  const SizedBox(height: 16),
                  Text(
                    'Impossible de charger vos avis.',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, color: AppColor.kGrayscale40),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _refresh,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColor.kPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Réessayer',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is AvisCharges) {
            final avis = state.avis;

            if (avis.isEmpty) {
              return RefreshIndicator(
                color: AppColor.kPrimary,
                onRefresh: _refresh,
                child: ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_border_rounded,
                            size: 64, color: AppColor.kGrayscale20),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun avis pour l\'instant',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColor.kGrayscale40,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Vos avis sur les livraisons apparaîtront ici.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColor.kGrayscale20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppColor.kPrimary,
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: avis.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final a = avis[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0E0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Colis #${a.colisId}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.kPrimary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            StarRating(note: a.note, size: 18),
                          ],
                        ),
                        if (a.commentaire != null &&
                            a.commentaire!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            a.commentaire!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColor.kGrayscaleDark100,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            );
          }

          // Initial / unexpected state — trigger load
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
