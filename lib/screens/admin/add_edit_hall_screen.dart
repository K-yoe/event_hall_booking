import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/db_service.dart';

class AddEditHallScreen extends StatefulWidget {
  const AddEditHallScreen({super.key});
  @override
  State<AddEditHallScreen> createState() => _AddEditHallScreenState();
}

class _AddEditHallScreenState extends State<AddEditHallScreen> {
  final _nameCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _pricePerDayCtrl = TextEditingController();
  final _pricePerHrCtrl = TextEditingController();
  String _selectedType = 'Event Hall';
  bool _loading = false;
  final _allAmenities = ['📽 Projector', '🎤 PA System', '❄️ AC', '🅿️ Parking', '☕ Catering', '🌐 WiFi', '📺 TV Screen', '💻 Computers'];
  final Set<String> _selectedAmenities = {'📽 Projector', '❄️ AC'};
  final _types = ['Event Hall', 'Conference', 'Training', 'Banquet'];
  final _db = DbService();

  bool _isEdit = false;
  bool _argsLoaded = false;
  String? _id;
  Map<String, dynamic> _existing = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && !_argsLoaded) {
      _argsLoaded = true;
      _isEdit = true;
      _existing = args;
      _id = (args['id'] ?? '').toString();
      _nameCtrl.text = (args['name'] ?? '').toString();
      _capacityCtrl.text = (args['capacity'] ?? '').toString();
      _locationCtrl.text = (args['location'] ?? '').toString();
      _descCtrl.text = (args['description'] ?? '').toString();
      _selectedType = (args['type'] ?? 'Event Hall').toString();
      final perDay = args['price_per_day'];
      final perHr = args['price_per_hr'];
      if (perDay is num && perDay > 0) _pricePerDayCtrl.text = perDay.toStringAsFixed(0);
      if (perHr is num && perHr > 0) _pricePerHrCtrl.text = perHr.toStringAsFixed(0);
      final amenities = args['amenities'];
      if (amenities is List && amenities.isNotEmpty) {
        _selectedAmenities
          ..clear()
          ..addAll(amenities.map((a) => a.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Hall' : 'Add Hall'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _imageUploadBox(),
          const SizedBox(height: 16),
          _field('Hall name *', 'e.g. Grand Ballroom A', _nameCtrl),
          const SizedBox(height: 14),
          const Text('Hall type *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          _typeSelector(),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _field('Capacity (pax) *', 'e.g. 500', _capacityCtrl, keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 14),
          _field('Location / address *', 'e.g. KL Sentral, Kuala Lumpur', _locationCtrl),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _field('Price per day (RM)', 'e.g. 2500', _pricePerDayCtrl, keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _field('Price per hour (RM)', 'e.g. 350', _pricePerHrCtrl, keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 14),
          const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Describe the hall, its features, and ideal use cases...'),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Amenities'),
          Wrap(
            children: _allAmenities.map((a) {
              final sel = _selectedAmenities.contains(a);
              return GestureDetector(
                onTap: () => setState(() => sel ? _selectedAmenities.remove(a) : _selectedAmenities.add(a)),
                child: Container(
                  margin: const EdgeInsets.only(right: 8, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.primaryLight : Colors.white,
                    border: Border.all(color: sel ? AppTheme.primary : AppTheme.cardBorder, width: sel ? 1.5 : 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(a, style: TextStyle(fontSize: 12, color: sel ? AppTheme.primary : AppTheme.textSecondary, fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_isEdit ? 'Update Hall' : 'Save Hall'),
          ),
          if (_isEdit) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _imageUploadBox() => GestureDetector(
        onTap: () {},
        child: Container(
          height: 120, width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            border: Border.all(color: AppTheme.primary, width: 1.5, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppTheme.primary),
            const SizedBox(height: 8),
            const Text('Upload hall images', style: TextStyle(fontSize: 14, color: AppTheme.primary, fontWeight: FontWeight.w500)),
            const Text('JPG, PNG up to 5MB each', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ]),
        ),
      );

  Widget _typeSelector() => Row(
        children: _types.map((t) {
          final sel = _selectedType == t;
          return Expanded(child: GestureDetector(
            onTap: () => setState(() => _selectedType = t),
            child: Container(
              margin: EdgeInsets.only(right: t != _types.last ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppTheme.primary : Colors.white,
                border: Border.all(color: sel ? AppTheme.primary : AppTheme.cardBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(t,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: sel ? Colors.white : AppTheme.textSecondary)),
            ),
          ));
        }).toList(),
      );

  Widget _field(String label, String hint, TextEditingController ctrl,
      {TextInputType keyboardType = TextInputType.text}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(controller: ctrl, keyboardType: keyboardType, decoration: InputDecoration(hintText: hint)),
      ]);

  void _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hall name is required')));
      return;
    }
    if (_locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location is required')));
      return;
    }
    final perDay = double.tryParse(_pricePerDayCtrl.text.trim()) ?? 0.0;
    final perHr = double.tryParse(_pricePerHrCtrl.text.trim()) ?? 0.0;
    if (perDay <= 0 && perHr <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a price per day or per hour')));
      return;
    }
    final priceLabel = perDay > 0
        ? 'RM ${perDay.toStringAsFixed(0)}/day'
        : 'RM ${perHr.toStringAsFixed(0)}/hr';

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'type': _selectedType,
      'location': _locationCtrl.text.trim(),
      'capacity': int.tryParse(_capacityCtrl.text.trim()) ?? 0,
      'rating': _existing['rating'] ?? 0.0,
      'reviewCount': _existing['reviewCount'] ?? 0,
      'price_per_day': perDay,
      'price_per_hr': perHr,
      'price': priceLabel,
      'status': _existing['status'] ?? 'Available',
      'statusType': _existing['statusType'] ?? 'success',
      'isActive': true,
      'amenities': _selectedAmenities.toList(),
      'description': _descCtrl.text.trim(),
      'image_url': _existing['image_url'] ?? '',
    };

    setState(() => _loading = true);
    final ok = _isEdit && (_id ?? '').isNotEmpty
        ? await _db.updateHall(_id!, data)
        : await _db.addHall(data);
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? (_isEdit ? 'Hall updated successfully' : 'Hall added successfully')
            : 'Failed to save hall'),
        backgroundColor: ok ? AppTheme.success : AppTheme.danger));
    if (ok) Navigator.pop(context);
  }
}
