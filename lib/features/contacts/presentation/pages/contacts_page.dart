import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nanei/core/theme/app_color.dart';
import '../../domain/entities/contact_favori.dart';
import '../cubit/contacts_cubit.dart';
import '../cubit/contacts_state.dart';
import 'ajouter_contact_page.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ContactsCubit>().loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          'Mes contacts',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFFFF7A00)),
            onPressed: _ouvrirAjout,
            tooltip: 'Ajouter un contact',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColor.kPrimary,
        onPressed: _ouvrirAjout,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
      body: BlocBuilder<ContactsCubit, ContactsState>(
        builder: (context, state) {
          if (state is ContactsLoading) {
            return const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFFFF7A00)),
            );
          }
          if (state is ContactsError) {
            return _buildError(state.message);
          }
          if (state is ContactsLoaded) {
            if (state.contacts.isEmpty) {
              return _buildEmpty();
            }
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<ContactsCubit>().loadContacts(),
              color: AppColor.kPrimary,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: state.contacts.length,
                itemBuilder: (_, i) =>
                    _buildContactItem(state.contacts[i]),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContactItem(ContactFavori contact) {
    return Dismissible(
      key: Key(contact.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
      ),
      confirmDismiss: (direction) async {
        return await _confirmSupprimer(context);
      },
      onDismissed: (_) async {
        await context.read<ContactsCubit>().supprimerContact(contact.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: AppColor.kPrimary.withValues(alpha: 0.15),
            child: Text(
              contact.initiales,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColor.kPrimary,
              ),
            ),
          ),
          title: Text(
            contact.nomComplet,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColor.kGrayscaleDark100,
            ),
          ),
          subtitle: Text(
            contact.telephone,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColor.kGrayscale40,
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded,
              color: Color(0xFFD1D5DB)),
        ),
      ),
    );
  }

  Future<bool?> _confirmSupprimer(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Supprimer ce contact ?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('Cette action est irréversible.',
            style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.contacts_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Aucun contact favori',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColor.kGrayscale40),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur + pour en ajouter un',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: AppColor.kGrayscale40),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(msg,
              style: GoogleFonts.plusJakartaSans(color: AppColor.kGrayscale40)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<ContactsCubit>().loadContacts(),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Future<void> _ouvrirAjout() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<ContactsCubit>(),
        child: const AjouterContactPage(),
      ),
    ));
  }
}
