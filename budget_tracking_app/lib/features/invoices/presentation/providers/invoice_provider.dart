import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/invoice.dart';
import '../../domain/models/invoice_settings.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../my_account/presentation/providers/profile_provider.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  final profile = ref.watch(profileProvider);
  return InvoiceRepository(user?.uid ?? 'guest',
      profileType: profile.profileType.index);
});

class InvoiceNotifier extends StateNotifier<AsyncValue<List<Invoice>>> {
  final InvoiceRepository _repository;

  InvoiceNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadInvoices();
  }

  Future<void> loadInvoices() async {
    state = const AsyncValue.loading();
    try {
      final invoices = await _repository.getInvoices();
      if (!mounted) return;
      state = AsyncValue.data(invoices);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveInvoice(Invoice invoice) async {
    try {
      await _repository.saveInvoice(invoice);
      if (!mounted) return;
      await loadInvoices();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteInvoice(String id) async {
    try {
      await _repository.deleteInvoice(id);
      if (!mounted) return;
      await loadInvoices();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleStatus(Invoice invoice) async {
    try {
      final newStatus = invoice.status == InvoiceStatus.paid
          ? InvoiceStatus.unpaid
          : InvoiceStatus.paid;
      await _repository.updateInvoiceStatus(invoice.id, newStatus);
      if (!mounted) return;
      await loadInvoices();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }
}

final invoicesProvider =
    StateNotifierProvider<InvoiceNotifier, AsyncValue<List<Invoice>>>((ref) {
  final repo = ref.watch(invoiceRepositoryProvider);
  return InvoiceNotifier(repo);
});

// For managing the current invoice being created
final currentInvoiceProvider = StateProvider<Invoice?>((ref) => null);

class InvoiceSettingsNotifier
    extends StateNotifier<AsyncValue<InvoiceSettings>> {
  final InvoiceRepository _repository;

  InvoiceSettingsNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _repository.getSettings();
      if (!mounted) return;
      state = AsyncValue.data(settings);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSettings(InvoiceSettings settings) async {
    try {
      await _repository.updateSettings(settings);
      if (!mounted) return;
      state = AsyncValue.data(settings);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }
}

final invoiceSettingsProvider =
    StateNotifierProvider<InvoiceSettingsNotifier, AsyncValue<InvoiceSettings>>(
        (ref) {
  final repo = ref.watch(invoiceRepositoryProvider);
  return InvoiceSettingsNotifier(repo);
});
