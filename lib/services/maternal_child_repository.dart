import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/maternal_pregnancy_model.dart';
import '../models/maternal_anc_model.dart';
import '../models/child_illness_model.dart';

class MaternalChildRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- MATERNAL PREGNANCY ---
  Future<List<MaternalPregnancyModel>> getPregnancies(String profileId) async {
    final response = await _supabase
        .from('maternal_pregnancies')
        .select()
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((item) => MaternalPregnancyModel.fromJson(item))
        .toList();
  }

  Future<void> addPregnancy(MaternalPregnancyModel pregnancy) async {
    await _supabase.from('maternal_pregnancies').insert(pregnancy.toJson());
  }

  // --- ANC RECORDS ---
  Future<List<MaternalAncModel>> getAncRecords(String pregnancyId) async {
    final response = await _supabase
        .from('maternal_anc_records')
        .select()
        .eq('pregnancy_id', pregnancyId)
        .order('visit_date', ascending: false);

    return (response as List)
        .map((item) => MaternalAncModel.fromJson(item))
        .toList();
  }

  Future<void> addAncRecord(MaternalAncModel ancRecord) async {
    await _supabase.from('maternal_anc_records').insert(ancRecord.toJson());
  }

  // --- CHILD ILLNESS LOGS ---
  Future<List<ChildIllnessModel>> getChildIllnesses(String childId) async {
    final response = await _supabase
        .from('child_illness_logs')
        .select()
        .eq('child_id', childId)
        .order('recorded_date', ascending: false);

    return (response as List)
        .map((item) => ChildIllnessModel.fromJson(item))
        .toList();
  }

  Future<void> addChildIllness(ChildIllnessModel illnessLog) async {
    await _supabase.from('child_illness_logs').insert(illnessLog.toJson());
  }
}