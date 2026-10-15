import 'package:flutter/material.dart';

class _HealthArticle {
  final String category;
  final String title;
  final String summary;
  final String content;
  final IconData icon;
  final Color color;

  const _HealthArticle({
    required this.category,
    required this.title,
    required this.summary,
    required this.content,
    required this.icon,
    required this.color,
  });
}

const _articles = [
  _HealthArticle(
    category: 'Kesehatan Anak',
    title: 'Pantau tumbuh kembang secara berkala',
    summary: 'Catatan rutin membantu melihat perubahan pertumbuhan anak.',
    content:
        'Bawa anak ke Posyandu atau fasilitas kesehatan untuk pemantauan berat '
        'dan panjang atau tinggi badan secara berkala. Bawa Buku KIA dan '
        'perhatikan perubahan hasil dari waktu ke waktu. Jika berat badan '
        'tidak naik, kurva pertumbuhan menurun, atau ada hal yang '
        'mengkhawatirkan, konsultasikan dengan kader atau tenaga kesehatan. '
        'Satu hasil pengukuran saja tidak cukup untuk menentukan diagnosis.',
    icon: Icons.show_chart,
    color: Color(0xFF2A9D8F),
  ),
  _HealthArticle(
    category: 'Nutrisi Anak',
    title: 'MPASI dimulai saat anak berusia 6 bulan',
    summary: 'Berikan makanan beragam sesuai usia sambil meneruskan ASI.',
    content:
        'ASI eksklusif dianjurkan selama 6 bulan pertama. Mulai usia 6 bulan, '
        'berikan makanan pendamping ASI yang beragam dan sesuai tekstur serta '
        'kebutuhan usia, sambil tetap melanjutkan pemberian ASI hingga 2 tahun '
        'atau lebih. Jaga kebersihan saat menyiapkan makanan dan ikuti saran '
        'tenaga kesehatan untuk kebutuhan khusus anak.',
    icon: Icons.restaurant,
    color: Color(0xFFE58A3A),
  ),
  _HealthArticle(
    category: 'Kesehatan Ibu',
    title: 'Kenali tanda bahaya selama kehamilan',
    summary: 'Beberapa keluhan perlu segera diperiksa, tidak menunggu jadwal kontrol.',
    content:
        'Segera cari pertolongan tenaga kesehatan bila terjadi perdarahan, '
        'nyeri kepala hebat atau pandangan kabur, kejang, sesak berat, nyeri '
        'perut hebat, demam tinggi, atau gerak janin berkurang. Hubungi bidan '
        'atau fasilitas kesehatan terdekat untuk arahan dan pemeriksaan; '
        'jangan menunda pertolongan sampai jadwal kontrol berikutnya.',
    icon: Icons.pregnant_woman,
    color: Color(0xFFB95778),
  ),
];

class HealthArticlesSection extends StatelessWidget {
  const HealthArticlesSection({super.key});

  Future<void> _openArticle(BuildContext context, _HealthArticle article) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(article.icon, color: article.color),
                  const SizedBox(width: 8),
                  Text(
                    article.category,
                    style: TextStyle(
                      color: article.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                article.title,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(article.content),
              const SizedBox(height: 20),
              const Text(
                'Informasi ini bersifat edukatif dan bukan pengganti pemeriksaan '
                'atau saran dari tenaga kesehatan.',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Artikel Kesehatan Ibu & Anak',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._articles.map(
          (article) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: article.color.withValues(alpha: 0.12),
                child: Icon(article.icon, color: article.color),
              ),
              title: Text(article.title),
              subtitle: Text('${article.category} - ${article.summary}'),
              trailing: const Icon(Icons.chevron_right),
              isThreeLine: true,
              onTap: () => _openArticle(context, article),
            ),
          ),
        ),
      ],
    );
  }
}
